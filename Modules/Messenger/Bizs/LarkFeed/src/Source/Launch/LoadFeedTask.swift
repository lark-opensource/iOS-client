//
//  LoadFeedTask.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/8/18.
//

import Foundation
import BootManager
import LarkContainer
import AppContainer
import LarkMessengerInterface
import LarkOpenFeed

// 因为Feed要显示Badge，不能做到viewDidLoad再拉数据
final class LoadFeedTask: UserFlowBootTask, Identifiable {
    static var identify = "LoadFeedTask"
    override class var compatibleMode: Bool { Feed.userScopeCompatibleMode }
    override var scheduler: Scheduler { return .concurrent }

    @ScopedInjectedLazy var preloader: FeedPreloaderService?
    @ScopedInjectedLazy var naviBarViewModel: FeedNavigationBarViewModel?
    @ScopedInjectedLazy var feedSettingStore: FeedSettingStore?

    override func execute(_ context: BootContext) {
        preloader?.preload()
        feedSettingStore?.getFeedActionSetting(forceUpdate: true)
        _ = self.naviBarViewModel
    }
}
