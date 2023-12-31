//
//  Main.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/5/18.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkContainer

///「联系人主菜单页」页面相关埋点
extension ContactTracker {
    struct Main {}
}

///「联系人主菜单页」的展示
extension ContactTracker.Main {
    /// 展示
    static func View(resolver: UserResolver) {
        let params = ContactTracker.Parms.MemberType(resolver: resolver)
        Tracker.post(TeaEvent(Homeric.CONTACT_MAIN_VIEW, params: params))
    }
}

///「消息筛选器编辑页面」的动作事件
extension ContactTracker.Main {
    struct Click {
        /// 点击进入组织架构页
        static func Architecture() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "architecture"
            params["target"] = "contact_architecture_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_MAIN_CLICK, params: params))
        }

        /// 点击进入外部联系人
        static func External() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "external"
            params["target"] = "contact_external_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_MAIN_CLICK, params: params))
        }

        /// 点击进入新的联系人
        static func New() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "new"
            params["target"] = "contact_new_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_MAIN_CLICK, params: params))
        }

        /// 点击进入我的群组
        static func Group() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "group"
            params["target"] = "contact_group_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_MAIN_CLICK, params: params))
        }

        /// 点击进入邮件联系人
        static func Email() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "email"
            params["target"] = "contact_email_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_MAIN_CLICK, params: params))
        }

        /// 点击进入特别关注人
        static func SpecialFocusList() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "starred_contact"
            params["target"] = "contact_starred_contact_view"
            Tracker.post(TeaEvent(Homeric.CONTACT_MAIN_CLICK, params: params))
        }

        static func Helpdesk() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "helpdesk"
            Tracker.post(TeaEvent(Homeric.CONTACT_MAIN_CLICK, params: params))
        }

        static func MyAI() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "my_ai"
            Tracker.post(TeaEvent(Homeric.CONTACT_MAIN_CLICK, params: params))
        }
    }
}
