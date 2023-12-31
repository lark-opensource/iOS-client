//
//  LogReceiver.swift
//  Lark
//
//  Created by linlin on 2017/3/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

final class LogReceiver {

    class func receiveEvent(event: LogEvent, events: [LogEvent]) -> [LogEvent] {
        return events + [event]
    }

    class func writeEventToAppender(event: LogEvent, appenders: [Appender]) {
        appenders.forEach { (appender) in
            #if DEBUG
            checkEventValid(event: event, appender: appender)
            #endif
            appender.doAppend(event)
        }
    }

    class func writeEventsToAppender(events: [LogEvent], appenders: [Appender]) -> [LogEvent] {
        events.forEach { (event) in
            appenders.forEach({ (appender) in
                #if DEBUG
                checkEventValid(event: event, appender: appender)
                #endif
                appender.doAppend(event)
            })
        }
        return []
    }

    class func checkEventValid(event: LogEvent, appender: Appender) {
        appender.debugLogRules().forEach { (rule) in
            assert(rule.check(event: event), "event not conform to rule \(rule.name), event file \(event.file) function \(event.function) line \(event.line)")
        }
    }
}
