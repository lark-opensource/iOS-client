//
//  AllFeedListViewModel+Bagde.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/25.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface
import RxDataSources
import AnimatedTabBar
import RxCocoa
import ThreadSafeDataStructure
import LarkNavigation
import LarkModel
import LarkTab
import LarkFeedBase

extension AllFeedListViewModel {

    /// 根据Push更新TabBar上的badge
    func updateMainTabBadge(pushFeedPreview: PushFeedPreview) {
        self.tabEntry?.updateBadge(pushFeedPreview: pushFeedPreview, showTabMuteBadge: FeedBadgeBaseConfig.showTabMuteBadge)
    }

    // 显示主导航免打扰badge
    func bindTabMuteBadge() {
        allFeedsDependency.tabMuteBadgeObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateTabBadgeMuteConfig()
            }).disposed(by: disposeBag)
    }

    func updateTabBadgeMuteConfig() {
        if let pushFeedPreview = self.getPushFeed() {
            updateMainTabBadge(pushFeedPreview: pushFeedPreview)
        }
    }

    func updatePushFeed(_ pushFeedPreview: PushFeedPreview) {
        assert(Thread.isMainThread, "pushFeedPreview is only available on main thread")
        self.pushFeedPreview = pushFeedPreview
        self.updateMainTabBadge(pushFeedPreview: pushFeedPreview)
    }

    func getPushFeed() -> PushFeedPreview? {
        assert(Thread.isMainThread, "pushFeedPreview is only available on main thread")
        return self.pushFeedPreview
    }
}
