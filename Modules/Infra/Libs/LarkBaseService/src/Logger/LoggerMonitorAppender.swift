//
//  LoggerMonitorAppender.swift
//  LarkBaseService
//
//  Created by ByteDance on 2023/5/11.
//

import Foundation
import Logger
import LarkMonitor

public final class LoggerMonitorAppender: Appender {

    public static func identifier() -> String {
        return "\(LoggerMonitorAppender.self)"
    }

    public static func persistentStatus() -> Bool {
        return false
    }

    public func doAppend(_ event: LogEvent) {
        let fileName = (event.file as NSString).lastPathComponent
        let function = "\(event.function) \(fileName)"
        LarkLoggerMonitor.shared.addRustLog(category: event.category, function: function)
    }

    public func persistent(status: Bool) {
        
    }
}
