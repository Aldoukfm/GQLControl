//
//  Apollo.swift
//  ApolloGraphql
//
//  Created by Aldo Fuentes on 12/27/18.
//  Copyright © 2018 softtek. All rights reserved.
//

import Foundation
import Apollo

public class Apollo {
    
    public static let shared = Apollo()
    var client: ApolloClient? = nil
    var store: ApolloStore?
    
    @discardableResult
    public static func configure(url: URL, headers: [String: String] = [:]) -> ApolloClient {
        let store = ApolloStore(cache: InMemoryNormalizedCache())
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = headers
        let client = ApolloClient(networkTransport: HTTPNetworkTransport(url: url, configuration: configuration), store: store)
        Apollo.shared.client = client
        Apollo.shared.store = store
        return client
    }
    
    @discardableResult public func fetch<Query: GraphQLQuery>(query: Query, cachePolicy: CachePolicy = .returnCacheDataElseFetch, queue: DispatchQueue = DispatchQueue.main, resultHandler: OperationResultHandler<Query>? = nil) -> Cancellable? {
        guard let client = client else {
            let error = NSError(domain: "GQLControl", code: -999, userInfo: [NSLocalizedDescriptionKey: "No ApolloClient configured"])
            resultHandler?(nil, error)
            return nil
        }
        return client.fetch(query: query, cachePolicy: cachePolicy, queue: queue, resultHandler: resultHandler)
    }
    
    @discardableResult public func perform<Mutation: GraphQLMutation>(mutation: Mutation, queue: DispatchQueue = DispatchQueue.main, resultHandler: OperationResultHandler<Mutation>? = nil) -> Cancellable? {
        guard let client = client else {
            let error = NSError(domain: "GQLControl", code: -999, userInfo: [NSLocalizedDescriptionKey: "No ApolloClient configured"])
            resultHandler?(nil, error)
            return nil
        }
        return client.perform(mutation: mutation, queue: queue, resultHandler: resultHandler)
    }
    
    @discardableResult public func watch<Query: GraphQLQuery>(query: Query, cachePolicy: CachePolicy = .returnCacheDataElseFetch, queue: DispatchQueue = DispatchQueue.main, resultHandler: @escaping OperationResultHandler<Query>) -> Cancellable? {
        guard let client = client else {
            let error = NSError(domain: "GQLControl", code: -999, userInfo: [NSLocalizedDescriptionKey: "No ApolloClient configured"])
            resultHandler(nil, error)
            return nil
        }
        return client.watch(query: query, cachePolicy: cachePolicy, queue: queue, resultHandler: resultHandler)
    }
    
    public func updateCacheOn<Query: GraphQLQuery>(query: Query, _ body: @escaping (inout Query.Data) throws -> Void) throws {
        guard let store = store else {
            let error = NSError(domain: "GQLControl", code: -999, userInfo: [NSLocalizedDescriptionKey: "No ApolloClient configured"])
            throw error
        }
        try store.withinReadWriteTransaction { (transaction) in
            try transaction.update(query: query, body)
        }.await()
    }
    
}
