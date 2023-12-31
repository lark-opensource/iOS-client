//
//  DocsLogger+Drive.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2022/5/26.
//
// nolint: long parameters

import Foundation
import SKFoundation

extension DocsLogger {
    class func driveDebug(_ log: String,
                          extraInfo: [String: Any] = [:],
                          category: String = "",
                          fileName: String = #fileID,
                          error: Error? = nil,
                          component: String = LogComponents.drive,
                          funcName: String = #function,
                          funcLine: Int = #line)
    {
        #if DEBUG
            let logStr = DocsLogger.innerLogString(level: "DEBUG",
                                                   log: log,
                                                   category: category,
                                                   extraInfo: extraInfo,
                                                   error: error)
            debugPrint(logStr)
        #else
            DocsLogger.debug("\(category) \(log)",
                             extraInfo: extraInfo,
                             error: error,
                             component: component,
                             fileName: fileName,
                             funcName: funcName,
                             funcLine: funcLine)

        #endif
    }

    /// Drive 业务日志
    /// - Parameters:
    ///   - log: 具体日志信息
    ///   - extraInfo: 额外参数
    ///   - category: Drive 子业务分类
    class func driveInfo(_ log: String,
                         extraInfo: [String: Any] = [:],
                         category: String = "",
                         error: Error? = nil,
                         component: String = LogComponents.drive,
                         fileName: String = #fileID,
                         funcName: String = #function,
                         funcLine: Int = #line)
    {
        #if DEBUG
            let logStr = DocsLogger.innerLogString(level: "INFO",
                                                   log: log,
                                                   category: category,
                                                   extraInfo: extraInfo,
                                                   error: error)
            debugPrint(logStr)
        #else
            DocsLogger.info("\(category) \(log)",
                            extraInfo: extraInfo,
                            error: error,
                            component: component,
                            fileName: fileName,
                            funcName: funcName,
                            funcLine: funcLine)
        #endif
    }

    class func driveWarning(_ log: String,
                            category: String = "",
                            extraInfo: [String: Any] = [:],
                            error: Error? = nil,
                            component: String = LogComponents.drive,
                            fileName: String = #fileID,
                            funcName: String = #function,
                            funcLine: Int = #line)
    {
        #if DEBUG
            let logStr = DocsLogger.innerLogString(level: "WARNING",
                                                   log: log,
                                                   category: category,
                                                   extraInfo: extraInfo,
                                                   error: error)
            debugPrint(logStr)
        #else
            DocsLogger.warning("\(category) \(log)",
                               extraInfo: extraInfo,
                               error: error,
                               component: component,
                               fileName: fileName,
                               funcName: funcName,
                               funcLine: funcLine)
        #endif
    }

    class func driveError(_ log: String,
                          category: String = "",
                          extraInfo: [String: Any] = [:],
                          error: Error? = nil,
                          component: String = LogComponents.drive,
                          fileName: String = #fileID,
                          funcName: String = #function,
                          funcLine: Int = #line)
    {
        #if DEBUG
            let logStr = DocsLogger.innerLogString(level: "ERROR",
                                                   log: log,
                                                   category: category,
                                                   extraInfo: extraInfo,
                                                   error: error)
            debugPrint(logStr)
        #else
            DocsLogger.error("\(category) \(log)",
                             extraInfo: extraInfo,
                             error: error,
                             component: component,
                             fileName: fileName,
                             funcName: funcName,
                             funcLine: funcLine)
        #endif
    }

    class func innerLogString(level: String,
                              log: String,
                              category: String,
                              extraInfo: [String: Any],
                              error: Error?) -> String
    {
        var logStr = "[\(level)] ==drive== \(category) \(log)"
        if !extraInfo.isEmpty {
            logStr += " [extraInfo]: \(String(describing: extraInfo))"
        }
        if let error = error {
            logStr += " [errorInfo]: \(error)"
        }
        return logStr
    }
}
