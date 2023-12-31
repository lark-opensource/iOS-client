//
//  FeedCardActionType.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/5/9.
//

import Foundation
import LarkModel

///
/// feed card 支持的action
///
public enum FeedCardSwipeActionType {
    case done               // 完成
    case shortcut           // 添加到置顶
    case hide               // 隐藏
    case flag               // 标记

    public func transform(preview: FeedPreview) -> FeedCardLongPressActionType? {
        switch self {
        case .hide:
            return nil
        case .done:
            return .done
        case .shortcut:
            return .pin(isShortcut: preview.basicMeta.isShortcut)
        case .flag:
            return .flag(isFlaged: preview.basicMeta.isFlaged)
        }
    }
}

public enum FeedCardLongPressActionType {
    case done
    case pin(isShortcut: Bool)
    case flag(isFlaged: Bool)
    case mute(isRemind: Bool)
    case label
    case deleteLabelFeed
    case debug
    case clearBadge
    case chatForbidden(isForbidden: Bool)
    case team

    public var clickTrackValue: String {
        switch self {
        case .done:
            return "finished"
        case .pin(let isShortcut):
            return isShortcut ? "cancel_top" : "top"
        case .flag(let isFlaged):
            return isFlaged ? "un_mark" : "mark"
        case .mute(let isRemind):
            return isRemind ? "mute" : "unmute"
        case .label:
            return "label"
        case .deleteLabelFeed:
            return "remove_label"
        case .debug: return "debug"
        case .clearBadge:
            return "clearBadge"
        case .chatForbidden(let isForbidden):
            return isForbidden ? "forbidden" : "allow"
        case .team:
            return "add_to_team"
        }
    }

    public var index: Int {
        switch self {
        case .pin(_):
            return 0
        case .flag(_):
            return 1
        case .team:
            return 2
        case .label:
            return 3
        case .clearBadge:
            return 4
        case .chatForbidden(_):
            return 5
        case .mute(_):
            return 6
        case .done:
            return 7
        case .deleteLabelFeed:
            return 8
        case .debug:
            return 9
        }
    }
}
