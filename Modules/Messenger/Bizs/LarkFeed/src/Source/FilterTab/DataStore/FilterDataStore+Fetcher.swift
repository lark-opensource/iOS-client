//
//  FilterDataStore+Fetcher.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/8/18.
//

import Foundation
import LarkContainer

extension FilterDataStore {
    func getFilters(tryLocal: Bool) {
        dependency.getFilters(tryLocal: tryLocal).subscribe(onNext: { [weak self] filter in
            guard let self = self, filter.version > self.version else { return }
            self.updateFilterList(filter)
            self.updateRuleMd5(filter.feedRuleMd5)
        }).disposed(by: disposeBag)
    }

    func bind() {
        dependency.pushFeedFilterSettings.subscribe(onNext: { [weak self] filtersModel in
            guard let self = self, filtersModel.version > self.version else { return }
            self.updateFilterList(filtersModel)
            self.updateRuleMd5(filtersModel.feedRuleMd5)
        }).disposed(by: disposeBag)

        dependency.pushFeedPreview.subscribe(onNext: { [weak self] pushFeedPreview in
            guard let self = self else { return }
            self.updatePushFeed(pushFeedPreview: pushFeedPreview)
            self.updateUnread(pushFeedPreview.filtersInfo)
        }).disposed(by: disposeBag)
    }

    func updateShowMute(_ showMute: Bool) {
        FeedDataQueue.executeOnMainThread { [weak self] in
            guard let self = self else { return }
            self.dependency.updateShowMute(showMute)
        }
    }

    private func updateRuleMd5(_ md5: String) {
        guard Feed.Feature(userResolver).groupSettingEnable else { return }
        guard feedRuleMd5 != md5 else { return }
        feedRuleMd5 = md5
        dependency.saveFeedRuleMd5(md5)
        NotificationCenter.default.post(name: FeedNotification.needReloadMsgFeedList, object: nil, userInfo: nil)
    }
}
