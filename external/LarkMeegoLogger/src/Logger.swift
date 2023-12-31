//
//  Logger.swift
//  LarkMeegoLogger
//
//  Created by shizhengyu on 2022/6/4.
//

import Foundation
import LKCommonsLogging

open class MeegoLogger {
    private static let logger = Logger.log(
        MeegoLogger.self,
        category: "MeegoLogger.logger"
    )
    private static let domainPrefix = "[Meego Native]"

    public static func debug(_ logMsg: @autoclosure () -> String, tag: String = "", customPrefix: String = "") {
        #if targetEnvironment(simulator) && DEBUG
        logger.debug("\(domainPrefix) \(customPrefix) \(logMsg())", tag: tag)
        debugPrint("[Meego Console] " + logMsg())
        #endif
    }

    public static func verbose(_ logMsg: String, tag: String = "", customPrefix: String = "") {
        logger.info("\(domainPrefix) \(customPrefix) \(logMsg)", tag: tag)
        #if targetEnvironment(simulator) && DEBUG
        debugPrint("[Meego Console] " + logMsg)
        #endif
    }

    public static func info(_ logMsg: String, tag: String = "", customPrefix: String = "") {
        logger.info("\(domainPrefix) \(customPrefix) \(logMsg)", tag: tag)
        #if targetEnvironment(simulator) && DEBUG
        debugPrint("[Meego Console] " + logMsg)
        #endif
    }

    public static func warn(_ logMsg: String, tag: String = "", customPrefix: String = "") {
        logger.warn("\(domainPrefix) \(customPrefix) \(logMsg)", tag: tag)
        #if targetEnvironment(simulator) && DEBUG
        debugPrint("[Meego Console] " + logMsg)
        #endif
    }

    public static func error(_ logMsg: String, tag: String = "", customPrefix: String = "") {
        logger.error("\(domainPrefix) \(customPrefix) \(logMsg)", tag: tag)
        #if targetEnvironment(simulator) && DEBUG
        debugPrint("[Meego Console] " + logMsg)
        #endif
    }
}
