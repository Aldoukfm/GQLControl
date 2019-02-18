//
//  QueueController.swift
//  Innotek
//
//  Created by Aldo Fuentes on 2/15/19.
//  Copyright © 2019 softtek. All rights reserved.
//

import Foundation

class QueueController {
    static let shared = QueueController()
    let GQLQueryQueue: DispatchQueue = DispatchQueue(label: "GQLQueryQueue", qos: DispatchQoS.userInteractive, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem, target: nil)
    let GQLOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "GQLOperationQueue"
        queue.qualityOfService = .userInteractive
        return queue
    }()
}

extension OperationQueue {
    public static var GQLQuery: OperationQueue {
        return QueueController.shared.GQLOperationQueue
    }
}
extension DispatchQueue {
    public static var GQLQuery: DispatchQueue {
        return QueueController.shared.GQLQueryQueue
    }
}
