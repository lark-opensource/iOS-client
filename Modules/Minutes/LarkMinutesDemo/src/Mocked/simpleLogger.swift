//
//  SimpleLog.swift
//  LKCommonsLogging
//
//  Created by lvdaqian on 2018/5/6.
//  Copyright © 2018年 Efficiency Engineering. All rights reserved.
//

import Foundation
import LKCommonsLogging

extension LogLevel {
    var levelColor: String {
        switch self {
        case .trace:
            return "💜"
        case .debug:
            return "💚"
        case .info:
            return "💙"
        case .warn:
            return "💛"
        case .error:
            return "❤️"
        case .fatal:
            return "❤️"
        default:
            return ""
        }
    }
}

struct SimpleLog: Log {
    let category: String
    let debug: Bool
    let trace: Bool

    func isDebug() -> Bool {
        return debug
    }

    func isTrace() -> Bool {
        return trace
    }

    func log(event: LogEvent) {
        let file = event.file.components(separatedBy: CharacterSet(charactersIn: "\\/")).last ?? event.file
        var logMessage: String = "\(Date(timeIntervalSince1970: event.time).timeString(ofStyle: .medium)) \(event.level.levelColor) "
            + "[\(file):\(event.line)][\(category)]"
            + " - \(event.message)"

        if let data = event.additionalData {
            logMessage += " with additional data: \(data)\n"
        }

        if let error = event.error {
            logMessage += " with error:\(error)\n"
        }

        print(logMessage)
    }
}
