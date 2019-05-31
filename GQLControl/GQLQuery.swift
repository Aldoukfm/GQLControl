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
    public var cachePolicy: CachePolicy = CachePolicy.returnCacheDataElseFetch
    
    public init<Query: GraphQLQuery>(sequenceQuery: Query) where QueryType.Data.Result: Sequence, Value: Sequence, Value.Element: GQLDecodable, Value.Element.Fragment == QueryType.Data.Result.Element, Value: ExpressibleByArrayLiteral {
        self.apolloOperation = sequenceQuery.asAnyOperation() as! AnyApolloOperation<QueryType>
        let collectionDecoder = CollectionDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(collectionDecoder)
    }
    
    public init<Query: GraphQLQuery>(valueQuery: Query) where Value: GQLDecodable, Value.Fragment == QueryType.Data.Result {
        self.apolloOperation = valueQuery.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ObjectDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
    }
    
    public init<Query: GraphQLQuery>(literalQuery: Query) where Value == QueryType.Data.Result {
        self.apolloOperation = literalQuery.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ScalarDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
    }
    
    public init<Mutation: GraphQLMutation>(sequenceMutation: Mutation) where QueryType.Data.Result: Sequence, Value: Sequence, Value.Element: GQLDecodable, Value.Element.Fragment == QueryType.Data.Result.Element, Value: ExpressibleByArrayLiteral {
        self.apolloOperation = sequenceMutation.asAnyOperation() as! AnyApolloOperation<QueryType>
        let collectionDecoder = CollectionDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(collectionDecoder)
    }
    
    public init<Mutation: GraphQLMutation>(valueMutation: Mutation) where Value: GQLDecodable, Value.Fragment == QueryType.Data.Result {
        self.apolloOperation = valueMutation.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ObjectDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
    }
    
    public init<Mutation: GraphQLMutation>(literalMutation: Mutation) where Value == QueryType.Data.Result {
        self.apolloOperation = literalMutation.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ScalarDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
    }
    
    open func execute(completion: @escaping (Result<Value>)->()) {
        
        let decoder = self.decoder
        
        let didLoadData: ((_ data: QueryType.Data) -> ())? = self.didLoadData
        
        cancellable = apolloOperation.execute(on: queue, cachePolicy: cachePolicy) { (result, error) in
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
        
        self.queue = DispatchQueue.GQLQuery
        
        let decoder = self.decoder
        let didLoadCache: ((_ data: QueryType.Data) -> ())? = self.didLoadCache
        
        cancellable = apolloOperation.watch(on: queue, cachePolicy: cachePolicy, completion: { (result, error) in
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


open class GQLQuery2<Value, QueryType: GraphQLOperation>: Query<Value> where QueryType.Data: GQLData {
    
    var apolloOperation: AnyApolloOperation<QueryType>
    var decoder: AnyGQLDecoder<QueryType.Data.Result, Value>
    var apolloQueue: DispatchQueue = DispatchQueue.GQLQuery
    public var cancellable: Cancellable?
    public var didLoadData: ((QueryType.Data)->())?
    public var didLoadCache: ((QueryType.Data)->())?
    public var cachePolicy: CachePolicy = CachePolicy.returnCacheDataElseFetch
    
    public init<Query: GraphQLQuery>(valueQuery: Query) where Value: GQLDecodable, Value.Fragment == QueryType.Data.Result {
        self.apolloOperation = valueQuery.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ObjectDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
        super.init()
        self.queue = OperationQueue.GQLQuery
    }
    
    open override func execution(completion: @escaping (Result<Value>)->()) {
        
        let decoder = self.decoder
        
        let didLoadData: ((_ data: QueryType.Data) -> ())? = self.didLoadData
        
        cancellable = apolloOperation.execute(on: apolloQueue, cachePolicy: cachePolicy) { (result, error) in
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
    
    open override func cancel() {
        super.cancel()
        cancellable?.cancel()
    }
    
    public init<Query: GraphQLQuery>(sequenceQuery: Query) where QueryType.Data.Result: Sequence, Value: Sequence, Value.Element: GQLDecodable, Value.Element.Fragment == QueryType.Data.Result.Element, Value: ExpressibleByArrayLiteral {
        self.apolloOperation = sequenceQuery.asAnyOperation() as! AnyApolloOperation<QueryType>
        let collectionDecoder = CollectionDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(collectionDecoder)
        super.init()
        self.queue = OperationQueue.GQLQuery
    }
    
    public init<Query: GraphQLQuery>(literalQuery: Query) where Value == QueryType.Data.Result {
        self.apolloOperation = literalQuery.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ScalarDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
        super.init()
        self.queue = OperationQueue.GQLQuery
    }

    public init<Mutation: GraphQLMutation>(sequenceMutation: Mutation) where QueryType.Data.Result: Sequence, Value: Sequence, Value.Element: GQLDecodable, Value.Element.Fragment == QueryType.Data.Result.Element, Value: ExpressibleByArrayLiteral {
        self.apolloOperation = sequenceMutation.asAnyOperation() as! AnyApolloOperation<QueryType>
        let collectionDecoder = CollectionDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(collectionDecoder)
        super.init()
        self.queue = OperationQueue.GQLQuery
    }

    public init<Mutation: GraphQLMutation>(valueMutation: Mutation) where Value: GQLDecodable, Value.Fragment == QueryType.Data.Result {
        self.apolloOperation = valueMutation.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ObjectDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
        super.init()
        self.queue = OperationQueue.GQLQuery
    }

    public init<Mutation: GraphQLMutation>(literalMutation: Mutation) where Value == QueryType.Data.Result {
        self.apolloOperation = literalMutation.asAnyOperation() as! AnyApolloOperation<QueryType>
        let objectDecoder = ScalarDecoder<QueryType.Data.Result, Value>()
        self.decoder = AnyGQLDecoder(objectDecoder)
        super.init()
        self.queue = OperationQueue.GQLQuery
    }
    
}


//extension GQLQuery2 where QueryType: GraphQLQuery {
//    open func watch(completion: @escaping (Result<Value>)->()) {
//
//        self.apolloQueue = DispatchQueue.GQLQuery
//
//        let decoder = self.decoder
//        let didLoadCache: ((_ data: QueryType.Data) -> ())? = self.didLoadCache
//
//        cancellable = apolloOperation.watch(on: apolloQueue, cachePolicy: cachePolicy, completion: { (result, error) in
//            guard error == nil else {
//                completion(Result.failure(error!))
//                return
//            }
//            guard let rawData = result?.data else {
//                completion(Result.failure(QueryError.noData))
//                return
//            }
//
//            guard let resultData = rawData.parseResult() else {
//                completion(Result.failure(QueryError.noData))
//                return
//            }
//            do {
//                let newResult = try decoder.decode(Value.self, from: resultData)
//                completion(Result.success(newResult))
//            } catch {
//                completion(Result.failure(error))
//            }
//            didLoadCache?(rawData)
//        })
//    }
//
////    open func updateCache(_ body: @escaping (inout QueryType.Data) throws -> Void) throws {
////        try apolloOperation.updateCache(body)
////    }
//}
