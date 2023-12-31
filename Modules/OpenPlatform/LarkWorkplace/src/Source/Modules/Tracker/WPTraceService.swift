//
//  WPTraceService.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/17.
//

import Foundation
import ECOProbe
import ThreadSafeDataStructure

/// 工作台 trace service
protocol WPTraceService: AnyObject {
    /// 工作台全局 trace
    var root: OPTrace { get }

    /// 当前页面所属 trace，暂时靠外部设置，后面需要跟生命周期绑定
    @available(*, deprecated, message: "use context.trace")
    var currentTrace: OPTrace { get set }

    @discardableResult
    /// 重新创建门户 trace，如果已经有了会替换。
    /// - Parameters:
    ///   - portalType: 门户类型
    ///   - portalId: 门户id
    /// - Returns: trace
    func regenerateTrace(for portalType: WPPortal.PortalType, with portalId: String?) -> OPTrace

    @available(*, deprecated, message: "use regenerateTrace(for:with:)")
    @discardableResult
    func lazyGetTrace(for portalType: WPPortal.PortalType, with portalId: String?) -> OPTrace

    @available(*, deprecated, message: "use regenerateTrace(for:with:)")
    @discardableResult
    func generateTrace(for portalType: WPPortal.PortalType, with portalId: String?) -> OPTrace

    @available(*, deprecated, message: "use lazyGetTrace(for:with:)")
    func getTrace(for portalType: WPPortal.PortalType, with portalId: String?) -> OPTrace?

    /// 根据 portalType 和 portalId 清理 trace，用于门户销毁时掉用。
    /// - Parameters:
    ///   - portalType: 门户类型
    ///   - portalId: 门户 id
    func removeTrace(for portalType: WPPortal.PortalType, with portalId: String?)
}

extension WPTraceService {
    @available(*, deprecated, message: "use regenerateTrace(for:)")
    @discardableResult
    func generateTrace(for portalType: WPPortal.PortalType) -> OPTrace {
        return generateTrace(for: portalType, with: nil)
    }

    @discardableResult
    func regenerateTrace(for portalType: WPPortal.PortalType) -> OPTrace {
        return regenerateTrace(for: portalType, with: nil)
    }

    @available(*, deprecated, message: "use regenerateTrace(for:)")
    func getTrace(for portalType: WPPortal.PortalType) -> OPTrace? {
        return getTrace(for: portalType, with: nil)
    }

    @available(*, deprecated, message: "use regenerateTrace(for:)")
    func lazyGetTrace(for portalType: WPPortal.PortalType) -> OPTrace {
        return lazyGetTrace(for: portalType, with: nil)
    }
}

final class WPTraceServiceImpl: WPTraceService {
    struct TraceKey: Hashable {
        let portalType: WPPortal.PortalType
        let portalId: String?
    }

    let root: OPTrace

    @available(*, deprecated, message: "use context.trace")
    var currentTrace: OPTrace

    private var portalTraceMap: SafeDictionary<TraceKey, OPTrace> = [:] + .readWriteLock

    init() {
        root = OPTraceService.default().generateTrace()
        currentTrace = root
    }

    func regenerateTrace(for portalType: WPPortal.PortalType, with portalId: String?) -> OPTrace {
        let traceKey = TraceKey(portalType: portalType, portalId: portalId)
        let newTrace = OPTraceService.default().generateTrace(withParent: root)
        portalTraceMap[traceKey] = newTrace
        return newTrace
    }

    @available(*, deprecated, message: "use regenerateTrace(for:with:)")
    @discardableResult
    func generateTrace(for portalType: WPPortal.PortalType, with portalId: String?) -> OPTrace {
        let traceKey = TraceKey(portalType: portalType, portalId: portalId)
        if let originalTrace = portalTraceMap[traceKey] {
            assertionFailure("generate trace repeat")
            return originalTrace
        }
        let newTrace = OPTraceService.default().generateTrace(withParent: root)
        portalTraceMap[traceKey] = newTrace
        return newTrace
    }

    @available(*, deprecated, message: "use regenerateTrace(for:with:)")
    func getTrace(for portalType: WPPortal.PortalType, with portalId: String?) -> OPTrace? {
        let traceKey = TraceKey(portalType: portalType, portalId: portalId)
        return portalTraceMap[traceKey]
    }

    @available(*, deprecated, message: "use regenerateTrace(for:with:)")
    func lazyGetTrace(for portalType: WPPortal.PortalType, with portalId: String?) -> OPTrace {
        let traceKey = TraceKey(portalType: portalType, portalId: portalId)
        if let trace = portalTraceMap[traceKey] {
            return trace
        }
        return generateTrace(for: portalType, with: portalId)
    }

    func removeTrace(for portalType: WPPortal.PortalType, with portalId: String?) {
        let traceKey = TraceKey(portalType: portalType, portalId: portalId)
        portalTraceMap.removeValue(forKey: traceKey)
    }
}
