//
//  ChatFeedCardAvatarVM.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/5/26.
//

import Foundation
import LarkOpenFeed
import LarkFeedBase
import LarkModel
import LarkBadge
import RustPB
import UniverseDesignColor
import LarkBizAvatar

final class ChatFeedCardAvatarVM: FeedCardAvatarVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .avatar
    }

    // VM 数据
    let avatarViewModel: FeedCardAvatarViewModel

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        let entityId: String
        if feedPreview.preview.chatData.chatType == .p2P {
            entityId = feedPreview.preview.chatData.chatterID
        } else {
            entityId = feedPreview.id
        }
        let medal = FeedCardMedal(key: feedPreview.preview.chatData.avatarMedal.key, name: feedPreview.preview.chatData.avatarMedal.name)
        let avatarItem = FeedCardAvatarUrlItem(
            entityId: entityId,
            avatarKey: feedPreview.uiMeta.avatarKey,
            medal: medal)
        let isBorderVisible = feedPreview.isUrgent
        let badgeInfo = FeedCardAvatarUtil.getBadgeInfo(feedPreview: feedPreview)
        var shortcutBadgeInfo = badgeInfo
        if feedPreview.isUrgent {
            shortcutBadgeInfo = FeedCardBadgeInfo(type: .icon(Resources.LarkFeedPlugin.badge_urgent_icon), style: .weak)
        } else if feedPreview.uiMeta.mention.hasAtInfo {
            shortcutBadgeInfo = FeedCardBadgeInfo(type: .icon(Resources.LarkFeedPlugin.badge_at_icon), style: .weak)
        }
        let miniIconProps: MiniIconProps?
        if feedPreview.preview.chatData.isCrypto {
            miniIconProps = MiniIconProps(.dynamicIcon(Resources.LarkFeedPlugin.secret_chat))
        } else if feedPreview.preview.chatData.isPrivateMode {
            miniIconProps = MiniIconProps(.dynamicIcon(Resources.LarkFeedPlugin.private_chat))
        } else {
            miniIconProps = nil
        }
        self.avatarViewModel = FeedCardAvatarViewModel(
            avatarDataSource: .remote(avatarItem),
            miniIconDataSource: nil,
            miniIconProps: miniIconProps,
            badgeInfo: badgeInfo,
            shortcutBadgeInfo: shortcutBadgeInfo,
            positionReversed: false,
            isBorderVisible: isBorderVisible,
            feedId: feedPreview.id,
            feedCardType: feedPreview.basicMeta.feedCardType)
    }
}
