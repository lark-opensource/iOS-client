//
//  LarkWebViewConfigurationUpdater.swift
//  LarkWebViewContainer
//
//  Created by dengbo on 2021/12/30.
//

import Foundation
import LarkContainer
import LKLoadable

private var lwkCallByInternalKey: Void?

@objc public extension WKWebViewConfiguration {
    /// 用webviewConfig更新WKWebViewConfiguration
    func lwk_update(webViewConfig: LarkWebViewConfig) {
        self.lwk_callByInternal = true
        
        let m: LarkWebViewMonitorServiceProtocol?
            m = InjectedOptional<LarkWebViewMonitorServiceProtocol>().wrappedValue
        guard let monitorService = m else {
            logger.warn("monitor service is nil")
            return
        }
        logger.info("will update WKWebViewConfiguration with monitorConfig")
        monitorService.updateWKWebViewConfiguration(configuration: self, monitorConfig: webViewConfig.monitorConfig)
    }
    
    var lwk_callByInternal: Bool {
        get {
            objc_getAssociatedObject(self, &lwkCallByInternalKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &lwkCallByInternalKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
