//
//  AlogAppender.swift
//  Logger
//
//  Created by CL7R on 2020/11/29.
//

import Foundation
import BDAlogProtocol

public final class AlogAppender: Appender {

    public init() {
    }

    public static func persistentStatus() -> Bool {
        return false
    }

    public static func identifier() -> String {
        return "\(AlogAppender.self)"
    }

    public func doAppend(_ event: LogEvent) {
        var level: kBDLogLevel = kLogLevelNone
        switch event.level {
        case .debug:
            level = kLogLevelDebug
        case .info:
            level = kLogLevelInfo
        case .warn:
            level = kLogLevelWarn
        case .error:
            level = kLogLevelError
        case .fatal:
            level = kLogLevelFatal
        default:
            level = kLogLevelNone
        }

        BDALogProtocol.setALogWithFileName(event.file, funcName: event.function, tag: event.tags.joined(separator: ","), line: Int32(event.line), level: Int32(level.rawValue), format: event.message)
    }

    public func persistent(status: Bool) {
    }
}
