//
//  Logger.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/8/8.
//

import Foundation

public enum LogLevel: Int {
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4
}

/// 日志协议
public protocol Logger {
    /// 打印一条日志
    /// 注意：Logger 的调用者永远不应该调用此方法
    /// - Parameters:
    ///   - level: 日志等级
    ///   - message: 日志内容
    ///   - file: 当前文件
    ///   - line: 当前行
    ///   - function: 当前方法
    func log(level: LogLevel,
             _ message: String,
             file: String,
             line: Int,
             function: String)
}

public extension Logger {
    /// Info
    /// - Parameter message: message
    func info(_ message: String,
              file: String = #fileID,
              line: Int = #line,
              function: String = #function) {
        log(level: .info, message, file: file, line: line, function: function)
    }

    /// Debug
    /// - Parameter message: message
    func debug(_ message: String,
               file: String = #fileID,
               line: Int = #line,
               function: String = #function) {
        log(level: .debug, message, file: file, line: line, function: function)
    }

    /// Warn
    /// - Parameter message: message
    func warn(_ message: String,
              file: String = #fileID,
              line: Int = #line,
              function: String = #function) {
        log(level: .warn, message, file: file, line: line, function: function)
    }

    /// Error
    /// - Parameter message: message
    func error(_ message: String,
               file: String = #fileID,
               line: Int = #line,
               function: String = #function) {
        log(level: .error, message, file: file, line: line, function: function)
    }
}
