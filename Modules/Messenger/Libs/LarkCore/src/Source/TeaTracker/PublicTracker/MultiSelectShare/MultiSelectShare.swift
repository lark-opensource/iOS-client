//
//  MultiSelectShare.swift
//  LarkCore
//
//  Created by 夏汝震 on 2021/5/13.
//

import Foundation
import LKCommonsTracker
import Homeric

///「分享含有选人组件」页面相关埋点
public extension PublicTracker {
    struct MultiSelectShare {}
    struct Send {}
}

///「分享含有选人组件」页面的展示
public extension PublicTracker.MultiSelectShare {
    static func View() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_MULTI_SELECT_SHARE_VIEW))
    }
}

///「分享含有选人组件」页面的动作事件
public extension PublicTracker.MultiSelectShare {
    struct Click {
        public static func Confirm() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "confirm"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.PUBLIC_MULTI_SELECT_SHARE_CLICK, params: params))
        }
    }
}

///「发送给他人时的的弹窗页面」
public extension PublicTracker.Send {
    static func View() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_SEND_TO_VIEW))
    }
}
