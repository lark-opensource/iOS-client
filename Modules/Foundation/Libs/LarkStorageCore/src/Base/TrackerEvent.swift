//
//  TrackerEvent.swift
//  LarkStorage
//
//  Created by 7Up on 2023/9/4.
//

import Foundation

public struct TrackerEvent {
    public let name: String
    public let metric: [AnyHashable : Any]
    public let category: [AnyHashable : Any]
    public let extra: [AnyHashable : Any]

    init(name: String, metric: [AnyHashable : Any], category: [AnyHashable : Any], extra: [AnyHashable : Any]) {
        self.name = name
        self.metric = metric
        self.category = category
        self.extra = extra
    }
}
