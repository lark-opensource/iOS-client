//
//  MultiSelect.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2021/5/11.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel

/// IM业务，会话进入多选态相关埋点
public extension IMTracker.Msg {
    struct MultiSelect {}
}

/// 进入多选态
public extension IMTracker.Msg.MultiSelect {
    static func View(_ chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_MSG_MULTI_SELECT_VIEW,
                              params: IMTracker.Param.chat(chat),
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

/// 多选态点击
public extension IMTracker.Msg.MultiSelect {
    struct Click {
        public static func SelectFollowMsg(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "select_follow_msg",
                                              "target": "none",
                                              "msg_id": "none",
                                              "msg_type": "none"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MULTI_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func MergeForward(_ chat: Chat, _ messages: [Message]) {
            var params: [AnyHashable: Any] = [
                "click": "mergeforward",
                "target": "im_msg_forward_select_view",
                "msg_id": messages.map({ $0.id }).joined(separator: ","),
                "msg_type": messages.map({ IMTracker.Base.messageType($0) }).joined(separator: ","),
                "msg_count": messages.count
            ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MULTI_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func OnebyoneForward(_ chat: Chat, _ messages: [Message]) {
            var params: [AnyHashable: Any] = [
                "click": "onebyone_forward",
                "target": "im_msg_forward_select_view",
                "msg_id": messages.map({ $0.id }).joined(separator: ","),
                "msg_type": messages.map({ IMTracker.Base.messageType($0) }).joined(separator: ","),
                "msg_count": messages.count
            ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MULTI_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func CreateTodo(_ chat: Chat, _ messages: [Message]) {
            var params: [AnyHashable: Any] = [
                "click": "create_todo",
                "target": "todo_create_view",
                "msg_id": messages.map({ $0.id }).joined(separator: ","),
                "msg_type": messages.map({ IMTracker.Base.messageType($0) }).joined(separator: ","),
                "msg_count": messages.count
            ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MULTI_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func FastAction(_ chat: Chat, _ messages: [Message]) {
            var params: [AnyHashable: Any] = [
                "click": "fast_action",
                "target": "none",
                "msg_id": messages.map({ $0.id }).joined(separator: ","),
                "msg_type": messages.map({ IMTracker.Base.messageType($0) }).joined(separator: ","),
                "msg_count": messages.count
            ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MULTI_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func MultiSelectFavorite(_ chat: Chat, _ messages: [Message]) {
            var params: [AnyHashable: Any] = [
                "click": "multiselect_favorite",
                "target": "none",
                "msg_id": messages.map({ $0.id }).joined(separator: ","),
                "msg_type": messages.map({ IMTracker.Base.messageType($0) }).joined(separator: ","),
                "msg_count": messages.count
            ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MULTI_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Delete(_ chat: Chat, _ messages: [Message]) {
            var params: [AnyHashable: Any] = [
                "click": "delete",
                "target": "im_delete_comfirm_view",
                "msg_id": messages.map({ $0.id }).joined(separator: ","),
                "msg_type": messages.map({ IMTracker.Base.messageType($0) }).joined(separator: ","),
                "msg_count": messages.count
            ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MULTI_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func CopyMessageLink(_ chat: Chat, _ messages: [Message]) {
            var params: [AnyHashable: Any] = [
                "click": "copy_msg_link",
                "target": "none",
                "msg_id": messages.map({ $0.id }).joined(separator: ","),
                "msg_type": messages.map({ IMTracker.Base.messageType($0) }).joined(separator: ","),
                "msg_count": messages.count
            ]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_MSG_MULTI_SELECT_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}
