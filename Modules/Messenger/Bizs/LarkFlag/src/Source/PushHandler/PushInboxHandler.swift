//
//  PushInboxHandler.swift
//  LarkFlag
//
//  Created by phoenix on 2022/6/1.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel

final class PushInboxHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? {
        try? userResolver.userPushCenter
    }

    func process(push message: Feed_V1_PushInboxCardsResponse) throws {
        guard let pushCenter = self.pushCenter else { return }
        var updateFeeds: [String: PushUpdateFeedInfo] = [:]
        var errorFeeds: [FeedPreview] = []
        message.updateEntityPreviews.forEach { (_: String, feedEntityPreview: Feed_V1_FeedEntityPreview) in
            let feed = FeedPreview.transformByEntityPreview(feedEntityPreview)
            guard let types = message.updateFilterList[feed.id]?.type else {
                errorFeeds.append(feed)
                return
            }
            let transformTypes = types.map({ return FlagFeedFilterType.transform(number: $0.filterType.rawValue) })
            let pushFeedInfo = PushUpdateFeedInfo(feedPreview: feed, types: transformTypes)
            updateFeeds[feed.id] = pushFeedInfo
        }

        let removeFeeds = message.removePreviews.map({ PushRemoveFeedInfo(feedId: $0.id) })
        var filtersInfo: [Feed_V1_FeedFilter.TypeEnum: FlagPushFeedFilterInfo] = [:]
        message.updateFilterInfos.forEach({ filterInfo in
            filtersInfo[filterInfo.type.filterType] = FlagPushFeedFilterInfo.transform(filterInfo)
        })

        let pushFeedMessage = PushFeedMessage(updateFeeds: updateFeeds,
                                              removeFeeds: removeFeeds,
                                              filtersInfo: filtersInfo)
        pushCenter.post(pushFeedMessage)
    }
}
