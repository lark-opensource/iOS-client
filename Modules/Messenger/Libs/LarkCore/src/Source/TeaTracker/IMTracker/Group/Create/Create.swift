//
//  Tracker.IM.Group.Create.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2021/5/10.
//

import Foundation
import LKCommonsTracker
import Homeric

/// 群创建相关埋点
public extension IMTracker.Group {
    struct Create {}
}

/// 群创建界面显示
public extension IMTracker.Group.Create {
    static func View(group: Bool, channel: Bool, history: Bool, transfer: Bool, source: String) {
        var params: [AnyHashable: Any] = [:]
        params["is_create_group"] = group ? "true" : "false"
        params["is_create_channel"] = channel ? "true" : "false"
        params["is_chat_history_included"] = history ? "true" : "false"
        params["is_transfer_included"] = transfer ? "true" : "false"
        params["source"] = source
        Tracker.post(TeaEvent(Homeric.IM_GROUP_CREATE_VIEW, params: params))
    }
}

/// 群创建界面点击事件
public extension IMTracker.Group.Create {
    struct Click {
        public static func Confirm(source: String, chatType: String, public: Bool, isPrivateMode: Bool, isSycn: Bool, leaveAMessage: Bool) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "confirm"
            params["source"] = source
            params["chat_type"] = chatType
            params["target"] = "none"
            params["is_public_group"] = `public` ? "true" : "false"
            //是否创建密盾群
            params["is_private_mode"] = isPrivateMode ? "true" : "false"
            //是否勾选同步聊天记录
            params["is_sycn"] = isSycn ? "true" : "false"
            //是否留言
            params["leave_a_message"] = leaveAMessage ? "true" : "false"
            //移动端建群时不能修改群头像和群名称，统一上报false
            params["is_change_avatar"] = "false"
            params["is_change_name"] = "false"
            Tracker.post(TeaEvent(Homeric.IM_GROUP_CREATE_CLICK, params: params))
        }

        /// 创群界面点击群类型
        public static func GroupType() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "group_type"
            params["target"] = "im_chat_type_view"
            Tracker.post(TeaEvent(Homeric.IM_GROUP_CREATE_CLICK, params: params))
        }

        /// 创群界面点击取消
        public static func Cancel() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "cancel"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.IM_GROUP_CREATE_CLICK, params: params))
        }
    }
}
