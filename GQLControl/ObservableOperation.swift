//
//  ObservableOperation.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/17/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation

public protocol OperationObserver: class {
    var id: Int { get set }
    func operation<Value>(_ operation: ObservableOperation<Value>, didCompleteWith result: Result<Value>)
}

public class UpdateOperation: Operation {
    public var update: Any?
}

public class ObservableOperation<Value>: UpdateOperation {
    weak var observer: OperationObserver?
    public var id: ID
    var result: Result<Value> = Result.failure(QueryError.nonRequested)
    
    public init(id: ID) {
        self.id = id
        super.init()
        completionBlock = { [weak self] in
            guard let self = self else { return }
            self.observer?.operation(self, didCompleteWith: self.result)
        }
    }
    
    public convenience init(id: ID, update: Any?) {
        self.init(id: id)
        self.update = update
    }
    
}
