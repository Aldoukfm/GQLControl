//
//  Query.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/15/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation


public typealias ID = String

public protocol _Query {
    associatedtype Value
    
    func execute(completion: @escaping (Result<Value>)->())
    func cancel()
}

extension _Query {
    func execute(completion: (Result<Value>)->()) {
        completion(Result.failure(QueryError.nonImplemented))
    }
    func execute() -> Result<Value> {
        var newResult = Result<Value>.failure(QueryError.nonImplemented)
        let group = DispatchGroup()
        group.enter()
        execute { (result) in
            newResult = result
            group.leave()
        }
        group.wait()
        return newResult
    }
    public func operation(completion: @escaping (Result<Value>)->()) -> QueryOperation<Self> {
        return QueryOperation.init(self, completion: completion)
    }
    
    public func observableOperation(id: ID) -> QueryObservableOperation<Self> {
        return QueryObservableOperation(id: id, self)
    }
    
}



enum QueryError: String, Error {
    case nonImplemented
    case operationTypeNotSupported
    case noData
    case decodingError
    case nonRequested = "Query non fetched"
}
