//
//  URLQuery.swift
//  GQLControl
//
//  Created by Aldo Fuentes on 2/26/19.
//  Copyright © 2019 aldofuentes. All rights reserved.
//

import Foundation

open class URLQuery: _Query {
    
    public typealias Value = Data
    
    public var url: URL?
    public var task: URLSessionDataTask?
    public var cachePolicy: NSURLRequest.CachePolicy
    public var timeoutInterval: TimeInterval = 15
    var headers: [String: String] = [:]
    
    public init(url: URL, cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad) {
        self.url = url
        self.cachePolicy = cachePolicy
    }
    
    public init(url: String?, cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad) {
        self.url = URL(string: url ?? "")
        self.cachePolicy = cachePolicy
    }
    
    open func execute(completion: @escaping (Result<Value>) -> ()) {
        guard let url = url else {
            completion(Result.failure(QueryError.noURL))
            return
        }
        let session = URLSession.shared
        var request = createRequest(url: url)
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        task = session.dataTask(with: request) {(data, response, error) in
            var result: Result<Value> = Result.failure(QueryError.nonRequested)
            if let error = error {
                result = Result.failure(error)
            } else if let data = data {
                result = Result.success(data)
            } else {
                result = Result.failure(QueryError.noData)
                
            }
            completion(result)
        }
        task!.resume()
    }
    
    public func cancel() {
        task?.cancel()
    }
    
    open func createRequest(url: URL) -> URLRequest {
        return URLRequest(url: url, cachePolicy: self.cachePolicy, timeoutInterval: self.timeoutInterval)
    }
    
    public func setValue(_ value: String, forHTTPHeaderField field: String) {
        headers[field] = value
    }
}



open class URLQuery2: Query<Data> {
    
    public var url: URL?
    public var task: URLSessionDataTask?
    public var cachePolicy: NSURLRequest.CachePolicy
    public var timeoutInterval: TimeInterval = 15
    var headers: [String: String] = [:]
    
    public init(url: URL, cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad) {
        self.url = url
        self.cachePolicy = cachePolicy
        super.init()
    }
    
    public init(url: String?, cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad) {
        self.url = URL(string: url ?? "")
        self.cachePolicy = cachePolicy
        super.init()
    }
    
    open override func execution(completion: @escaping (Result<Data>) -> ()) {
        guard let url = url else {
            completion(Result.failure(QueryError.noURL))
            return
        }
        let session = URLSession.shared
        var request = createRequest(url: url)
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        task = session.dataTask(with: request) {(data, response, error) in
            var result: Result<Value> = Result.failure(QueryError.nonRequested)
            if let error = error {
                result = Result.failure(error)
            } else if let data = data {
                result = Result.success(data)
            } else {
                result = Result.failure(QueryError.noData)
                
            }
            completion(result)
        }
        task!.resume()
    }
    
    open override func cancel() {
        super.cancel()
        task?.cancel()
    }
    
    open func createRequest(url: URL) -> URLRequest {
        return URLRequest(url: url, cachePolicy: self.cachePolicy, timeoutInterval: self.timeoutInterval)
    }
    
    public func setValue(_ value: String, forHTTPHeaderField field: String) {
        headers[field] = value
    }
}
