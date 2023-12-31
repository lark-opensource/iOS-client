//
//  SKTracing.swift
//  SKCommon
//
//  Created by zengsenyuan on 2021/11/25.
//  


import Foundation
import LarkSetting


/// 用于链路追踪流程透传的上下文参数。
public struct TracingContext {
    public var traceRootId: String
    
    public init(rootId: String) {
        self.traceRootId = rootId
    }
}


public enum SpanResult {
    case normal
    case error(errMsg: String)
}

let CCMTraceUnableKey = "CMM_TracingUnable"

/// SKTracing 是用来追踪各个主要流程的。设计文档  https://bytedance.feishu.cn/docs/doccn3R5NPVlMFYKDp5PAcu078e
public final class SKTracing {

    enum TracingCommand {
        case startRoot(spanName: String, spanId: String, currentTime: Int64)
        case startChild(spanName: String, spanId: String, parentSpanId: String, rootId: String, currentTime: Int64)
        case end(spanId: String, tags: String?, rootId: String, currentTime: Int64)
        case finishTrace(rootId: String)
    }
    
//    struct SpanModel {
//        var name: String
//        var id: String
//    }
    
    public static let shared = SKTracing()
    
    private var tracingEnable: Bool = true
    
    private lazy var traceCache: SKTracingCache = SKTracingCache()
    
    /// 执行写日志的任务串行队列，确保前后以来数据依赖关系是能对应上的。
    private var queue = DispatchQueue(label: "CCM.SKTracing", qos: .default)
    
    /// 开启根节点，此时 rust 会生成一个与 root spanId 挂钩的 traceId，但是 TraceId 是不用关心的。
    /// - Parameter spanName: spanName: 根节点名称
    /// - Returns: root spanId
    @discardableResult
    public func startRootSpan(spanName: String) -> String {
        guard self.tracingEnable else {
            return CCMTraceUnableKey
        }
        return _startRootSpan(spanName: spanName)
    }
    
    /// 开始一个子节点，获取 rootSpanId这条链上最后一个对应 parentSpanName 的 spanId，再进行生成。如果没有传 parentSpanName， 那就默认根节点为父节点。
    /// - Parameters:
    ///   - spanName: 子节点名称
    ///   - parentSpanName: 父节点名称
    ///   - rootSpanId: 根结点 Id
    /// - Returns: 返回该字节点的 id
    @discardableResult
    public func startChild(spanName: String,
                           parentSpanName: String? = nil,
                           rootSpanId: String,
                           params: [String: Any] = [:],
                           component: String,
                           fileName: String = #fileID,
                           funcName: String = #function,
                           funcLine: Int = #line) -> String {
        
        self.docsLog(spanName: spanName + " start",
                     spanResult: .normal,
                     params: params,
                     component: component,
                     traceId: rootSpanId,
                     fileName: fileName,
                     funcName: funcName,
                     funcLine: funcLine)
        
        guard self.tracingEnable else {
            return CCMTraceUnableKey
        }
        if let parentSpanName = parentSpanName,
           let parentSpanId = traceCache.getLastSpan(spanName: parentSpanName, rootId: rootSpanId)?.id {
            return _startChild(spanName: spanName, parentSpanId: parentSpanId, rootSpanId: rootSpanId)
        } else {
            return _startChild(spanName: spanName, parentSpanId: rootSpanId, rootSpanId: rootSpanId)
        }
    }
    
    /// 结束某个节点：获取 rootSpanId 这条链上最后一个对应 spanName 的 spanId，再进行结束。
    /// - Parameters:
    ///   - spanName: 要结束节点的名称
    ///   - rootSpanId: 根节点 Id
    ///   - spanResult: 以什么结果结束该节点
    ///   - params: 需要传递的参数
    ///   - component: 与 DocsLogger 挂钩的标志
    public func endSpan(spanName: String,
                        rootSpanId: String,
                        spanResult: SpanResult = .normal,
                        params: [String: Any] = [:],
                        component: String,
                        fileName: String = #fileID,
                        funcName: String = #function,
                        funcLine: Int = #line) {
        
        self.docsLog(spanName: spanName + " end",
                     spanResult: spanResult,
                     params: params,
                     component: component,
                     traceId: rootSpanId,
                     fileName: fileName,
                     funcName: funcName,
                     funcLine: funcLine)
        
        guard self.tracingEnable else {
            return
        }
        if let spanId = traceCache.getLastSpan(spanName: spanName, rootId: rootSpanId)?.id {
            _endSpan(spanId: spanId,
                     spanName: spanName,
                     rootSpanId: rootSpanId,
                     spanResult: spanResult,
                     params: params,
                     component: component,
                     fileName: fileName,
                     funcName: funcName,
                     funcLine: funcLine)
        }
    }

