//
//  FeedGroupBase.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2023/9/4.
//

import Foundation
import LarkModel
import RustPB
import LKCommonsTracker
import LarkFeedBase
import LarkOpenFeed

extension FeedTracker {
    struct Group {
        // TODO: open feed tea埋点以及日志打印
        static func Name(groupType: Feed_V1_FeedFilter.TypeEnum) -> String {
            FeedGroupData.name(groupType: groupType)
        }

        public static func Groups(belongedTab: Feed_V1_FeedFilter.TypeEnum, targetTab: Feed_V1_FeedFilter.TypeEnum) -> [AnyHashable: Any] {
            var params: [AnyHashable: Any] = [:]
            params["belonged_tab"] = FeedTracker.Group.Name(groupType: belongedTab)
            params["target_tab"] = FeedTracker.Group.Name(groupType: targetTab)
            return params
        }
    }
}
