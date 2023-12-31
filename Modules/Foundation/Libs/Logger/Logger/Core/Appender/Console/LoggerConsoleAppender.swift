//
//  LoggerConsoleAppender.swift
//  Lark
//
//  Created by Sylar on 2017/11/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public typealias LoggerConsoleConfig = LogEnv

open class LoggerConsoleAppender: Appender {
    public static func identifier() -> String {
        return "\(LoggerConsoleAppender.self)"
    }

    // lint:disable lark_storage_check - 无用代码，后续删掉

    public static func persistentStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: LoggerConsoleAppender.identifier())
    }

    public func persistent(status: Bool) {
        UserDefaults.standard.set(status, forKey: LoggerConsoleAppender.identifier())
        UserDefaults.standard.synchronize()
    }

    // lint:enable lark_storage_check

    var logEnv: LoggerConsoleConfig
    let console = LoggerConsole.shared

    init(_ logEnv: LoggerConsoleConfig) {
        self.logEnv = logEnv
    }

    public func doAppend(_ event: LogEvent) {

        if event.level < self.logEnv.logLevel { return }

        let fileUrl = URL(fileURLWithPath: event.file)
        if let formatTime = ConsoleAppender.dateFormatter.string(for: Date(timeIntervalSince1970: event.time)) {
            let logText = "\(formatTime) \n[\(event.function)] (\(fileUrl.lastPathComponent)(\(event.line)):\(event.type)): \(self.template(message: event.message, error: event.error)). \(self.extractAdditionalData(additionalData: event.params ?? [:]))"
            switch event.level {
            case .trace: console.verbose(logText, tags: [event.category])
            case .debug: console.debug(logText, tags: [event.category])
            case .info: console.info(logText, tags: [event.category])
            case .warn: console.warning(logText, tags: [event.category])
            case .error: console.error(logText, tags: [event.category])
            case .fatal: console.fatal(logText, tags: [event.category])
            }
        }
    }

}
