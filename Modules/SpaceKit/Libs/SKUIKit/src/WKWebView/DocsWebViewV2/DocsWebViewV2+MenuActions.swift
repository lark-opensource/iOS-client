//
//  SKWebViewV2+MenuActions.swift
//  SKUIKit
//
//  Created by lijuyou on 2020/10/9.


import Foundation
import SKFoundation
import WebKit

@objc extension DocsWebViewV2: _ActionHelperActionDelegate {

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let res = actionHelper.canPerformAction(action, withSender: sender)
        return res
    }

    func canSuperPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender)
    }

    func canPerformUndefinedAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return canSuperPerformAction(action, withSender: sender)
    }
}

extension DocsWebViewV2 {

     var actionHelper: SKWebViewActionHelper {
        get {
            guard let helper = objc_getAssociatedObject(self, &DocsWebViewV2._kActionHelperKey) as? SKWebViewActionHelper else {
                let obj = SKWebViewActionHelper()
                obj.delegate = self
                self.actionHelper = obj
                return obj
            }
            return helper
        }
        set { objc_setAssociatedObject(self, &DocsWebViewV2._kActionHelperKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private static var _kActionHelperKey: UInt8 = 0
}
