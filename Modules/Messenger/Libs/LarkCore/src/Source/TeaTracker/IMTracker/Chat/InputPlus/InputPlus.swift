//
//  InputPlus.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2021/5/11.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel

/// 会话主界面，键盘+号菜单相关埋点
public extension IMTracker.Chat {
    struct InputPlus {}
}

/// 键盘+号菜单点击
public extension IMTracker.Chat.InputPlus {
    struct Click {
        public static func Event(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "event", "target": "cal_event_full_create_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Todo(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "todo", "target": "todo_create_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func PersonalCard(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "personal_card", "target": "im_chat_main_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Docs(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "docs", "target": "ccm_space_im_docs_send_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func GroupRunningList(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "group_running_list", "target": "im_group_running_list_set_view"]
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func location(_ chat: Chat?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "location", "target": "message_location_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
        public static func hongbao(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "hongbao", "target": "im_msg_hongbao_confirm_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
        public static func localFile(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "local_file", "target": "im_msg_send_confirm_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
        public static func translationButton(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "translation_button",
                                              "target": "none",
                                              "status": chat.typingTranslateSetting.isOpen ? "on_to_off" : "off_to_on"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func delayedSend(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "delayed_send",
                                              "target": "im_msg_delayed_send_time_view"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

/// 键盘 + 号菜单页面展示
public extension IMTracker.Chat.InputPlus {
    static func View(_ chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_VIEW,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}
