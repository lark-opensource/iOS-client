//
//  TraceIdUtil.swift
//  LarkRustClient
//
//  Created by ByteDance on 2023/3/6.
//

import Foundation

class TraceIdUtil {

    /// 与LarkTraceId中的key保持一致，勿随意修改
    static let traceIdKey: String = "TraceId"

    /// 获取TraceID
    static func getTraceId() -> String {
        return Thread.current.threadDictionary.value(forKey: Self.traceIdKey) as? String ?? ""
    }

    /// 手动设置TraceID
    static func setTraceId(_ traceId: String) {
        Thread.current.threadDictionary.setValue(traceId, forKey: Self.traceIdKey)
    }

    /// 清理TraceID
    static func clearTraceId() {
        Thread.current.threadDictionary.removeObject(forKey: Self.traceIdKey)
    }

    /// 从contextId解析出traceId
    static func parseContextId(_ contextId: String) -> String {
        guard !contextId.isEmpty else {
            return ""
        }
        let traceId = contextId.components(separatedBy: "-").first ?? ""
        return (traceId == contextId) ? "" : traceId
    }

    /// 将traceId拼接到contextId上
    static func wrapContextId(_ contextId: String) -> String {
        let traceId = Self.getTraceId()
        // 如果contextId过长，则不再添加
        if traceId.isEmpty || contextId.count >= 60 {
            return contextId
        }
        return "\(traceId)-\(contextId)"
    }
}
