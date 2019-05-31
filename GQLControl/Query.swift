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

public protocol QueryObserver: class {
    var observerID: Int { get set }
    func operation<Value>(_ operation: Query<Value>, didCompleteWith result: Result<Value>)
    func operation<Value>(willBeing operation: Query<Value>)
    func operation<Value>(didCancel operation: Query<Value>)
}

open class Query<Value>: AsyncOperation, _Query {
    
    open var queue: OperationQueue?
    
    open var _execution: ( ( ((Result<Value>) -> ())? ) -> ())!
    open var completion: ((Result<Value>) -> ())?
    open var cancellation: (() -> ())?
    
    @objc public dynamic var update: Any?
    public weak var observer: QueryObserver?
    public var id: ID?
    
    public init(query: @escaping ( ( ((Result<Value>) -> ())? ) -> ()) ) {
        _execution = query
    }
    
    public override init() {
        super.init()
        _execution = {[unowned self] completion in
            self.execution(completion: { (result) in
                completion?(result)
            })
        }
    }
    
    public init(error: Error) {
        _execution = { completion in
            completion?(Result.failure(error))
        }
    }
    
    open override func main() {
        observer?.operation(willBeing: self)
        _execution {[unowned self] (result) in
            if self.isCancelled { return }
            self.completion?(result)
            self.observer?.operation(self, didCompleteWith: result)
            self.state = .Finished
        }
    }
    
    open func execution(completion: @escaping (Result<Value>) -> ()) {
        completion(Result.failure(QueryError.nonImplemented))
    }
    
    open func execute(completion: @escaping (Result<Value>) -> ()) {
        self.completion = completion
        let queue = self.queue ?? OperationQueue()
        queue.addOperation(self)
    }
    
    public func execute() {
        let queue = self.queue ?? OperationQueue()
        queue.addOperation(self)
    }
    
    public func then<NewValue>(_ execute: @escaping (Value) -> (Query<NewValue>)) -> Query<NewValue> {
        let query = ChainQuery.init(query: self, execute: execute)
        query.queue = self.queue
        return query
    }
    
    public func then<NewValue>(_ execute: @escaping () -> (Query<NewValue>)) -> Query<NewValue> {
        let query = ChainQuery.init(query: self, execute: execute)
        query.queue = self.queue
        return query
    }
    
    public func then(_ execute: @escaping (Value) throws -> ()) -> Query {
        let query = ChainQuery<Value>.init(query: self, execute: execute)
        query.queue = self.queue
        return query
    }
    
    public func then(onMainThread execute: @escaping (Value) -> ()) -> Query {
        let query = ChainQuery<Value>.init(query: self, onMainThread: execute)
        query.queue = self.queue
        return query
    }
    
    public func parse<NewValue>(_ transform: @escaping (Value) -> (NewValue)) -> Query<NewValue> {
        let query = ChainQuery<NewValue>.init(query: self, transform: transform)
        query.queue = self.queue
        return query
    }
    
    open override func cancel() {
        super.cancel()
        cancellation?()
        observer?.operation(didCancel: self)
    }
    
}

class ChainQuery<Value>: Query<Value> {
    
    var chainQueue: OperationQueue = OperationQueue()
    
    var chainOperations: [Operation] = []
    
    override init(query: @escaping ((((Result<Value>) -> ())?) -> ())) {
        super.init(query: query)
    }
    
