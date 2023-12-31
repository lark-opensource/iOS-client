//
//  Reaction.swift
//  LarkCore
//
//  Created by 李勇 on 2021/5/20.
//

import Homeric
import LarkCore
import Foundation
import LarkFloatPicker
import LKCommonsTracker
import LarkEmotionKeyboard
import LarkStorage

/// 所有Reaction面板相关埋点
public extension PublicTracker {
    struct Reaction {}
}

/// 所有Reaction面板的展示
public extension PublicTracker.Reaction {
    static func View(scene: ReactionPanelScene) {
        var params: [AnyHashable: Any] = [:]
        if scene != .unknown {
            params["scene"] = scene.getDescription()
        } else {
            assertionFailure()
        }
        params["have_organization_emojis"] = KVPublic.Emotion.customEmotion.value()
        Tracker.post(TeaEvent(Homeric.PUBLIC_REACTION_PANEL_SELECT_VIEW, params: params))
    }
}

/// 所有Reaction面板的动作事件
// nolint: duplicated_code - 历史埋点设计
public extension PublicTracker.Reaction {
    static func Click(_ reaction: String,
                      scene: String,
                      tab: ReactionTab,
                      isSkintonePanel: Bool,
                      skintoneEmojiSelectWay: SelectedWay?,
                      chatId: String? = nil) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "emoji"
        params["target"] = "none"
        params["emoji_type"] = reaction
        if let scene = ReactionPanelScene(rawValue: scene), scene != .unknown {
            params["scene"] = scene.getDescription()
        } else {
            assertionFailure()
        }
        params["tab"] = tab.getDescription()
        if let chatId = chatId {
            params["chat_id"] = chatId
        }
        if let way = skintoneEmojiSelectWay {
            switch way {
            case .tap:
                params["skintone_emoji_select_way"] = "click_to_select"
            case .slide:
                params["skintone_emoji_select_way"] = "slide_to_select"
            }
        }
        params["is_skintone_panel"] = isSkintonePanel ? "true" : "false"
        params["have_organization_emojis"] = KVPublic.Emotion.customEmotion.value()
        Tracker.post(TeaEvent(Homeric.PUBLIC_REACTION_PANEL_SELECT_CLICK, params: params))
    }
}
// enable-lint: duplicated_code

public enum ReactionTab: String {
    case all
    case recent
    case mru

    func getDescription() -> String {
        switch self {
        case .all:
            return "all"
        case .recent:
            return "recently_used"
        case .mru:
            return "commonly_used"
        }
    }
}