    /// 开始一个子节点并自动结束：获取 rootSpanId这条链上最后一个对应 parentSpanName 的 spanId，再进行生成。
    @discardableResult
    public func startChildAndEndAutomatically(spanName: String,
                                              parentSpanName: String? = nil,
                                              rootSpanId: String,
                                              spanResult: SpanResult = .normal,
                                              params: [String: Any] = [:],
                                              component: String,
                                              fileName: String = #fileID,
                                              funcName: String = #function,
                                              funcLine: Int = #line) -> String {
        
        self.docsLog(spanName: spanName + " startAndEnd",
                     spanResult: spanResult,
                     params: params,
                     component: component,
                     traceId: rootSpanId,
                     fileName: fileName,
                     funcName: funcName,
                     funcLine: funcLine)
        
        guard self.tracingEnable else {
            return CCMTraceUnableKey
        }
        let spanId: String
        if let parentSpanName = parentSpanName,
           let parentSpanId = traceCache.getLastSpan(spanName: parentSpanName, rootId: rootSpanId)?.id {
            spanId = _startChild(spanName: spanName, parentSpanId: parentSpanId, rootSpanId: rootSpanId)
        } else {
            spanId = _startChild(spanName: spanName, parentSpanId: rootSpanId, rootSpanId: rootSpanId)
        }
        _endSpan(spanId: spanId,
                 spanName: spanName,
                 rootSpanId: rootSpanId,
                 spanResult: spanResult,
                 params: params,
                 component: component,
                 fileName: fileName,
                 funcName: funcName,
                 funcLine: funcLine)
    
        return spanId
    }
    
    /// 如果能明确这条链已经结束的话，直接调用 finish 清空内存数据
    /// - Parameter rootSpanId: 跟 traceId
    public func finishTrace(rootSpanId: String) {
        guard self.tracingEnable else {
            return
        }
//        debugPrint("SKTracing finishTrace: \(rootSpanId)")
        excuteCommand(.finishTrace(rootId: rootSpanId))
    }
    
}

// MARK: 将事件转换为 rust 埋点命令
extension SKTracing {
    
    @discardableResult
    private func _startRootSpan(spanName: String) -> String {
//        debugPrint("SKTracing startRootSpan: \(spanName)")
        let spanId = createSpanId(spanName: spanName)
        traceCache.appendSpan(spanName: spanName, spanId: spanId, rootId: spanId)
        excuteCommand(.startRoot(spanName: spanName, spanId: spanId, currentTime: SKRustTracing.getCurrentTime()))
        return spanId
    }
    
    
    /// 开始一个子节点: 利用父节点 Id 直接生成。
    /// - Parameters:
    ///   - spanName: 子节点名称
    ///   - parentSpanId: 父节点id
    /// - Returns: 返回该字节点的 id
    @discardableResult
    private func _startChild(spanName: String, parentSpanId: String, rootSpanId: String) -> String {
//        debugPrint("SKTracing startChild: \(spanName), parentSpanId: \(parentSpanId)")
        let spanId = createSpanId(spanName: spanName)
        traceCache.appendSpan(spanName: spanName, spanId: spanId, rootId: rootSpanId)
        excuteCommand(.startChild(spanName: spanName, spanId: spanId, parentSpanId: parentSpanId, rootId: rootSpanId, currentTime: SKRustTracing.getCurrentTime()))
        return spanId
    }
    
    
    /// 根据 spanId  结束某个节点
    /// - Parameters:
    ///   - spanName: 要结束节点的Id
    ///   - spanName: 要结束节点的名称
    ///   - rootSpanId: 根节点 Id
    ///   - spanResult: 以什么结果结束该节点
    ///   - params: 需要传递的参数
    ///   - component: 与 DocsLogger 挂钩的标志
    private func _endSpan(spanId: String,
                          spanName: String,
                          rootSpanId: String,
                          spanResult: SpanResult = .normal,
                          params: [String: Any] = [:],
                          component: String,
                          fileName: String = #fileID,
                          funcName: String = #function,
                          funcLine: Int = #line) {
        var params = params
        params.updateValue(component, forKey: "component")
        params.updateValue(rootSpanId, forKey: "traceId")
        params.updateValue(URL(fileURLWithPath: fileName).lastPathComponent, forKey: "fileName")
        var tags = params.jsonString ?? ""
        if case .error = spanResult {
            tags = tags.encryptToShort
        }
//        debugPrint("SKTracing endSpan: \(spanId), params: \(params)")
        excuteCommand(.end(spanId: spanId, tags: tags, rootId: rootSpanId, currentTime: SKRustTracing.getCurrentTime()))
    }
}

