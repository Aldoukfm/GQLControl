//
//  ImageURLQuery.swift
//  GQLControl
//
//  Created by Aldo Fuentes on 2/26/19.
//  Copyright © 2019 aldofuentes. All rights reserved.
//

import Foundation

public class ImageURLQuery: _Query {
    
    public typealias Value = UIImage
    
    var query: URLQuery
    var completionHandlerQueue = DispatchQueue.main
    
    public init(url: URL) {
        self.query = URLQuery(url: url)
    }
    
    public init(url: String?) {
        self.query = URLQuery(url: url)
    }
    
    public func execute(completion: @escaping (Result<UIImage>) -> ()) {
        let queue = self.completionHandlerQueue
        query.execute { (result) in
            let newResult: Result<UIImage>
            switch result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    newResult = Result.success(image)
                } else {
                    newResult = Result.failure(QueryError.decodingError)
                }
            case .failure(let error):
                newResult = Result.failure(error)
            }
            queue.async(execute: {
                completion(newResult)
            })
        }
    }
    
    public func cancel() {
        query.cancel()
    }
}
