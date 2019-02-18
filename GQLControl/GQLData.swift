//
//  GQLData.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/5/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation

public protocol GQLData {
    associatedtype Result
    func parseResult() -> Result?
}
