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
    
    public static func configure(url: URL) {
        Apollo.shared.client = ApolloClient(url: url)
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
}
