//
//  OperationController.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/15/19.
//  Copyright © 2019 softtek. All rights reserved.
//


import Foundation
import Apollo

public struct ObserverWrapper {
    public weak var observer: OperationObserver?
    
    public init(_ observer: OperationObserver) {
        self.observer = observer
    }
}

open class ObservableOperationController: NSObject {

    public var observerID: Int = 0

    private var operations: [ID: ObservableOperation] = [:]
    
    private var observers: [ID: [Int: ObserverWrapper]] = [:]
    
    private var watchers: [ID: Cancellable] = [:]
    
    public var keepOperations = false
    
    public var queue = OperationQueue.GQLQuery

    public func addObserver(_ observer: OperationObserver, for id: ID) {
        let wrapper = ObserverWrapper(observer)
        var newObservers: [Int: ObserverWrapper] = observers[id] ?? [:]
        newObservers[observer.observerID] = wrapper

        observers.updateValue(newObservers, forKey: id)
    }
    
    public func addObservers(_ observers: [OperationObserver], for id: ID) {
        for observer in observers {
            addObserver(observer, for: id)
        }
    }

    public func removeObserver(_ observer: OperationObserver, for id: ID) {
        guard var currentObservers = observers[id] else { return }
        currentObservers.removeValue(forKey: observer.observerID)
    }
    
    public func removeObservers(_ observers: [OperationObserver], for id: ID) {
        for observer in observers {
            removeObserver(observer, for: id)
        }
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
    
    open func watch<Query: GraphQLQuery, Value>(query: GQLQuery<Value, Query>, with id: ID) {
        watchers[id]?.cancel()
        watchers[id] = query
        query.watch {[weak self] (result) in
            guard let value = result.value else { return }
            print("Did watch value: \(value)")
            guard let self = self else { return }
            guard let observers = self.observers[id]?.compactMap({ $0.value.observer }) else { return }
            
            for observer in observers {
                observer.operation(didUpdateCacheWith: value, with: id)
            }
        }
    }
    
    open func cancelWatch(onQueryWith id: ID) {
        watchers[id]?.cancel()
    }
    
    deinit {
        for (id, op) in operations {
            observers.removeValue(forKey: id)
            op.cancel()
        }
    }
    
}

extension ObservableOperationController: OperationObserver { }
