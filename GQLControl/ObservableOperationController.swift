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

open class ObservableOperationController: NSObject, OperationObserver {

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

public struct ObserverWrapper2 {
    public weak var observer: QueryObserver?
    
    public init(_ observer: QueryObserver) {
        self.observer = observer
    }
}

open class ObservableOperationController2: NSObject, QueryObserver {
    
    public var observerID: Int = 0
    
    private var operations: [ID: ObservableOperation2] = [:]
    
    private var observers: [ID: [Int: ObserverWrapper2]] = [:]
    
    public var keepOperations = false
    
    public var queue = OperationQueue.GQLQuery
    
    open func addObserver(_ observer: QueryObserver, for id: ID) {
        let wrapper = ObserverWrapper2(observer)
        var newObservers: [Int: ObserverWrapper2] = observers[id] ?? [:]
        newObservers[observer.observerID] = wrapper
        
        observers.updateValue(newObservers, forKey: id)
    }
    
    open func addObservers(_ observers: [QueryObserver], for id: ID) {
        for observer in observers {
            addObserver(observer, for: id)
        }
    }
    
    open func removeObserver(_ observer: QueryObserver, for id: ID) {
        guard var currentObservers = observers[id] else { return }
        currentObservers.removeValue(forKey: observer.observerID)
    }
    
    open func removeObservers(_ observers: [QueryObserver], for id: ID) {
        for observer in observers {
            removeObserver(observer, for: id)
        }
    }
    
    open func removeAllObservers(for id: ID) {
        observers.removeValue(forKey: id)
    }
    
    open func removeAllObservers() {
        observers.removeAll()
    }
    
    open func execute<Value>(_ query: Query<Value>) {
        guard let id = query.id else {
            fatalError("Query has no ID")
        }
        if let currentOp = operations[id] {
            currentOp.cancel()
        }
        operations[id] = query
        query.observer = self
        queue.addOperation(query)
    }
    
    open func execute<Value>(_ operations: [Query<Value>]) {
        for op in operations {
            execute(op)
        }
    }
    
    open func pendingUpdate(for id: ID) -> Any? {
        return operations[id]?.update
    }
    
    open func isExecutingOperation(with id: ID) -> Bool {
        return operations[id]?.isExecuting ?? false
    }
    
    open func didFinishOperation(with id: ID) -> Bool {
        return operations[id]?.isFinished ?? false
    }
    
    open func cancelOperation(with id: ID) {
        operations[id]?.cancel()
    }
    
    open func cancelAllOperations() {
        operations.values.forEach({ $0.cancel() })
    }
    
    open func query<Value>(_ operation: Query<Value>, didCompleteWith result: Result<Value>) {
        guard let id = operation.id else {
            fatalError("Query has no ID")
        }
        guard let currentObservers = observers[id] else { return }
        for wrapper in currentObservers.values {
            wrapper.observer?.query(operation, didCompleteWith: result)
        }
//        if !keepOperations {
//            if let index = operations.index(forKey: id) {
//                operations[id] = nil
////                operations.remove(at: index)
//            }
////            operations.removeValue(forKey: id)
//        }
    }
    
    open func query<Value>(willBeing operation: Query<Value>) {
        guard let id = operation.id else {
            fatalError("Query has no ID")
        }
        guard let currentObservers = observers[id] else { return }
        for wrapper in currentObservers.values {
            wrapper.observer?.query(willBeing: operation)
        }
    }
    
    open func query<Value>(didCancel operation: Query<Value>) {
        guard let id = operation.id else {
            fatalError("Query has no ID")
        }
        guard let currentObservers = observers[id] else { return }
        for wrapper in currentObservers.values {
            wrapper.observer?.query(didCancel: operation)
        }
        if !keepOperations {
            operations.removeValue(forKey: id)
        }
    }
    
    deinit {
        for (id, op) in operations {
            observers.removeValue(forKey: id)
            op.cancel()
        }
    }
    
}


