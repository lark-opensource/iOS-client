//
//  More.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2021/5/11.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel

/// IM业务，话题群/话题详情点击右上方[...]出现的菜单相关埋点
public extension IMTracker.Msg.Menu {
    struct More {}
}

/// 显示
public extension IMTracker.Msg.Menu.More {
    static func View(_ chat: Chat, _ message: Message) {
        var params: [AnyHashable: Any] = IMTracker.Param.message(message)
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_MORE_VIEW,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
    }
}

/// 点击事件
public extension IMTracker.Msg.Menu.More {
    struct Click {
        public static func Pin(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "pin", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_MORE_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        public static func UnPin(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "unpin", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_MORE_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        public static func Todo(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "todo", "target": "todo_create_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_MORE_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        public static func Close(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "close_topic", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_MORE_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        /// 点击撤回话题
        public static func Withdraw(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "withdraw_topic", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_MORE_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        public static func EditMsg(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "edit_msg", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_MORE_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

        public static func RecallFoldCard(_ chat: Chat, _ message: Message, isReacllCard: Bool, _ chatFromWhere: String?) {
            var params: [AnyHashable: Any] = ["click": !isReacllCard ? "withdraw_repeat_msg" : "withdraw_repeat_card",
                                              "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MENU_MORE_CLICK,
                                  params: params,
                                  md5AllowList: [],
                                  bizSceneModels: [IMTracker.Transform.chat(chat), IMTracker.Transform.message(message)]))
        }

    }
}
