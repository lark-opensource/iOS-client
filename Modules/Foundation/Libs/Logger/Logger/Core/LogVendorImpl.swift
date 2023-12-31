//
//  LogVendor.swift
//  Lark
//
//  Created by linlin on 2017/3/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

final class LogVendorImpl: LogVendor {
    let eventWriteQueue: OperationQueue

    var appenders: [Appender]

    init(appenders: [Appender]) {
        self.eventWriteQueue = OperationQueue()
        self.eventWriteQueue.maxConcurrentOperationCount = 1
        self.eventWriteQueue.name = "logWriter"
        self.eventWriteQueue.qualityOfService = .background
        self.appenders = appenders
    }

    func writeEvent(_ event: LogEvent) {
        self.writeEvent(event, forward: false)
    }

    /// forward 表明此事件会被转发
    func writeEvent(_ event: LogEvent, forward: Bool) {
        eventWriteQueue.addOperation {
            LogReceiver.writeEventToAppender(event: event, appenders: self.appenders)
        }
    }

    func isActivate(_ appenderType: AnyClass) -> Appender? {
        for value in self.appenders {
            if type(of: value) == appenderType {
                return value
            }
        }
        return nil
    }

    func setup(appenders: [Appender]) {
        if self.appenders.isEmpty {
            self.appenders = appenders
        } else {
            eventWriteQueue.addOperation {
                self.appenders = appenders
            }
        }
    }

    func addAppender(_ appender: Appender, persistent status: Bool) {
        eventWriteQueue.addOperation {
            self.appenders = LogVendorImpl.addAppender(appender, appenders: self.appenders)
            if status {
                appender.persistent(status: true)
            }
        }
    }

    func removeAppender(_ appender: Appender, persistent status: Bool) {
        eventWriteQueue.addOperation {
            self.appenders = LogVendorImpl.removeAppender(appender, appenders: self.appenders)
            if status {
                appender.persistent(status: false)
            }
        }
    }

    func updateAppender(_ appender: Appender) {
        eventWriteQueue.addOperation {
            self.appenders = LogVendorImpl.updateAppender(appender, appenders: self.appenders)
        }
    }

    private class func addAppender(_ appender: Appender, appenders: [Appender]) -> [Appender] {
        return appenders + [appender]
    }

    private class func removeAppender(_ appender: Appender, appenders: [Appender]) -> [Appender] {
        var tempAppenders = appenders
        for (index, value) in tempAppenders.enumerated() {
            if type(of: value) == type(of: appender) {
                tempAppenders.remove(at: index)
                break
            }
        }
        return tempAppenders
    }

    private class func updateAppender(_ appender: Appender, appenders: [Appender]) -> [Appender] {
        var tempAppenders = appenders
        for (index, value) in tempAppenders.enumerated() {
            if type(of: value) == type(of: appender) {
                tempAppenders.remove(at: index)
                tempAppenders.insert(appender, at: index)
                break
            }
        }
        return tempAppenders
    }
}

final class LogVenderProxy: LogVendor {

    var vender: LogVendorImpl
    var forward: LogVendorImpl

    init(vender: LogVendorImpl, forward: LogVendorImpl) {
        self.vender = vender
        self.forward = forward
    }

    func writeEvent(_ event: LogEvent) {
        vender.writeEvent(event, forward: true)
        forward.writeEvent(event)
    }

    func addAppender(_ appender: Appender, persistent status: Bool) {
        self.vender.addAppender(appender, persistent: status)
    }
}
