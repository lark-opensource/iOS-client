//
//  ClearBadgeSetting.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/12.
//

import Foundation
import LarkSetting
import RustPB

public extension FeedSetting {
    static private let feedGroupClearBadgeActionSettingName = UserSettingKey.make(userKeyLiteral: "im_batch_clear_badge_switch_526")
    func gettGroupClearBadgeSetting() -> FeedGroupActionSetting {
        guard let settingJson = getSettingJson(key: Self.feedGroupClearBadgeActionSettingName) else {
            return FeedSetting.FeedGroupActionSetting()
        }
        let msgTabEnable: Bool
        if let otherMaps = settingJson["other"] as? [String: Bool], let navTabEnable = otherMaps["nav_tab"] as? Bool {
            msgTabEnable = navTabEnable
        } else {
            msgTabEnable = false
        }
        let secondryLabel: Bool
        let secondryTeam: Bool

        if let secondaryFilter = settingJson["secondary_filter"] as? [String: Bool] {
            if let teamEnabled = secondaryFilter["16"] as? Bool {
                secondryTeam = teamEnabled
            } else {
                secondryTeam = false
            }
            if let labelEnabled = secondaryFilter["18"] as? Bool {
                secondryLabel = labelEnabled
            } else {
                secondryLabel = false
            }
        } else {
            secondryLabel = false
            secondryTeam = false
        }
        let groupSetting = getFeedGroupSetting(settingJson: settingJson)
        return FeedSetting.FeedGroupActionSetting(
            groupSetting: groupSetting,
            msgTab: msgTabEnable,
            secondryLabel: secondryLabel,
            secondryTeam: secondryTeam)
    }

    func getFeedCardClearBadgeSetting() -> FeedCardSetting {
        guard let settingJson = getSettingJson(key: Self.feedGroupClearBadgeActionSettingName) else {
            return FeedCardSetting(feedCardMap: [:])
        }
        let feedCardSetting = getFeedCardSetting(settingJson: settingJson, feedcardKey: "feedEntitySwitch")
        return feedCardSetting
    }
}

extension FeedGroupSetting {
    func mockCheckClearBadge(feedGroupPBType: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        if [.team, .tag, .flag].contains(feedGroupPBType) {
            return false
        }
        return true
    }

    func mockCheckClearBadge(feedPreviewPBType: RustPB.Basic_V1_FeedCard.EntityType) -> Bool {
        let types: [RustPB.Basic_V1_FeedCard.EntityType] = [.chat, .thread, .docFeed]
        if types.contains(feedPreviewPBType) {
            return false
        }
        return true
    }
}