// MARK: private method
extension SKTracing {
    
    /// 执行命令，链接到 rust 的 tracing 中。
    /// - Parameter command: 指令
    private func excuteCommand(_ command: TracingCommand) {
        queue.async {
            switch command {
            case let .startRoot(spanName, customId, currentTime):
                if let spanId = SKRustTracing.startRoot(spanName: spanName, currentTime: currentTime) {
                    self.traceCache.mapRust(spanId: spanId, to: customId, rootId: customId)
                }
            case let .startChild(spanName, customId, customParentId, customRootId, currentTime):
                if let parentSpanId = self.traceCache.getRustSpanId(by: customParentId, rootId: customRootId),
                   let spanId = SKRustTracing.startChild(spanName: spanName, parentSpanId: parentSpanId, currentTime: currentTime) {
                    self.traceCache.mapRust(spanId: spanId, to: customId, rootId: customRootId)
                }
            case let .end(customId, tags, customRootId, currentTime):
                if let spanId = self.traceCache.getRustSpanId(by: customId, rootId: customRootId) {
                    SKRustTracing.endSpan(by: spanId, tag: tags, currentTime: currentTime)
                }
            case let .finishTrace(rootId):
                self.traceCache.removeTrace(rootId: rootId)
            }
        }
    }
    
    /// 生成本地的唯一的 spanId
    /// - Parameter spanName: 节点名称
    /// - Returns: 唯一 spanId
    private func createSpanId(spanName: String) -> String {
        return spanName + "\(Date().timeIntervalSince1970)"
    }
    
    private func docsLog(spanName: String,
                         spanResult: SpanResult,
                         params: [String: Any],
                         component: String,
                         traceId: String,
                         fileName: String = #fileID,
                         funcName: String = #function,
                         funcLine: Int = #line) {
        switch spanResult {
        case .normal:
            let des = params.reduce(spanName + " ") {
                $0 + "\($1.key)=\($1.value), "
            }
            DocsLogger.info(des, extraInfo: nil, component: component, traceId: traceId, fileName: fileName, funcName: funcName, funcLine: funcLine)
        case .error(let errMsg):
            var params = params
            params.updateValue(errMsg, forKey: "errMsg")
            let des = params.reduce(spanName + " ") {
                $0 + "\($1.key)=\($1.value), "
            }
            DocsLogger.error(des, extraInfo: nil, component: component, traceId: traceId, fileName: fileName, funcName: funcName, funcLine: funcLine)
        }
    }
}

// MARK: 测试性能
//extension SKTracing {
//
//    public func howMuchTimeCost() {
//        let start = CACurrentMediaTime()
//        let N = 1000
//        let M = 10
//        for i in 0..<N {
//            let rootId = self.startRootSpan(spanName: "root_\(i)")
//            for j in 0..<M {
//                self.startChildAndEndAutomatically(spanName: "child_\(j)", rootSpanId: rootId, component: "test")
//            }
//        }
//        let end = CACurrentMediaTime()
//        let cost = end - start
//        debugPrint("howMuchTimeCost: cost on \(cost)")
//    }
//}
