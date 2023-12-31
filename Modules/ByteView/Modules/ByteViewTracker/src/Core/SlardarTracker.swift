//
//  SlardarTracher.swift
//  Pods
//
//  Created by lunner on 2018/11/13.
//

import Foundation
import LKCommonsTracker
import ByteViewCommon

class SlardarTracker: TrackHandler {
    static let shared = SlardarTracker()

    func track(event: TrackEvent) {
        Tracker.post(toSlardarEvent(event))
    }

    private func toSlardarEvent(_ event: TrackEvent) -> SlardarEvent {
        let name = event.name
        let extra = event.params.rawValue
        return SlardarEvent(name: name, metric: event.slardar?.metric ?? [:], category: event.slardar?.category ?? [:], extra: extra)
    }
}
