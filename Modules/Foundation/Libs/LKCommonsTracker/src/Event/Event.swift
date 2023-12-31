//
//  Event.swift
//  LKCommonsTracker
//
//  Created by 李晨 on 2019/3/25.
//

import Foundation

public class Event {
    public let name: String
    public let timestamp: Timestamp

    public init(
        name: String,
        timestamp: Timestamp = Tracker.currentTime()) {
        self.name = name
        self.timestamp = timestamp
    }
}

extension Event: CustomStringConvertible {
    public var description: String {
        return "Tracker event, \(self.timestamp), type \(type(of: self)), name \(self.name)"
    }
}

extension Event: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}

public struct Timestamp {
    public let start: TimeInterval
    public let end: TimeInterval
    public var duration: TimeInterval {
        return self.end - self.start
    }

    public init(start: TimeInterval, end: TimeInterval) {
        self.start = start
        self.end = end
    }

    public init(time: TimeInterval) {
        self.start = time
        self.end = time
    }
}

extension Timestamp: CustomStringConvertible {
    public var description: String {
        if self.duration > 0 {
            let startDesc = Date(timeIntervalSince1970: self.start)
            let endDesc = Date(timeIntervalSince1970: self.end)
            let durationDesc = self.duration
            return "start: \(startDesc), end: \(endDesc), duration: \(durationDesc)"
        } else {
            return "time: \(Date(timeIntervalSince1970: self.start))"
        }
    }
}

extension Timestamp: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}
