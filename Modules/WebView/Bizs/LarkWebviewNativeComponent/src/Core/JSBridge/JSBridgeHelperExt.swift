//
//  BridgeHelperExt.swift
//  LarkWebviewNativeComponent
//
//  Created by tefeng liu on 2020/10/30.
//

import Foundation
import LarkWebViewContainer

private var kBridgeManager: Void?

extension LarkWebView {
    var componetBridge: JSBridgeManager {
        get {
            if let manager = objc_getAssociatedObject(self, &kBridgeManager) as? JSBridgeManager {
                return manager
            } else {
                let manager = JSBridgeManager()
                manager.webview = self
                objc_setAssociatedObject(self, &kBridgeManager, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return manager
            }
        }
    }
}
