//
//  Logger.swift
//  RichTextEditor
//
//  Created by chenhuaguan on 2020/6/29.
//

import Foundation
import LKCommonsLogging

enum LogLevel: Int {
    case debug
    case info
    case warning
    case error

}

final class Logger {
    static let shared = Logger()
    let logger = LKCommonsLogging.Logger.log(Logger.self, category: "Module.CalendarRichTextEditor")

    class func info(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        self.log(level: .info, message: message, extraInfo: extraInfo, error: error, component: component, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }

    class func debug(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        self.log(level: .debug, message: message, extraInfo: extraInfo, error: error, component: component, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }

    class func warning(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        self.log(level: .warning, message: message, extraInfo: extraInfo, error: error, component: component, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }

    class func error(
        _ message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {
        self.log(level: .error, message: message, extraInfo: extraInfo, error: error, component: component, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }

    class func log(
        level: LogLevel,
        message: String,
        extraInfo: [String: Any]? = nil,
        error: Error? = nil,
        component: String? = nil,
        fileName: String = #fileID,
        funcName: String = #function,
        funcLine: Int = #line) {

        let resultMessage = (component ?? "") + message
        let resultExtraInfo = extraInfo?.mapValues({ (value) -> String in
            "\(value)"
        })
        switch level {
        case .debug:
            Logger.shared.logger.debug(resultMessage, additionalData: resultExtraInfo, error: error, file: fileName, function: funcName, line: funcLine)
        case .info:
            Logger.shared.logger.info(resultMessage, additionalData: resultExtraInfo, error: error, file: fileName, function: funcName, line: funcLine)
        case .warning:
            Logger.shared.logger.warn(resultMessage, additionalData: resultExtraInfo, error: error, file: fileName, function: funcName, line: funcLine)
        case .error:
            Logger.shared.logger.error(resultMessage, additionalData: resultExtraInfo, error: error, file: fileName, function: funcName, line: funcLine)
        }

    }

}
