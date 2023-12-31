//
//  SecurityPolicyLogger.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/16.
//

import Foundation
import LarkSecurityComplianceInfra
import LKCommonsLogging
import RustSDK
import LarkContainer

public typealias SPLogger = SecurityPolicyLogger

public final class SecurityPolicyLogger {
  
    public static var shared = SecurityPolicyLogger()
    
    private init() {}

    static func info(_ msg: String,
                     debugViewMsg: String? = nil,
                     tag: String = "",
                     additionalData params: [String: String]? = nil,
                     file: String = #fileID,
                     function: String = #function,
                     line: Int = #line) {
        Logger.info(msg,
                    tag: tag,
                    additionalData: params,
                    file: file,
                    function: function,
                    line: line)
    }

    static func debug(_ msg: String,
                      debugViewMsg: String? = nil,
                      tag: String = "",
                      additionalData params: [String: String]? = nil,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line) {
        Logger.debug(msg,
                    tag: tag,
                    additionalData: params,
                    file: file,
                    function: function,
                    line: line)
    }

    static func error(_ msg: String,
                      debugViewMsg: String? = nil,
                      tag: String = "",
                      additionalData params: [String: String]? = nil,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line) {
        Logger.error(msg,
                    tag: tag,
                    additionalData: params,
                    file: file,
                    function: function,
                    line: line)
    }

    static func warn(_ msg: String,
                     debugViewMsg: String? = nil,
                     tag: String = "",
                     additionalData params: [String: String]? = nil,
                     file: String = #fileID,
                     function: String = #function,
                     line: Int = #line) {
        Logger.warn(msg,
                    tag: tag,
                    additionalData: params,
                    file: file,
                    function: function,
                    line: line)
    }
}
