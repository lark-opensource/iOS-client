//
//  InboxPushFeedPreviewMockFeedAPI.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by 夏汝震 on 2020/5/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB
import LarkRustClient

enum OperationType: Int {
    case insert = 0, update, delete
}

class InboxPushFeedPreviewMockFeedAPI: ChatCellMockFeedAPI {
    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()
        let updateTimer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            guard let `self` = self else {
                return
            }

            var response: Feed_V1_PushInboxCardsResponse?
            let operationType = InboxPushFeedPreviewMockFeedAPI.randomOperationType()
            switch operationType {
            case .insert:
                response = self.insertCard()
            case .update:
                response = self.updateCard()
            case .delete:
                response = self.deleteCard()
            }

            guard var response1 = response else { return }
            // 更新messenger tab上的未读数为32
            response1.filteredUnreadCount = 32

            // 仅在filteredUnreadCount - miniAppCount == 0的时候，才发挥作用，被设置在tab上
            response1.filteredMuteUnreadCount = 0

            // - 更新status中的稍后阅读
            response1.delayedChannelCount = 7
            MockInterceptionManager.shared.postMessage(command: .pushInboxCards, message: response1)
        }

        RunLoop.main.add(updateTimer, forMode: .common)
        return ret
    }

    func updateCard() -> Feed_V1_PushInboxCardsResponse? {
        let index = self.randomIndex()
        guard index < self.feedsGenerated.count else { return nil }
        var response = Feed_V1_PushInboxCardsResponse()
        var updates = [String: FeedCardPreview]()
        var card = self.feedsGenerated[index]
        card.localizedDigestMessage = "Hey, I was updated... incl. unreadCount"
        card.unreadCount += 1
        let cardUpdateTime = Int64(Date().timeIntervalSince1970)
        card.rankTime = cardUpdateTime
        card.displayTime = cardUpdateTime
        updates[card.pair.id] = card
        response.updatePreviews = updates
        return response
    }

    func insertCard() -> Feed_V1_PushInboxCardsResponse {
        var response = Feed_V1_PushInboxCardsResponse()
        var updates = [String: FeedCardPreview]()
        var card = MockFeedsGenerator.getRandomFeed(.inbox, 0)
        card.pair = MockFeedsGenerator.getRandomPairWithType(.chat)
        card.localizedDigestMessage = "Hey, I was insert... incl. unreadCount"
        card.entityStatus = .unread
        card.unreadCount = 1
        let cardUpdateTime = Int64(Date().timeIntervalSince1970)
        card.rankTime = cardUpdateTime
        card.displayTime = cardUpdateTime
        updates[card.pair.id] = card
        response.updatePreviews = updates
        return response
    }

    func deleteCard() -> Feed_V1_PushInboxCardsResponse? {
        let index = self.randomIndex()
        guard index < self.feedsGenerated.count else { return nil }
        var response = Feed_V1_PushInboxCardsResponse()
        let card = self.feedsGenerated[index].pair
        response.removePreviews = [card]
        return response
    }

    func randomIndex() -> Int {
        return Int(arc4random_uniform(UInt32(self.feedsGenerated.count)))
    }

    class func randomOperationType() -> OperationType {
        return OperationType(rawValue: Int(arc4random_uniform(UInt32(3)))) ?? .insert
    }
}
