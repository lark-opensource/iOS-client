//
//  MomentsFeedContainerViewController+NaviBar.swift
//  Moment
//
//  Created by liluobin on 2021/4/19.
//

import UIKit
import Foundation
import AnimatedTabBar
import RxSwift
import RxRelay
import LarkUIKit
import UniverseDesignBadge
import LarkMessengerInterface
import EENavigator
import LarkFeatureGating
import UniverseDesignIcon
import UniverseDesignColor
import LarkSetting

extension MomentsFeedContainerViewController: LarkNaviBarDataSource {
    var isDrawerEnabled: Bool {
        return true
    }

    var isDefaultSearchButtonDisabled: Bool {
        return false
    }

    // 显示统一导航栏
    var isNaviBarEnabled: Bool {
        return true
    }
    func larkNavibarBgColor() -> UIColor? {
        return UIColor.ud.bgBody
    }

    // Title
    var titleText: BehaviorRelay<String> {
        return .init(value: BundleI18n.Moment.Lark_Community_CommunityCustomize(MomentTab.tabTitle()))
    }

    var useNaviButtonV2: Bool { return true }
    func larkNaviBarV2(userDefinedButtonOf type: LarkNaviButtonTypeV2) -> UIButton? {
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.search.icon") ?? false

        if type == .first {
            guard fgValue else { return nil }
            //搜索
            let button = UIButton()
            button.setImage(UDIcon.searchOutlineOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
            button.addTarget(self, action: #selector(onSearchButtonTapped), for: .touchUpInside)
            return button
        }
        if type == .second {
            return showUserButton()
        }
        if type == .third {
            if let badgeNoti = self.viewModel.badgeNoti {
                let badgeCount = badgeNoti.currentBadge
                Self.logger.info("badgeNoti messageCount -- \(badgeCount.messageCount) -- reactionCount \(badgeCount.reactionCount)")
                currentAccountIconBadge = showBadgeButton.setupBadge(messageCount: badgeCount.messageCount, reactionCount: badgeCount.reactionCount)
            }
            return showBadgeButton
        }
        if type == .fourth,
           !(self.momentsAccountService?.getMyOfficialUsers() ?? []).isEmpty {
            if let badgeNoti = self.viewModel.badgeNoti {
                var badgeCount: Int = 0
                if let currentBadgeInfo = badgeNoti.currentBadgeInfo {
                    badgeCount = self.momentsAccountService?.getOtherUsersTotalBadgeCount(currentBadgeInfo) ?? 0
                }
                Self.logger.info("changeAccountButton badgeNoti setupBadge -- \(badgeCount)")
                accountSwitcherIconBadge = changeAccountButton.setupBadge(count: badgeCount)
            }
            return changeAccountButton
        }
        return nil
    }

    func showUserButton() -> UIButton {
        let button = UIButton()
        button.addTarget(self, action: #selector(userProfileClick), for: .touchUpInside)
        button.setImage(Resources.iconUserProfile, for: .normal)
        return button
    }
}

extension MomentsFeedContainerViewController: LarkNaviBarDelegate {
    func onDefaultAvatarTapped() {
    }

    func onTitleViewTapped() {
    }

    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        if type == .search {
            let body = SearchMainBody(topPriorityScene: nil, sourceOfSearch: .moments)
            userResolver.navigator.push(body: body, from: self)
        }
    }
}

extension MomentsFeedContainerViewController: LarkNaviBarAbility { }
