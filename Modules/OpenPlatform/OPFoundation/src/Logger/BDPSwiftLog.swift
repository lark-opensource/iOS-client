//
//  BDPSwiftLog.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/8.
//

import Foundation
import LKCommonsLogging

/// 记录info级别日志
/// - Parameters:
///   - tag: 日志标签
///   - fileName: 文件名
///   - functionName: 方法名
///   - line: 行号
///   - content: 日志内容
public func BDPLogInfo(
    tag: BDPTagEnum,
    fileName: String = #fileID,
    functionName: String = #function,
    line: Int = #line,
    _ content: String = ""
) {
    _BDPLog(.info, tag.rawValue, nil, fileName, functionName, Int32(line), content)
}

/// 记录debug级别日志
/// - Parameters:
///   - tag: 日志标签
///   - fileName: 文件名
///   - functionName: 方法名
///   - line: 行号
///   - content: 日志内容
public func BDPLogDebug(
    tag: BDPTagEnum,
    fileName: String = #fileID,
    functionName: String = #function,
    line: Int = #line,
    _ content: String = ""
) {
    _BDPLog(.debug, tag.rawValue, nil, fileName, functionName, Int32(line), content)
}

/// 记录warn级别日志
/// - Parameters:
///   - tag: 日志标签
///   - fileName: 文件名
///   - functionName: 方法名
///   - line: 行号
///   - content: 日志内容
public func BDPLogWarn(
    tag: BDPTagEnum,
    fileName: String = #fileID,
    functionName: String = #function,
    line: Int = #line,
    _ content: String = ""
) {
    _BDPLog(.warn, tag.rawValue, nil, fileName, functionName, Int32(line), content)
}

/// 记录info级别日志
/// - Parameters:
///   - tag: 日志标签
///   - fileName: 文件名
///   - functionName: 方法名
///   - line: 行号
///   - content: 日志内容
public func BDPLogError(
    tag: BDPTagEnum,
    fileName: String = #fileID,
    functionName: String = #function,
    line: Int = #line,
    _ content: String = ""
) {
    _BDPLog(.error, tag.rawValue, nil, fileName, functionName, Int32(line), content)
}

// 迁移自EMAPluginLogImpl
public func _BDPLog(
    _ level: BDPLogLevel,
    _ tag: String?,
    _ tracing: String?,
    _ filename: String?,
    _ func_name: String?,
    _ line: Int32,
    _ content: String?
) {
    EMAPluginLogImpl.bdp_Log(with: level, tag: tag, tracing: tracing, fileName: filename, funcName: func_name, line: line, content: content)
}

@objc
final public class BDPLoggerHelper: NSObject {
    static let logger = Logger.oplog(BDPLoggerHelper.self, category: "EEMicroApp")
    
    @objc public static func log(withLevel level: BDPLogLevel, tag: String?, filename: String?, func_name: String?, line: Int, content: String?, logId: String?) {
        let messgaeContent = content ?? ""
        let file = filename ?? ""
        let function = func_name ?? ""
        let tagValue = tag ?? ""
        let logIdValue = logId ?? ""
        switch level {
        case .debug:
            Self.logger.debug(logId: logIdValue, messgaeContent, tags: [tagValue], file: file, function: function, line: line)
        case .info:
            Self.logger.info(logId: logIdValue, messgaeContent, tags: [tagValue], file: file, function: function, line: line)
        case .warn:
            Self.logger.warn(logId: logIdValue, messgaeContent, tags: [tagValue], file: file, function: function, line: line)
        case .error:
            Self.logger.error(logId: logIdValue, messgaeContent, tags: [tagValue], file: file, function: function, line: line)
        @unknown default:
            Self.logger.info(logId: logIdValue, messgaeContent, tags: [tagValue], file: file, function: function, line: line)
        }
    }
}
