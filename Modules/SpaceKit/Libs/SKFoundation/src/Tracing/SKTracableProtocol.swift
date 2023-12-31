//
//  SKTracableProtocol.swift
//  SKFoundation
//
//  Created by zengsenyuan on 2021/12/6.
//  


import Foundation

/// 用于规范 tracing 过程中数据的透传
public protocol SKTracableProtocol: AnyObject {
    /// 用来进行环境参数传递
    var tracingContext: TracingContext? { get set }
    /// 参照 LogComponnet
    var tracingComponent: String { get }
    /// 设置默认参数
    var tracingCommonParams: [String: Any] { get }
}


extension SKTracableProtocol {
    
    public var tracingCommonParams: [String: Any] {
        return [:]
    }
    
    public var traceRootId: String? {
        tracingContext?.traceRootId
    }
    
    public var rootTracing: SKRootTracing {
        if let rootId = tracingContext?.traceRootId {
            return SKRootTracing(rootId: rootId, logComponent: tracingComponent, commonParams: tracingCommonParams)
        } else {
            /// 注： 这里的 assert 不要随意注释，一定要确保有 tracingContext 后才使用 rootTracing。 这里自动生成链只是最后的兜底。为了确保包含 log 能正确打印。
            spaceAssertionFailure("need get tracingContext When use rootTracing")
            let wrongRootStart = "CCM_WrongRootStart"
            let rootId = SKTracing.shared.startRootSpan(spanName: wrongRootStart)
            SKTracing.shared.endSpan(spanName: wrongRootStart, rootSpanId: rootId, params: tracingCommonParams, component: tracingComponent)
            return SKRootTracing(rootId: rootId, logComponent: tracingComponent, commonParams: tracingCommonParams)
        }
    }
}
