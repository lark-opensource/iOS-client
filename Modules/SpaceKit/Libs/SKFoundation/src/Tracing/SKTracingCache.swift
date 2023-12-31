//
//  SKTracingCache.swift
//  SKCommon
//
//  Created by zengsenyuan on 2021/11/26.
//  

import Foundation

/// 用来管理链路追踪过程中的内存数据。
class SKTracingCache {

    /// 事件模型
    struct SpanModel {
        var name: String
        var id: String
    }
    
    /// 链路模型
    struct TraceModel {
        private(set) var id: String
        private(set) var createTime: TimeInterval
        private(set) var lastUseTime: TimeInterval
        private(set) var spans: [SpanModel] = []
        private var customToRust: [String: UInt64] = [:]
        
        init(id: String) {
            self.createTime = Date().timeIntervalSince1970
            self.lastUseTime = Date().timeIntervalSince1970
            self.id = id
        }
        mutating func append(span: SpanModel) {
            self.lastUseTime = Date().timeIntervalSince1970
            self.spans.append(span)
        }
        
        mutating func getRustSpanId(by customId: String) -> UInt64? {
            self.lastUseTime = Date().timeIntervalSince1970
            return customToRust[customId]
        }
        
        mutating func mapRust(spanId: UInt64, to customId: String) {
            self.lastUseTime = Date().timeIntervalSince1970
            customToRust[customId] = spanId
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(trimTraceIfNeed), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trimTraceIfNeed), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /// 同时最多存在多少条链
    private let maxTrace: Int = 20
    /// 记录每一条链上的节点，将树型打平成线型： rootId -> spans
    private var tracesMap: [String: TraceModel] = [:]
    
    private var _lock = NSLock()

    func appendSpan(spanName: String, spanId: String, rootId: String) {
        _lock.lock(); defer { _lock.unlock() }
        let spanItem = SpanModel(name: spanName, id: spanId)
        var trace = tracesMap[rootId] ?? TraceModel(id: rootId)
        trace.append(span: spanItem)
        self.tracesMap.updateValue(trace, forKey: rootId)
    }
    
    func getLastSpan(spanName: String, rootId: String) -> SpanModel? {
        _lock.lock(); defer { _lock.unlock() }
        guard let trace = tracesMap[rootId] else {
            spaceAssertionFailure("getLastSpan find rootId \(rootId) fail")
            return nil
        }
        guard let span = trace.spans.last(where: { $0.name == spanName }) else {
            spaceAssertionFailure("getLastSpan find spanName \(spanName) fail")
            return nil
        }
        return span
    }
    
    func removeTrace(rootId: String) {
        _lock.lock(); defer { _lock.unlock() }
        tracesMap.removeValue(forKey: rootId)
    }
    
    /// 根据 customSpanId 映射 rustId
    func mapRust(spanId: UInt64, to customSpanId: String, rootId: String) {
        _lock.lock(); defer { _lock.unlock() }
        tracesMap[rootId]?.mapRust(spanId: spanId, to: customSpanId)
    }
    
    /// 根据 customSpanId 获取 rustId
    func getRustSpanId(by customSpanId: String, rootId: String) -> UInt64? {
        _lock.lock(); defer { _lock.unlock() }
        let rustId = tracesMap[rootId]?.getRustSpanId(by: customSpanId)
        return rustId
    }
    
    @objc
    func trimTraceIfNeed() {
        _lock.lock(); defer { _lock.unlock() }
        let dropCount = tracesMap.count - maxTrace
        if dropCount > 0 {
            var traces = tracesMap.compactMap { $0.value }.sorted(by: { $0.lastUseTime > $1.lastUseTime })
            traces = traces.dropLast(dropCount)
            tracesMap.removeAll()
            traces.forEach {
                tracesMap.updateValue($0, forKey: $0.id)
            }
        }
    }
}
