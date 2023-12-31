//
//  FeedDisplayRuleSetting.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/10/10.
//

import Foundation
import LarkSetting
import RustPB

extension FeedSetting {
    static private let feedDisplayRuleSettingName = UserSettingKey.make(userKeyLiteral: "lark_feed_filter_displayrule")

    func getGroupDisplayRuleSetting() -> FeedGroupActionSetting {
        guard let settingJson = getSettingJson(key: Self.feedDisplayRuleSettingName) else {
            return FeedSetting.FeedGroupActionSetting()
        }
        var secondaryTeam: Bool = false
        var secondaryLabel: Bool = false
        if let secondaryFilter = settingJson["secondary_filter"] as? [String: Bool] {
            if let teamEnabled = secondaryFilter["16"] {
                secondaryTeam = teamEnabled
            }
            if let labelEnabled = secondaryFilter["18"] {
                secondaryLabel = labelEnabled
            }
        }
        let groupSetting = getFeedGroupSetting(settingJson: settingJson)
        return FeedSetting.FeedGroupActionSetting(groupSetting: groupSetting,
                                                  secondryLabel: secondaryLabel,
                                                  secondryTeam: secondaryTeam)
    }
}

extension FeedGroupSetting {
    func mockCheckDisplayRule(type: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        if [.inbox, .message, .team, .atMe, .unread, .flag, .done, .delayed].contains(type) {
            return false
        }
        return true
    }
}
