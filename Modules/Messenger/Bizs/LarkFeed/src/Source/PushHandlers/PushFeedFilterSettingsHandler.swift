//
//  PushFeedFilterSettingsHandler.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/31.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel
import LarkSDKInterface

extension FiltersModel: PushMessage {}

final class PushFeedFilterSettingsHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushFeedFilterSettings) throws {
        guard let pushCenter = self.pushCenter else { return }
        var info = "filterEnable: \(message.filterEnable), "
                 + "hasShowMute: \(message.hasShowMute), "
                 + "showMute: \(message.showMute), "
                 + "showAtAllInAtFilter: \(message.showAtAllInAtFilter), "
        info.append("usedFilterInfos: ")
        message.usedFilterInfos.forEach { filter in
            info.append("\(filter.description), ")
        }
        info.append("commonlyUsedFilters: ")
        message.commonlyUsedFilters.forEach { filter in
            info.append("\(filter.description), ")
        }
        info.append("feedRule: \(Feed_V1_DisplayFeedRule.transform(rules: message.filterDisplayFeedRule)), ")
        info.append("feedRuleMd5: \(message.filterDisplayFeedRuleMd5)")
        FeedContext.log.info("feedlog/filter/pushFilterSettings. \(info)")
        let filters = FiltersModel.transform(userResolver: userResolver, message)
        pushCenter.post(filters)
    }
}
