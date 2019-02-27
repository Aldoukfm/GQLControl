//
//  OperationExt.swift
//  GQLControl
//
//  Created by Aldo Fuentes on 2/25/19.
//  Copyright © 2019 aldofuentes. All rights reserved.
//

import Foundation

extension Operation {
    public func execute(on operation: OperationQueue = OperationQueue.GQLQuery) {
        operation.addOperation(self)
    }
}
