//
//  ShortcutExpandMoreViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/17.
//

import Foundation
import LarkModel
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkBadge
import LarkFeedBase

final class ShortcutExpandMoreViewModel {

    // 是否显示的状态相关
    private var displayRelay = BehaviorRelay<Bool>(value: false)
    var displayDriver: Driver<Bool> {
        return displayRelay.asDriver().distinctUntilChanged()
    }

    // 收起/展开的状态相关
    private var expandedSubject = PublishSubject<Bool>()
    var expandedObservable: Observable<Bool> {
        return expandedSubject.asObservable().distinctUntilChanged()
    }

    // 更新badge的信号
    private var updateContentSubject = PublishSubject<Void>()
    var updateContentObservable: Observable<Void> {
        return updateContentSubject.asObservable()
    }

    //「更多」按钮是否显示
    private(set) var display: Bool = false

    //「更多」按钮是否展开
    private(set) var isExpanded: Bool = false

    // 关于 badge 的数据
    private(set) var badgeInfo = FeedCardBadgeInfo.default()

    var name: String {
        display ? (isExpanded ? BundleI18n.LarkFeed.Lark_Feed_QuickSwitcherFold : BundleI18n.LarkFeed.Lark_Feed_QuickSwitcherUnfold) : ""
    }
}

extension ShortcutExpandMoreViewModel {
    // 更新 ExpandMoreViewModel
    func update(_ moreShortcuts: [ShortcutCellViewModel], expanded: Bool) {

        var totalBadgeNumber = 0 //badge总数
        var remindBadgeNumber = 0 //提醒的badge数
        var deRemindBadgeNumber = 0 //不提醒的badge数
        var hasAtBadge: Bool = false //是否有At消息

        for shortcut in moreShortcuts {
            let singleItemBadgeNumber = shortcut.unreadCount
            totalBadgeNumber += singleItemBadgeNumber
            if shortcut.isRemind {
                remindBadgeNumber += singleItemBadgeNumber
            } else {
                deRemindBadgeNumber += singleItemBadgeNumber
            }
            if shortcut.hasAtInfo {
                hasAtBadge = true
            }
        }

        var badge = FeedCardBadgeInfo.default()
        if hasAtBadge {
            badge = FeedCardBadgeInfo(type: .icon(Resources.badge_at_icon), style: .weak)
        } else if totalBadgeNumber > 0 {
            if remindBadgeNumber > 0 {
                badge = FeedCardBadgeInfo(type: .label(.number(remindBadgeNumber)), style: .strong)
            } else if deRemindBadgeNumber > 0 {
                switch FeedBadgeBaseConfig.badgeStyle {
                case .weakRemind:
                    badge = FeedCardBadgeInfo(type: .label(.number(deRemindBadgeNumber)), style: .weak)
                @unknown default:
                    badge = FeedCardBadgeInfo(type: .dot(.lark), style: .strong)
                }
            }
        }

        self.badgeInfo = badge
        self.display = !moreShortcuts.isEmpty // 首行需要空出出一个位置给「更多」按钮
        self.isExpanded = expanded

        FeedContext.log.info("feedlog/shortcut/dataflow/output/expand. "
                             + "moreShortcuts.count: \(moreShortcuts.count), "
                             + "display: \(self.display), "
                             + "totalBadgeCount: \(totalBadgeNumber), "
                             + "remindBadgeCount: \(remindBadgeNumber), "
                             + "deRemindBadgeCount: \(deRemindBadgeNumber), "
                             + "hasAt: \(hasAtBadge), "
                             + "isExpanded: \(isExpanded)")
        fireRefresh()
    }

    private func fireRefresh() {
        displayRelay.accept(display)
        expandedSubject.onNext(isExpanded)
        updateContentSubject.onNext(())
    }
}
