//
//  OperationController.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/15/19.
//  Copyright © 2019 softtek. All rights reserved.
//


import Foundation

private struct ObserverWrapper {
    weak var observer: OperationObserver?
}

open class ObservableOperationController: NSObject {

    public var id: Int = 0

    private var operations: [ID: ObservableOperation] = [:]
    
    private var observers: [ID: [Int: ObserverWrapper]] = [:]
    
    public var keepOperations = false
    
    public var queue = OperationQueue.GQLQuery

    public func addObserver(_ observer: OperationObserver, for id: ID) {
        let wrapper = ObserverWrapper(observer: observer)
        var newObservers: [Int: ObserverWrapper] = observers[id] ?? [:]
        newObservers[observer.id] = wrapper

        observers.updateValue(newObservers, forKey: id)
    }

    public func removeObserver(_ observer: OperationObserver, for id: ID) {
        guard var currentObservers = observers[id] else { return }
        currentObservers.removeValue(forKey: observer.id)
    }

    public func removeAllObservers(for id: ID) {
        observers.removeValue(forKey: id)
    }

    public func execute(_ operation: ObservableOperation) {
        if let currentOp = operations[operation.id] {
            currentOp.cancel()
        }
        operations[operation.id] = operation
        operation.observer = self
        queue.addOperation(operation)
    }
    
    public func execute(_ operations: [ObservableOperation]) {
        for op in operations {
            execute(op)
        }
    }
    
    public func pendingUpdate(for id: ID) -> Any? {
        return operations[id]?.update
    }
    
    public func isExecutingOperation(with id: ID) -> Bool {
        return operations[id]?.isExecuting ?? false
    }
    
    public func didFinishOperation(with id: ID) -> Bool {
        return operations[id]?.isFinished ?? false
    }
    
    public func cancelOperation(with id: ID) {
        operations[id]?.cancel()
    }
    
    open func operation(didCancel operation: ObservableOperation) {
        guard let currentObservers = observers[operation.id] else { return }
        for wrapper in currentObservers.values {
            wrapper.observer?.operation(didCancel: operation)
        }
        if !keepOperations {
            operations.removeValue(forKey: operation.id)
        }
    }
    
    open func operation<Value>(_ operation: ObservableOperation, didCompleteWith result: Result<Value>) {
        guard let currentObservers = observers[operation.id] else { return }
        for wrapper in currentObservers.values {
            wrapper.observer?.operation(operation, didCompleteWith: result)
        }
        if !keepOperations {
            operations.removeValue(forKey: operation.id)
        }
    }
    
    open func operation(willBeing operation: ObservableOperation) {
        guard let currentObservers = observers[operation.id] else { return }
        for wrapper in currentObservers.values {
            wrapper.observer?.operation(willBeing: operation)
        }
    }
    
    deinit {
        for (id, op) in operations {
            observers.removeValue(forKey: id)
            op.cancel()
        }
    }
    
}

extension ObservableOperationController: OperationObserver { }
