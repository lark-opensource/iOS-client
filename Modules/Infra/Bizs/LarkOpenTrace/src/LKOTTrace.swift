//
//  LKOTTrace.swift
//  LarkOpenTrace
//
//  Created by sniperj on 2020/11/10.
//

import Foundation
import LKCommonsLogging
import Heimdallr

/// HMDOTTraceWrapper
public final class LKOTTrace {
    /// HMDOTTrace
    public let trace: HMDOTTrace?
    var spanScope: [LKOTSpan] = []
    init(_ trace: HMDOTTrace?) {
        self.trace = trace
    }
    /// 初始化一次trace
    /// - Parameter serviceName: trace的名字 (默认使用当前时间为 trace 开始时间)
    /// - Returns: trace对象
    public class func start(_ serviceName: String) -> LKOTTrace {
        let trace = HMDOTTrace.start(serviceName)
        return LKOTTrace(trace)
    }

    /// 初始化一次trace
    /// - Parameters:
    ///   - serviceName: trace的名字
    ///   - startDate:  trace 开始的时间，传空默认是当前时间
    /// - Returns: trace对象
    public class func start(_ serviceName: String, start startDate: Date?) -> LKOTTrace {
        let trace = HMDOTTrace.start(serviceName, start: startDate)
        return LKOTTrace(trace)
    }

//    /// 初始化一次trace
//    /// - Parameters:
//    ///   - serviceName: trace的名字
//    ///   - startDate:  trace 开始的时间，传空默认是当前时间
//    ///   - insertMode: span写入模式，具体可以查看HMDOTTraceInsertMode枚举的定义
//    /// - Returns: trace对象
//    public class func start(_ serviceName: String,
//                            start startDate: Date?,
//                            insertMode: HMDOTTraceInsertMode) -> LKOTTrace {
//        let trace = HMDOTTrace.start(serviceName, start: startDate, insertMode: insertMode)
//        return LKOTTrace(trace)
//    }

    /// 重置开始时间
    /// - Parameter startDate: 开始的时间;
    public func resetTraceStart(_ startDate: Date) {
        self.trace?.resetTraceStart(startDate)
    }

    /// 一次trace结束的标志，必须手动调用; (默认使用当前时间为结束时间)
    public func finish() {
        finish(with: nil)
    }

    /// 向一次trace中记录筛选信息，可以在平台上筛选分析，trace中的tag最终将作用于当次trace中的每个span上
    /// - Parameters:
    ///   - key: tag的名字，只支持string
    ///   - value: 值，只支持string
    public func setTag(_ key: String, value: String) {
        self.trace?.setTag(key, value: value)
    }

    /// 废弃当前的 trace; 三种insert model均支持
    public func abandonCurrentTrace() {
        self.trace?.abandonCurrentTrace()
    }

    /// 一次trace结束的标志，必须手动调用
    /// - Parameter finishDate: trace 结束的时间
    public func finish(with finishDate: Date?) {
        self.trace?.finish(with: finishDate)
        if let mTrace = self.trace,
           mTrace.responds(to: Selector(("reportDictionary"))) {
            if let info = mTrace.perform(Selector(("reportDictionary")))?.takeUnretainedValue() as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: info, options: []),
                let str = String(data: data, encoding: String.Encoding.utf8) {
                LKOpenTraceLogger.logger.info(str)
            } else {
                LKOpenTraceLogger.logger.error("HMDOTTrace reportData can't transform json")
            }
        } else {
            LKOpenTraceLogger.logger.error("HMDOTTrace not reponds selector reportDictionary")
        }
    }

    /// get hmdTrace traceid
    public lazy var traceID: String? = {
        return self.trace?.traceID
    }()

    /// get active span by current threadID
    /// - Returns: activeSpan
    /// abolish
    public func getActiveSpan() -> HMDOTSpan? {
//        return spanScope.last?.span
        return nil
    }

    /// abolish
    internal func activeSpan(_ span: LKOTSpan) {
//        spanScope.append(span)
    }

    /// abolish
    internal func closeSpan() {
//        spanScope.removeLast()
    }
}
