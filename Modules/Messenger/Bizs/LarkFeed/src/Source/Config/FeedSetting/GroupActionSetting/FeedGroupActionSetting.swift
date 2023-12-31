//
//  FeedGroupActionSetting.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/11/9.
//

import Foundation
import LarkSetting
import RustPB

public extension FeedSetting {
    struct FeedGroupActionSetting {
        let groupSetting: FeedGroupSetting
        public let msgTab: Bool
        let secondryLabel: Bool
        let secondryTeam: Bool
        init(groupSetting: FeedGroupSetting = FeedGroupSetting(feedGroupMap: [:]),
             msgTab: Bool = false,
             secondryLabel: Bool = false,
             secondryTeam: Bool = false) {
            self.groupSetting = groupSetting
            self.msgTab = msgTab
            self.secondryLabel = secondryLabel
            self.secondryTeam = secondryTeam
        }
    }
}
