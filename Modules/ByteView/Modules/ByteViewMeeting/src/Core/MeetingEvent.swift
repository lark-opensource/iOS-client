//
//  MeetingEvent.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/5/31.
//

import Foundation

public struct MeetingEvent {
    public let name: MeetingEventName
    public let params: [MeetingAttributeKey: Any]

    public init(name: MeetingEventName, params: [MeetingAttributeKey: Any] = [:]) {
        self.name = name
        self.params = params
    }

    public func param<T>(for key: MeetingAttributeKey, defaultValue: T) -> T {
        if let value = params[key] as? T {
            return value
        } else {
            return defaultValue
        }
    }

    public func appendParam<T>(_ value: T, for key: MeetingAttributeKey) -> MeetingEvent {
        var p = params
        p[key] = value
        return MeetingEvent(name: name, params: p)
    }
}

public struct MeetingEventName: RawRepresentable, ExpressibleByStringLiteral, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}

extension MeetingEventName: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String { rawValue }
    public var description: String { rawValue }
}

public extension MeetingEventName {
    /// 切换账户
    static let changeAccount: MeetingEventName = "changeAccount"
    /// 忙线响铃：接听
    static let acceptOther: MeetingEventName = "acceptOther"
}

public extension MeetingAttributeKey {
    /// acceptOther的参数，value类型为MeetingSession
    static let otherSession: MeetingAttributeKey = "otherSession"
}
