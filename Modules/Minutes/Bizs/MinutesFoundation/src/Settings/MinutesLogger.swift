//
//  MinutesLogger.swift
//  MinutesFoundation
//
//  Created by yangyao on 2023/2/9.
//

import Foundation
import LKCommonsLogging

public class MinutesLogger {
    public static let detail = LoggerWrapper(category: "detail")
    public static let list = LoggerWrapper(category: "list")
    public static let subtitle = LoggerWrapper(category: "subtitle")
    public static let podcast = LoggerWrapper(category: "podcast")
    public static let record = LoggerWrapper(category: "record|action")
    public static let recordBasic = LoggerWrapper(category: "record|action|basic")
    public static let recordFloat = LoggerWrapper(category: "record|float")
    public static let recordTracker = LoggerWrapper(category: "record|tracker")
    public static let recordFile = LoggerWrapper(category: "record|file")
    public static let upload = LoggerWrapper(category: "record|upload|process")
    public static let uploadAppState = LoggerWrapper(category: "record|upload|appstate")
    public static let uploadRetry = LoggerWrapper(category: "record|upload|retry")
    public static let uploadData = LoggerWrapper(category: "record|upload|data")
    public static let uploadSuccess = LoggerWrapper(category: "record|upload|success")
    public static let uploadFailed = LoggerWrapper(category: "record|upload|failed")
    public static let uploadStatistics = LoggerWrapper(category: "record|upload|statistics")
    public static let video = LoggerWrapper(category: "video")
    public static let network = LoggerWrapper(category: "network")
    public static let common = LoggerWrapper(category: "common")
    public static let data = LoggerWrapper(category: "data")
}

public final class LoggerWrapper {
    private let logger: LKCommonsLogging.Log
    
    init(category: String) {
        logger = LKCommonsLogging.Logger.log(MinutesLogger.self, category: category)
    }
   
    public func info(
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
        logger.info(message, tag: tag, additionalData: params, error: error, file: file, function: function, line: line)
    }
   
    public func warn(
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
        logger.warn(message, tag: tag, additionalData: params, error: error, file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
        logger.error(message, tag: tag, additionalData: params, error: error, file: file, function: function, line: line)
    }
    
    public func debug(
        _ message: String,
        tag: String = "",
        additionalData params: [String: String]? = nil,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
        logger.debug(message, tag: tag, additionalData: params, error: error, file: file, function: function, line: line)
    }
    
    public func assertDebug(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
        logger.assertDebug(condition(), message, params: params, file: file, function: function, line: line)
    }
    
    public func assertWarn(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        params: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
        logger.assertWarn(condition(), message, params: params, file: file, function: function, line: line)
    }

}
