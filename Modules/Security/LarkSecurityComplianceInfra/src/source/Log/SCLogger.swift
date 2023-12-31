//
//  Logger.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/12.
//

import LKCommonsLogging

public final class SCLogger {
    
    // MARK: - Public
    
    public let tag: String
    public var didLogCallback: ((String) -> Void)?
    
    public init(tag: String) {
        self.tag = tag
    }
    
    public func info(_ msg: String,
                     file: String = #fileID,
                     function: String = #function,
                     line: Int = #line,
                     additionalData: SCLoggerAdditionalDataConvertable?...) {
        var dict = [String: String]()
        for addition in additionalData {
            guard let addition else { continue }
            dict.merge(addition.logData) { v1, _ in v1 }
        }
        Self.info(msg, tag: tag, additionalData: dict, file: file, function: function, line: line)
        didLogCallback?("""
            Time: \(Date()),
            LogLevel: Info,
            Msg: \(msg),
            File: \(file),
            Func: \(function),
            AdditionalData: \(dict)
        """)
    }
    
    public func debug(_ msg: String,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line,
                      additionalData: SCLoggerAdditionalDataConvertable?...) {
        var dict = [String: String]()
        for addition in additionalData {
            guard let addition else { continue }
            dict.merge(addition.logData) { v1, _ in v1 }
        }
        Self.debug(msg, tag: tag, additionalData: dict, file: file, function: function, line: line)
        didLogCallback?("""
            Time: \(Date()),
            LogLevel: Debug,
            Msg: \(msg),
            File: \(file),
            Func: \(function),
            AdditionalData: \(dict)
        """)
    }
    
    public func error(_ msg: String,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line,
                      additionalData: SCLoggerAdditionalDataConvertable?...) {
        var dict = [String: String]()
        for addition in additionalData {
            guard let addition else { continue }
            dict.merge(addition.logData) { v1, _ in v1 }
        }
        Self.error(msg, tag: tag, additionalData: dict, file: file, function: function, line: line)
        didLogCallback?("""
            Time: \(Date()),
            LogLevel: Error,
            Msg: \(msg),
            File: \(file),
            Func: \(function),
            AdditionalData: \(dict)
        """)
    }
    
    public func warn(_ msg: String,
                     file: String = #fileID,
                     function: String = #function,
                     line: Int = #line,
                     additionalData: SCLoggerAdditionalDataConvertable?...) {
        var dict = [String: String]()
        for addition in additionalData {
            guard let addition else { continue }
            dict.merge(addition.logData) { v1, _ in v1 }
        }
        Self.warn(msg, tag: tag, additionalData: dict, file: file, function: function, line: line)
        didLogCallback?("""
            Time: \(Date()),
            LogLevel: Warn,
            Msg: \(msg),
            File: \(file),
            Func: \(function),
            AdditionalData: \(dict)
        """)
    }
    
}

public typealias Logger = SCLogger
