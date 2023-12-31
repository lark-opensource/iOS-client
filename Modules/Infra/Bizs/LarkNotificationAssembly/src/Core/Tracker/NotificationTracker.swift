//
//  NotificationTracker.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/12/18.
//

import Foundation
import LKCommonsTracker
import Homeric
import NotificationUserInfo
import EENavigator

struct NotificationTracker {
    static func msgSend(msgId: String?, userId: String?, ifCrossTenant: Bool, isWatch: Bool, isRemote: Bool) {
        /// 消息发送埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        Tracker.post(TeaEvent("public_push_detail_click", params: [
            "click": "msg_send",
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant ? "true" : "false",
            "sub_user_id": userId ?? "",
            "is_watch": isWatch,
            "target": "none",
            "is_online_message": isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"]))
    }

    static func okSend(msgId: String?, userId: String?, ifCrossTenant: Bool, isWatch: Bool, isRemote: Bool) {
        /// ok点击埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
            Tracker.post(TeaEvent("public_push_detail_click", params: [
            "click": "ok",
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant ? "true" : "false",
            "sub_user_id": userId ?? "",
            "is_watch": isWatch,
            "target": "none",
            "is_online_message": isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"]))
    }

    static func clickReply(msgId: String?, userId: String?, ifCrossTenant: Bool, isWatch: Bool, isRemote: Bool) {
        /// 回复点击埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        Tracker.post(TeaEvent("public_push_detail_click", params: [
            "click": "reply",
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant ? "true" : "false",
            "sub_user_id": userId ?? "",
            "is_watch": isWatch,
            "target": "none",
            "is_online_message": isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"]))
    }

    static func clickBanner(userInfo: UserInfo, userId: String?, currentUserID: String, msgId: String?, navigator: Navigatable) {
        guard let urlString = userInfo.extra?.content.url,
            !urlString.isEmpty,
            let url = URL(string: urlString) else {
                return
        }
        /// 推送chat的埋点
        var trackInfo = [String: Any]()
        let response = navigator.response(for: url, context: [:], test: true)
        if let chatId = response.request.parameters["chatId"] {
            trackInfo["chat_id"] = chatId
        }
        if let chatType = userInfo.extra?.type.rawValue {
            trackInfo["chat_type"] = chatType
        }
        Tracker.post(TeaEvent(Homeric.PUSH_CHAT_CLICK, params: trackInfo))

        let ifCrossTenant = currentUserID == userId ? "true": "false"
        /// 通知点击埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        Tracker.post(TeaEvent("public_push_detail_click", params: [
            "click": "push",
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant,
            "sub_user_id": userId ?? "",
            "target": "none",
            "is_online_message": (userInfo.nseExtra?.isRemote ?? true) ? "false" : "true"
        ], md5AllowList: ["sub_user_id"]))
    }
}

extension NotificationTracker {
    struct QuickReply {}
}

extension NotificationTracker.QuickReply {
    static func view(msgId: String?, userId: String?, ifCrossTenant: Bool, isRemote: Bool) {
        /// 通知点击埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        Tracker.post(TeaEvent("public_push_quick_reply_view", params: [
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant,
            "sub_user_id": userId ?? "",
            "is_online_message": isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"]))
    }

    static func clickSend(msgId: String?, userId: String?, ifCrossTenant: Bool, isRemote: Bool) {
        /// 消息发送埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        Tracker.post(TeaEvent("public_push_quick_reply_click", params: [
            "click": "msg_send",
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant ? "true" : "false",
            "sub_user_id": userId ?? "",
            "is_watch": false,
            "target": "none",
            "is_online_message": isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"]))
    }

    static func clickSwitch(msgId: String?, userId: String?, ifCrossTenant: Bool, isRemote: Bool) {
        /// 消息发送埋点：https://bytedance.larkoffice.com/sheets/KX0Psp7nFhbPYatdMSkck2ycn8q
        Tracker.post(TeaEvent("public_push_quick_reply_click", params: [
            "click": "switch_account",
            "msg_id": msgId ?? "",
            "if_cross_tenant": ifCrossTenant ? "true" : "false",
            "sub_user_id": userId ?? "",
            "is_watch": false,
            "target": "none",
            "is_online_message": isRemote ? "false" : "true"
        ], md5AllowList: ["sub_user_id"]))
    }
}
