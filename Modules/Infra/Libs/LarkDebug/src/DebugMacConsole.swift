//
//  DebugMacConsole.swift
//
//  Created by limboy on 10/6/19.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//
#if !LARK_NO_DEBUG
import Foundation
import Logger
import os.log

open class MacConsoleAppender: Appender {
    static var shared = MacConsoleAppender()
    private let log = OSLog(subsystem: "com.bytedance.lark", category: "Logging")

    public static func identifier() -> String {
        return "\(MacConsoleAppender.self)"
    }

    public static func persistentStatus() -> Bool {
        return false
    }

    public func persistent(status: Bool) {
    }

    public func doAppend(_ event: LogEvent) {
        let fileUrl = URL(fileURLWithPath: event.file)
        let logText = """
            [\(event.level)] \(fileUrl.lastPathComponent)(\(event.line)):\
            \(event.thread):[\(event.type)|\(event.category)]:\
            \(self.template(message: event.message, error: event.error)).\
            \(self.extractAdditionalData(additionalData: event.params ?? [:]))
            """
        os_log("%{public}s", log: log, logText)
    }
}
#endif
