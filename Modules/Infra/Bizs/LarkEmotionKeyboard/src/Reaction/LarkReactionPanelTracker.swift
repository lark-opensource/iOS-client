//
//  LarkReactionPanelTracker.swift
//  LarkReactionPanel
//
//  Created by 王元洵 on 2021/2/9.
//

import Foundation
import LKCommonsTracker
import Homeric

final class LarkReactionPanelTracker {
    static func trackerEmojiLoadDuration(duration: CFTimeInterval, emojiKey: String, isLocalImage: Bool) {
        if isLocalImage {
            Tracker.post(SlardarEvent(name: Homeric.LARKW_EMOJI,
                                      metric: ["emoji_img_load_duration": duration * 1_000],
                                      category: ["protocol": "file", "domain": "unknown"],
                                      extra: ["emojiKey": emojiKey]))
        } else {
            Tracker.post(SlardarEvent(name: Homeric.LARKW_EMOJI,
                                      metric: ["emoji_img_load_duration": duration * 1_000],
                                      category: ["protocol": "rust", "domain": "unknown"],
                                      extra: ["emojiKey": emojiKey]))
        }
    }
}

public enum ReactionPanelScene: String {
    case im
    case ccm
    case moments    // 公司圈
    case todo
    case groupAvatar
    // 默认兼容字段
    case unknown
    public func getDescription() -> String {
        switch self {
        case .unknown:
            assertionFailure()
            return ""
        case .im:
            return "im"
        case .ccm:
            return "ccm"
        case .moments:
            return "moments"
        case .todo:
            return "todo"
        case .groupAvatar:
            return "group_avatar"
        }
    }
}

public enum EmotionKeyboardScene: String {
    case im
    case moments
    case vc
    case personalStatus
    // 默认兼容字段
    case unknown

    func getDescription() -> String {
        switch self {
        case .unknown:
            assertionFailure()
            return ""
        case .vc:
            return "vc"
        case .im:
            return "im"
        case .moments:
            return "moments"
        case .personalStatus:
            return "personal_status"
        }
    }
}
