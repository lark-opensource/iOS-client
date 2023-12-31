//
//  IMTracker.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/30.
//

import Foundation
import Homeric // Homeric
import LarkModel // Chat
import LarkCore // IMTracker
import LKCommonsTracker // Tracker
import LarkMessengerInterface // ChatFromWhere

/// 从IMTracker中扩展出场景相关显示、点击埋点
public extension IMTracker {
    struct Scene {}
}

public extension IMTracker.Scene {
    /// 场景相关显示埋点
    struct View {}
    /// 场景相关点击埋点
    struct Click {}
}

/// 场景相关点击埋点
public extension IMTracker.Scene.View {
    /// 「我的场景」展示
    static func sceneList(_ chat: Chat, sceneIds: [Int64]) {
        var params: [AnyHashable: Any] = ["view_type": "my_scene", "scene_chat_id": "[\(sceneIds.map({ "\($0)" }).joined(separator: ","))]"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_ai_scene_chat_side_view",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    /// 「创建场景」展示
    static func newScene(_ chat: Chat) {
        var params: [AnyHashable: Any] = ["view_type": "new_create_scene"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_ai_scene_chat_side_view",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    /// 「编辑场景」展示
    static func editScene(_ chat: Chat, params: [AnyHashable: Any]) {
        var params: [AnyHashable: Any] = params
        params += ["view_type": "new_create_scene"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_ai_scene_chat_side_view",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    /// My AI场景会话中二次确认弹窗展示，「通过AppLink添加到我的收藏」没有chat
    static func confirm(_ chat: Chat? = nil, params: [AnyHashable: Any]) {
        if let chat = chat {
            var params: [AnyHashable: Any] = params
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent("im_ai_scene_chat_confirm_view",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        } else {
            Tracker.post(TeaEvent("im_ai_scene_chat_confirm_view",
                                  params: params))
        }
    }
}

/// 场景相关显示埋点
public extension IMTracker.Scene.Click {
    /// 我的场景页面点击事件
    static func sceneList(_ chat: Chat, params: [AnyHashable: Any]) {
        var params: [AnyHashable: Any] = params
        params += ["view_type": "my_scene"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_ai_scene_chat_side_click",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    /// 创建场景页面点击事件
    static func newScene(_ chat: Chat, params: [AnyHashable: Any]) {
        var params: [AnyHashable: Any] = params
        params += ["view_type": "new_create_scene", "click": "create"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_ai_scene_chat_side_click",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    /// 编辑场景页面点击事件
    static func editScene(_ chat: Chat, params: [AnyHashable: Any]) {
        var params: [AnyHashable: Any] = params
        params += ["view_type": "new_create_scene", "click": "edit"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_ai_scene_chat_side_click",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    /// My AI场景会话中二次确认弹窗点击，「通过AppLink添加到我的收藏」没有chat
    static func confirm(_ chat: Chat? = nil, params: [AnyHashable: Any]) {
        if let chat = chat {
            var params: [AnyHashable: Any] = params
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent("im_ai_scene_chat_confirm_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        } else {
            Tracker.post(TeaEvent("im_ai_scene_chat_confirm_click",
                                  params: params))
        }
    }

    /// 点击My AI bot推送的卡片内容，包括点击内部的场景，问题等
    static func card(_ chat: Chat, params: [AnyHashable: Any]) {
        var params: [AnyHashable: Any] = params
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("public_ai_message_click",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    /// session创建的时候上报，用于区分场景触发时机
    static func session(_ chat: Chat, params: [AnyHashable: Any]) {
        var params: [AnyHashable: Any] = params
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("public_ai_session_scene_type_server",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}
