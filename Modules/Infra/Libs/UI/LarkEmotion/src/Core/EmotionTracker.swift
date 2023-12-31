//
//  EmotionTracker.swift
//  LarkEmotion
//
//  Created by 李勇 on 2021/3/31.
//

import Foundation
import Homeric
import LKCommonsTracker
import LKCommonsLogging
import LarkRustClient

public final class EmotionTracker {
    static func trackFallback(key: String, version: Int32) {
        Tracker.post(TeaEvent(Homeric.EMOJI_SHOW_FALLBACK, params: ["key": key, "version": version]))
    }
    // 表情监控：Tea埋点
    public static func trackerTea(event: String,
                                  time: Double?,
                                  extraParams: [AnyHashable: Any],
                                  error: Error?) {
        var paramsDic = extraParams
        let errorInfo = Self.getErrorInfo(error: error)
        paramsDic[Cons.status] = errorInfo.status
        paramsDic[Cons.reason] = errorInfo.reason
        paramsDic[Cons.cost] = time
        Tracker.post(TeaEvent(event, params: paramsDic))
    }
    // 表情监控：Slardar埋点
    public static func trackerSlardar(event: String, time: Double, category: [AnyHashable : Any], metric: [AnyHashable : Any], error: Error?) {
        var metricDic = metric
        metricDic[Cons.cost] = time
        // error.underlyingError 取的是最顶层的error，一般是APIError
        // RCError: 大部分的请求错误都是RCError
        // 这里只对比RCError，所以取最底层error
        let errorInfo = Self.getErrorInfo(error: error)
        var categoryDic = category
        categoryDic[Cons.status] = errorInfo.status
        categoryDic[Cons.reason] = errorInfo.reason
        Tracker.post(SlardarEvent(
            name: event,
            metric: metricDic,
            category: categoryDic,
            extra: [:])
        )
    }
    private static func getErrorInfo(error: Error?) -> (status: Int32, reason: String) {
        var status: Int32 = 0
        var reason = ""
        guard let error else { return (status, reason) }
        let errorStack = error.metaErrorStack
        if let rcError: RCError = errorStack.isEmpty ? (error as? RCError) : (errorStack.last as? RCError) {
            switch rcError {
            case .businessFailure(let errorInfo):
                reason = errorInfo.displayMessage
                status = errorInfo.errorStatus
            default:
                reason = error.localizedDescription
                status = -1
            }
        }
        return (status, reason)
    }
}

struct EmotionUtils {
    // emotion 统一logger
    public static var logger = Logger.log(EmotionUtils.self, category: "Module.LarkEmotion")
}

extension EmotionTracker {
    enum Cons {
        static var status: String { "status" }
        static var reason: String { "reason" }
        static var cost: String { "cost" }
    }
}
