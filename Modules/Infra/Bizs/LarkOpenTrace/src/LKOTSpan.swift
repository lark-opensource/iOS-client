//
//  LKOTSpan.swift
//  LarkOpenTrace
//
//  Created by sniperj on 2020/11/10.
//

import Foundation
import LKCommonsLogging
import Heimdallr

/// HMDOTSpanWrapper
public final class LKOTSpan {
    public let span: HMDOTSpan?
    public let trace: LKOTTrace?
    init(_ span: HMDOTSpan?, _ trace: LKOTTrace?) {
        self.span = span
        self.trace = trace
    }
    /// 初始化一个trace的span
    /// - Parameters:
    ///   - trace: span归属的trace
    ///   - operationName: span的名字 (默认使用当前时间为 span 开始时间)
    /// - Returns: span对象
    public class func start(of trace: LKOTTrace?,
                            operationName: String) -> LKOTSpan {
        let span = HMDOTSpan.start(of: trace?.trace, operationName: operationName)
        span?.setTag("os", value: "iOS")
        let lkSpan = LKOTSpan(span, trace)
        trace?.activeSpan(lkSpan)
        return lkSpan
    }

    /// 初始化一个trace的span
    /// - Parameters:
    ///   - trace: span归属的trace
    ///   - operationName: span的名字
    ///   - startDate: span 开始的时间
    /// - Returns: span对象
    public class func start(of trace: LKOTTrace?,
                            operationName: String,
                            spanStart startDate: Date?) -> LKOTSpan {
        let span = HMDOTSpan.start(of: trace?.trace, operationName: operationName, spanStart: startDate)
        span?.setTag("os", value: "iOS")
        let lkSpan = LKOTSpan(span, trace)
        trace?.activeSpan(lkSpan)
        return lkSpan
    }

    /// 初始化一个span的子span
    /// - Parameters:
    ///   - operationName: span的名字
    ///   - parent: span的父span
    /// - Returns: span对象
    public class func start(_ operationName: String, childOf parent: LKOTSpan?) -> LKOTSpan {
        let span = HMDOTSpan.start(operationName, childOf: parent?.span)
        span?.setTag("os", value: "iOS")
        let lkSpan = LKOTSpan(span, parent?.trace)
        parent?.trace?.activeSpan(lkSpan)
        return lkSpan
    }

    /// 初始化一个span的子span
    /// - Parameters:
    ///   - operationName: span的名字
    ///   - parent: span的父span
    ///   - startDate: span 开始的时间
    /// - Returns: span对象
    public class func start(_ operationName: String,
                            childOf parent: LKOTSpan?,
                            spanStart startDate: Date?) -> LKOTSpan {
        let span = HMDOTSpan.start(operationName, childOf: parent?.span, spanStart: startDate)
        span?.setTag("os", value: "iOS")
        let lkSpan = LKOTSpan(span, parent?.trace)
        parent?.trace?.activeSpan(lkSpan)
        return lkSpan
    }

    /// 初始化一个span的兄弟span
    /// - Parameters:
    ///   - operationName: span的名字
    ///   - reference: 该span的前继兄弟span
    /// - Returns: span对象
    public class func start(_ operationName: String, referenceOf reference: LKOTSpan?) -> LKOTSpan {
        let span = HMDOTSpan.start(operationName, referenceOf: reference?.span)
        span?.setTag("os", value: "iOS")
        let lkSpan = LKOTSpan(span, reference?.trace)
        reference?.trace?.activeSpan(lkSpan)
        return lkSpan
    }

    /// 在span中记录一些关键的信息和对排查问题有意义的上下文信息
    /// - Parameters:
    ///   - message: 关键的信息，只支持string类型
    ///   - fields: 对排查问题有意义的上下文信息，fields的key和value必须都是string，否则fields整体会被忽略
    public func logMessage(_ message: String, fields: [String: String]) {
        self.span?.logMessage(message, fields: fields)
    }

    /// 记录本次span发生了错误
    /// - Parameter error: 一个NSError对象
    public func logError(_ error: Error) {
        self.span?.logError(error)
    }

    /// 记录一次错误的信息
    /// - Parameter message: 错误信息
    public func logError(withMessage message: String) {
        self.span?.logError(withMessage: message)
    }

    /// 向一次span中记录筛选信息，可以在平台上筛选分析
    /// - Parameters:
    ///   - key: tag的名字，只支持string
    ///   - value: 值，只支持string
    public func setTag(_ key: String, value: String) {
        self.span?.setTag(key, value: value)
    }

    /// 重置开始时间
    /// - Parameter startDate: 开始时间;
    public func resetSpanStart(_ startDate: Date) {
        self.span?.resetSpanStart(startDate)
    }

    /// 一次span完成的标志，必须手动调用
    public func finish() {
        finish(withEnd: nil)
    }

    /// 因为错误导致span中断的一次完成
    /// - Parameter error: 一个NSError对象
    public func finishWithError(_ error: Error) {
        logError(error)
        finish(withEnd: nil)
    }

    /// 因为错误导致span中断的一次完成
    /// - Parameter message: 错误信息，只支持string
    public func finishWithErrorMsg(_ message: String) {
        logError(withMessage: message)
        finish(withEnd: nil)
    }

    /// 一次span完成的标志，必须手动调用
    /// - Parameter endDate: 结束时间;
    public func finish(withEnd endDate: Date?) {
        self.trace?.closeSpan()
        self.span?.finish(withEnd: endDate)
        if let mSpan = self.span,
           mSpan.responds(to: Selector(("reportDictionary"))) {
            if let info = mSpan.perform(Selector(("reportDictionary")))?.takeUnretainedValue() as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: info, options: []),
                let str = String(data: data, encoding: String.Encoding.utf8) {
                LKOpenTraceLogger.logger.info(str)
            } else {
                LKOpenTraceLogger.logger.error("HMDOTSpan reportData can't transform json")
            }
        } else {
            LKOpenTraceLogger.logger.error("HMDOTSpan not reponds selector reportDictionary")
        }
    }
}
