//
//  SCLoggerProxy.swift
//  LarkSecurityComplianceInfra
//
//  Created by qingchun on 2023/9/8.
//

import Foundation
import LKCommonsLogging

public extension SCLogger {
    
    private static let logger = LKCommonsLogging.Logger.log(SCLogger.self, category: "security_compliance")
    
    // MARK: - Public
    
    static func info(_ msg: String,
                     tag: String = "",
                     additionalData params: [String: String]? = nil,
                     file: String = #fileID,
                     function: String = #function,
                     line: Int = #line) {
        logger.info(msg, tag: tag, additionalData: params, file: file, function: function, line: line)
    }
    
    static func debug(_ msg: String,
                      tag: String = "",
                      additionalData params: [String: String]? = nil,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line) {
        logger.debug(msg, tag: tag, additionalData: params, file: file, function: function, line: line)
    }
    
    static func error(_ msg: String,
                      tag: String = "",
                      additionalData params: [String: String]? = nil,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line) {
        logger.error(msg, tag: tag, additionalData: params, file: file, function: function, line: line)
    }
    
    static func warn(_ msg: String,
                     tag: String = "",
                     additionalData params: [String: String]? = nil,
                     file: String = #fileID,
                     function: String = #function,
                     line: Int = #line) {
        logger.warn(msg, tag: tag, additionalData: params, file: file, function: function, line: line)
    }
}
