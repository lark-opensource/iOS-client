//
//  Lark+LKCommonsLogging.swift
//  Lark
//
//  Created by lvdaqian on 2018/9/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import Logger

struct LarkLoggerProxy: LKCommonsLogging.Log {
    let logger: LoggerLog
    let custom: LKCommonsLogging.Log?
    private let lock = NSLock()

    init(_ type: Any, _ category: String, custom: LKCommonsLogging.Log? = nil) {
        let typeCls: AnyClass = type as? AnyClass ?? Logger.self
        self.logger = Logger.log(typeCls, category: category)
        self.custom = custom
    }

    func log(event: LKCommonsLogging.LogEvent) {
        lock.lock(); defer { lock.unlock() }
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
