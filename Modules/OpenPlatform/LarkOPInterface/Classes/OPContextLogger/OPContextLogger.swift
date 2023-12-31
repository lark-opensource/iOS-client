//
//  OPContextLogger.swift
//  Timor
//
//  Created by yinyuan on 2020/9/7.
//

import Foundation

/// 输出日志时会自动带上已添加的上下文信息(key:value or message)，可以不断添加上下文(key:value or message)
extension OPContextLogger {
    
    /// 基于已有默认日志上下文信息，添加日志上下文信息，可以补充多条。相当于 addLogMessage(name:value)
    /// - Parameters:
    ///   - name: 字段名
    ///   - value: 字段值
    /// - Returns: OPContextLogger
    public func addLogValue(name: String?, value: Any?) -> OPContextLogger {
        return self.__addLogMessage("\(name):\(value)")
    }
    
    
    /// 添加上下文信息(message)
    /// - Parameter message: message
    /// - Returns: OPContextLogger
    public func addLogMessage(_ message: String?) -> OPContextLogger {
        return self.__addLogMessage(message)
    }
    
    /// 基于已有默认日志上下文信息，立即打印一条日志(info)
    public func logInfo(
        message: String?,
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) -> OPContextLogger {
        self.__logWithContextInfo()(.info, fileName.cString(using: .utf8), fileName.cString(using: .utf8), line, message)
        return self
    }
    
    /// 基于已有默认日志上下文信息，立即打印一条日志(warn)
    public func logWarn(
        message: String?,
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) -> OPContextLogger {
        self.__logWithContextInfo()(.warn, fileName.cString(using: .utf8), fileName.cString(using: .utf8), line, message)
        return self
    }
    
    /// 基于已有默认日志上下文信息，立即打印一条日志(error)
    public func logError(
        message: String?,
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) -> OPContextLogger {
        self.__logWithContextInfo()(.error, fileName.cString(using: .utf8), fileName.cString(using: .utf8), line, message)
        return self
    }
    
    /// 基于已有默认日志上下文信息，立即打印一条日志(debug)
    public func logDebug(
        message: String?,
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) -> OPContextLogger {
        self.__logWithContextInfo()(.debug, fileName.cString(using: .utf8), fileName.cString(using: .utf8), line, message)
        return self
    }
    
}
