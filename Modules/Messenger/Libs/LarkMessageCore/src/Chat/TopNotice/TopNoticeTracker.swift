//
//  TopNoticeTracker.swift
//  LarkMessageCore
//
//  Created by liluobin on 2021/11/14.
//

import Foundation
import UIKit
import LarkModel
import LarkCore
import Homeric
import LKCommonsTracker

public final class TopNoticeTracker {

    public enum AnnouncementSettingType: String {
        /// 发送到群聊（移动端）
        case sendToChat = "send_to_chat"
        /// 在群内消息置顶（移动端）
        case pinToTop = "pin_to_top"
        /// 发送到群聊并在群内置顶(移动端)
        case sendToChatAndPinToTop = "send_to_chat_and_pin_to_top"
        var target: String { return "none" }
    }

    public enum TapLocation {
        case content
        case fromUser
        case close
    }

    enum TopRestriction {
        case all
        case onlyAdmin
    }

    public enum TopType {
        case message
        case announcement
    }

    public enum RemoveOrCloseAction: String {
        /// 关闭仅自己的置顶
        case close = "unpin_to_top_for_only_oneself"
        /// 关闭所有人的置顶
        case remove = "unpin_to_top_for_all"
        /// 在单聊模式下点击「确定」键
        case p2pRemove = "confirm"
    }

    /// 「消息置顶卡片」页展示
    public static func TopNoticeView(_ chat: Chat, _ message: Message?, isTopNoticeOwner: Bool, topType: TopType) {
        var params: [AnyHashable: Any] = ["is_pin_to_top_owner": isTopNoticeOwner ? "true" : "false"]
        switch topType {
        case .message:
            params += ["card_type": "msg"]
        case .announcement:
            params += ["card_type": "announcement"]
        }
        var bizSceneModels: [TeaBizSceneProtocol] = [IMTracker.Transform.chat(chat)]
        if let message = message {
            params += IMTracker.Param.message(message)
            bizSceneModels.append(IMTracker.Transform.message(message))
        }
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_MSG_PIN_TO_TOP_CARD_VIEW,
                              params: params,
                              bizSceneModels: bizSceneModels))
    }

    // 在「消息置顶卡片」页，发生动作事件
    public static func TopNoticeClick(_ chat: Chat, _ message: Message?, tapLocation: TapLocation, isOnlyAdmin: Bool, isTopNoticeOwner: Bool, topType: TopType) {
        var params: [AnyHashable: Any] = ["is_pin_to_top_owner": isTopNoticeOwner ? "true" : "false"]
        switch topType {
        case .message:
            params += ["card_type": "msg"]
        case .announcement:
            params += ["card_type": "announcement"]
        }
        switch tapLocation {
        case .content:
            params += ["click": "click_pin_to_top",
                       "target": "im_chat_main_view"]
        case .fromUser:
            params += [ "click": "pin_to_top_owner",
                        "target": "profile_main_view"]
        case .close:
            params += ["click": "close_pin_to_top",
                       "target": "none",
                       "pin_to_top_restriction": isOnlyAdmin ? "only_group_owner_and_admin" : "all"]
        }
        var bizSceneModels: [TeaBizSceneProtocol] = [IMTracker.Transform.chat(chat)]
        if let message = message {
            params += IMTracker.Param.message(message)
            bizSceneModels.append(IMTracker.Transform.message(message))
        }
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_MSG_PIN_TO_TOP_CARD_CLICK,
                              params: params,
                              bizSceneModels: bizSceneModels))
    }

    public static func TopNoticeCancelAlertView(_ chat: Chat, _ message: Message?, isTopNoticeOwner: Bool) {
        var params: [AnyHashable: Any] = ["is_pin_to_top_owner": isTopNoticeOwner ? "true" : "false"]
        params += IMTracker.Param.chat(chat)
        var bizSceneModels: [TeaBizSceneProtocol] = [IMTracker.Transform.chat(chat)]
        if let message = message {
            params += IMTracker.Param.message(message)
            bizSceneModels.append(IMTracker.Transform.message(message))
        }
        Tracker.post(TeaEvent(Homeric.IM_MSG_UNPIN_TO_TOP_CONFIRM_VIEW,
                              params: params,
                              bizSceneModels: bizSceneModels))
    }

    /// 在「消息取消置顶确认弹窗」页，发生动作事件.
    /// 消息菜单中点击取消置顶 & 置顶消息卡片中点击关闭时都上报
    public static func TopNoticeDidRemove(_ chat: Chat, _ message: Message?, isTopNoticeOwner: Bool, action: RemoveOrCloseAction) {
        var params: [AnyHashable: Any] = ["is_pin_to_top_owner": isTopNoticeOwner ? "true" : "false"]
        params += ["click": action.rawValue, "target": "im_chat_main_view"]
        var bizSceneModels: [TeaBizSceneProtocol] = [IMTracker.Transform.chat(chat)]
        if let message = message {
            params += IMTracker.Param.message(message)
            bizSceneModels.append(IMTracker.Transform.message(message))
        }
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_MSG_UNPIN_TO_TOP_CONFIRM_CLICK,
                              params: params,
                              bizSceneModels: bizSceneModels))
    }

    public static func GroupAnnouncementSettingView(_ chat: Chat) {
        let params = IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_chat_announcement_setting_view",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    public static func GroupAnnouncementSettingClick(_ chat: Chat, type: AnnouncementSettingType) {
        var params: [AnyHashable: Any] = ["click": type.rawValue,
                                          "target": type.target]

        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_chat_announcement_setting_click",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    public static func ChatAnnouncementPageClick(_ chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "release",
                                          "target": "im_chat_announcement_setting_view"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_chat_announcement_page_click",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}
