//
//  FontBar.swift
//  LarkCore
//
//  Created by liluobin on 2021/9/16.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel
import LarkBaseKeyboard

/// 所有FontBar面板相关埋点
public extension PublicTracker {
    struct FontBar {}
}

/// 所有FontBar面板的展示
public extension PublicTracker.FontBar {
    static func View(_ chat: Chat?, isFullScreen: Bool, isUserClick: Bool) {
        guard let chat = chat else {
            return
        }
        var params: [AnyHashable: Any] = [ "trigger_type": isUserClick ? "aa_click" : "content_select",
                                           "isFullScreen": isFullScreen ? "true" : "false",
                                           "target": "none"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_TOOLBAR_VIEW,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

/// 所有FontBar面板的动作事件
public extension PublicTracker.FontBar {
    static func Click(_ chat: Chat, isFullScreen: Bool, type: FontActionType, _ threadId: String? = nil) {
        var action = "none"
        switch type {
        case .bold:
            action = "bold"
        case .italic:
            action = "italic"
        case .underline:
            action = "underline"
        case .strikethrough:
            action = "strikethrough"
        default:
            break
        }
        var params: [AnyHashable: Any] = [ "click": action,
                                           "target": "none",
                                           "isFullScreen": isFullScreen ? "true" : "false"]
        if let threadId = threadId {
            params["thread_id"] = threadId
        }
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_TOOLBAR_CLICK,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}
