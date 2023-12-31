//
//  FeedGuideConfig.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2022/11/15.
//

import Foundation
import LarkFeed
import LarkOpenFeed
import LarkFeatureSwitch

protocol FeedGuideConfigService {
    func feedBatchClearBadgeEnabled() -> Bool
}

final class FeedGuideConfigServiceImpl: FeedGuideConfigService {
    let filterDataStore: FilterDataStore
    let feedGuideDependency: FeedGuideDependency

    init(filterDataStore: FilterDataStore,
         feedGuideDependency: FeedGuideDependency) {
        self.filterDataStore = filterDataStore
        self.feedGuideDependency = feedGuideDependency
    }

    func feedBatchClearBadgeEnabled() -> Bool {
        guard FeedSetting(feedGuideDependency.userResolver).gettGroupClearBadgeSetting().msgTab else {
            FeedPluginTracker.log.info("feedlog/guide/batchClearBadge. setting = false")
            return false
        }

        var guideEnabled = true
        LarkFeatureSwitch.Feature.on(.feedGuide).apply(on: {}, off: { guideEnabled = false })
        let needGuide = feedGuideDependency.checkShouldShowGuide(key: GuideKey.feedBatchClearBadgeGuide.rawValue)
        FeedPluginTracker.log.info("feedlog/guide/batchClearBadge. needGuide: \(needGuide), switchGuide: \(guideEnabled), guideEnable: \(needGuide && guideEnabled)")
        return needGuide && guideEnabled
    }
}
