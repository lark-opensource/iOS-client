//
//  LarkAllActionLogger.swift
//  LarkApp
//
//  Created by sniperj on 2019/8/6.
//

import UIKit
import Foundation
import LKCommonsLogging
import LarkExtensions
import LarkCompatible

enum Phase: Int {

    case began

    case moved

    case stationary

    case ended

    case cancelled

    func toString() -> String {
        switch self {
        case .began:
            return "began"
        case .moved:
            return "moved"
        case .stationary:
            return "stationary"
        case .ended:
            return "ended"
        case .cancelled:
            return "cancelled"
        }
    }
}

@objc
public final class LarkAllActionLoggerLoad: NSObject {

    static private let normalLogger = Logger.log(LarkAllActionLoggerLoad.self, category: "normal")
    static private let uiEventlogger = Logger.log(LarkAllActionLoggerLoad.self, category: "uiEvent")
    static private let lifeCycleLogger = Logger.log(LarkAllActionLoggerLoad.self, category: "lifeCycle")
    static private let performanceLogger = Logger.log(LarkAllActionLoggerLoad.self, category: "performance")

    @objc
    public static func logUIEvent(event: UIEvent) {
        if #available(iOS 13.4, *), event.type == .hover {
            return
        }
        event.allTouches?.filter({ (touch) -> Bool in
            return touch.phase != .moved
        }).forEach({ (touch) in
            // if let view = touch.view {
                let viewDesc = touch.view != nil ? NSStringFromClass(type(of: touch.view!)) : "nil"
                var windowIdentifier = "[not find window]"
                if let touchView = touch.view, let touchWindow = LarkUIKitExtension.getRootWindowByView(touchView) {
                    windowIdentifier = touchWindow.windowIdentifier
                }
                LarkAllActionLoggerLoad
                    .uiEventlogger
                    .info("""
                        touchType = \(Phase(rawValue: touch.phase.rawValue)?.toString() ?? "none") \
                        touTime = \(touch.timestamp) \
                        touchView = \(viewDesc) \
                        touchWindow = \(windowIdentifier) \
                        touchLocation = \(touch.location(in: touch.window))
                        """)
            // }
        })
    }

    @objc
    public static func logLifeCycleInfo(info: String) {
        LarkAllActionLoggerLoad.lifeCycleLogger.info(info)
    }

    @objc
    public static func logPerformanceInfo(info: String) {
        LarkAllActionLoggerLoad.performanceLogger.info(info)
    }

    @objc
    public static func logPerformanceError(error: String) {
        LarkAllActionLoggerLoad.performanceLogger.error(error)
    }

    @objc
    public static func logPerformanceWarn(warn: String) {
        LarkAllActionLoggerLoad.performanceLogger.warn(warn)
    }

    @objc
    public static func logNarmalInfo(info: String) {
        LarkAllActionLoggerLoad.normalLogger.info(info)
    }

    @objc
    public static func logNarmalError(error: String) {
        LarkAllActionLoggerLoad.normalLogger.error(error)
    }
}

@objc
public final class LKCExceptionLogger: NSObject {
    static private let logger = Logger.log(LKCExceptionLogger.self, category: "stack")

    @objc
    public static func logStack(name: String, stack: [String]) {
        var stacks = "thread name:" + name + "\n"
        stack.forEach { (address) in
            stacks.append(address + "\n")
        }
        LKCExceptionLogger.logger.warn(stacks)
    }
}
