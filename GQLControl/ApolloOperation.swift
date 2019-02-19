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
}

private class _AnyApolloOperationBase<OperationType: GraphQLOperation>: ApolloOperation {
    func execute(on queue: DispatchQueue, completion: @escaping (GraphQLResult<OperationType.Data>?, Error?) -> ()) -> Cancellable? {
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
}

final class AnyApolloOperation<OperationType: GraphQLOperation>: ApolloOperation {
    private let box: _AnyApolloOperationBase<OperationType>
    init<Concrete: ApolloOperation>(_ concrete: Concrete) where Concrete.OperationType == OperationType {
        self.box = _AnyApolloOperationBox(concrete)
    }
    func execute(on queue: DispatchQueue, completion: @escaping (GraphQLResult<OperationType.Data>?, Error?) -> ()) -> Cancellable? {
        return box.execute(on: queue, completion: completion)
    }
}


extension GraphQLQuery {
    func asAnyOperation() -> AnyApolloOperation<Self> {
        let qq = ApolloQuery(self)
        return AnyApolloOperation(qq)
    }
}

extension GraphQLMutation {
    func asAnyOperation() -> AnyApolloOperation<Self> {
        let qq = ApolloMutation(self)
        return AnyApolloOperation(qq)
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
}
