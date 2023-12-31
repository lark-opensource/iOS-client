//
//  TraceIdService.swift
//  LarkTraceId
//
//  Created by ByteDance on 2022/12/21.
//

import Foundation
import LKCommonsLogging
import LarkSetting

/// 定义事件归属的模块名，便于筛选出同一模块下的所有事件流
/// 最好采用"通用模块名_Trace"的格式加以区分
public enum TraceEventModuleType: String {
    case onboarding = "Onboarding_Trace"
    case forward = "Forward_Trace"
    case ugGuide = "UGGuide_Trace"
    case emotion = "Emotion_Trace"
    case unknown = "Unknown_Module"
}

public class TraceIdService {

    static let logger = Logger.log(TraceIdService.self, category: "TraceIdService")

    static let traceIdKey: String = "TraceId"

    /// 获取TraceID
    public static func getTraceId() -> String {
        return Thread.current.threadDictionary.value(forKey: Self.traceIdKey) as? String ?? ""
    }

    /// 设置TraceID
    public static func setTraceId(_ traceId: String) {
        Thread.current.threadDictionary.setValue(traceId, forKey: Self.traceIdKey)
    }

    /// 清理TraceID
    public static func clearTraceId() {
        Thread.current.threadDictionary.removeObject(forKey: Self.traceIdKey)
    }

    /// 事件开始，内部会自动清理TraceID
    /// - Parameters:
    ///     - eventName: 事件名
    ///     - moduleName: 模块名
    ///     - event: 事件block
    @discardableResult
    public static func start<T>(eventName: String?,
                                moduleName: TraceEventModuleType = .unknown,
                                event: (() -> T)) -> T {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let traceId = String((0...9).map { _ in letters.randomElement()! })
        Self.setTraceId(traceId)
        if let eventName = eventName, !eventName.isEmpty {
            let additionalData = (moduleName == .unknown) ? [:] : ["TraceModule": moduleName.rawValue]
            Self.logger.info("\(eventName)", additionalData: additionalData)
        }
        let res = event()
        Self.clearTraceId()
        return res
    }

    /// 事件开始，需要手动动清理TraceID
    /// - Parameters:
    ///     - eventName: 事件名
    ///     - moduleName: 模块名
    public static func start(eventName: String?,
                                moduleName: TraceEventModuleType = .unknown) {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let traceId = String((0...9).map { _ in letters.randomElement()! })
        Self.setTraceId(traceId)
        if let eventName = eventName, !eventName.isEmpty {
            let additionalData = (moduleName == .unknown) ? [:] : ["TraceModule": moduleName.rawValue]
            Self.logger.info("\(eventName)", additionalData: additionalData)
        }
    }

    /// 重新设置TraceID，内部会自动清理TraceID
    /// - Parameters:
    ///     - traceId: 需要设置的TraceID
    ///     - event: 事件block
    @discardableResult
    public static func resume<T>(traceId: String,
                                 event: (() -> T)) -> T {
        Self.setTraceId(traceId)
        let res = event()
        Self.clearTraceId()
        return res
    }
}
