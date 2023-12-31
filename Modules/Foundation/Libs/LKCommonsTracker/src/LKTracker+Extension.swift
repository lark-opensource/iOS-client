//
//  LKTracker.swift
//  LKCommonsTracker
//
//  Created by 李晨 on 2019/4/11.
//

import Foundation

extension Tracker {
    public static func post(_ event: SlardarEvent) {
        self.tracker(key: .slardar).post(event: event)
    }
    public static func post(_ event: SlardarCustomEvent) {
        self.tracker(key: .slardar).post(event: event)
    }

    public static func post(_ event: TeaEvent) {
        self.tracker(key: .tea).post(event: event)
    }

    public static func register(key: Platform, tracker: TrackerService) {
        Tracker.shared.register(key: key, tracker: tracker)
    }

    public static func unregister(key: Platform, tracker: TrackerService) {
        Tracker.shared.unregister(key: key, tracker: tracker)
    }

    public static func unregisterAll(key: Platform) {
        Tracker.shared.unregisterAll(key: key)
    }

    static func tracker(key: Platform) -> TrackerService {
        return Tracker.shared.tracker(key: key)
    }

    public static func start(token: String) {
        Tracker.shared.start(token: token)
    }

    /// WARNING: Will be discarded
    public static func end(token: String) -> Timestamp? {
        return Tracker.shared.end(token: token)
    }

    public static func end(token: String, platform: Platform, evtgen: (TimeInterval?) -> Event) {
        let duration = Tracker.shared.end(token: token)?.duration
        guard duration != nil else {
            /// Error
            assert(false, "Dont't exist start time for token \(token) in LKCommonsTracker")
            return
        }
        self.tracker(key: platform).post(event: evtgen(duration))
    }
}
