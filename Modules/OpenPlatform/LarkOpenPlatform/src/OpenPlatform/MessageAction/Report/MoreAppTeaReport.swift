//
//  MoreAppTeaReport.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/21.
//

import LarkModel
import LKCommonsTracker
import LarkMessengerInterface
import LarkSnsShare
import LarkCore
import LarkAccountInterface
import LarkContainer

struct MoreAppTeaReport {
    enum keys: String {
        /// 在底部栏「【+】号菜单」页，点击开放平台应用事件
        case im_chat_input_plus_click
        /// 「消息快捷操作的应用设置页」页面展开
        case im_chat_msg_menu_more_app_view
        /// 「聊天加号的应用设置页」页面展开
        case im_chat_input_plus_more_app_view
        /// 在「消息快捷操作的应用设置页」，点击开放平台应用
        case im_chat_msg_menu_more_app_click
        /// 在「聊天加号的应用设置页」，点击开放平台应用
        case im_chat_msg_plus_more_app_click
    }

    /// 在底部栏「【+】号菜单」页，点击开放平台应用事件
    static func imChatInputPlusClick(resolver: UserResolver, chat: Chat, isMoreOrElseApp: Bool, appID: String? = nil) {
        let isOwner = chat.ownerId == resolver.userID
        let isAdmin = chat.isGroupAdmin
        let myUserId = resolver.userID
        let clickType: String = isMoreOrElseApp ? "more" : "openplatform_app"

        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        var params = [
            "click": clickType,
            "chat_type": chatType,
            "chat_type_detail": chatTypeDetail,
            "is_inner_group": !chat.isPublic ? "true" : "false",
            "is_public_group": chat.isPublic ? "true" : "false",
            "member_type": memberType.rawValue,
            "chat_id": chat.id
          ]
        params["target"] = isMoreOrElseApp ? "im_chat_input_plus_more_app_view" : "none"
        params["click_application_id"] = appID
        Tracker.post(TeaEvent(Self.keys.im_chat_input_plus_click.rawValue,
                              params: params))
    }

    /// 「消息快捷操作/加号菜单的应用设置页」页面展开
    static func imChatMoreAppView(bizScene: BizScene) {
        var key = ""
        switch bizScene {
        case .addMenu:
            key = Self.keys.im_chat_input_plus_more_app_view.rawValue
        default:
            key = Self.keys.im_chat_msg_menu_more_app_view.rawValue
        }
        Tracker.post(TeaEvent(key, params: [:]))
    }

    /// 「消息快捷操作/加号菜单的应用设置页」页面展开
    static func imChatMoreAppClick(bizScene: BizScene, appID: String?) {
        var key = ""
        switch bizScene {
        case .addMenu:
            key = Self.keys.im_chat_msg_plus_more_app_click.rawValue
        default:
            key = Self.keys.im_chat_msg_menu_more_app_click.rawValue
        }
        var params = [
            "click": "openplatform_app"
          ]
        params["target"] = "none"
        params["click_application_id"] = appID
        Tracker.post(TeaEvent(key, params: params))
    }
}
