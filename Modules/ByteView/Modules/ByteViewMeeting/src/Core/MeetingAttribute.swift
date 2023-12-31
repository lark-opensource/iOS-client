//
//  MeetingAttribute.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/5/31.
//

import Foundation
import ByteViewCommon

public extension MeetingSession {
    func attr<T>(_ key: MeetingAttributeKey, type: T.Type) -> T? {
        MeetingAttributeCache.shared.getAttribute(key, sessionId: sessionId) as? T
    }

    @inline(__always)
    func attr<T>(_ key: MeetingAttributeKey) -> T? {
        attr(key, type: T.self)
    }

    @inline(__always)
    func attr<T>(_ key: MeetingAttributeKey, _ defaultValue: T) -> T {
        if let x = attr(key, type: T.self) {
            return x
        } else {
            return defaultValue
        }
    }

    @discardableResult
    func setAttr<T>(_ value: T?, for key: MeetingAttributeKey) -> T? {
        if let value = value {
            return MeetingAttributeCache.shared.setAttribute(value, for: key, sessionId: sessionId)
        } else {
            return MeetingAttributeCache.shared.removeAttribute(for: key, sessionId: sessionId) as? T
        }
    }

    @discardableResult
    func removeAttr(_ key: MeetingAttributeKey) -> Any? {
        MeetingAttributeCache.shared.removeAttribute(for: key, sessionId: sessionId)
    }
}

/// MeetingSession维护的属性
public struct MeetingAttributeKey: Hashable, ExpressibleByStringLiteral, CustomDebugStringConvertible {
    public let rawValue: String
    public let releaseOnEnd: Bool
    /// - parameter rawValue: 属性名
    /// - parameter releaseOnEnd: 是否在end的时候释放，默认为true。否则在session deinit的时候释放。
    public init(_ rawValue: String, releaseOnEnd: Bool = true) {
        self.rawValue = rawValue
        self.releaseOnEnd = releaseOnEnd
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
        self.releaseOnEnd = true
    }

    public var debugDescription: String {
        releaseOnEnd ? rawValue : "[Ex]\(rawValue)"
    }
}

/// 代持会议属性，避免和MeetingSession循环引用
final class MeetingAttributeCache {
    static let shared = MeetingAttributeCache()

    private let lock = RwLock()
    private var sessionCaches: [String: [MeetingAttributeKey: Any]] = [:]
    private var sessionFullLifeCaches: [String: [MeetingAttributeKey: Any]] = [:]

    func leaveSession(sessionId: String, isDeinit: Bool) {
        lock.withWrite {
            sessionCaches.removeValue(forKey: sessionId)
            if isDeinit {
                sessionFullLifeCaches.removeValue(forKey: sessionId)
            }
        }
    }

    func getAttribute(_ key: MeetingAttributeKey, sessionId: String) -> Any? {
        return lock.withRead {
            if key.releaseOnEnd {
                return sessionCaches[sessionId]?[key]
            } else {
                return sessionFullLifeCaches[sessionId]?[key]
            }
        }
    }

    func setAttribute<T>(_ value: T, for key: MeetingAttributeKey, sessionId: String) -> T? {
        lock.withWrite {
            if key.releaseOnEnd {
                var cache = sessionCaches[sessionId, default: [:]]
                let oldValue = cache.updateValue(value, forKey: key)
                sessionCaches[sessionId] = cache
                return oldValue as? T
            } else {
                var cache = sessionFullLifeCaches[sessionId, default: [:]]
                let oldValue = cache.updateValue(value, forKey: key)
                sessionFullLifeCaches[sessionId] = cache
                return oldValue as? T
            }
        }
    }

    func removeAttribute(for key: MeetingAttributeKey, sessionId: String) -> Any? {
        lock.withWrite {
            if key.releaseOnEnd {
                return sessionCaches[sessionId]?.removeValue(forKey: key)
            } else {
                return sessionFullLifeCaches[sessionId]?.removeValue(forKey: key)
            }
        }
    }
}
