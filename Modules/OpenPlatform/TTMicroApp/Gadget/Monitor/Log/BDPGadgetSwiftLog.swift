//
//  BDPGadgetSwiftLog.swift
//  TTMicroApp
//
//  Created by xingjinhao on 2021/12/22.
//

import Foundation
import LKCommonsLogging

private let gadgetMessagePrefix = "[Gadget]"

public final class GadgetLog {
    
    public let logger: Log
    
    public init(_ type: Any, category: String = "") {
        let logger = Logger.log(type, category: gadgetMessagePrefix + category)
        self.logger = logger
    }
    
    /// 记录debug级别日志，添加logId参数，实现更灵活的日志调控
    ///
    /// - Parameters:
    ///     - logId: 日志Id
    ///     - message: 日志内容
    ///     - params: 参数信息
    ///     - file: 文件名
    ///     - function: 函数
    ///     - line: 行号
    public func debug(
        logId: String = "",
        _ message: String = "",
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
        ) {
        logger.log(logId: logId,
            message,
            params: params,
            tags: [gadgetMessagePrefix],
            level: .debug,
            file: file,
            function: function,
            line: line)
    }
    
    /// 记录info级别日志，添加logId参数，实现更灵活的日志调控
    ///
    /// - Parameters:
    ///     - logId: 日志Id
    ///     - message: 日志内容
    ///     - params: 参数信息
    ///     - file: 文件名
    ///     - function: 函数
    ///     - line: 行号
    public func info(
        logId: String = "",
        _ message: String = "",
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
        ) {
        logger.log(logId: logId,
            message,
            params: params,
            tags: [gadgetMessagePrefix],
            level: .info,
            file: file,
            function: function,
            line: line)
    }

    /// 记录warn级别日志，添加logId参数，实现更灵活的日志调控
    ///
    /// - Parameters:
    ///     - logId: 日志Id
    ///     - message: 日志内容
    ///     - params: 参数信息
    ///     - file: 文件名
    ///     - function: 函数
    ///     - line: 行号
    public func warn(
        logId: String = "",
        _ message: String = "",
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
        ) {
        logger.log(logId: logId,
            message,
            params: params,
            tags: [gadgetMessagePrefix],
            level: .warn,
            file: file,
            function: function,
            line: line)
    }

    /// 记录error级别日志，添加logId参数，实现更灵活的日志调控
    ///
    /// - Parameters:
    ///     - logId: 日志Id
    ///     - message: 日志内容
    ///     - params: 参数信息
    ///     - file: 文件名
    ///     - function: 函数
    ///     - line: 行号
    public func error(
        logId: String = "",
        _ message: String = "",
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
        ) {
        logger.log(logId: logId,
            message,
            params: params,
            tags: [gadgetMessagePrefix],
            level: .error,
            file: file,
            function: function,
            line: line)
    }
}

