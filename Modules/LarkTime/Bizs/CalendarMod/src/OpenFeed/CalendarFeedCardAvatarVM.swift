//
//  CalendarFeedCardAvatarVM.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/8/17.
//

import Foundation
import LarkOpenFeed
import LarkFeedBase
import LarkModel
import LarkBadge
import RustPB
import UniverseDesignColor
import LarkContainer
import LarkBizAvatar
import UniverseDesignIcon

final class CalendarFeedCardAvatarVM: FeedCardAvatarVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .avatar
    }

    // VM 数据
    let avatarViewModel: FeedCardAvatarViewModel

    // 在子线程生成view data
    required init(feedPreview: FeedPreview, userResolver: UserResolver) {
        let badgeInfo = FeedCardAvatarUtil.getBadgeInfo(feedPreview: feedPreview)
        self.avatarViewModel = FeedCardAvatarViewModel(
            avatarDataSource: .local(CalendarFeedCardAvatarVM.getCalendarFeedAvatar()),
            miniIconDataSource: nil,
            miniIconProps: nil,
            badgeInfo: badgeInfo,
            shortcutBadgeInfo: badgeInfo,
            positionReversed: false,
            isBorderVisible: false,
            feedId: feedPreview.id,
            feedCardType: feedPreview.basicMeta.feedCardType)
    }

    static func getCalendarFeedAvatar() -> UIImage {
        if let icon = UDIcon.feedEventFilled.ud.resized(to: CGSize(width: 24, height: 24)).colorImage(UDColor.staticWhite) {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: 48, height: 48), false, 0)
            let context = UIGraphicsGetCurrentContext()
            context?.setFillColor(UDColor.orange.cgColor)
            context?.fill(CGRect(x: 0, y: 0, width: 48, height: 48))
            icon.draw(in: CGRect(x: 12, y: 12, width: 24, height: 24))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image ?? icon
        } else {
            return UDIcon.feedEventFilled.ud.resized(to: CGSize(width: 24, height: 24))
        }
    }
}
