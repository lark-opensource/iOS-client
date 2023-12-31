//
//  Menu.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2021/5/11.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel
import LarkMessengerInterface
import LarkContainer
import LarkMessageBase

/// IM业务，消息菜单相关埋点
public extension IMTracker.Msg {
    struct Menu {}
}

/// 消息菜单点击
public extension IMTracker.Msg.Menu {
    struct Click {
        /// 点击最近使用面部右侧的+号
        public static func Reaction(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "reaction", "target": "public_reaction_panel_select_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        /// 点击某个具体的reaction
        public static func ReactionClick(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "reaction_click", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }
        public static func CopyMessageLink(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "copy_msg_link",
                                              "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        /// MyAI分会场，点击业务方传入的按钮
        public static func Output(_ chat: Chat, _ message: Message, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = params
            params += ["click": "output", "target": "none"]
            params += IMTracker.Param.message(message, doc: false)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent("im_ai_msg_menu_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        /// MyAI分会场，点击赞按钮
        public static func Like(_ chat: Chat, _ message: Message, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = params
            params += ["click": "like", "target": "none"]
            params += IMTracker.Param.message(message, doc: false)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent("im_ai_msg_menu_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        /// MyAI分会场，点击踩按钮
        public static func Dislike(_ chat: Chat, _ message: Message, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = params
            params += ["click": "dislike", "target": "none"]
            params += IMTracker.Param.message(message, doc: false)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent("im_ai_msg_menu_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }
    }
}

public extension IMTracker.Msg {
    static func WithdrawConfirmCLick(_ chat: Chat?, _ message: Message?, clickConfirm: Bool) {
        guard let chat = chat,
              let message = message else {
            return
        }

        var params: [AnyHashable: Any] = ["click": clickConfirm ? "confirm" : "close", "target": "none"]
        params += IMTracker.Param.message(message, doc: true)
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_msg_withdraw_confirm_click",
                              params: params,
                              md5AllowList: ["file_id"],
                              bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
    }

    /// MyAI分会场，显示业务方传入的按钮
    static func OutputShow(_ chat: Chat, _ message: Message, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
        var params: [AnyHashable: Any] = params
        params += ["target": "none"]
        params += IMTracker.Param.message(message, doc: false)
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
        Tracker.post(TeaEvent("im_ai_msg_output_show_click",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
    }
}
