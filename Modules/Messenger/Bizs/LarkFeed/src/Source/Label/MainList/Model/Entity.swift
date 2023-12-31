//
//  Entity.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import UIKit
import Foundation
import RustPB
import LarkModel
import LarkSDKInterface
import LarkBizAvatar
import LarkBadge
import LarkFeedBase
import LarkOpenFeed

struct LabelViewModel {
    let item: EntityItem
    let meta: Feed_V1_FeedGroupPreview
    var badgeInfo: (type: BadgeType, style: LarkBadge.BadgeStyle)?

    init(item: EntityItem,
         meta: Feed_V1_FeedGroupPreview) {
        self.item = item
        self.meta = meta
        self.badgeInfo = getBadgeInfo()
    }

    private func getBadgeInfo() -> (type: BadgeType, style: LarkBadge.BadgeStyle)? {
        var remindUnreadCount = Int(meta.extraData.remindUnreadCount)
        var muteUnreadCount = Int(meta.extraData.muteUnreadCount)
        if remindUnreadCount <= 0 && muteUnreadCount <= 0 {
            return nil
        }

        if remindUnreadCount > 0 {
            return (.label(.number(remindUnreadCount)), .strong)
        }

        switch FeedBadgeBaseConfig.badgeStyle {
        case .weakRemind: return (.label(.number(muteUnreadCount)), .weak)
        @unknown default: return (.dot(.lark), .strong)
        }
    }

    func getArrowConfig(mode: SwitchModeModule.Mode) -> (Bool, CGFloat, CGFloat) {
        let isHidden: Bool
        let leading: CGFloat
        let size: CGFloat
        switch mode {
        case .standardMode:
            isHidden = false
            leading = Cons.standardLeading
            size = Cons.standardSize
        case .threeBarMode(_):
            isHidden = true
            leading = Cons.threeBarLeading
            size = Cons.threeBarSize
        }
        return (isHidden, leading, size)
    }

    enum Cons {
        static let standardLeading: CGFloat = 16.0
        static let standardSize: CGFloat = 12.0
        static let threeBarLeading: CGFloat = 8.0
        static let threeBarSize: CGFloat = 0.0
    }
}

extension LabelViewModel {
    var description: String {
        return "item: \(item.description), "
            + "meta: \(meta.description)"
    }
}

struct LabelFeedViewModel {
    let feedViewModel: FeedCardViewModelInterface
    var feedPreview: FeedPreview {
        return feedViewModel.feedPreview
    }

    var avatarId: String = "" // setAvatar时需要
    var avatarBadgeInfo: (type: BadgeType, style: LarkBadge.BadgeStyle) = (.none, .weak)
    var badgeInfo: (type: BadgeType, style: LarkBadge.BadgeStyle)?
    var atBorderImage: UIImage? // At/At All border

    init(feedViewModel: FeedCardViewModelInterface) {
        self.feedViewModel = feedViewModel
        self.badgeInfo = getBadgeInfo()
        badgeInfo = getBadgeInfo()
        atBorderImage = getAtBorderImage()
        avatarId = getAvatarId()
        avatarBadgeInfo = getBadgeInfo()
    }
}

extension LabelFeedViewModel {
    private func getAvatarId() -> String {
        if feedViewModel.feedPreview.preview.chatData.chatType == .p2P {
            return feedPreview.preview.chatData.chatterID
        }
        return feedPreview.id
    }

    func getBadgeInfo() -> (type: BadgeType, style: LarkBadge.BadgeStyle) {
        if feedPreview.isUrgent {
            return (.icon(Resources.badge_urgent_icon), .weak)
        } else {
            return (.none, .weak)
        }
    }

    private func getAtBorderImage() -> UIImage? {
        guard feedPreview.uiMeta.mention.hasAtInfo else { return nil }
        return feedPreview.uiMeta.mention.atInfo.type == .all ? Resources.feed_at_all_border : Resources.feed_at_me_border
    }

    private func getBadgeInfo() -> (type: BadgeType, style: LarkBadge.BadgeStyle)? {
        let unreadCount = feedPreview.basicMeta.unreadCount
        if unreadCount <= 0 {
            return nil
        }

        if feedPreview.basicMeta.isRemind {
            return (.label(.number(unreadCount)), .strong)
        }

        switch FeedBadgeBaseConfig.badgeStyle {
        case .weakRemind: return (.label(.number(unreadCount)), .weak)
        @unknown default: return (.dot(.lark), .strong)
        }
    }

    func getHeight(mode: SwitchModeModule.Mode) -> CGFloat {
        switch mode {
        case .standardMode:
            return LableFeedCell.Cons.cellHeight
        case .threeBarMode(_):
            return feedViewModel.cellRowHeight
        }
    }
}

struct EntityItem: IndexDataInterface {
    let id: Int
    let parentId: Int
    let position: Int64
    let updateTime: Int64

    var description: String {
        return "id: \(id), "
            + "parentId: \(parentId), "
            + "position: \(position), "
            + "updateTime: \(updateTime)"
    }
    init(id: Int, parentId: Int, position: Int64, updateTime: Int64) {
        self.id = id
        self.parentId = parentId
        self.position = position
        self.updateTime = updateTime
    }
}
