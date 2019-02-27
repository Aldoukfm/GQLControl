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

    public var operations: [ID: UpdateOperation] = [:]
    
    public var observers: [ID: [Int: OperationObserver]] = [:]
    public var queue = OperationQueue.GQLQuery

    public func addObserver(_ observer: OperationObserver, for id: ID) {

        var newObservers: [Int: OperationObserver] = observers[id] ?? [:]
        newObservers[observer.id] = observer

        observers.updateValue(newObservers, forKey: id)
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
    
    public func execute<Value>(_ operations: [ObservableOperation<Value>]) {
        for op in operations {
            execute(op)
        }
    }
    
    public func pendingUpdate(for id: ID) -> Any? {
        return operations[id]?.update
    }
    
    public func esExecutingOperation(with id: ID) -> Bool {
        return operations[id]?.isExecuting ?? false
    }
    
    public func notifyObservers<Value>(of operation: ObservableOperation<Value>, with result: Result<Value>) {
        guard let currentObservers = observers[operation.id] else { return }
        for observer in currentObservers.values {
            observer.operation(operation, didCompleteWith: result)
        }
    }
    
    open func operation<Value>(_ operation: ObservableOperation<Value>, didCompleteWith result: Result<Value>) {
        operations.removeValue(forKey: operation.id)
        notifyObservers(of: operation, with: result)
    }
    
}

extension ObservableOperationController: OperationObserver { }
