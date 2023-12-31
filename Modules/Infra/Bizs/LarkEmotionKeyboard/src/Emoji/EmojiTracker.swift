//
//  EmojiTracker.swift
//  LarkEmotionKeyboard
//
//  Created by 李勇 on 2021/5/20.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkFloatPicker
import LarkStorage

struct EmojiTracker {
    static func trackerTea(event: String, params: [AnyHashable: Any]) {
        Tracker.post(TeaEvent(event, params: params))
    }
    static func view(scene: EmotionKeyboardScene) {
        var params: [AnyHashable: Any] = [:]
        if scene == .unknown {
            assertionFailure()
        } else {
            params["scene"] = scene.getDescription()
        }
        params["have_organization_emojis"] = KVPublic.Emotion.customEmotion.value()
        Tracker.post(TeaEvent(Homeric.PUBLIC_EMOJI_PANEL_SELECT_VIEW, params: params))
    }

    static func click(_ reaction: String,
                      scene: EmotionKeyboardScene,
                      tab: EmojiTab,
                      chatId: String? = nil,
                      isSkintonePanel: Bool,
                      skintoneEmojiSelectWay: SelectedWay? = nil) {
        var params: [AnyHashable: Any] = [:]
        if scene == .unknown {
            assertionFailure()
        } else {
            params["scene"] = scene.getDescription()
        }
        params["tab"] = tab.getDescription()
        params["click"] = "emoji"
        params["target"] = "none"
        params["is_skintone_panel"] = isSkintonePanel ? "true" : "false"
        params["emoji_type"] = reaction
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
        params["have_organization_emojis"] = KVPublic.Emotion.customEmotion.value()
        Tracker.post(TeaEvent(Homeric.PUBLIC_EMOJI_PANEL_SELECT_CLICK, params: params))
    }
}

enum EmojiTab: String {
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
