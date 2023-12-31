//
//  TodayEvent.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/29.
//

import Foundation
import LKCommonsLogging

class TodayEvent {
    static let logPrefix = "[TodayEvent] - "
    static private var logger: LKCommonsLogging.Log {
        return Logger.log(EventDetail.self, category: "lark.calendar.TodayEvent")
    }

    static func logInfo(_ message: String) {
        logger.info(logPrefix + message)
    }

    static func logError(_ message: String) {
        logger.error(logPrefix + message)
    }

    static func logWarning(_ message: String) {
        logger.warn(logPrefix + message)
    }
}
