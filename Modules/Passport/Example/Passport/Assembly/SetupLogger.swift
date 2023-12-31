//
//  Lark+Logger.swift
//  Lark
//
//  Created by lichen on 2018/8/10.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

/// 从 LarkBaseService  拷贝

import Foundation
import LarkEnv
import Swinject
import Logger
import LKCommonsLogging
import LarkContainer

struct EventTransform {
    static func transform(_ event: LKCommonsLogging.LogEvent) -> LoggerLogEvent {
        return LoggerLogEvent(
            logId: event.logId,
            time: event.time,
            tags: event.tags,
            level: LogLevel(rawValue: event.level) ?? LogLevel.fatal,
            message: event.message,
            thread: event.thread,
            file: event.file,
            function: event.function,
            line: event.line,
            error: event.error,
            params: event.params
        )
    }
}

struct LarkLoggerProxy: LKCommonsLogging.Log {
    let logger: LoggerLog
    let custom: LKCommonsLogging.Log?

    init(_ type: Any, _ category: String, custom: LKCommonsLogging.Log? = nil) {
        let typeCls: AnyClass = type as? AnyClass ?? Logger.self
        self.logger = Logger.log(typeCls, category: category)
        self.custom = custom
    }

    func log(event: LKCommonsLogging.LogEvent) {
        let en = EventTransform.transform(event)
        logger.log(en)
        self.custom?.log(event: event)
    }

    func isDebug() -> Bool {
        return true
    }

    func isTrace() -> Bool {
        return true
    }
}

struct LarkALoggerProxy: LKCommonsLogging.Log {
    let logger: LoggerLog

    init(_ type: Any, _ category: String, custom: LKCommonsLogging.Log? = nil) {
        let typeCls: AnyClass = type as? AnyClass ?? Logger.self
        self.logger = Logger.log(typeCls, category: category, backendType: "ALog")
    }

    func log(event: LKCommonsLogging.LogEvent) {
        let en = EventTransform.transform(event)
        logger.log(en)
    }

    func isDebug() -> Bool {
        return true
    }

    func isTrace() -> Bool {
        return true
    }
}

class LarkLogger {

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
        #if DEBUG
        appenders.append(createConsoleAppender())
        #endif
        if LoggerConsoleAppender.persistentStatus() {
            appenders.append(createLoggerConsoleAppender())
        }
        Logger.setup(appenders: appenders)
        //增加Alog 初始化
        var alogAppenders: [Appender] = [createAlogAppender()]
        Logger.setup(appenders: alogAppenders, backendType: "ALog")
    }

    static func setupLKCommonsLogging() {
        Logger.setup { (type, category) -> LKCommonsLogging.Log in
            return  LarkLoggerProxy(type, category)
        }
        //增加Alog 初始化
        LKCommonsLogging.Logger.setup(for: "ALog.") { (type, category) -> LKCommonsLogging.Log in
            return LarkALoggerProxy(type, category)
        }
    }

    static func logRootPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return "\(paths[0])/logs"
    }

    static func logRootURL() -> URL {
        return URL(fileURLWithPath: logRootPath())
    }

    static func logUrls() -> [URL] {
        var fileUrls: [URL] = []

        let fileManager = FileManager.default

        // 读取Lark和Rust所有日志路径
        let rootUrls = LarkLogger.rustLogUrls() + [URL(fileURLWithPath: LarkLogger.logRootPath())]

        rootUrls.forEach { (url) in

            // 检查路径是否存在，是不是文件
            var sourcePathIsDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &sourcePathIsDirectory) else {
                return
            }

            // 如果路径是文件，则直接加入fileUrls
            guard sourcePathIsDirectory.boolValue else {
                fileUrls.append(url)
                return
            }

            // 读取路径下所有路径
            let dirEnumerater = fileManager.enumerator(atPath: url.path)
            while let name = dirEnumerater?.nextObject() as? String {

                // 拼接出完整文件路径
                let fileURL = url.appendingPathComponent(name)
                var isDirectory: ObjCBool = false

                // 路径存在且是文件则加入fileUrls
                if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) {
                    if !isDirectory.boolValue {
                        fileUrls.append(fileURL)
                    }
                }
            }
        }

        return fileUrls
    }

    private static func rustLogUrls() -> [URL] {
        let rustLogPath = globalLogPath
        let xlogPath = rustLogPath.appendingPathComponent("xlog")
        var logUrls: [URL] = []
        let maxLogNumber = 5
        do {
            let paths = try FileManager.default.contentsOfDirectory(atPath: xlogPath.path)
            let xlogFileUrls = paths.filter { $0.hasSuffix(".xlog") }
                .sorted { $0 > $1 }
                .map { xlogPath.appendingPathComponent($0) }
                .prefix(maxLogNumber)
            logUrls.append(contentsOf: xlogFileUrls)

            let mmapFileUrls = paths.filter { $0.hasSuffix(".mmap2") }
                .map { xlogPath.appendingPathComponent($0) }
            logUrls.append(contentsOf: mmapFileUrls)
        } catch {
        }
        return logUrls
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

    /// 创建Alog appender
    /// - Returns: alog apender
    private static func createAlogAppender() -> Appender {
        return AlogAppender()
    }

    private static func setupRustLogSDK() {
        DispatchQueue.global().async {
            let rustLogConfig = RustLogConfig(
                process: "lark",
                logPath: globalLogPath.path,
                monitorEnable: true
            )
            RustLogAppender.setupRustLogSDK(config: rustLogConfig)
            RustMetricAppender.setupMetric(storePath: rustLogConfig.logPath)
        }
    }
}

// Path
extension LarkLogger {
    static var documentPath: URL {
        let URLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let URL = URLs[URLs.count - 1]
        return URL
    }

    static var globalLogPath: URL {
        return documentPath.appendingPathComponent(relativeLogPath, isDirectory: false)
    }

    static var relativeLogPath: String {
        switch EnvManager.env.type {
        case .release:
            return "sdk_storage/log"
        case .preRelease:
            return "sdk_storage/pre_release/log"
        case .staging:
            return "sdk_storage/staging/log"
        }
    }
}
