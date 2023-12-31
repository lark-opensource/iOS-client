//
//  Logger.swift
//  ByteView
//
//  Created by kiri on 2020/8/26.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging

/// Logger的回调，由ByteView主工程实现
public protocol LogDelegate: AnyObject {
    func didLog(on category: String)
}

public enum LogLevel: Int, Hashable, Comparable {
    case trace = 0
    case debug
    case info
    case warn
    case error
    case fatal

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public final class Logger {
    fileprivate static weak var delegate: LogDelegate?
    public static func setup(_ delegate: LogDelegate?) {
        self.delegate = delegate
    }

    public var category: String { logger.category }
    private let logger: LoggerImpl
    private let contextId: String?
    private let tag: String?
    private init(_ logger: LoggerImpl, contextId: String?, tag: String?) {
        self.logger = logger
        self.contextId = contextId
        self.tag = tag
    }

    // MARK: - factory
    private static let lock = NSLock()
    private static var factories: [String: Logger] = [:]

    /// 获取Logger实例
    /// - parameters:
    ///     - category: 名称，相同category返回同一个的Logger，真正的category = `"\(prefix).\(category)"`
    ///     - prefix: 名称前缀，默认ByteView
    public static func getLogger(_ category: String, prefix: String = "ByteView") -> Logger {
        lock.lock()
        defer { lock.unlock() }
        let fullName = "\(prefix).\(category)"
        if let logger = factories[fullName] {
            return logger
        } else {
            let logger = Logger(LoggerImpl(fullName), contextId: nil, tag: nil)
            factories[fullName] = logger
            return logger
        }
    }

    public func withContext(_ contextId: String) -> Logger {
        if contextId.isEmpty, self.contextId == nil { return self }
        if self.contextId == contextId { return self }
        return Logger(self.logger, contextId: contextId, tag: self.tag)
    }

    public func withTag(_ tag: String) -> Logger {
        if tag.isEmpty, self.tag == nil { return self }
        if self.tag == tag { return self }
        return Logger(self.logger, contextId: self.contextId, tag: tag)
    }
}

public extension Logger {
    func log(_ level: LogLevel, _ message: String, error: Error? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        var prefix = "[\(category)]"
        if let tag = tag, !tag.isEmpty {
            prefix += tag
        }
        var params: [String: String]?
        if let contextId = contextId, !contextId.isEmpty {
            params = ["contextID": contextId]
        }
        logger.log(level, "\(prefix) \(message)", params: params, error: error, file: file, function: function, line: line)
    }

    func debug(_ message: String, error: Error? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(.debug, message, error: error, file: file, function: function, line: line)
    }

    func info(_ message: String, error: Error? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(.info, message, error: error, file: file, function: function, line: line)
    }

    func warn(_ message: String, error: Error? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(.warn, message, error: error, file: file, function: function, line: line)
    }

    func error(_ message: String, error: Error? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(.error, message, error: error, file: file, function: function, line: line)
    }
}

/// ByteView统一管理的Logger，type为"ByteView"，category前缀"ByteView."
///
/// log本身由LKCommonsLogging控制，log完之后会回调出来做后续处理
private final class LoggerImpl {
    let category: String
    private let logger: LKCommonsLogging.Log
    init(_ category: String) {
        self.category = category
        self.logger = LKCommonsLogging.Logger.log("ByteView", category: category)
    }

    func log(_ level: LogLevel, _ message: String, params: [String: String]?, error: Error?, file: String, function: String, line: Int) {
        logger.log(level: level.rawValue, message, tag: "", additionalData: params, error: error,
                   file: file, function: function, line: line)
        Logger.delegate?.didLog(on: category)
    }
}

/// 常用的logger
public extension Logger {
    static let ui = getLogger("UI")
    static let network = getLogger("Network")
    static let push = getLogger("Push")
    static let monitor = getLogger("Monitor")
    static let meeting = getLogger("Meeting")
    static let util = getLogger("Util")
    static let privacy = getLogger("Privacy")
}
