//
//  New.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/5/18.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkContainer

///「新的联系人页」相关埋点
extension ContactTracker {
    struct New {}
}

///「新的联系人页」的展示
extension ContactTracker.New {
    /// 展示
    static func View(newCount: Int, resolver: UserResolver) {
        let params = ContactTracker.Parms.MemberType(resolver: resolver)
        Tracker.post(TeaEvent(Homeric.CONTACT_NEW_VIEW, params: params))
    }
}

///「新的联系人页」的动作事件
extension ContactTracker.New {
    struct Click {
        /// 点击添加外部联系人
        static func AddExternal() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "add_external"
            params["target"] = "contact_add_external_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_NEW_CLICK, params: params))
        }

        /// 点击外部联系人头像
        static func MemberAvatar() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "member_avatar"
            params["target"] = "profile_main_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_NEW_CLICK, params: params))
        }
    }
}
