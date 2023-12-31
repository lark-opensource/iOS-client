//
//  TimeLogger.swift
//  AppContainer
//
//  Created by SuPeng on 1/22/19.
//

import Foundation
import UIKit
import os.signpost
import LKCommonsLogging
import ThreadSafeDataStructure

public final class TimeLogger {
    public static let shared = TimeLogger()

    #if DEBUG
    private let osLogger = OSLog(subsystem: "Lark", category: "TimeLogger")
    private let signPostName: StaticString = "App Launch"
    #endif

    private static let logger = Logger.log(TimeLogger.self, category: "AppContainer.TimeLogger")

    lazy var firstEventTime: CFTimeInterval = {
        return CACurrentMediaTime()
    }()

    // Client Perf需要输出启动时间到日志，部分模块启动在日志模块初始化之前，需要缓存
    private var startTimeStampDic: SafeDictionary<String, TimeInterval>? = [:] + .readWriteLock
    private var endTimeStampDic: SafeDictionary<String, TimeInterval>? = [:] + .readWriteLock

    private init() {}

    /// 用于记录异步event begin事件
    ///
    /// - Parameters:
    ///   - eventName: event name
    /// - Returns: identity Object, 下次停止的时候传入
    public func logBegin(eventName: String) -> AnyObject {
        // Client Perf
        let startTimeStamp = Date().timeIntervalSince1970 * 1000
        startTimeStampDic?[eventName] = startTimeStamp

        TimeLogger.logger.info("Start of " + eventName)
        let randomObject = NSObject()
        #if DEBUG
        if #available(iOS 12.0, *) {
            let spid = OSSignpostID(log: osLogger, object: randomObject)
            os_signpost(.begin, log: osLogger, name: signPostName, signpostID: spid, "%{public}s", eventName)
        }
        #endif
        return randomObject
    }

    /// 用于记录异步event end事件
    ///
    /// - Parameters:
    ///   - identityObject: logBegin方法返回的object
    ///   - eventName: event name
    public func logEnd(identityObject: AnyObject, eventName: String) {
        // Client Perf
        let endTimeStamp = Date().timeIntervalSince1970 * 1000
        endTimeStampDic?[eventName] = endTimeStamp

        TimeLogger.logger.info("End of " + eventName)
        #if DEBUG
        if #available(iOS 12.0, *) {
            let spid = OSSignpostID(log: osLogger, object: identityObject)
            os_signpost(.end, log: osLogger, name: signPostName, signpostID: spid, "%{public}s", eventName)
        }
        #endif
    }

    public typealias ClientPerf = (_ start: [String: TimeInterval], _ end: [String: TimeInterval]) -> Void
    public func printDebugResult(_ callback: ClientPerf) {
        if let start = self.startTimeStampDic?.getImmutableCopy(), let end = self.endTimeStampDic?.getImmutableCopy() {
            callback(start, end)
        }
        self.startTimeStampDic = nil
        self.endTimeStampDic = nil
    }
}
