//
//  RustFlagAPI.swift
//  LarkSDK
//
//  Created by phoenix on 2022/5/9.
//

import Foundation
import RxSwift
import RustPB
import ServerPB
import LarkModel
import LarkSDKInterface
import LarkContainer
import LarkAccountInterface

final class RustFlagAPI: LarkAPI, FlagAPI {

    private let pushCenter: PushNotificationCenter
    private let currentChatterId: String

    init(pushCenter: PushNotificationCenter,
         currentChatterId: String,
         client: SDKRustService,
         onScheduler: ImmediateSchedulerType? = nil) {
        self.pushCenter = pushCenter
        self.currentChatterId = currentChatterId
        super.init(client: client, onScheduler: onScheduler)
    }

    func updateChat(isFlaged: Bool, chatId: String) -> Observable<Void> {
        var item: ServerPB_Feed_FlagItem = ServerPB_Feed_FlagItem()
        let flagType: ServerPB.ServerPB_Feed_FlagItem.FlagType = .feed
        let entityType: Basic_V1_FeedCard.EntityType = .chat
        let itemType = entityType.rawValue
        item.flagType = Int32(flagType.rawValue)
        item.itemType = Int32(itemType)
        item.itemID = Int64(chatId) ?? 0
        return self.updateItems(isFlaged: isFlaged, flagItems: [item])
    }

    func updateMessage(isFlaged: Bool, messageId: String) -> Observable<Void> {
        var item: ServerPB_Feed_FlagItem = ServerPB_Feed_FlagItem()
        let flagType: ServerPB.ServerPB_Feed_FlagItem.FlagType = .message
        item.flagType = Int32(flagType.rawValue)
        item.itemType = Int32(0)
        item.itemID = Int64(messageId) ?? 0
        return self.updateItems(isFlaged: isFlaged, flagItems: [item])
    }

    func updateFeed(isFlaged: Bool, feedId: String, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        var item: ServerPB_Feed_FlagItem = ServerPB_Feed_FlagItem()
        let flagType: ServerPB.ServerPB_Feed_FlagItem.FlagType = .feed
        let itemType = entityType.rawValue
        item.flagType = Int32(flagType.rawValue)
        item.itemType = Int32(itemType)
        item.itemID = Int64(feedId) ?? 0
        return self.updateItems(isFlaged: isFlaged, flagItems: [item])
    }

    internal func updateItems(isFlaged: Bool, flagItems: [ServerPB.ServerPB_Feed_FlagItem]) -> Observable<Void> {
        var request = ServerPB.ServerPB_Feed_UpdateFlagsRequest()
        if isFlaged {
            request.items = flagItems
        } else {
            request.deletedItems = flagItems
        }
        return self.client.sendPassThroughAsyncRequest(request, serCommand: ServerPB_Improto_Command.updateFlags)
    }

    func getFlags(cursor: Feed_V1_FeedCursor?, count: Int = 20, sortingRule: Feed_V1_FlagSortingRule = .default) -> Observable<GetFlagsResult> {
        var request = RustPB.Feed_V1_GetFlagsRequest()
        if let cursor = cursor {
            request.cursor = cursor
        } else {
            request.cursor = Feed_V1_FeedCursor.max
        }
        request.count = Int32(count)
        request.flagSortingRule = sortingRule
        return self.client.sendAsyncRequest(request, transform: { (response: GetFlagsResponse) -> GetFlagsResult in
            let flags = response.flags
            let flagFeeds = response.flagFeeds
            let flagMessages = response.flagMessages
            let nextCursor = response.nextCursor
            return GetFlagsResult(flags: flags, flagFeeds: flagFeeds, flagMessages: flagMessages, nextCursor: nextCursor)
        }).subscribeOn(scheduler)
    }
}
