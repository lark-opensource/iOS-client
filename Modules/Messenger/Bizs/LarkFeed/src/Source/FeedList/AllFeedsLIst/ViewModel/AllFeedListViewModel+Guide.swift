//
//  AllFeedListViewModel+Guide.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/9.
//

import Foundation
import LarkFeatureSwitch

extension AllFeedListViewModel {
    /// 是否应该显示Feed引导(At/At All/Badge)
    func feedAtAndBadgeGuideEnabled() -> Bool {
        var guideEnabled = true
        LarkFeatureSwitch.Feature.on(.feedGuide).apply(on: {}, off: { guideEnabled = false })
        return (needShowGuide(key: .feedAtGuide) ||
            needShowGuide(key: .feedAtAllGuide) ||
            needShowGuide(key: .feedBadgeGuide)) &&
            guideEnabled
    }

    /// 是否显示引导
    func needShowGuide(key: GuideKey) -> Bool {
        return allFeedsDependency.needShowNewGuide(guideKey: key.rawValue)
    }
}
