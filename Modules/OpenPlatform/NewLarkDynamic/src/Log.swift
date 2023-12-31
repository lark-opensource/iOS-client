//
//  Log.swift
//  NewLarkDynamic
//
//  Created by lilun.ios on 2021/6/20.
//

import Foundation
import LKCommonsLogging
import LarkFeatureGating
public final class MessageCardLog {
    /// 是否支持染色日志
    public func enableColorLog() -> Bool {
        #if DEBUG
        return true
        #endif
        return LarkFeatureGating.shared.getFeatureBoolValue(for: FeatureGating.messageCardDetailLog)
    }
    public func warn(_ message: String, tag: String = "", additionalData params: [String : String]? = nil, error: Error? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        if enableColorLog() {
            cardlog.warn(message,
                         tag: tag,
                         additionalData: params,
                         error: error,
                         file: file,
                         function: function,
                         line: line)
        }
    }

    public func info(_ message: String, tag: String = "", additionalData params: [String : String]? = nil, error: Error? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        if enableColorLog() {
            cardlog.info(message,
                         tag: tag,
                         additionalData: params,
                         error: error,
                         file: file,
                         function: function,
                         line: line)
        }
    }

    public func error(_ message: String, tag: String = "", additionalData params: [String : String]? = nil, error: Error? = nil, file: String = #fileID, function: String = #function, line: Int = #line) {
        if enableColorLog() {
            cardlog.error(message,
                         tag: tag,
                         additionalData: params,
                         error: error,
                         file: file,
                         function: function,
                         line: line)
        }
    }
}
public let cardlog = Logger.log(MessageCardLog.self, category: "MessageCard")

/// 染色日志对象
public let detailLog = MessageCardLog()
