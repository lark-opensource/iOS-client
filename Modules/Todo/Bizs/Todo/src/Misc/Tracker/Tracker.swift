//
//  Tracker.swift
//  Todo
//
//  Created by 张威 on 2021/4/26.
//

import LKCommonsTracker

typealias Tracker = LKCommonsTracker.Tracker

// MARK: TrackerConvertible

protocol TrackerEventKeyConvertible {
    var eventKey: String { get }
}

protocol TrackerConvertible {
    associatedtype TrackerEvent: TrackerEventKeyConvertible
}

extension TrackerConvertible {

    static func trackEvent(_ event: TrackerEvent, with params: [AnyHashable: Any] = [:]) {
        Tracker.post(TeaEvent(event.eventKey, params: params))
    }
}

// MARK: TrackerUtil

struct TrackerUtil { }
