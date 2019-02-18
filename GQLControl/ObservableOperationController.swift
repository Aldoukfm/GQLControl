//
//  OperationController.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/15/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation


open class ObservableOperationController: NSObject {

    public var id: Int = 0

    var operations: [ID: UpdateOperation] = [:]
    
    var observers: [ID: [Int: OperationObserver]] = [:]
    public var queue = OperationQueue.GQLQuery

    public func addObserver(_ observer: OperationObserver, for id: ID) {
        if var currentObservers = observers[id] {
            currentObservers[observer.id] = observer
        } else {
            observers[id] = [observer.id: observer]
        }
    }

    public func removeObserver(_ observer: OperationObserver, for id: ID) {
        guard var currentObservers = observers[id] else { return }
        currentObservers.removeValue(forKey: observer.id)
    }

    public func removeAllObservers(for id: ID) {
        observers.removeValue(forKey: id)
    }

    public func execute<Value>(_ operation: ObservableOperation<Value>) {
        if let currentOp = operations[operation.id] {
            currentOp.cancel()
        }
        operations[operation.id] = operation
        operation.observer = self
        queue.addOperation(operation)
    }
    
    public func pendingUpdate(for id: ID) -> Any? {
        return operations[id]?.update
    }
    
}

extension ObservableOperationController: OperationObserver {

    public func operation<Value>(_ operation: ObservableOperation<Value>, didCompleteWith result: Result<Value>) {
        let id = operation.id
        operations.removeValue(forKey: id)
        guard let currentObservers = observers[id] else { return }
        for observer in currentObservers.values {
            observer.operation(operation, didCompleteWith: result)
        }
    }
}
