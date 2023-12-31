//
//  FeedMsgDisplayMoreSettingDependency.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/29.
//

import Foundation
protocol FeedMsgDisplayMoreSettingDependency {
    func getLabelRules() -> [FeedMsgDisplayFilterItem]
    func updateLabelRuleItem(_ item: FeedMsgDisplayFilterItem)
    func saveChangedLabelRuleItems()
}

extension FeedMsgDisplayMoreSettingDependency {
    func getLabelRules() -> [FeedMsgDisplayFilterItem] { return [] }
    func updateLabelRuleItem(_ item: FeedMsgDisplayFilterItem) {}
    func saveChangedLabelRuleItems() {}
}
