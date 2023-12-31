//
//  FeedMainViewController+TabbarItemTapProtocol.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import Foundation
import AnimatedTabBar
import RustPB

extension FeedMainViewController: TabbarItemTapProtocol {
    /// 主Feed TabBar双击跳转下一未读逻辑
    func onTabbarItemDoubleTap() {
        guard self.view.window != nil else { return }
        self.moduleVCContainerView.currentListVC?.doubleClickTabbar()
        FeedTeaTrack.trackFeedTap(false)
        FeedTracker.Tab.Click.Double()
    }

    func onTabbarItemTap(_ isSameTab: Bool) {
        FeedTeaTrack.trackFeedTap(true)
    }

    func onTabbarItemLongPress() {
        let filterGroupAction = try? userResolver.resolve(assert: FilterActionHandler.self)
        filterGroupAction?.tryShowFilterActionsSheet(filterType: .inbox, isTab: true, view: nil)
    }
}
