//
//  TeaTracker.swift
//  Pods
//
//  Created by lunner on 2018/11/13.
//
import Foundation
import LKCommonsTracker
import ByteViewCommon

class TeaTracker: TrackHandler {
    static let shared = TeaTracker()

    func track(event: TrackEvent) {
        Tracker.post(toTeaEvent(event))
    }

    private func toTeaEvent(_ event: TrackEvent) -> TeaEvent {
        TeaEvent(event.name, category: "byteview", params: event.params.rawValue, timestamp: Timestamp(time: event.trackTime.timeIntervalSince1970))
    }
}
