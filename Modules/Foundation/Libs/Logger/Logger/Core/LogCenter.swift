//
//  LogCenter.swift
//  Logger
//
//  Created by 崔贵林 on 2019/5/14.
//

import Foundation
import LKCommonsLogging

public struct LogCenter: LKCommonsLogging.Log {

    public struct Config {
        public let backend: String
        public let appenders: [Appender]
        public let forwardToDefault: Bool

        public  init(
            backend: String,
            appenders: [Appender],
            forwardToDefault: Bool = false
        ) {
            self.backend = backend
            self.appenders = appenders
            self.forwardToDefault = forwardToDefault
        }
    }

    let logger: LoggerLog

    init(_ type: Any,
         _ category: String,
         _ backendType: String,
         _ forwardToDefault: Bool = false
    ) {
        let typeCls: AnyClass = type as? AnyClass ?? Logger.self
        logger = Logger.log(
            typeCls,
            category: category,
            backendType: backendType,
            forwardToDefault: forwardToDefault
        )
    }

    public func isDebug() -> Bool {
        return true
    }

    public func isTrace() -> Bool {
        return true
    }

    public func log(event: LKCommonsLogging.LogEvent) {
        let e = LoggerLogEvent(
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
        logger.log(e)
    }

    public static func setup(configs: [Config]) {
        configs.forEach { (config) in
            Logger.setup(
                appenders: config.appenders,
                backendType: config.backend
            )
            LKCommonsLogging.Logger.setup(for: config.backend) { (type, category) -> LKCommonsLogging.Log in
                return LogCenter(
                    type,
                    category,
                    config.backend,
                    config.forwardToDefault
                )
            }
        }
    }

    public static func setup(config: [String: [Appender]]) {
        for (backend, appenders) in config {
            Logger.setup(appenders: appenders, backendType: backend)
            LKCommonsLogging.Logger.setup(for: backend) { (type, category) -> LKCommonsLogging.Log in
                return LogCenter(type, category, backend)
            }
        }
    }
}
