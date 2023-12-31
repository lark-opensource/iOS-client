//
//  BaseViewController+Fullscreen.swift
//  SKCommon
//
//  Created by 邱沛 on 2020/12/23.
//

import LarkSplitViewController
import SKUIKit
import SpaceInterface

extension BaseViewController {

    private struct AssociatedKeys {
        static var bizType = "bizType"
    }

    var inFullScreenMode: Bool {
        guard SKDisplay.pad, let lkSplitVC = lkSplitViewController else { return true }
        return lkSplitVC.splitMode == .secondaryOnly
    }

    // 为了做iPad全屏埋点的上报，区分业务模块
    public var bizType: DocsType {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.bizType) as? DocsType ?? .unknownDefaultType
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.bizType, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
