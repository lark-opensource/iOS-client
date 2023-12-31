//
//  MinutesTracker.swift
//  Minutes_iOS
//
//  Created by panzaofeng on 2020/12/23.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import LKCommonsTracker
import MinutesFoundation

/// class MinutesTracker
public class SlardarTracker {
    public init() {
    }

    public func tracker(service: String, metric: [String: Any], category: [String: Any]) {
        #if DEBUG
        MinutesLogger.common.debug("SlardarTracker service: \(service) metric: \(metric), category: \(category)")
        #else
        let event = SlardarEvent(name: service, metric: metric, category: category, extra: [:])
        Tracker.post(event)
        #endif
    }
}
