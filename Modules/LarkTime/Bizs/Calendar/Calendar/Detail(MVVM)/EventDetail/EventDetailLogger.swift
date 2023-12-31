//
//  EventDetailLogger.swift
//  Calendar
//
//  Created by Rico on 2021/4/19.
//

import Foundation
import LKCommonsLogging

extension EventDetail {

    static let logPrefix = "[EventDetail] - "
    static private var logger: LKCommonsLogging.Log {
        return Logger.log(EventDetail.self, category: "lark.calendar.detail")
    }

    static func logInfo(_ message: String,
                        file: String = #fileID,
                        function: String = #function,
                        line: Int = #line) {
        logger.info(logPrefix + message,
                    file: file,
                    function: function,
                    line: line)
    }

    static func logError(_ message: String,
                         file: String = #fileID,
                         function: String = #function,
                         line: Int = #line) {
        logger.error(logPrefix + message,
                     file: file,
                     function: function,
                     line: line)
    }

    static func logWarn(_ message: String,
                        file: String = #fileID,
                        function: String = #function,
                        line: Int = #line) {
        logger.warn(logPrefix + message,
                    file: file,
                    function: function,
                    line: line)
    }

    static func logDebug(_ message: String,
                         file: String = #fileID,
                         function: String = #function,
                         line: Int = #line) {
        logger.debug(logPrefix + message,
                     file: file,
                     function: function,
                     line: line)
    }

    static func logUnreachableLogic(file: String = #fileID,
                                    function: String = #function,
                                    line: Int = #line) {
        assertionFailure(logPrefix + "should not excute code!")
        logger.warn(logPrefix + "should not excute code!")
    }
}
