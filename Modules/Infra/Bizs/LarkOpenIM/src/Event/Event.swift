//
//  Event.swift
//  LarkOpenChat
//
//  Created by 李勇 on 2020/12/7.
//

import UIKit
import Foundation

/// 事件类型
public enum EventType: Int {
    case chat
    case message
    case keyboard
}

/// 事件基类，Chat内流转的事件都必须继承自此类
open class Event {
    /// name
    open class var name: String {
        assertionFailure("Must be overrided.")
        return "name"
    }
    /// name
    public var name: String { return Self.name }
    /// type
    open class var type: EventType {
        assertionFailure("Must be overrided.")
        return .chat
    }
    /// 事件由哪个类发出
    public var source: AnyClass?
    /// 事件创建的时间
    public let timestamp: CFTimeInterval = CACurrentMediaTime()

    public init() {}
}
