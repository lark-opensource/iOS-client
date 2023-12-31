//
//  External.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/5/18.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkContainer

///「外部联系人」页面相关埋点
extension ContactTracker {
    struct External {}
}

///「外部联系人页」的展示
extension ContactTracker.External {
    /// 展示
    static func View(resolver: UserResolver) {
        let params = ContactTracker.Parms.MemberType(resolver: resolver)
        Tracker.post(TeaEvent(Homeric.CONTACT_EXTERNAL_VIEW, params: params))
    }
}

///「组织架构目录页」的动作事件
extension ContactTracker.External {
    struct Click {
        /// 点击添加外部联系人
        static func AddExternal() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "add_external"
            params["target"] = "contact_add_external_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_EXTERNAL_CLICK, params: params))
        }

        /// 点击外部联系人头像
        static func MemberAvatar() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "member_avatar"
            params["target"] = "profile_main_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_EXTERNAL_CLICK, params: params))
        }
    }
}
