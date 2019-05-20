//
//  GQLOperation.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/15/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation

public class QueryOperation<Query: _Query>: AsyncOperation {
    private var query: Query
    private var completion: ((Result<Query.Value>)->())?
    
    init(_ query: Query, completion: ((Result<Query.Value>)->())? = nil) {
        self.query = query
        self.completion = completion
    }
    
    override public func main() {
        if isCancelled { return }
        query.execute {[weak self] (result) in
            guard let self = self else { return }
            if self.isCancelled { return }
            self.completion?(result)
            self.state = .Finished
        }
    }
    
    public override func cancel() {
        super.cancel()
        query.cancel()
    }
}

public class QueryObservableOperation<Query: _Query>: ObservableOperation {
    
    private var query: Query

    init(id: ID, _ query: Query) {
        self.query = query
        super.init(id: id)
    }

    override public func main() {
        if isCancelled { return }
        observer?.operation(willBeing: self)
        query.execute {[weak self] (result) in
            guard let self = self else { return }
            if self.isCancelled { return }
            self.observer?.operation(self, didCompleteWith: result)
            self.state = .Finished
        }
    }

    public override func cancel() {
        super.cancel()
        query.cancel()
        observer?.operation(didCancel: self)
    }
}
