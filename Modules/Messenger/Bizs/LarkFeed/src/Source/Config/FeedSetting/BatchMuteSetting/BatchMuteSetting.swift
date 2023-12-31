//
//  BatchMuteSetting.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/16.
//

import Foundation
import LarkSetting
import RustPB

extension FeedSetting {
    static private let feedGroupMuteActionSettingName = UserSettingKey.make(userKeyLiteral: "im_batch_mute_switch_mobile_526")
    func getFeedMuteActionSetting() -> FeedGroupActionSetting {
        guard let settingJson = getSettingJson(key: Self.feedGroupMuteActionSettingName) else {
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
        return FeedSetting.FeedGroupActionSetting(groupSetting: groupSetting,
                                      msgTab: msgTabEnable,
                                      secondryLabel: secondryLabel,
                                      secondryTeam: secondryTeam)
    }
}

extension FeedGroupSetting {
    func mockCheckMute(type: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        if [.p2PChat, .bot, .helpDesk, .groupChat].contains(type) {
            return true
        }
        return false
    }
}