    init<OldValue>(query: Query<OldValue>, execute: @escaping (OldValue) -> (Query<Value>)) {
        super.init { (_) in }
        chainOperations.append(query)
        _execution =  {[unowned self] (completion) in
            
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
    
    init<OldValue>(query: Query<OldValue>, execute: @escaping () -> (Query<Value>)) {
        super.init { (_) in }
        chainOperations.append(query)
        _execution =  {[unowned self] (completion) in
            
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
    
    init(query: Query<Value>, execute: @escaping (Value) throws -> ()) {
        super.init { (_) in }
        chainOperations.append(query)
        _execution =  {[unowned self] (completion) in
            var then: Query<Value>?
            query.completion = { result in
                switch result {
                case .success(let value):
                    then = Query(query: { (completion2) in
                        do {
                            try execute(value)
                            completion2?(result)
                        } catch {
                            completion2?(Result.failure(error))
                        }
                    })
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
    
    init(query: Query<Value>, onMainThread execute: @escaping (Value) -> ()) {
        super.init { (_) in }
        chainOperations.append(query)
        _execution =  {[unowned self] (completion) in
            var then: Query<Value>?
            query.completion = { result in
                switch result {
                case .success(let value):
                    then = Query<Value>(query: { (completion2) in
                        DispatchQueue.main.async {
                            execute(value)
                            completion2?(result)
                        }
                    })
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion?(Result.failure(error))
                    }
                }
            }
            self.executeOperations()
            guard let newQuery = then else { return }
            newQuery.completion = completion
            self.chainOperations = [newQuery]
            self.executeOperations()
        }
    }
    
    init<OldValue>(query: Query<OldValue>, transform: @escaping (OldValue) -> (Value)) {
        super.init { (_) in }
        chainOperations.append(query)
        _execution =  {[unowned self] (completion) in
            var then: Query<Value>?
            query.completion = { result in
                switch result {
                case .success(let value):
                    then = Query<Value>(query: { (completion2) in
                        let newValue = transform(value)
                        completion2?(Result.success(newValue))
                    })
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
    
    override func then<NewValue>(_ execute: @escaping (Value) -> (Query<NewValue>)) -> Query<NewValue> {

        let prevExecution = _execution!
        let query = ChainQuery<NewValue>.init { (_) in }
        query.cancellation = self.cancellation
        query.chainQueue = self.chainQueue
        query.chainOperations = self.chainOperations
        query._execution = {[unowned query] (completion) in
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
            newQuery.completion = completion
            query.chainOperations = [newQuery]
            query.executeOperations()
        }
        
        return query
    }
    
    override func then<NewValue>(_ execute: @escaping () -> (Query<NewValue>)) -> Query<NewValue> {
//        let prevExecution = _execution!
//        self._execution = {[unowned self] completion in
//
//            var then: Query<NewValue>?
//            prevExecution { result in
//                switch result {
//                case .success(let value):
//                    then = execute()
//                case .failure(let error):
//                    completion?(Result.failure(error))
//                }
//            }
//            guard let newQuery = then else { return }
//            newQuery.completion = (completion as! ((Result<NewValue>) -> ()))
//            self.chainOperations = [newQuery]
//            self.executeOperations()
//        }
//        return self as! Query<NewValue>
        
        let query = ChainQuery<NewValue>.init { (_) in }
        query.cancellation = self.cancellation
        query.chainQueue = self.chainQueue
        query.chainOperations = self.chainOperations
        query.queue = self.queue
        query._execution = {[unowned query] (completion) in
            var then: Query<NewValue>?
            self._execution { result in
                switch result {
                case .success(let value):
                    then = execute()
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            guard let newQuery = then else { return }
            newQuery.completion = completion
            query.chainOperations = [newQuery]
            query.executeOperations()
        }
        
        return query
    }
    
    override func then(_ execute: @escaping (Value) throws -> ()) -> Query<Value> {
        let prevExecution = _execution!
        self._execution = {[unowned self] completion in
            var then: Query<Value>?
            prevExecution { result in
                switch result {
                case .success(let value):
                    then = Query(query: { (completion2) in
                        do {
                            try execute(value)
                            completion2?(result)
                        } catch {
                            completion2?(Result.failure(error))
                        }
                    })
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            guard let newQuery = then else { return }
            newQuery.completion = completion
            self.chainOperations = [newQuery]
            self.executeOperations()
        }
        return self
    }
    
    override func then(onMainThread execute: @escaping (Value) -> ()) -> Query<Value> {
        let prevExecution = _execution!
        self._execution = {[unowned self] completion in
            
            var then: Query<Value>?
            prevExecution { result in
                switch result {
                case .success(let value):
                    then = Query(query: { (completion2) in
                        DispatchQueue.main.async {
                            execute(value)
                            completion2?(result)
                        }
                    })
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion?(Result.failure(error))
                    }
                }
            }
            guard let newQuery = then else { return }
            newQuery.completion = completion
            self.chainOperations = [newQuery]
            self.executeOperations()
        }
        return self
    }
    
    override func parse<NewValue>(_ transform: @escaping (Value) -> (NewValue)) -> Query<NewValue> {
        let query = ChainQuery<NewValue>.init { (_) in }
        query.cancellation = self.cancellation
        query.chainQueue = self.chainQueue
        query.chainOperations = self.chainOperations
        query.queue = self.queue
        query._execution = {[unowned query] (completion) in
            var then: Query<NewValue>?
            self._execution { result in
                switch result {
                case .success(let value):
                    then = Query(query: { (completion2) in
                        let transformed = transform(value)
                        completion2?(Result.success(transformed))
                    })
                case .failure(let error):
                    completion?(Result.failure(error))
                }
            }
            guard let newQuery = then else { return }
            newQuery.completion = completion
            query.chainOperations = [newQuery]
            query.executeOperations()
        }
        
        return query
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


public extension Error {
    func queryThrowingError<Value>() -> Query<Value> {
        return Query.init(error: self)
    }
}

public func QuerySuccess<Value>(_ value: Value) -> Query<Value> {
    return Query(query: { (completion) in
        completion?(Result.success(value))
    })
}

public func QueryThrowError<Value>(_ error: Error) -> Query<Value> {
    return Query(query: { (completion) in
        completion?(Result.failure(error))
    })
}
