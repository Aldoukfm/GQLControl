//
//  Query.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/15/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation
import protocol Apollo.Cancellable

public typealias ID = String

public protocol _Query: Cancellable {
    associatedtype Value
    
    func execute(completion: @escaping (Result<Value>)->())
    func cancel()
}

extension _Query {
    func execute(completion: (Result<Value>)->()) {
        completion(Result.failure(QueryError.nonImplemented))
    }
    func execute() -> Result<Value> {
        var newResult = Result<Value>.failure(QueryError.nonImplemented)
        let group = DispatchGroup()
        group.enter()
        execute { (result) in
            newResult = result
            group.leave()
        }
        group.wait()
        return newResult
    }
    public func operation(completion: @escaping (Result<Value>)->()) -> QueryOperation<Self> {
        return QueryOperation.init(self, completion: completion)
    }
    
    public func observableOperation(id: ID) -> QueryObservableOperation<Self> {
        return QueryObservableOperation(id: id, self)
    }
    
}


open class Query<Value>: AsyncOperation, _Query {
    
    open var queue: OperationQueue?
    
    open var execution: ( ( ((Result<Value>) -> ())? ) -> ())!
    open var completion: ((Result<Value>) -> ())?
    open var cancellation: (() -> ())?
    
    public init(query: @escaping ( ( ((Result<Value>) -> ())? ) -> ()) ) {
        execution = query
    }
    
    open override func main() {
        execution {[weak self] (result) in
            guard let self = self else { return }
            if self.isCancelled { return }
            self.completion!(result)
            self.state = .Finished
        }
    }
    
    public func execute(completion: @escaping (Result<Value>) -> ()) {
        self.completion = completion
        guard let queue = queue else {
            completion(Result.failure(QueryError.noOperationQueue))
            return
        }
        queue.addOperation(self)
    }
    
    public func then<NewValue>(_ execute: @escaping (Value) -> (Query<NewValue>)) -> Query<NewValue> {
        let query = ChainQuery.init(query: self, execute: execute)
        query.queue = self.queue
        return query
    }
    
    public func then<NewValue>(_ execute: @escaping @autoclosure () -> (Query<NewValue>)) -> Query<NewValue> {
        let query = ChainQuery.init(query: self, execute: execute)
        query.queue = self.queue
        return query
    }
    
    public func then(_ execute: @escaping (Value) -> ()) -> Query {
        let query = ChainQuery<Value>.init(query: self, execute: execute)
        query.queue = self.queue
        return query
    }
    
    public func then(onMainThread execute: @escaping (Value) -> ()) -> Query {
        let query = ChainQuery<Value>.init(query: self, onMainThread: execute)
        query.queue = self.queue
        return query
    }
    
    open override func cancel() {
        super.cancel()
        cancellation?()
    }
    
}

class ChainQuery<Value>: Query<Value> {
    
    var chainQueue: OperationQueue = OperationQueue()
    
    var chainOperations: [Operation] = []
    
    init<OldValue>(query: Query<OldValue>, execute: @escaping (OldValue) -> (Query<Value>)) {
        super.init { (_) in }
        chainOperations.append(query)
        execution =  {[weak self] (completion) in
            guard let self = self else { return }
            
            var then: Query<Value>?
            query.completion = { result in
                switch result {
                case .success(let value):
                    then = execute(value)
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            self.executeOperations()
            guard let newQuery = then else { return }
            newQuery.completion = completion
            self.chainOperations = [newQuery]
            self.executeOperations()
            
        }
    }
    
    init<OldValue>(query: Query<OldValue>, execute: @escaping @autoclosure () -> (Query<Value>)) {
        super.init { (_) in }
        chainOperations.append(query)
        execution =  {[weak self] (completion) in
            guard let self = self else { return }
            
            var then: Query<Value>?
            query.completion = { result in
                switch result {
                case .success(let value):
                    then = execute()
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            self.executeOperations()
            guard let newQuery = then else { return }
            newQuery.completion = completion
            self.chainOperations = [newQuery]
            self.executeOperations()
            
        }
    }
    
    init<Value>(query: Query<Value>, execute: @escaping (Value) -> ()) {
        super.init { (_) in }
        chainOperations.append(query)
        execution =  {[unowned self] (completion) in
            var then: Query<Value>?
            query.completion = { result in
                switch result {
                case .success(let value):
                    then = Query(query: { (completion) in
                        execute(value)
                        completion?(result)
                    })
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            self.executeOperations()
            guard let newQuery = then else { return }
            newQuery.completion = completion as! ((Result<Value>) -> ())
            self.chainOperations = [newQuery]
            self.executeOperations()
        }
    }
    
    init<Value>(query: Query<Value>, onMainThread execute: @escaping (Value) -> ()) {
        super.init { (_) in }
        chainOperations.append(query)
        execution =  {[unowned self] (completion) in
            var then: Query<Value>?
            query.completion = { result in
                switch result {
                case .success(let value):
                    then = Query<Value>(query: { (completion) in
                        DispatchQueue.main.async {
                            execute(value)
                            completion?(result)
                        }
                    })
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            self.executeOperations()
            guard let newQuery = then else { return }
            newQuery.completion = completion as? ((Result<Value>) -> ())
            self.chainOperations = [newQuery]
            self.executeOperations()
        }
    }
    
    override func then<NewValue>(_ execute: @escaping (Value) -> (Query<NewValue>)) -> Query<NewValue> {
        let prevExecution = execution!
        self.execution = {[weak self] completion in
            guard let self = self else { return }
            var then: Query<NewValue>?
            prevExecution { result in
                switch result {
                case .success(let value):
                    then = execute(value)
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            guard let newQuery = then else { return }
            newQuery.completion = (completion as? ((Result<NewValue>) -> ()))
            self.chainOperations = [newQuery]
            self.executeOperations()
        }
        return self as! Query<NewValue>
    }
    
    override func then<NewValue>(_ execute: @escaping @autoclosure () -> (Query<NewValue>)) -> Query<NewValue> {
        let prevExecution = execution!
        self.execution = {[weak self] completion in
            guard let self = self else { return }
            var then: Query<NewValue>?
            prevExecution { result in
                switch result {
                case .success(let value):
                    then = execute()
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            guard let newQuery = then else { return }
            newQuery.completion = (completion as! ((Result<NewValue>) -> ()))
            self.chainOperations = [newQuery]
            self.executeOperations()
        }
        return self as! Query<NewValue>
    }
    
    override func then(_ execute: @escaping (Value) -> ()) -> Query<Value> {
        let prevExecution = execution!
        self.execution = {[weak self] completion in
            guard let self = self else { return }
            var then: Query<Value>?
            prevExecution { result in
                switch result {
                case .success(let value):
                    then = Query(query: { (completion) in
                        execute(value)
                        completion?(result)
                    })
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            guard let newQuery = then else { return }
            newQuery.completion = (completion as! ((Result<Value>) -> ()))
            self.chainOperations = [newQuery]
            self.executeOperations()
        }
        return self
    }
    
    func executeOperations() {
        chainQueue.addOperations(chainOperations, waitUntilFinished: true)
    }
    
    override func cancel() {
        super.cancel()
        for op in chainOperations {
            op.cancel()
        }
    }
}
