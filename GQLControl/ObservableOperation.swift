//
//  ObservableOperation.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/17/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation

public protocol OperationObserver: class {
    var observerID: Int { get set }
    func operation<Value>(_ operation: ObservableOperation, didCompleteWith result: Result<Value>)
    func operation(willBeing operation: ObservableOperation)
    func operation(didCancel operation: ObservableOperation)
    func operation<Value>(didUpdateCacheWith value: Value, with id: ID)
}

public extension OperationObserver {
    func operation(willBeing operation: ObservableOperation) {}
    func operation(didCancel operation: ObservableOperation) {}
    func operation<Value>(didUpdateCacheWith value: Value, with id: ID) {}
}

public class ObservableOperation: AsyncOperation {
    @objc public dynamic var update: Any?
    public weak var observer: OperationObserver?
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
