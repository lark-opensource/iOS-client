//
//  OPSpecifiedObjectInfoAllocator.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/3/31.
//

import Foundation

/// 目标对象的类型信息
fileprivate let targetTypeKey = "target_type"
/// 目标对象的内存地址信息
fileprivate let targetKey = "target"

/// 负责收集与目标对象类型强相关的信息
struct OPSpecifiedObjectInfoAllocator: OPMemoryInfoAllocator {

    func allocateMemoryInfo(with target: NSObject, monitor: OPMonitor) {
        // 目标对象信息
        _ = monitor.addCategoryValue(targetTypeKey, "\(type(of: target))")
        _ = monitor.addCategoryValue(targetKey, String(describing: target))

        // 针对特定类型收集特定的信息
        switch target {
        case let page as BDPAppPage:
            allocateAppPageInfo(page, monitor)
        case let runtime as OPMicroAppJSRuntime:
            allocateJSRuntimeInfo(runtime, monitor)
        case let task as BDPTask:
            if let runtime = task.context {
                allocateJSRuntimeInfo(runtime, monitor)
            }
        default:
            break
        }
    }

}

fileprivate let appPageIDKey = "app_page_id"
fileprivate let isAppPageReadyKey = "is_app_page_ready"
fileprivate let isHasWebViewKey = "is_has_webview"
fileprivate let isNeedRouteKey = "is_need_route"
fileprivate let isFireEventReadyKey = "is_fire_event_ready"
fileprivate let isContextReadyKey = "is_context_ready_key"
fileprivate let jsCoreExecCostKey = "js_core_exec_cost"
private extension OPSpecifiedObjectInfoAllocator {
    func allocateAppPageInfo(_ page: BDPAppPage, _ monitor: OPMonitor) {
        _ = monitor.addCategoryValue(appPageIDKey, page.appPageID)
        _ = monitor.addCategoryValue(isAppPageReadyKey, page.isAppPageReady)
        _ = monitor.addCategoryValue(isHasWebViewKey, page.isHasWebView)
        _ = monitor.addCategoryValue(isNeedRouteKey, page.isNeedRoute)
        _ = monitor.addCategoryValue(isFireEventReadyKey, page.isFireEventReady)
    }

    func allocateJSRuntimeInfo(_ runtime: OPMicroAppJSRuntimeProtocol, _ monitor: OPMonitor) {
        _ = monitor.addCategoryValue(isFireEventReadyKey, runtime.isFireEventReady)
        _ = monitor.addCategoryValue(isContextReadyKey, runtime.isContextReady)
        _ = monitor.addCategoryValue(jsCoreExecCostKey, runtime.jsCoreExecCost)
    }
}



