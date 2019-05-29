//
//  MultipartFormDataQuery.swift
//  GQLControl
//
//  Created by Aldo Fuentes on 4/21/19.
//  Copyright © 2019 aldofuentes. All rights reserved.
//

import Foundation

public struct Media {
    public let key: String
    public let filename: String
    public let data: Data
    public let mimeType: MIMEType
    
    public init(key: String, filename: String, data: Data, mimeType: MIMEType) {
        self.key = key
        self.filename = filename
        self.data = data
        self.mimeType = mimeType
    }
}

open class MultipartFormDataQuery: URLQuery {
    
    public var httpMethod: String = "GET"
    public var params: [String: String]?
    public var mediaArr: [Media]?
    
    public init(url: String?, params: [String: String]? = nil, media: [Media]? = nil) {
        super.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        self.params = params
        self.mediaArr = media
    }
    
    public init(url: URL, params: [String: String]? = nil, media: [Media]? = nil) {
        super.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        self.params = params
        self.mediaArr = media
    }
    
    override open func createRequest(url: URL) -> URLRequest {
        var request = super.createRequest(url: url)
        request.httpMethod = self.httpMethod
        let boundary = generateBoundary()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = createBody(params: self.params, mediaArr: self.mediaArr, boundary: boundary)
        
        request.httpBody = body
        
        return request
    }
    
    open func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    open func createBody(params: [String: String]?, mediaArr: [Media]?, boundary: String) -> Data {
        
        let lineBreak = "\r\n"
        let doubleLineBreak = lineBreak + lineBreak
        var body = Data()
        
        if let params = params {
            for (key, value) in params {
                body.append(str: "--\(boundary + lineBreak)")
                body.append(str: "Content-Disposition: form-data; name=\"\(key)\"\(doubleLineBreak)")
                body.append(str: "\(value + lineBreak)")
                
            }
        }
        
        if let mediaArr = mediaArr {
            for media in mediaArr {
                body.append(str: "--\(boundary + lineBreak)")
                body.append(str: "Content-Disposition: form-data; name=\"\(media.key)\"; filename=\"\(media.filename)\"\(lineBreak)")
                body.append(str: "Content-Type: \(media.mimeType.rawValue + doubleLineBreak)")
                body.append(media.data)
                body.append(str: lineBreak)
            }
        }
        
        body.append(str: "--\(boundary)--\(lineBreak)")
        
        return body
    }
}

extension Data {
    mutating func append(str: String) {
        guard let data = str.data(using: .utf8) else { return }
        append(data)
    }
}
