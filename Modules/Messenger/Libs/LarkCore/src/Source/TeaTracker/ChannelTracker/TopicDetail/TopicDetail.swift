//
//  TopicDetail.swift
//  LarkCore
//
//  Created by 李勇 on 2021/5/18.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel

/// 话题详情相关埋点
public extension ChannelTracker {
    struct TopicDetail {}
}

/// 话题详情展示
public extension ChannelTracker.TopicDetail {
    static func View(_ chat: Chat, _ threadId: String) {
        var params: [AnyHashable: Any] = ["thread_id": threadId,
                                          "is_group_member": chat.role == .member ? "true" : "false"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_VIEW, params: params))
    }
}

/// 话题详情点击
public extension ChannelTracker.TopicDetail {
    struct Click {

        public static func commonParam(chat: Chat) -> [AnyHashable: Any] {
            return ["is_group_member": chat.role == .member ? "true" : "false"]
        }

        public static func Close(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "close", "target": "none", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            params += commonParam(chat: chat)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK, params: params))
        }

        public static func More(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "more", "target": "im_msg_menu_more_view", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            params += commonParam(chat: chat)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK, params: params))
        }

        public static func Subscribe(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "subscribe", "target": "none", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            params += commonParam(chat: chat)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK, params: params))
        }

        public static func Forward(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "forward", "target": "im_msg_forward_select_view", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            params += commonParam(chat: chat)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK, params: params))
        }

        public static func Post(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "post", "target": "im_chat_post_view", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            params += commonParam(chat: chat)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK, params: params))
        }

        public static func ImageSelect(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "image_select", "target": "im_chat_image_send_view", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            params += commonParam(chat: chat)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK, params: params))
        }

        public static func VoiceMsg(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "voice_msg", "target": "im_chat_voice_msg_view", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            params += commonParam(chat: chat)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK, params: params))
        }

        public static func MsgPress(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg_press", "target": "im_msg_menu_view", "thread_id": message.id]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.message(message)
            params += commonParam(chat: chat)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK, params: params))
        }

        public static func FromTopic(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "from_topic_group",
                                              "target": "im_chat_main_view"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.message(message)
            params += commonParam(chat: chat)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK, params: params))
        }
    }
}

/// 消息点击太过复杂，单独汇总
public extension ChannelTracker.TopicDetail.Click {
    struct Msg {
        public static func Doc(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "doc", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Image(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "image", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Media(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "media", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func VideoChat(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "videoChat", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Sticker(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "sticker", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func MergeForward(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "mergeForward", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ShareGroupChat(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "shareGroupChat", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ShareUserCard(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "shareUserCard", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Someone(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "@someone", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Icon(_ chat: Chat, _ message: Message) {
            var params: [AnyHashable: Any] = ["click": "msg", "thread_id": message.id, "occasion": "icon", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent(Homeric.CHANNEL_TOPIC_DETAIL_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}
