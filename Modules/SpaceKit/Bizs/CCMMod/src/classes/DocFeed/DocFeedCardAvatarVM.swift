//
//  DocFeedCardAvatarVM.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/5/29.
//
#if MessengerMod
import Foundation
import LarkOpenFeed
import LarkFeedBase
import LarkModel
import LarkBadge
import RustPB
import UniverseDesignColor
import LarkContainer
import LarkBizAvatar

final class DocFeedCardAvatarVM: FeedCardAvatarVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .avatar
    }

    // VM 数据
    let avatarViewModel: FeedCardAvatarViewModel

    // 在子线程生成view data
    required init(feedPreview: FeedPreview, userResolver: UserResolver) {
        let docsModel = DocsIconBinderModel(
            iconInfo: feedPreview.preview.docData.iconInfo,
            docsUrl: feedPreview.preview.docData.docURL,
            docType: feedPreview.preview.docData.docType,
            userResolver: userResolver)
        let badgeInfo = FeedCardAvatarUtil.getBadgeInfo(feedPreview: feedPreview)
        var shortcutBadgeInfo = badgeInfo
        if feedPreview.uiMeta.mention.hasAtInfo {
            shortcutBadgeInfo = FeedCardBadgeInfo(type: .icon(BundleResources.CCMMod.Feed.badge_at_icon), style: .weak)
        }
        self.avatarViewModel = FeedCardAvatarViewModel(
            avatarDataSource: .custom(docsModel),
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
#endif
