//
//  BoxFeedCardAvatarVM.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/5/29.
//

import Foundation
import LarkOpenFeed
import LarkFeedBase
import LarkModel
import LarkBadge
import RustPB
import UniverseDesignColor
import LarkFeed

final class BoxFeedCardAvatarVM: FeedCardAvatarVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .avatar
    }

    // VM 数据
    let avatarViewModel: FeedCardAvatarViewModel

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        var badgeStyle: LarkBadge.BadgeStyle?
        if feedPreview.basicMeta.unreadCount > 0 {
            switch FeedBadgeBaseConfig.badgeStyle {
            case .weakRemind:   badgeStyle = .weak
            case .strongRemind: badgeStyle = .strong
            @unknown default:   badgeStyle = nil
            }
        }
        let badgeInfo: FeedCardBadgeInfo
        if let style = badgeStyle {
            badgeInfo = FeedCardBadgeInfo(type: .dot(.lark), style: style)
        } else {
            badgeInfo = .default()
        }
        var shortcutBadgeInfo = badgeInfo
        if feedPreview.uiMeta.mention.hasAtInfo {
            shortcutBadgeInfo = FeedCardBadgeInfo(type: .icon(Resources.LarkFeedPlugin.badge_at_icon), style: .weak)
        }
        self.avatarViewModel = FeedCardAvatarViewModel(
            avatarDataSource: .local(LarkFeed.Resources.feed_box_avatar),
            miniIconDataSource: nil,
            miniIconProps: nil,
            badgeInfo: badgeInfo,
            shortcutBadgeInfo: shortcutBadgeInfo,
            positionReversed: false,
            isBorderVisible: false,
            feedId: feedPreview.id,
            feedCardType: feedPreview.basicMeta.feedCardType)
    }
}
