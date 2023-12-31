//
//  OPTrace+Logger.swift
//  ECOProbe
//
//  Created by qsc on 2021/3/31.
//

import Foundation
import LKCommonsLogging

fileprivate var logger = Logger.oplog(OPTrace.self, category: "OPTraceLog")

extension OPTrace: Log {
    public func log(event: LogEvent) {
        logger.log(logId: event.logId,
                   "[trace=\(self.traceId)] \(event.message)",
                   params: event.params,
                   tags: event.tags,
                   level: event.level,
                   time: event.time,
                   file: event.file,
                   function: event.function,
                   line: event.line)
    }

    public func isDebug() -> Bool {
        return logger.isDebug()
    }

    public func isTrace() -> Bool {
        return logger.isTrace()
    }
}

/// OPTrace Objc log helper
@objcMembers
public final class OPTraceLoggerObjc: NSObject {

    /// 打印 debug 日志
    /// - Parameters:
    ///   - trace: trace 实例
    ///   - message: 打印的内容
    ///   - file: 所在文件
    ///   - function: 所在函数
    ///   - line: 所在行
    public class func _debug(trace: OPTrace, message: String, file: String, function: String, line: Int) {
        trace.debug(message, file: file, function: function, line: line)
    }

    /// 打印 info 日志
    /// - Parameters:
    ///   - trace: trace 实例
    ///   - message: 打印的内容
    ///   - file: 所在文件
    ///   - function: 所在函数
    ///   - line: 所在行
    public class func _info(trace: OPTrace, message: String, file: String, function: String, line: Int) {
        trace.info(message, file: file, function: function, line: line)
    }

    /// 打印 warnning 日志
    /// - Parameters:
    ///   - trace: trace 实例
    ///   - message: 打印的内容
    ///   - file: 所在文件
    ///   - function: 所在函数
    ///   - line: 所在行
    public class func _warn(trace: OPTrace, message: String, file: String, function: String, line: Int) {
        trace.warn(message, file: file, function: function, line: line)
    }

    /// 打印 error 日志
    /// - Parameters:
    ///   - trace: trace 实例
    ///   - message: 打印的内容
    ///   - file: 所在文件
    ///   - function: 所在函数
    ///   - line: 所在行
    public class func _error(trace: OPTrace, message: String, file: String, function: String, line: Int) {
        trace.error(message, file: file, function: function, line: line)
    }
}

