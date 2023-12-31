//
//  Group.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/5/18.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkContainer

///「我的群组页」相关埋点
extension ContactTracker {
    struct Group {}
}

///「我的群组页」的展示
extension ContactTracker.Group {
    /// 展示
    static func View(resolver: UserResolver) {
        let params = ContactTracker.Parms.MemberType(resolver: resolver)
        Tracker.post(TeaEvent(Homeric.CONTACT_GROUP_VIEW, params: params))
    }
}

///「我的群组页」的动作事件
extension ContactTracker.Group {
    struct Click {
        /// 点击我加入的群组
        static func JoinedGroup() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "joined_group"
            params["target"] = "contact_joined_group_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_GROUP_CLICK, params: params))
        }

        /// 点击我创建的群组
        static func CreatedGroup() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "created_group"
            params["target"] = "contact_created_group_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_GROUP_CLICK, params: params))
        }

        /// 点击群头像
        static func Avatar() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "group_avatar"
            params["target"] = "im_chat_main_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_GROUP_CLICK, params: params))
        }
    }
}
