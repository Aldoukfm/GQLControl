//
//  ApolloOperation.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/5/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation
import Apollo

protocol ApolloOperation {
    associatedtype OperationType: GraphQLOperation
    
    func execute(on queue: DispatchQueue, completion: @escaping (GraphQLResult<OperationType.Data>?, Error?) -> ()) -> Cancellable?
    func watch(on queue: DispatchQueue, completion: @escaping (GraphQLResult<OperationType.Data>?, Error?) -> ()) -> Cancellable?
    func updateCache( _ body: @escaping (inout OperationType.Data) throws -> Void) throws
}

private class _AnyApolloOperationBase<OperationType: GraphQLOperation>: ApolloOperation {
    
    func execute(on queue: DispatchQueue, completion: @escaping (GraphQLResult<OperationType.Data>?, Error?) -> ()) -> Cancellable? {
        fatalError()
    }
    
    func updateCache(_ body: @escaping (inout OperationType.Data) throws -> Void) throws {
        fatalError()
    }
    
    func watch(on queue: DispatchQueue, completion: @escaping (GraphQLResult<OperationType.Data>?, Error?) -> ()) -> Cancellable? {
        fatalError()
    }
}

private final class _AnyApolloOperationBox<Concrete: ApolloOperation>: _AnyApolloOperationBase<Concrete.OperationType> {
    var concrete: Concrete
    init(_ concrete: Concrete) {
        self.concrete = concrete
    }
    override func execute(on queue: DispatchQueue, completion: @escaping (GraphQLResult<Concrete.OperationType.Data>?, Error?) -> ()) -> Cancellable? {
        return concrete.execute(on: queue, completion: completion)
    }
    
    override func watch(on queue: DispatchQueue, completion: @escaping (GraphQLResult<Concrete.OperationType.Data>?, Error?) -> ()) -> Cancellable? {
        return concrete.watch(on: queue, completion: completion)
    }
    
    override func updateCache(_ body: @escaping (inout Concrete.OperationType.Data) throws -> Void) throws {
        try concrete.updateCache(body)
    }
}

final class AnyApolloOperation<OperationType: GraphQLOperation>: ApolloOperation {
    
    private let box: _AnyApolloOperationBase<OperationType>
    init<Concrete: ApolloOperation>(_ concrete: Concrete) where Concrete.OperationType == OperationType {
        self.box = _AnyApolloOperationBox(concrete)
    }
    func execute(on queue: DispatchQueue, completion: @escaping (GraphQLResult<OperationType.Data>?, Error?) -> ()) -> Cancellable? {
        return box.execute(on: queue, completion: completion)
    }
    func watch(on queue: DispatchQueue, completion: @escaping (GraphQLResult<OperationType.Data>?, Error?) -> ()) -> Cancellable? {
        return box.watch(on: queue, completion: completion)
    }
    func updateCache(_ body: @escaping (inout OperationType.Data) throws -> Void) throws {
        try box.updateCache(body)
    }
}

struct ApolloQuery<Query: GraphQLQuery>: ApolloOperation {
    
    typealias OperationType = Query
    var query: Query
    init(_ query: Query) {
        self.query = query
    }
    
    func execute(on queue: DispatchQueue, completion: @escaping (GraphQLResult<Query.Data>?, Error?) -> ()) -> Cancellable? {
        return Apollo.shared.fetch(query: query, queue: queue) { (result, error) in
            completion(result, error)
        }
    }
    
    func watch(on queue: DispatchQueue, completion: @escaping (GraphQLResult<Query.Data>?, Error?) -> ()) -> Cancellable? {
        return Apollo.shared.watch(query: query, cachePolicy: CachePolicy.returnCacheDataDontFetch, queue: queue, resultHandler: { (result, error) in
            completion(result, error)
        })
    }
    
    func updateCache(_ body: @escaping (inout Query.Data) throws -> Void) throws {
        try Apollo.shared.updateCacheOn(query: query, body)
    }
    
}

struct ApolloMutation<Mutation: GraphQLMutation>: ApolloOperation {
    
    typealias OperationType = Mutation
    var mutation: Mutation
    init(_ mutation: Mutation) {
        self.mutation = mutation
    }
    
    func execute(on queue: DispatchQueue, completion: @escaping (GraphQLResult<Mutation.Data>?, Error?) -> ()) -> Cancellable? {
        return Apollo.shared.perform(mutation: mutation, queue: queue) { (result, error) in
            completion(result, error)
        }
    }
    
    func updateCache( _ body: @escaping (inout OperationType.Data) throws -> Void) throws {
        let error = NSError(domain: "GQLControl", code: -998, userInfo: [NSLocalizedDescriptionKey: "Can not update cache on mutation"])
        throw error
    }
    
    func watch(on queue: DispatchQueue, completion: @escaping (GraphQLResult<Mutation.Data>?, Error?) -> ()) -> Cancellable? {
        let error = NSError(domain: "GQLControl", code: -998, userInfo: [NSLocalizedDescriptionKey: "Can not update cache on mutation"])
        completion(nil, error)
        return nil
    }
    
}


extension GraphQLQuery {
    ///Transform GraphQLQuery into AnyApolloOperation
    func asAnyOperation() -> AnyApolloOperation<Self> {
        let qq = ApolloQuery(self)
        return AnyApolloOperation(qq)
    }
}

extension GraphQLMutation {
    ///Transform GraphQLMutation into AnyApolloOperation
    func asAnyOperation() -> AnyApolloOperation<Self> {
        let qq = ApolloMutation(self)
        return AnyApolloOperation(qq)
    }
}
