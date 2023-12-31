//
//  SettingLoggerService.swift
//  LarkOpenSetting
//
//  Created by panbinghua on 2022/8/11.
//

import Foundation
import LKCommonsLogging

public final class SettingLoggerService {
    public static func logger(_ category: Category) -> Log {
        return MyLogger(category)
    }

    public enum Category: Equatable {
        case none
        case factory
        case page(String)
        case module(String)
        case store
        case track
        case custom(String)

        var description: String {
            switch self {
            case .none: return ""
            case .factory: return "factory"
            case .page(let name): return "page.\(name)"
            case .module(let name): return "module.\(name)"
            case .store: return "store"
            case .track: return "track"
            case .custom(let str): return str
            }
        }

        public static func == (lhs: Category, rhs: Category) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none), (.factory, .factory), (.store, .store), (.track, .track):
                return true
            case (.page(let str1), .page(let str2)),
                (.module(let str1), .module(let str2)),
                (.custom(let str1), .custom(let str2)):
                return str1 == str2
            default:
                return false
            }
        }
    }

    final class MyLogger: Log {

        let category: Category

        init(_ category: Category) {
            self.category = category
        }

        private let logger = Logger.log(SettingLoggerService.self, category: "OpenSetting")
        func isDebug() -> Bool {
            return logger.isDebug()
        }

        func isTrace() -> Bool {
            return logger.isTrace()
        }

        func log(event: LogEvent) {
            let str = category == .none ? "" : (category.description + "/")
            let msg = "openSettingLog/\(str)\(event.message)"
            logger.log(logId: event.logId, msg, params: event.params, tags: event.tags, level: event.level, time: event.time, file: event.file, function: event.function, line: event.line)
        }
    }
}
