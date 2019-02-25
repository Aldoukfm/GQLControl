//
//  AsyncOperation.swift
//  Apollo
//
//  Created by Aldo Fuentes on 2/24/19.
//

import Foundation

public class AsyncOperation: Operation {
    enum State: String {
        case Ready, Executing, Finished
        
        fileprivate var keyPath: String {
            return "is" + rawValue
        }
    }
    
    var state = State.Ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
}


extension AsyncOperation {
    
    override public var isReady: Bool {
        return super.isReady && state == .Ready
    }
    
    override public var isExecuting: Bool {
        return state == .Executing
    }
    
    override public var isFinished: Bool {
        return state == .Finished
    }
    
    override public var isAsynchronous: Bool {
        return true
    }
    
    override public func start() {
        if isCancelled {
            state = .Finished
            return
        }
        
        main()
        state = .Executing
    }
    
    override public func cancel() {
        state = .Finished
    }
}

public class QueryOperation<Query: _Query>: AsyncOperation {
    
}
