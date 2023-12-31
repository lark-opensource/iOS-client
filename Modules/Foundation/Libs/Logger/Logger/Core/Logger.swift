//
//  Logger.swift
//  Lark
//
//  Created by linlin on 2017/3/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

protocol LogVendor {

    func writeEvent(_ event: LogEvent)

    func addAppender(_ appender: Appender, persistent status: Bool)
}

public struct LogEnv {
    public let logLevel: LogLevel

    public init(logLevel: LogLevel) {
        self.logLevel = logLevel
    }
}

fileprivate var unfairLock = os_unfair_lock_s()

public final class Logger {
    static var shared: Logger = Logger()
    fileprivate var vendors: [String: LogVendorImpl] = [:]
    fileprivate var vender: LogVendorImpl = LogVendorImpl(appenders: [])

    public init() {}

    static public func setup(appenders: [Appender], backendType: String = "") {
        if backendType == "" {
            shared.vender.setup(appenders: appenders)
            return
        }

        os_unfair_lock_lock(&unfairLock)
        if let vendor = shared.vendors[backendType] {
            os_unfair_lock_unlock(&unfairLock)
            vendor.setup(appenders: appenders)
        } else {
            shared.vendors[backendType] = LogVendorImpl(appenders: appenders)
            os_unfair_lock_unlock(&unfairLock)
        }
    }

    /// 创建 Log 对象
    /// - Parameters:
    ///   - type: Log Type Class
    ///   - category: category 先关信息
    ///   - backendType: backendType 用于指定 Log 对应 Appenders
    ///   - forwardToDefault: 是否转发至默认 Log Appender
    static public func log(
        _ type: AnyClass,
        category: String = "",
        backendType: String = "",
        forwardToDefault: Bool = false
    ) -> Log {
        return Log(type, category: category, vendor: { [unowned shared] in
            let vender = shared.vendor(backendType)

            /// forwardToDefault 表明需要转发到默认 Log
            if forwardToDefault && backendType != "" {
                let forward = shared.vendor("")
                if vender !== forward {
                    return LogVenderProxy(
                        vender: vender,
                        forward: forward
                    )
                }
            }
            return vender
        })
    }

    public static func commit(backendType: String = "") {
        shared.vendor(backendType).appenders.forEach { (appender) in
            appender.commit()
        }
    }

    // MARK: - Add and Remove Appender

    public static func isActivate<T: Appender>(appenderType: T.Type, backendType: String = "") -> Bool {
        return !(shared.vendor(backendType).isActivate(appenderType) == nil)
    }

    // TODO: 需要讨论是否可以可以添加重复类型的  Appender
    public static func add(appender: Appender, persistent status: Bool = false, backendType: String = "") {
        let appenderType = type(of: appender)
        let vendor = shared.vendor(backendType)
        if vendor.isActivate(appenderType) == nil {
            vendor.addAppender(appender, persistent: status)
        }
    }

    public static func remove<T: Appender>(appenderType: T.Type, persistent status: Bool = false, backendType: String = "") {
        let vendor = shared.vendor(backendType)
        if let appender = vendor.isActivate(appenderType) {
            vendor.removeAppender(appender, persistent: status)
        }
    }

    public static func update(appender: Appender, backendType: String = "") {
        shared.vendor(backendType).updateAppender(appender)
    }

    private func vendor(_ backendType: String) -> LogVendorImpl {
        let vendor: LogVendorImpl
        if backendType == "" {
            vendor = self.vender
        } else {
            os_unfair_lock_lock(&unfairLock)
            vendor = self.vendors[backendType] ?? self.vender
            os_unfair_lock_unlock(&unfairLock)
        }
        return vendor
    }
}

public enum LogLevel: Int {
    case trace
    case debug
    case info
    case warn
    case error
    case fatal
}

func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func > (lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue > rhs.rawValue
}

func <= (lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}

func >= (lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}

struct LevelColor {
    static let trace = "💜"    // silver
    static let debug = "💚"    // green
    static let info = "💙"     // blue
    static let warning = "💛"  // yellow
    static let error = "❤️"    // red
}

public typealias LoggerLogEvent = LogEvent

public struct LogEvent {
    public let logId: String
    public let time: TimeInterval
    public var type: AnyClass
    public let tags: [String]
    public let level: LogLevel
    public let message: String
    public let thread: String
    public let file: String
    public let function: String
    public let line: Int
    public var category: String
    public let error: Error?
    public let params: [String: String]?

    public init(logId: String = "",
                time: TimeInterval = Date().timeIntervalSince1970,
                tags: [String] = [],
                type: AnyClass = AnyObject.self,
                level: LogLevel,
                message: String,
                thread: String = Thread.current.description,
                file: String = #fileID,
                function: String = #function,
                line: Int = #line,
                category: String = "",
                error: Error? = nil,
                params: [String: String]? = nil) {
        self.logId = logId
        self.time = time
        self.type = type
        self.tags = tags
        self.level = level
        self.message = message
        self.thread = thread
        self.file = file
        self.function = function
        self.line = line
        self.category = category
        self.error = error
        self.params = params
    }
}
