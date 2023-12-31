//
//  LKCommonsLoggingProtocol.swift
//  LKCommonsLogging
//
//  Created by lvdaqian on 2018/3/25.
//  Copyright © 2018年 Efficiency Engineering. All rights reserved.
//

import Foundation

/// 日志输出对象协议
/// 符合该协议的对象将可以用于各个模块输出日志
public protocol Log {

    /// 判断是否在debug模式
    /// 允许使用者知道是否为debug模式，因此可以输出一些特殊的日志、例如比较消耗性能的操作
    ///
    /// - Returns: Bool值，是或否
    func isDebug() -> Bool

    /// 判断是否在trace模式
    /// 允许使用者知道是否为trace模式，因此可以对输出日志做一些特殊的处理、例如获取当前cpu使用率等
    ///
    /// - Returns: Bool值，是或否
    func isTrace() -> Bool

    /// 实际记录日志的方法，日志提供者需要实现此方法记录日志。
    ///
    /// - Parameter event: 日志事件结构体 参考：@LogEvent
    func log(event: LogEvent)
}

public extension Log {

    /// 日志记录，填写logId，level，message，params，tags等信息
    ///
    /// Usage:
    ///
    ///     logger.log(logId: EESA_APP_LAUNCH,
    ///                "app launch",
    ///                params: ["version": APP_VERSION],
    ///                tags: ["lifecycle"],
    ///                level: .info)
    ///
    /// - Parameters:
    ///     - logId: 日志Id
    ///     - message: 日志内容
    ///     - params: 参数信息
    ///     - tags: 日志标签
    ///     - level: 日志级别
    ///     - time: 时间戳，单位秒
    ///     - error: 附加错误
    ///     - file: 文件名
    ///     - function: 函数
    ///     - line: 行号
    func log(
        logId: String,
        _ message: String = "",
        params: [String: String]? = nil,
        tags: [String] = [""],
        level: LogLevel = .info,
        time: TimeInterval = Date().timeIntervalSince1970,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
        log(event: LogEvent(
            logId: logId,
            time: time,
            level: level,
            tags: tags,
            message: message,
            thread: Thread.logInfo,
            file: file,
            function: function,
            line: line,
            error: error,
            additionalData: params,
            params: params))
    }

    /// 记录debug级别日志，添加logId参数，实现更灵活的日志调控
    ///
    /// Usage:
    ///
    ///     logger.debug(logId: EESA_APP_LAUNCH,
    ///                 "app launch",
    ///                 params: ["version": APP_VERSION],
    ///                 tags: ["lifecycle"])
    ///
    /// - Parameters:
    ///     - logId: 日志Id
    ///     - message: 日志内容
    ///     - params: 参数信息
    ///     - tags: 日志标签
    ///     - file: 文件名
    ///     - function: 函数
    ///     - line: 行号
    func debug(
        logId: String,
        _ message: String = "",
        params: [String: String]? = nil,
        tags: [String] = [""],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
        ) {
        log(logId: logId,
            message,
            params: params,
            tags: tags,
            level: .debug,
            file: file,
            function: function,
            line: line)
    }

    /// 记录info级别日志，添加logId参数，实现更灵活的日志调控
    ///
    /// Usage:
    ///
    ///     logger.info(logId: EESA_APP_LAUNCH,
    ///                 "app launch",
    ///                 params: ["version": APP_VERSION],
    ///                 tags: ["lifecycle"])
    ///
    /// - Parameters:
    ///     - logId: 日志Id
    ///     - message: 日志内容
    ///     - params: 参数信息
    ///     - tags: 日志标签
    ///     - file: 文件名
    ///     - function: 函数
    ///     - line: 行号
    func info(
        logId: String,
        _ message: String = "",
        params: [String: String]? = nil,
        tags: [String] = [""],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
        ) {
        log(logId: logId,
            message,
            params: params,
            tags: tags,
            level: .info,
            file: file,
            function: function,
            line: line)
    }

    /// 记录warn级别日志，添加logId参数，实现更灵活的日志调控
    ///
    /// Usage:
    ///
    ///     logger.warn(logId: EESA_APP_LAUNCH,
    ///                 "app launch",
    ///                 params: ["version": APP_VERSION],
    ///                 tags: ["lifecycle"])
    ///
    /// - Parameters:
    ///     - logId: 日志Id
    ///     - message: 日志内容
    ///     - params: 参数信息
    ///     - tags: 日志标签
    ///     - file: 文件名
    ///     - function: 函数
    ///     - line: 行号
    func warn(
        logId: String,
        _ message: String = "",
        params: [String: String]? = nil,
        tags: [String] = [""],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
        ) {
        log(logId: logId,
            message,
            params: params,
            tags: tags,
            level: .warn,
            file: file,
            function: function,
            line: line)
    }

