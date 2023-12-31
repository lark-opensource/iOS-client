//
//  UploadLogAppender.swift
//  LarkApp
//
//  Created by quyiming@bytedance.com on 2019/7/9.
//
import Foundation
import Logger
import LarkAccountInterface

typealias UploadLogConfig = LogEnv

class UploadLogAppender: Appender {

    static let dateFormatter: DateFormatter = DateFormatter()

    public var logEnv: UploadLogConfig

    var logger: UploadLog?

    public init(_ logEnv: UploadLogConfig) {
        self.logEnv = logEnv
        UploadLogAppender.dateFormatter.dateFormat = "yyyy-MM-dd\'T\'HH:mm:ss.SSSSSSXXXXX"
    }

    public static func identifier() -> String {
        return "\(UploadLogAppender.self)"
    }

    public static func persistentStatus() -> Bool {
        return false
     }

    public func doAppend(_ event: LogEvent) {
        if event.level.rawValue >= logEnv.logLevel.rawValue,
            let formatTime = UploadLogAppender.dateFormatter.string(for: Date(timeIntervalSince1970: event.time)),
            let logger = logger {
            let h5Log = event.params?["h5Log"] != nil
            let messagePart1 = SuiteLoginLogFormat.template(message: event.message, error: event.error)
            let messagePart2 = SuiteLoginLogFormat.extractAdditionalData(additionalData: event.params ?? [:])
            let msg = "\(messagePart1).\(messagePart2) "
            let log = LogModel(level: event.level.string(),
                               msg: msg,
                               file: event.file,
                               line: event.line,
                               h5Log: h5Log,
                               time: formatTime,
                               thread: event.thread)
            logger.log(log)
        }
    }

    public func persistent(status: Bool) {
    }
}

private extension LogLevel {

    func string() -> String {
        switch self {
        case .trace:
            return Level.debug.rawValue
        case .debug:
            return Level.debug.rawValue
        case .info:
            return Level.info.rawValue
        case .warn:
            return Level.warn.rawValue
        case .error:
            return Level.error.rawValue
        case .fatal:
            return Level.error.rawValue
        @unknown default:
            assert(false, "new value")
            return "unknown"
        }
    }

}
