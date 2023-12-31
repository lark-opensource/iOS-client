//
//  AtAllSetting.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/12/2.
//

import Foundation
import LarkSetting
import RustPB
import LarkContainer

public struct FeedAtAllSetting {
    let groupSetting: FeedGroupSetting
    let timeout: Int
    let secondryLabel: Bool
    let secondryTeam: Bool
    init(groupSetting: FeedGroupSetting = FeedGroupSetting(feedGroupMap: [:]),
         timeout: Int = 0,
         secondryLabel: Bool = false,
         secondryTeam: Bool = false) {
        self.groupSetting = groupSetting
        self.timeout = timeout
        self.secondryLabel = secondryLabel
        self.secondryTeam = secondryTeam
    }

    static func get(userResolver: UserResolver) -> FeedAtAllSetting {
        guard let settingJson = FeedSetting(userResolver).getSettingJson(key: .make(userKeyLiteral: "im_feed_at_all_528")) else {
            return FeedAtAllSetting()
        }
        let timeout: Int
        if let extra = settingJson["extra"] as? [String: Any], let atimeout = extra["timeout_mobile"] as? Int {
            timeout = atimeout
        } else {
            timeout = 1000
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
        let groupSetting = FeedSetting(userResolver).getFeedGroupSetting(settingJson: settingJson)
        return FeedAtAllSetting(groupSetting: groupSetting,
                              timeout: timeout,
                              secondryLabel: secondryLabel,
                              secondryTeam: secondryTeam)
    }
}

extension FeedGroupSetting {
    func mockCheckAtAll(type: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        if [.p2PChat, .bot, .helpDesk, .groupChat].contains(type) {
            return true
        }
        return false
    }
}
