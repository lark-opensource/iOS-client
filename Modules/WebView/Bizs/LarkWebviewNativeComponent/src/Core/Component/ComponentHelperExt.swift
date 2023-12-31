//
//  ComponentHelperExt.swift
//  LarkWebviewNativeComponent
//
//  Created by tefeng liu on 2020/11/1.
//

import Foundation
import LarkWebViewContainer

private var kComponentManager: Void?
extension LarkWebView {
    /// 默认使用 ComponentManager 类，若想替换，可实现 NativeComponentManageable 后进行逻辑自定义
    var componentManager: NativeComponentManageable {
        get {
            if let manager = objc_getAssociatedObject(self, &kComponentManager) as? NativeComponentManageable {
                return manager
            } else {
                let manager = ComponentManager()
                objc_setAssociatedObject(self, &kComponentManager, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return manager
            }
        }
        set {
            objc_setAssociatedObject(self, &kComponentManager, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
