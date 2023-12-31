//
//  MenuTracker.swift
//  LarkMenuController
//
//  Created by JackZhao on 2022/2/10.
//

import Foundation
import Homeric
import LarkFloatPicker
import LKCommonsTracker
import LarkEmotionKeyboard
import LarkStorage

struct MenuTracker {
    static func trackerTea(event: String, params: [AnyHashable: Any]) {
        Tracker.post(TeaEvent(event, params: params))
    }
    static func reactionPanelView(scene: ReactionPanelScene) {
        var params: [AnyHashable: Any] = [:]
        if scene != .unknown {
            params["scene"] = scene.getDescription()
        } else {
            assertionFailure()
        }
        params["have_organization_emojis"] = KVPublic.Emotion.customEmotion.value()
        Tracker.post(TeaEvent(Homeric.PUBLIC_REACTION_PANEL_SELECT_VIEW, params: params))
    }

    static func emotionPanelClick(_ reaction: String,
                                  scene: ReactionPanelScene,
                                  tab: String,
                                  isSkintonePanel: Bool,
                                  skintoneEmojiSelectWay: SelectedWay?,
                                  chatId: String? = nil) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "emoji"
        params["target"] = "none"
        params["emoji_type"] = reaction
        if scene != .unknown {
            params["scene"] = scene.getDescription()
        } else {
            assertionFailure()
        }
        if let tab = ReactionTab(rawValue: tab) {
            params["tab"] = tab.getDescription()
        } else {
            assertionFailure()
        }
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

enum ReactionTab: String {
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
