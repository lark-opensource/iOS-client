//
//  LKOTTraceManager.swift
//  LarkOpenTrace
//
//  Created by sniperj on 2020/12/7.
//

import Foundation

public enum LKOTTraceType: String {
    case coldLaunch
}

/// trace manager
public final class LKOTTraceManager {
    /// shared instance
    public static let shared = LKOTTraceManager()
    private var unfair = os_unfair_lock_s()
    var traceMap: [LKOTTraceType: [LKOTTrace]] = [:]
    /// get trace by traceType(Just for test)
    /// - Parameter traceType: traceType
    /// - Returns: trace
    public func getTrace(by traceType: LKOTTraceType) -> LKOTTrace? {
        os_unfair_lock_lock(&unfair)
        defer { os_unfair_lock_unlock(&unfair) }
        return traceMap[traceType]?.last
    }

    internal func registTrace(trace: LKOTTrace, traceType: LKOTTraceType) {
        os_unfair_lock_lock(&unfair)
        defer { os_unfair_lock_unlock(&unfair) }
        traceMap[traceType]?.append(trace)
    }

    internal func unRegistTrace(traceType: LKOTTraceType) {
        os_unfair_lock_lock(&unfair)
        defer { os_unfair_lock_unlock(&unfair) }
        if let traceAry = traceMap[traceType], traceAry.count <= 1 {
            traceMap.removeValue(forKey: traceType)
        } else {
            traceMap[traceType]?.removeFirst()
        }
    }
}
