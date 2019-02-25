//
//  ObservableOperation.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/17/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation

public protocol OperationObserver: class {
    var id: Int { get set }
    func operation<Value>(_ operation: ObservableOperation<Value>, didCompleteWith result: Result<Value>)
}

public class ObservableOperation<Value>: UpdateOperation {
    weak var observer: OperationObserver?
    public var id: ID
    
    public init(id: ID) {
        self.id = id
        super.init()
    }
    
    public convenience init(id: ID, update: Any?) {
        self.init(id: id)
        self.update = update
    }
}