    /// 记录error级别日志，添加logId参数，实现更灵活的日志调控
    ///
    /// Usage:
    ///
    ///     logger.error(logId: EESA_APP_LAUNCH,
    ///                 "app launch",
    ///                 params: ["version": APP_VERSION],
    ///                 tags: ["lifecycle"])
    ///
    /// - Parameters:
    ///     - logId: 日志Id
    ///     - message: 日志内容
    ///     - params: 参数信息
    ///     - tags: 日志标签
    ///     - file: 文件名
    ///     - function: 函数
    ///     - line: 行号
    func error(
        logId: String,
        _ message: String = "",
        params: [String: String]? = nil,
        tags: [String] = [""],
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
        ) {
        log(logId: logId,
            message,
            params: params,
            tags: tags,
            level: .error,
            file: file,
            function: function,
            line: line)
    }

    /// 断言，以trace级别记录
    ///
    /// - Parameters:
    ///   - condition: 断言条件
    ///   - message: 断言信息
    ///   - additionalData: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func assertTrace(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        additionalData: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        guard !condition() else { return }
        self.trace(message, additionalData: additionalData, error: error, file: file, function: function, line: line)
    }

    /// 断言，以debug级别记录
    ///
    /// - Parameters:
    ///   - condition: 断言条件
    ///   - message: 断言信息
    ///   - params: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func assertDebug(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        guard !condition() else { return }
        self.debug(logId: "eesa_assert_debug", message, params: params, file: file, function: function, line: line)
    }

    /// 断言，以Info级别记录
    ///
    /// - Parameters:
    ///   - condition: 断言条件
    ///   - message: 断言信息
    ///   - params: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func assertInfo(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        guard !condition() else { return }
        self.info(logId: "eesa_assert_info", message, params: params, file: file, function: function, line: line)
    }

    /// 断言，以warn级别记录
    ///
    /// - Parameters:
    ///   - condition: 断言条件
    ///   - message: 断言信息
    ///   - params: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func assertWarn(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        guard !condition() else { return }
        self.warn(logId: "eesa_assert_warn", message, params: params, file: file, function: function, line: line)
    }

    /// 断言，以error级别记录
    ///
    /// - Parameters:
    ///   - condition: 断言条件
    ///   - message: 断言信息
    ///   - params: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func assertError(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        guard !condition() else { return }
        self.error(logId: "eesa_assert_error", message, params: params, file: file, function: function, line: line)
    }

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
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
        #if DEBUG
        let event = LogEvent(
                logId: "",
                time: Date().timeIntervalSince1970,
                level: .trace,
                tags: [tag],
                message: message,
                thread: Thread.logInfo,
                file: file,
                function: function,
                line: line,
                error: error,
                additionalData: params,
                params: params
                )

        log(event: event)
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
    // @available(*, deprecated, message: "Use debug(logId:message:params:tags:) instead")
    func debug(
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        let event = LogEvent(
            logId: "",
            time: Date().timeIntervalSince1970,
            level: .debug,
            tags: [tag],
            message: message,
            thread: Thread.logInfo,
            file: file,
            function: function,
            line: line,
            error: error,
            additionalData: params,
            params: params)

        log(event: event)
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
    // @available(*, deprecated, message: "Use info(logId:message:params:tags:) instead")
    func info(
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        let event = LogEvent(
            logId: "",
            time: Date().timeIntervalSince1970,
            level: .info,
            tags: [tag],
            message: message,
            thread: Thread.logInfo,
            file: file,
            function: function,
            line: line,
            error: error,
            additionalData: params,
            params: params)

        log(event: event)
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
    // @available(*, deprecated, message: "Use warn(logId:message:params:tags:) instead")
    func warn(
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        let event = LogEvent(
            logId: "",
            time: Date().timeIntervalSince1970,
            level: .warn,
            tags: [tag],
            message: message,
            thread: Thread.logInfo,
            file: file,
            function: function,
            line: line,
            error: error,
            additionalData: params,
            params: params)

        log(event: event)
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
    // @available(*, deprecated, message: "Use error(logId:message:params:tags:) instead")
    func error(
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        let event = LogEvent(
            logId: "",
            time: Date().timeIntervalSince1970,
            level: .error,
            tags: [tag],
            message: message,
            thread: Thread.logInfo,
            file: file,
            function: function,
            line: line,
            error: error,
            additionalData: params,
            params: params)

        log(event: event)
    }

    /// 记录自定义级别日志
    ///
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 日志内容
    ///   - additionalData: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    func log(
        level: LogLevel,
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {

        let event = LogEvent(
            logId: "",
            time: Date().timeIntervalSince1970,
            level: level,
            tags: [tag],
            message: message,
            thread: Thread.logInfo,
            file: file,
            function: function,
            line: line,
            error: error,
            additionalData: params,
            params: params)

        log(event: event)
    }
}
