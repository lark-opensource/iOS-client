//
//  Lark+Logger.swift
//  Lark
//
//  Created by lichen on 2018/8/10.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkEnv
import Swinject
import Logger
import LKCommonsLogging
import LarkContainer
import BootManager
import LarkMonitor
import LarkStorage

final class LarkLogger {

    static let logger = Logger.log(LarkLogger.self, category: "lark.logger")

    static func setup() {
        setupLogger()
        setupLKCommonsLogging()
    }

    static func setupLogger() {
        self.setupRustLogSDK()
        var appenders: [Appender] = [
            createRustLogAppender()
        ]
        
        if LarkLoggerMonitor.shared.setupRustlogMonitor() {
            appenders.append(createLogMonitorAppender())
        }
        
        #if DEBUG
        appenders.append(createConsoleAppender())
        #endif
        if LoggerConsoleAppender.persistentStatus() {
            appenders.append(createLoggerConsoleAppender())
        }
        Logger.setup(appenders: appenders)
        // 增加Alog 初始化
        var alogAppenders: [Appender] = [createAlogAppender()]
        Logger.setup(appenders: alogAppenders, backendType: "ALog")
    }

    static func setupLKCommonsLogging() {
        Logger.setup { (type, category) -> LKCommonsLogging.Log in
            return  LarkLoggerProxy(type, category)
        }
        // 增加Alog 初始化
        LKCommonsLogging.Logger.setup(for: "ALog.") { (type, category) -> LKCommonsLogging.Log in
            return LarkALoggerProxy(type, category)
        }
    }

    static func logRootPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return "\(paths[0])/logs"
    }

    private static func createConsoleAppender() -> Appender {
        let config = XcodeConsoleConfig(logLevel: .debug)
        return LoggerConstruct.createConsoleAppender(config: config)
    }

    private static func createLoggerConsoleAppender() -> Appender {
        let config = LoggerConsoleConfig(logLevel: .debug)
        return LoggerConstruct.createLoggerConsoleAppender(config: config)
    }

    private static func createRustLogAppender() -> Appender {
        return RustLogAppender()
    }
    
    private static func createLogMonitorAppender() -> Appender {
        return LoggerMonitorAppender()
    }

    /// 创建Alog appender
    /// - Returns: alog apender
    private static func createAlogAppender() -> Appender {
        return AlogAppender()
    }

    private static func setupRustLogSDK() {
        let rustLogConfig = RustLogConfig(
            process: "lark",
            logPath: rustLogRootPath.absoluteString,
            monitorEnable: true
        )
        RustLogAppender.setupRustLogSDK(config: rustLogConfig)
        DispatchQueue.global().async {
            RustMetricAppender.setupMetric(storePath: rustLogConfig.logPath)
        }
    }
}

// Path
extension LarkLogger {
    static var rustLogRootPath: AbsPath {
        let relativePath: String
        switch EnvManager.env.type {
        case .release, .preRelease:
            relativePath = "log"
        case .staging:
            relativePath = "staging/log"
        @unknown default:
            relativePath = "log"
        }
        return AbsPath.rustSdk + relativePath
    }
}
