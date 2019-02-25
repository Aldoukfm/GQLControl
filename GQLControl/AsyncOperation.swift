//
//  AsyncOperation.swift
//  GQLControl
//
//  Created by Aldo Fuentes on 2/25/19.
//  Copyright © 2019 aldofuentes. All rights reserved.
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
        super.cancel()
        state = .Finished
    }
}
