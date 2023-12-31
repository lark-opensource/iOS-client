//
//  SetupLoggerBootTask.swift
//  LarkByteView
//
//  Created by 刘建龙 on 2020/7/6.
//

import Foundation
import BootManager
import VolcEngineRTC
import LKCommonsLogging
import Logger
import LarkContainer

final class SetupLoggerBootTask: UserFlowBootTask, Identifiable {
    static var identify: TaskIdentify {
        "ByteView.SetupLoggerTask"
    }

    override var runOnlyOnce: Bool {
        true
    }

    override func execute(_ context: BootContext) {
        // 初始化 ByteView and Voip custom logger
        Logger.setup(for: "ByteView.") { (type, category) -> LKCommonsLogging.Log in
            return LarkLoggerProxy(type, category)
        }
        ByteRtcMeetingEngineKit.setLogLevel(RTC_LOG_LEVEL_INFO)
    }
}


private struct LarkLoggerProxy: LKCommonsLogging.Log {
    let logger: LoggerLog
    let custom: LKCommonsLogging.Log?

    init(_ type: Any, _ category: String, custom: LKCommonsLogging.Log? = nil) {
        let typeCls: AnyClass = type as? AnyClass ?? Logger.self
        self.logger = Logger.log(typeCls, category: category)
        self.custom = custom
    }

    func log(event: LKCommonsLogging.LogEvent) {
        let e = EventTransform.transform(event)
        logger.log(e)
        self.custom?.log(event: event)
    }

    func isDebug() -> Bool {
        return true
    }

    func isTrace() -> Bool {
        return true
    }
}

private struct EventTransform {
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
