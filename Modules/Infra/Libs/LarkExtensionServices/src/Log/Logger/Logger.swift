//
//  Logger.swift
//  LarkExtensionSetvices
//
//  Created by 王元洵 on 2021/4/01.
//  Copyright © 2018年 Efficiency Engineering. All rights reserved.
//

import Foundation

/// 日志输出对象协议
/// 符合该协议的对象将可以用于各个模块输出日志
public struct Logger {
    private var handler: LogHandler

    /// Logger的标识符.
    public let label: String

    /// 初始化一个对象，用于输出日志
    ///
    /// - Parameters:
    ///   - label: 日志标识符
    ///   - handler: LogHandler对象，用于处理日志消息
    public init(label: String, _ handler: LogHandler) {
        self.label = label
        self.handler = handler
    }
}

extension Logger {
    /// 实际记录日志的方法，交给LogHandler变量处理。
    ///
    /// - Parameter event: 日志事件结构体 参考：@Logger.Message
    func log(eventMessage: Logger.Message) {
        self.handler.log(eventMessage: eventMessage)
    }

    func log(level: Logger.Level,
             tag: String,
             message: Logger.Message,
             file: String,
             function: String,
             line: Int,
             error: Error?,
             additionalData: [String: String]?) {
        let event = Logger.Event(
            label: label,
            time: Date().addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT())).timeIntervalSince1970,
            level: .info,
            tags: [tag],
            message: message,
            thread: Thread.logInfo,
            file: file,
            function: function,
            line: line,
            error: error,
            additionalData: additionalData)
        log(eventMessage: .init(stringLiteral: event.description))
    }
}

public extension Logger {

    /// 记录trace级别日志，仅在DEBUG宏打开情况下开启，保证release环境下不会输出。
    ///
    /// - Parameters:
    ///   - message: 日志内容
    ///   - additionalData: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func trace(
        _ message: Logger.Message,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
        #if DEBUG
        log(level: .trace, tag: tag, message: message, file: file, function: function, line: line, error: error, additionalData: params)
        #endif
    }

    /// 记录debug级别日志
    ///
    /// - Parameters:
    ///   - message: 日志内容
    ///   - additionalData: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func debug(
        _ message: Logger.Message,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        log(level: .debug, tag: tag, message: message, file: file, function: function, line: line, error: error, additionalData: params)
    }

    /// 记录info级别日志
    ///
    /// - Parameters:
    ///   - message: 日志内容
    ///   - additionalData: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func info(
        _ message: Logger.Message,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        log(level: .info, tag: tag, message: message, file: file, function: function, line: line, error: error, additionalData: params)
    }

    /// 记录warn级别日志
    ///
    /// - Parameters:
    ///   - message: 日志内容
    ///   - additionalData: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func warn(
        _ message: Logger.Message,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        log(level: .warn, tag: tag, message: message, file: file, function: function, line: line, error: error, additionalData: params)
    }

    /// 记录error级别日志
    ///
    /// - Parameters:
    ///   - message: 日志内容
    ///   - additionalData: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func error(
        _ message: Logger.Message,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        log(level: .error, tag: tag, message: message, file: file, function: function, line: line, error: error, additionalData: params)
    }
}
