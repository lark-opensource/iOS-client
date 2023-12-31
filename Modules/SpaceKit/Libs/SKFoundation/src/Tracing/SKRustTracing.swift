//
//  SKRustTracing.swift
//  SKCommon
//
//  Created by zengsenyuan on 2021/11/26.
//  


import Foundation
import RustPB
import RustSDK

/// 对 rust 的接口进行二次封装。
class SKRustTracing {

    /// 开启根节点，此时 rust 会生成一个与 root spanId 挂钩的 traceId
    /// - Parameter spanName: spanName: 根节点名称
    /// - Returns: root spanId, 如果返回的是空，证明流程 Id 生成失败。
    static func startRoot(spanName: String, currentTime: Int64) -> UInt64? {
        return timeMonitor(task: {
            let spanID = start_root_span2(spanName, currentTime)
            return spanID != 0 ? spanID : nil
        }, message: "SKRustTracing startRoot time:")
        
    }

    /// 开始一个子节点
    /// - Parameters:
    ///   - spanName: 子节点名称
    ///   - parentSpanId: 父节点id
    /// - Returns: 返回该字节点的 id，如果返回的是空，证明流程 Id 生成失败。
    static func startChild(spanName: String, parentSpanId: UInt64, currentTime: Int64) -> UInt64? {
        return timeMonitor(task: {
            let spanID = start_child_span2(parentSpanId, spanName, currentTime)
            return spanID != 0 ? spanID : nil
        }, message: "SKRustTracing startChild time:")
    }

    /// 根据 spanId  结束某个节点
    /// - Parameters:
    ///   - spanId: 要结束节点的 id
    ///   - tag: 该节点的参数，字典的 jsonString。
    static func endSpan(by spanId: UInt64, tag: String?, currentTime: Int64) {
        timeMonitor(task: { () -> Int in
            end_span2(spanId, tag, currentTime)
            return 0
        }, message: "SKRustTracing endSpan time:")
    }
    
    static func getCurrentTime() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    @discardableResult
    static func timeMonitor<T>(task: @escaping () -> T, message: String) -> T {
        #if DEBUG
        let start = CACurrentMediaTime()
        let result = task()
        let end = CACurrentMediaTime() 
        debugPrint("\(message) \(end - start)")
        #else
        let result = task()
        #endif
        return result
    }
}
