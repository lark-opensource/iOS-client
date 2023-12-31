//
//  LarkWebView+Monitor.swift
//  LarkWebViewContainer
//
//  Created by yinyuan on 2022/4/27.
//

import Foundation

public final class LarkWebViewMonitor {
    
    private var extensionMonitorDataSemaphore = DispatchSemaphore(value: 1)
    private var extensionMonitorData: [String: Any] = [:]
    
    public func setMonitorData(key: String, value: Any?) {
        extensionMonitorDataSemaphore.wait()
        extensionMonitorData[key] = value
        extensionMonitorDataSemaphore.signal()
    }
    
    public func allExtensionMonitorData() -> [String: Any] {
        extensionMonitorDataSemaphore.wait()
        let data = extensionMonitorData
        extensionMonitorDataSemaphore.signal()
        return data
    }
}

extension LarkWebView {
    
    private static var _LarkWebViewMonitorKey: Void?
    
    /// 埋点数据管理器
    public private(set) var lkwb_monitor: LarkWebViewMonitor {
        get {
            if let value = objc_getAssociatedObject(self, &LarkWebView._LarkWebViewMonitorKey) as? LarkWebViewMonitor {
                return value
            } else {
                let value = LarkWebViewMonitor()
                objc_setAssociatedObject(self, &LarkWebView._LarkWebViewMonitorKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return value
            }
        }
        set {
            // nothing todo
        }
    }
}
