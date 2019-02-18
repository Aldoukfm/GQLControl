//
//  Apollo.swift
//  ApolloGraphql
//
//  Created by Aldo Fuentes on 12/27/18.
//  Copyright © 2018 softtek. All rights reserved.
//

import Foundation
import Apollo

public class Apollo {
    
    public static let shared = Apollo()
    static let url: String = "http://localhost:7071/api/graphQL"
    public let client: ApolloClient

    init() {
        client = ApolloClient(url: URL(string: Apollo.url)!)
    }
}
