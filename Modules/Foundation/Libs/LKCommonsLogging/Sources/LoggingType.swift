//
//  LKCommonsLogging.swift
//  Efficiency Engineering
//
//  Created by lvdaqian on 2018/3/25.
//  Copyright © 2018 Efficiency Engineering. All rights reserved.
//

import Foundation

/// 日志输出级别， 扩展与Int. 可以根据需要扩展与转换, 例如：
/// ```
/// extension LogLevel {
///     public static let customLevel: LogLevel = 999
/// }
/// ```
/// 内置的日志级别如下
/// - trace: 详细信息，值为0
/// - debug: 调试信息，值为1
/// - info: 一般信息，值为2
/// - warn: 警告信息，值为3
/// - error: 错误信息，值为4
/// - fatal: 严重错误信息，值为5
public typealias LogLevel = Int

extension LogLevel {
    public static let trace: LogLevel = 0
    public static let debug: LogLevel = 1
    public static let info: LogLevel = 2
    public static let warn: LogLevel = 3
    public static let error: LogLevel = 4
    public static let fatal: LogLevel = 5
}

/// 日志事件
public struct LogEvent {
    /// 日志Id
    public let logId: String
    /// 日志记录的时间，1970年1月1日以来的秒数。浮点类型，小数部分可以精确到ms。
    public let time: TimeInterval
    /// 日志的记录级别，参考 @LogLevel
    public let level: LogLevel
    /// 日志 Tags 标记
    public let tags: [String]
    /// 日志详细内容
    public let message: String
    /// 记录日志发生的线程
    public let thread: String
    /// 记录日志的文件名
    public let file: String
    /// 记录日志的函数名
    public let function: String
    /// 记录日志的所在行号
    public let line: Int
    /// 额外添加的错误，默认为空
    public let error: Error?
    /// Depreciated： 额外添加的附加信息，键值对数据，默认为空
    public let additionalData: [String: String]?
    // 参数信息，替代additionalData
    public let params: [String: String]?

    public init(logId: String, time: TimeInterval, level: LogLevel, tags: [String], message: String, thread: String, file: String, function: String, line: Int, error: Error?, additionalData: [String: String]?, params: [String: String]?) {
        let traceId = Thread.current.threadDictionary["TraceId"] as? String ?? ""
        var params = params ?? [:]
        if !traceId.isEmpty {
            params["TraceId"] = traceId
        }
        self.logId = logId
        self.time = time
        self.level = level
        self.tags = tags
        self.message = message
        self.thread = thread
        self.file = file
        self.function = function
        self.line = line
        self.error = error
        self.additionalData = additionalData
        self.params = params
    }
}
