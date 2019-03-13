//
//  GQLQuery.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/5/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation
import Apollo

public protocol _GQLQuery: _Query {
    var cancellable: Cancellable? { get set }
}

extension _GQLQuery {
    public func cancel() {
        cancellable?.cancel()
    }
}

open class GQLQuery<Value, QueryType: GraphQLOperation>: _GQLQuery where QueryType.Data: GQLData {
    
    var apolloOperation: AnyApolloOperation<QueryType>
    var decoder: AnyGQLDecoder<QueryType.Data.Result, Value>
    var queue: DispatchQueue = DispatchQueue.GQLQuery
    public var cancellable: Cancellable?
    public var didLoadData: ((QueryType.Data)->())?
    public var didLoadCache: ((QueryType.Data)->())?
    
    public init<Query: GraphQLQuery>(_ query: Query) where QueryType.Data.Result: Sequence, Value: Sequence, Value.Element: GQLDecodable, Value.Element.Fragment == QueryType.Data.Result.Element, Value: ExpressibleByArrayLiteral {
        self.apolloOperation = query.asAnyOperation() as! AnyApolloOperation<QueryType>
        let collectionDecoder = CollectionDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(collectionDecoder)
    }
    
    public init<Query: GraphQLQuery>(_ query: Query) where Value: GQLDecodable, Value.Fragment == QueryType.Data.Result {
        self.apolloOperation = query.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ObjectDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
    }
    
    public init<Query: GraphQLQuery>(_ query: Query) where Value == QueryType.Data.Result {
        self.apolloOperation = query.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ScalarDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
    }
    
    public init<Mutation: GraphQLMutation>(_ mutation: Mutation) where QueryType.Data.Result: Sequence, Value: Sequence, Value.Element: GQLDecodable, Value.Element.Fragment == QueryType.Data.Result.Element, Value: ExpressibleByArrayLiteral {
        self.apolloOperation = mutation.asAnyOperation() as! AnyApolloOperation<QueryType>
        let collectionDecoder = CollectionDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(collectionDecoder)
    }
    
    public init<Mutation: GraphQLMutation>(_ mutation: Mutation) where Value: GQLDecodable, Value.Fragment == QueryType.Data.Result {
        self.apolloOperation = mutation.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ObjectDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
    }
    
    public init<Mutation: GraphQLMutation>(_ mutation: Mutation) where Value == QueryType.Data.Result {
        self.apolloOperation = mutation.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ScalarDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
    }
    
    open func execute(completion: @escaping (Result<Value>)->()) {
        
        let decoder = self.decoder
        
        let didLoadData: ((_ data: QueryType.Data) -> ())? = self.didLoadData
        
        cancellable = apolloOperation.execute(on: queue) { (result, error) in
            guard error == nil else {
                completion(Result.failure(error!))
                return
            }
            guard let rawData = result?.data else {
                completion(Result.failure(QueryError.noData))
                return
            }
            
            guard let resultData = rawData.parseResult() else {
                completion(Result.failure(QueryError.noData))
                return
            }
            do {
                let newResult = try decoder.decode(Value.self, from: resultData)
                completion(Result.success(newResult))
            } catch {
                completion(Result.failure(error))
            }
            
            didLoadData?(rawData)
        }
    }
    
}


extension GQLQuery where QueryType: GraphQLQuery {
    open func watch(completion: @escaping (Result<Value>)->()) {
        
        self.queue = DispatchQueue.GQLQueryWatcher
        
        let decoder = self.decoder
        let didLoadCache: ((_ data: QueryType.Data) -> ())? = self.didLoadCache
        
        cancellable = apolloOperation.watch(on: queue, completion: { (result, error) in
            guard error == nil else {
                completion(Result.failure(error!))
                return
            }
            guard let rawData = result?.data else {
                completion(Result.failure(QueryError.noData))
                return
            }
            
            guard let resultData = rawData.parseResult() else {
                completion(Result.failure(QueryError.noData))
                return
            }
            do {
                let newResult = try decoder.decode(Value.self, from: resultData)
                completion(Result.success(newResult))
            } catch {
                completion(Result.failure(error))
            }
            didLoadCache?(rawData)
        })
    }
    
    open func updateCache(_ body: @escaping (inout QueryType.Data) throws -> Void) throws {
        try apolloOperation.updateCache(body)
    }
}
