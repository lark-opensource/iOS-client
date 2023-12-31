//
//  AppLogger.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/9.
//

import Foundation
import LKCommonsLogging
import Logger
import VolcEngineRTC
import LKCommonsTracker
import AppReciableSDK

struct AppLogger {
    static var ignoredCategories: Set<String> = ["UUIDManager", "Suite.OfflineLogout", "ByteView.ByteRtcSDK.Log", "Module.LarkEmotion"]
    static var filters: [AppLogFilter] = [RustLogFilter()]
    static var ignoredSourceFiles: Set<String> = ["RunloopMonitor.swift"]
    /// enable/disable logs in console: [LayoutConstraints]
    static var isLayoutConstraintsLogEnabled = true

    static func setupLogger() {
        let config = XcodeConsoleConfig(logLevel: .debug)
        let appenders: [Appender] = [ConsoleAppender(config), RustLogAppender()]

        let globalLogPath: URL = Self.globalLogURL
        let rustLogConfig = RustLogConfig(
            process: "ByteViewDemo.rust",
            logPath: globalLogPath.path,
            monitorEnable: true
        )

        RustLogAppender.setupRustLogSDK(config: rustLogConfig)
        RustMetricAppender.setupMetric(storePath: rustLogConfig.logPath)

        Logger.setup(appenders: appenders)
        Logger.setup(for: "") { (type, category) -> LKCommonsLogging.Log in
            return ConsoleLogger(type, category)
        }

        // lint:disable:next lark_storage_check
        UserDefaults.standard.set(isLayoutConstraintsLogEnabled, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")

        ByteRtcMeetingEngineKit.setLogLevel(RTC_LOG_LEVEL_ERROR)

        Tracker.register(key: .slardar, tracker: EmptyTrackerServcie.shared)
        Tracker.register(key: .tea, tracker: EmptyTrackerServcie.shared)

        AppReciableSDK.shared.setupPrinter(AppReciablePrinterImpl())
    }

    private static var globalLogURL: URL {
        let logPath = DemoEnv.isStaging ? "sdk_storage/staging/log" : "sdk_storage/log"
        return Util.documentsDirectoryURL.appendingPathComponent(logPath)
    }
}

private class EmptyTrackerServcie: TrackerService {
    static let shared = EmptyTrackerServcie()
    func post(event: LKCommonsTracker.Event) {}
}

private class EmptyLogger: LKCommonsLogging.Log {
    static let shared = EmptyLogger()
    func log(event: LKCommonsLogging.LogEvent) {}
    func isDebug() -> Bool { false }
    func isTrace() -> Bool { false }
}

private class ConsoleLogger: LKCommonsLogging.Log {
    let wrapper: LoggerLog

    init(_ type: Any, _ category: String, custom: LKCommonsLogging.Log? = nil) {
        let typeCls: AnyClass = type as? AnyClass ?? Logger.self
        self.wrapper = Logger.log(typeCls, category: category)
    }

    func log(event: LKCommonsLogging.LogEvent) {
        #if DEBUG
        if event.message.count > 4000 {
            print("日志过长,count:\(event.message.count)")
        }
        self.wrapper.log(transform(event))
        #endif
    }

    func transform(_ event: LKCommonsLogging.LogEvent) -> LoggerLogEvent {
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

    func isDebug() -> Bool {
        return false
    }

    func isTrace() -> Bool {
        return false
    }
}

private class ConsoleAppender: Appender {

    static let dateFormatter: DateFormatter = DateFormatter()
    static let queue = DispatchQueue(label: "com.byteview.console-appender")

    var logEnv: XcodeConsoleConfig
    let appName = Bundle.main.infoDictionary?["CFBundleName"]

    init(_ logEnv: XcodeConsoleConfig) {
        self.logEnv = logEnv
        ConsoleAppender.dateFormatter.dateFormat = "[HH:mm:ss.SSS]"
    }

    static func identifier() -> String {
        return "\(ConsoleAppender.self)"
    }

    func persistent(status: Bool) {
    }

    static func persistentStatus() -> Bool {
        return false
    }

    func printEvent(_ event: LoggerLogEvent) {
        if AppLogger.ignoredCategories.contains(event.category) {
            return
        }
        let fileName = URL(fileURLWithPath: event.file).lastPathComponent
        if AppLogger.ignoredSourceFiles.contains(fileName) {
            return
        }
        for filter in AppLogger.filters {
            if filter.shouldIgnore(fileName: fileName, event: event) {
                return
            }
        }
        if let formatTime = ConsoleAppender.dateFormatter.string(for: Date(timeIntervalSince1970: event.time)) {
            var logColor = ""
            switch event.level {
            case .trace:
                logColor = "[T]"
            case .debug:
                logColor = "[D]"
            case .info:
                logColor = "[I]"
            case .warn:
                logColor = "[W]"
            case .error:
                logColor = "[E]"
            case .fatal:
                logColor = "[F]"
            default:
                break
            }
            let msg = template(message: event.message, error: event.error)
            var ctxId = ""
            if let contextId = event.params?["contextID"], !contextId.isEmpty {
                ctxId = "[\(contextId)]"
            }
            if event.category == "ByteView.Push" || event.category == "ByteView.Network" {
                print("\(logColor)\(formatTime)\(ctxId)\(msg) [\(fileName):\(event.line)]")
            } else if event.category.starts(with: "ByteView.") || event.category.starts(with: "Demo.") {
                print("\(logColor)\(formatTime)\(msg) [\(fileName):\(event.line)]")
            } else {
                let category = event.category.isEmpty ? "\(event.type)" : event.category
                print("\(logColor)\(formatTime)\(ctxId)[\(category)] \(msg) [\(fileName):\(event.line)]")
            }
        }
    }

    func doAppend(_ event: LoggerLogEvent) {
        #if DEBUG
        if event.level.rawValue >= logEnv.logLevel.rawValue {
            Self.queue.async {
                self.printEvent(event)
            }
        }
        #endif
    }

}

protocol AppLogFilter {
    func shouldIgnore(fileName: String, event: LoggerLogEvent) -> Bool
}

private struct RustLogFilter: AppLogFilter {
    func shouldIgnore(fileName: String, event: LoggerLogEvent) -> Bool {
        if fileName == "RustManager.swift" && event.message.contains("pushMessageProcessCallback") {
            // [10:39:14.643][RustSDK.Client] RustManager.swift(381): pushMessageProcessCallback pushChatters[] executionTime: 0.0000.
            return true
        }
        return false
    }
}

private class AppReciablePrinterImpl: AppReciableSDKPrinter {
    private let logger = LKCommonsLogging.Logger.log("Demo", category: "LarkAppreciable")

    func info(logID: String, _ message: String, _ timestamp: TimeInterval?) {
        logger.info(message)
    }

    func error(logID: String, _ message: String, _ timestamp: TimeInterval?) {
        logger.error(message)
    }
}
