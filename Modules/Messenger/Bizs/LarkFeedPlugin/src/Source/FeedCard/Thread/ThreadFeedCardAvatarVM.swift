//
//  ThreadFeedCardAvatarVM.swift
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

final class ThreadFeedCardAvatarVM: FeedCardAvatarVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .avatar
    }

    // VM 数据
    let avatarViewModel: FeedCardAvatarViewModel

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        // 头像资源
        let avatarDataSource: FeedCardAvatarDataSource
        // 头像右下角的mini icon 资源
        let miniIconDataSource: FeedCardMiniIconDataSource?
        let positionReversed: Bool

        if feedPreview.preview.threadData.entityType == .msgThread {
            avatarDataSource = .local(BundleResources.LarkFeedPlugin.msg_thread)
            positionReversed = true
            let entityId: String
            // 单聊时候需要展示个人头像
            let threadMsgP2pAvatarInfo: (key: String, id: String)?
            if feedPreview.preview.threadData.chatType == .p2P {
                threadMsgP2pAvatarInfo = (feedPreview.preview.threadData.avatarKey, feedPreview.preview.threadData.chatterID)
            } else {
                threadMsgP2pAvatarInfo = nil
            }
            if let info = threadMsgP2pAvatarInfo {
                entityId = info.id
            } else {
                entityId = feedPreview.preview.threadData.chatID
            }
            let avatarKey: String
            if let info = threadMsgP2pAvatarInfo {
                avatarKey = info.key
            } else {
                avatarKey = feedPreview.uiMeta.avatarKey
            }
            let minIconRemoteItem = FeedCardMinIconUrlItem(
                entityId: entityId,
                avatarKey: avatarKey)
            miniIconDataSource = .remote(minIconRemoteItem)
        } else {
            positionReversed = false
            let avatarItem = FeedCardAvatarUrlItem(
                entityId: feedPreview.preview.threadData.chatID,
                avatarKey: feedPreview.uiMeta.avatarKey)
            avatarDataSource = .remote(avatarItem)
            miniIconDataSource = .local(BundleResources.LarkFeedPlugin.thread_topic)
        }

        let badgeInfo = FeedCardAvatarUtil.getBadgeInfo(feedPreview: feedPreview)
        var shortcutBadgeInfo = badgeInfo
        if feedPreview.uiMeta.mention.hasAtInfo {
            shortcutBadgeInfo = FeedCardBadgeInfo(type: .icon(Resources.LarkFeedPlugin.badge_at_icon), style: .weak)
        }
        // TODO: open feed. thread不支持置顶
        self.avatarViewModel = FeedCardAvatarViewModel(
            avatarDataSource: avatarDataSource,
            miniIconDataSource: miniIconDataSource,
            miniIconProps: nil,
            badgeInfo: badgeInfo,
            shortcutBadgeInfo: shortcutBadgeInfo,
            positionReversed: positionReversed,
            isBorderVisible: false,
            feedId: feedPreview.id,
            feedCardType: feedPreview.basicMeta.feedCardType)
    }
}
