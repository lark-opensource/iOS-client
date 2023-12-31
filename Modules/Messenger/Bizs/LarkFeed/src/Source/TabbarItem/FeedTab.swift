//
//  FeedTab.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/15.
//

import Foundation
import AnimatedTabBar
import LarkNavigation
import RxCocoa
import LarkTab
import LarkFeedBase
import LKCommonsLogging

final class FeedTab: TabRepresentable {
    static let logger = Logger.log(FeedTab.self, category: "Module.Feed")

    private(set) var badge: BehaviorRelay<BadgeType>?
    private(set) var springBoardBadgeEnable: BehaviorRelay<Bool>?
    private(set) var badgeStyle: BehaviorRelay<BadgeRemindStyle>?

    init() {
        badge = BehaviorRelay<BadgeType>(value: .none)
        springBoardBadgeEnable = BehaviorRelay<Bool>(value: true)
        badgeStyle = BehaviorRelay<BadgeRemindStyle>(value: .weak)
    }

    var tab: Tab {
        .feed
    }

    func updateBadge(pushFeedPreview: PushFeedPreview, showTabMuteBadge: Bool) {
        var badgeType: BadgeType = .none
        let logInfo: String
        guard let inbox = pushFeedPreview.filtersInfo[.inbox] else {
            logInfo = ("cannot find inbox")
            let info = FeedBaseErrorInfo(type: .error(track: false), errorMsg: logInfo)
            FeedExceptionTracker.Tabbar.tabBadge(node: .updateBadge, info: info)
            return
        }
        if inbox.unread > 0 {
            badgeType = .number(inbox.unread)
        } else if inbox.muteUnread > 0 {
            if showTabMuteBadge {
                badgeType = .dot(inbox.muteUnread)
            }
        }
        logInfo = ("unread: \(inbox.unread), muteUnread: \((inbox.muteUnread))")
        FeedContext.log.info("feedlog/tabBadge/updateBadge. \(logInfo)")
        set(badgeType)
    }

    func set(_ badge: BadgeType) {
        Self.logger.info("[NavigationTabBadge] FeedTab update badge: \(badge.description)")
        self.badge?.accept(badge)

        // 只有.number是相加到桌面Badge的
        switch badge {
        case .number: self.springBoardBadgeEnable?.accept(true)
        default: self.springBoardBadgeEnable?.accept(false)
        }

        // style
        let style: BadgeRemindStyle
        switch FeedBadgeBaseConfig.badgeStyle {
        case .strongRemind: style = .strong
        case .weakRemind: style = .weak
        @unknown default:
            assert(false, "new value")
            style = .weak
        }
        Self.logger.info("[NavigationTabBadge] FeedTab update badge Style : \(style.description)")
        self.badgeStyle?.accept(style)
    }
}
