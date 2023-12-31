//
//  GetDelayedFeedCardsMockAPI.swift
//  Lark
//
//  Created by 夏汝震 on 2020/6/1.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB
import LarkRustClient

class GetDelayedFeedCardsMockAPI: ChatCellMockFeedAPI {

    // status状态栏上的【稍后处理】按钮是通过push来进行管理的
    // 发现一种情况：直接push消息不会触发显示稍后处理按钮的逻辑，延迟发送消息会触发
    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()
        let updateTimer = Timer(timeInterval: 1, repeats: false) { _ in
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
            card.isDelayed = true
            updates[card.pair.id] = card
            response.updatePreviews = updates
            response.filteredUnreadCount = 32
            response.filteredMuteUnreadCount = 2
            response.delayedChannelCount = 7 // 显示status栏上的按钮逻辑由该字段控制
            MockInterceptionManager.shared.postMessage(command: .pushInboxCards, message: response)
        }
        RunLoop.main.add(updateTimer, forMode: .common)
        return ret
    }

    // 【稍后处理】页面通过下面的接口获取列表数据
    override func getDelayedFeedCards() -> Observable<[FeedCardPreview]> {
        _ = super.getDelayedFeedCards()
        return Observable<[FeedCardPreview]>.create { ob in
            var card = MockFeedsGenerator.getRandomFeed(.inbox, 0)
            card.pair = MockFeedsGenerator.getRandomPairWithType(.chat)
            card.localizedDigestMessage = "I am in markLater list"
            card.isDelayed = true
            ob.onNext([card])
            return Disposables.create()
        }
    }
}
