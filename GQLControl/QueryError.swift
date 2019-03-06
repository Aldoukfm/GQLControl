//
//  QueryError.swift
//  GQLControl
//
//  Created by Aldo Fuentes on 2/26/19.
//  Copyright © 2019 aldofuentes. All rights reserved.
//

import Foundation

public enum QueryError: String, Error {
    case nonImplemented
    case operationTypeNotSupported
    case noData
    case decodingError
    case nonRequested
    case noURL
}
