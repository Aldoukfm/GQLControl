//
//  Result.swift
//  GQLControl
//
//  Created by Aldo Fuentes on 2/17/19.
//  Copyright © 2019 aldofuentes. All rights reserved.
//

import Foundation

public enum Result<Value> {
    case success(Value)
    case failure(Error)
}

extension Result: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success(let value):
            return "Success(\(value))"
        case .failure(let error):
            return "Error(\(error))"
        }
    }
}

extension Result {
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure(_):
            return nil
        }
    }
    
    public var error: Error? {
        switch self {
        case .success(_):
            return nil
        case .failure(let error):
            return error
        }
    }
    
    public func valueOrError() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
