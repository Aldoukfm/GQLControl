//
//  GQLOperation.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/15/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation
import protocol Apollo.GraphQLOperation


public class GQLOperation<Value, QueryType: GraphQLOperation>: Operation where QueryType.Data: GQLData {
    
    var query: GQLQuery<Value, QueryType>
    var result: Result<Value> = Result.failure(QueryError.nonRequested)
    
    init(_ query: GQLQuery<Value, QueryType>, completion: ((Result<Value>)->())? = nil) {
        self.query = query
        super.init()
        completionBlock = { [weak self] in
            guard let self = self else { return }
            self.isCancelled ? nil : completion?(self.result)
        }
    }
    override public func main() {
        if isCancelled { return }
        result = query.execute()
    }
    
    override public func cancel() {
        super.cancel()
        query.cancel()
    }
}

public class GQLObservableOperation<Value, QueryType: GraphQLOperation>: ObservableOperation<Value> where QueryType.Data: GQLData {
    
    var query: GQLQuery<Value, QueryType>
    
    init(id: ID, query: GQLQuery<Value, QueryType>) {
        self.query = query
        super.init(id: id)
    }
    
    override public func main() {
        if isCancelled { return }
        self.result = query.execute()
    }
    
    override public func cancel() {
        super.cancel()
        query.cancel()
    }
    
}

extension Operation {
    public func execute(on operation: OperationQueue = OperationQueue.GQLQuery) {
        operation.addOperation(self)
    }
}

