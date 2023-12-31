//
//  Event.swift
//  LKRichView
//
//  Created by qihongye on 2021/9/20.
//

import UIKit
import Foundation

/// LKRichEvent
/// Event defination for touches in iPhone or iPad.
public class LKRichEvent {
    /// Event type defination.
    public enum TypeEnum: UInt8 {
        case touchStart
        case touchMove
        case touchEnd
        case touchCancel
        case hover
    }

    /// Event type.
    public let type: TypeEnum

    /// The time when event occurred.
    public let timestamp: TimeInterval

    /// The element respond to event.
    public let target: LKRichElement?

    /// The element hit by event. If no element listen to event, `source` will be equal to `target`.
    public let source: LKRichElement

    /// Is pointer hover event, this is designed for iPad.
    public internal(set) var defaultPrevented: Bool = false

    public internal(set) var isPropagation: Bool = true

    init(type: TypeEnum, source: LKRichElement, target: LKRichElement? = nil, timestamp: TimeInterval) {
        self.type = type
        self.timestamp = timestamp
        self.source = source
        self.target = target ?? source
    }

    public func stopPropagation() {
        isPropagation = false
    }

    /// Prevent default event handler.
    public func preventDefault() {
        defaultPrevented = true
    }
}

public struct LKRichTouch {
    public let source: LKRichElement
    public let target: LKRichElement?
    public let position: CGPoint

    init(source: LKRichElement, target: LKRichElement? = nil, position: CGPoint) {
        self.source = source
        self.target = target
        self.position = position
    }
}

public final class LKRichTouchEvent: LKRichEvent {
    public let touches: [LKRichTouch]

    init(type: TypeEnum, source: LKRichElement, target: LKRichElement? = nil, timestamp: TimeInterval, touches: [LKRichTouch]) {
        self.touches = touches
        super.init(type: type, source: source, target: target, timestamp: timestamp)
    }

    static func create(touchStart event: UIEvent, source: LKRichElement, target: LKRichElement?, touches: [LKRichTouch]) -> LKRichTouchEvent {
        return .init(type: .touchStart, source: source, target: target, timestamp: event.timestamp, touches: touches)
    }

    static func create(touchMove event: UIEvent, source: LKRichElement, target: LKRichElement?, touches: [LKRichTouch]) -> LKRichTouchEvent {
        return .init(type: .touchMove, source: source, target: target, timestamp: event.timestamp, touches: touches)
    }

    static func create(touchEnd event: UIEvent, source: LKRichElement, target: LKRichElement?, touches: [LKRichTouch]) -> LKRichTouchEvent {
        return .init(type: .touchEnd, source: source, target: target, timestamp: event.timestamp, touches: touches)
    }

    static func create(touchCancel event: UIEvent, source: LKRichElement, target: LKRichElement?, touches: [LKRichTouch]) -> LKRichTouchEvent {
        return .init(type: .touchCancel, source: source, target: target, timestamp: event.timestamp, touches: touches)
    }
}
