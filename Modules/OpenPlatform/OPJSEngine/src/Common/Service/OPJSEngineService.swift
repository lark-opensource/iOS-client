//
//  OPJSEngineService.swift
//  OPJSEngine
//
//  Created by yi on 2021/12/23.
//

import Foundation
import LKCommonsLogging
import ECOProbe
import OPSDK
import OPFoundation

@objc
public protocol OPJSEngineUtilsProtocol: NSObjectProtocol {
    // 异步执行在主线程
    func executeOnMainQueue(_ block: (()->Void)?)
    // 同步执行在主线程
    func executeOnMainQueueSync(_ block: (()->Void)?)
    // jsvalue->dictionary
    func convertJSValueToObject(_ jsValue: JSValue) -> NSDictionary?

    // 网络状态变化的通知的名称
    func reachabilityChangedNotification() -> NSNotification.Name?

    func currentNetworkConnected() -> Bool

    func currentNetworkType() -> String

    // 是否使用newbridge
    func shouldUseNewBridge() -> Bool

    // 包装tracing的block。获取当前线程的tracing，并传递到block内部，block执行完成的时候，替换为之前的tracing。
    func convertTracingBlock(_ block: (()->Void)?) -> (()->Void)?

    func debugRuntimeType() -> OPRuntimeType
}


public protocol OPJSEngineMonitorProtocol: NSObjectProtocol {
    // monitor绑定trace
    func bindTracing(monitor: OPMonitor, uniqueID: OPAppUniqueID)
}

// js worker module管理类
@objcMembers
public final class OPJSEngineService: NSObject {
    public static let shared = OPJSEngineService()
    public var utils: OPJSEngineUtilsProtocol? // 工具方法
    public var monitor: OPJSEngineMonitorProtocol? // 埋点相关

}
