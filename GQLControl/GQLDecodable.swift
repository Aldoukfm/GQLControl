//
//  GQLDecodable.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/5/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation
import protocol Apollo.GraphQLFragment

public protocol GQLDecodable {
    associatedtype Fragment: GraphQLFragment
    init?(_ fragment: Fragment)
}
