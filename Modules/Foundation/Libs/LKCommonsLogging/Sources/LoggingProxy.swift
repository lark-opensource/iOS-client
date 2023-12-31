//
//  LoggingProxy.swift
//  LKCommonsLogging
//
//  Created by lvdaqian on 2018/5/6.
//  Copyright © 2018年 Efficiency Engineering. All rights reserved.
//

import Foundation

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

final class LoggingProxy: Log {

    static let logQueue = DispatchQueue(label: "LKCommonsLogging.LoggingProxy", qos: .background)

    var logger: Log?
    let type: Any
    let category: String

    private var caches: [LogEvent] = []
    private var lock = NSLock()

    init(_ type: Any, category: String) {
        self.type = type
        self.category = category
    }

    func setupLogFactory(_ block: LogFactoryBlock) {
        let logger = block(type, category)
        lock.lock(); defer { lock.unlock() }
        self.logger = logger
        self.caches.forEach { (event) in
            self.logger?.log(event: event)
        }
        self.caches.removeAll()
    }

    func isDebug() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard let logger = self.logger else { return true }
        return logger.isDebug()
    }

    func isTrace() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard let logger = self.logger else { return true }
        return logger.isTrace()
    }

    func log(event: LogEvent) {
        lock.lock(); defer { lock.unlock() }
        if let logger = self.logger {
            logger.log(event: event)
        } else {
            simpleLog(event: event)
        }
    }

    func simpleLog(event: LogEvent) {
        #if DEBUG
        let category = self.category

        LoggingProxy.logQueue.async {
            let file = event.file.components(separatedBy: CharacterSet(charactersIn: "\\/")).last ?? event.file
            var logMessage: String = "\(Date(timeIntervalSince1970: event.time)) \(event.level.levelColor) "
                + "[\(file):\(event.line)][\(category)]"
                + "[\(event.thread)]"
                + " - \(event.message)\n"

            if let data = event.params {
                logMessage += "    with additional data: \(data)\n"
            }

            if let error = event.error {
                logMessage += "    with error:\(error)\n"
            }

            print(logMessage)
        }
        #endif
        caches.append(event)
    }
}
