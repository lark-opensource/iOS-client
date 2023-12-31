//
//  ConsoleAppender.swift
//  Lark
//
//  Created by Sylar on 2018/1/17.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation

public typealias XcodeConsoleConfig = LogEnv

final class ConsoleAppender: Appender {

    static let dateFormatter: DateFormatter = DateFormatter()

    var logEnv: XcodeConsoleConfig
    let appName: String = (Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? ""

    init(_ logEnv: XcodeConsoleConfig) {
        self.logEnv = logEnv
        ConsoleAppender.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }

    static func identifier() -> String {
        return "\(ConsoleAppender.self)"
    }

    func persistent(status: Bool) {
    }

    static func persistentStatus() -> Bool {
        return false
    }

    internal func doAppend(_ event: LogEvent) {

        func printEvent(_ event: LogEvent) {
            if let formatTime = ConsoleAppender.dateFormatter.string(for: Date(timeIntervalSince1970: event.time)) {

                let fileUrl = URL(fileURLWithPath: event.file)
                let logText = "\(formatTime) \(appName) [\(event.level)] \(fileUrl.lastPathComponent)(\(event.line)):\(event.thread):[\(event.type)|\(event.category)]: \(self.template(message: event.message, error: event.error)).\(self.extractAdditionalData(additionalData: event.params ?? [:]))"

                var logColor = ""
                switch event.level {
                case .trace:
                    logColor = LevelColor.trace
                case .debug:
                    logColor = LevelColor.debug
                case .info:
                    logColor = LevelColor.info
                case .warn:
                    logColor = LevelColor.warning
                case .error:
                    logColor = LevelColor.error
                default:
                    break
                }
                print("\(logColor) \(logText)")
            }
        }

        if event.level >= logEnv.logLevel {
            printEvent(event)
        }
    }

}
