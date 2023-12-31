//
// Created by bytedance on 2020/5/20.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB
import LarkRustClient

class InboxCardsTwoUpdatesOneDeleteMockFeedAPI: ChatCellMockFeedAPI {
    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()

        // 冷启动必然调用这个，在这里启动timer，隔20s触发一条message
        // 注意，下面即该test case所覆盖的修改内容，注意阅读，要生成 >= 6 个Feeds才可以
        let updateTimer = Timer(timeInterval: 20, repeats: false) { [weak self] _ in
            guard let self = self else {
                return
            }

            // fire timer - 注意，下面的第x个是被generated的顺序，不代表tableview中的顺序，所以这里就取了4-5-6，可以避免疑惑
            var response = Feed_V1_PushInboxCardsResponse()

            // app icon是以filteredUnreadCount为准 (FeedListViewController tabEntry? 被设置时
            // LkTabbarController 会把各tabs的number合并计算，传给 totalMainBadge，然后被传递到 applicationBadgeIconNumber上
            //response.unreadCount = 53  // app home icon badge num - 误导，没有用了

            // 这个在handler里面被过滤掉了...
            //response.newBoxCount = 5

            // 更新messenger tab上的未读数为32
            response.filteredUnreadCount = 32

            // 仅在filteredUnreadCount - miniAppCount == 0的时候，才发挥作用，被设置在tab上
            response.filteredMuteUnreadCount = 0

            // - 更新status中的稍后阅读
            response.delayedChannelCount = 7

            var updates = [String: FeedCardPreview]()

            // 更新第4个feed到top
            var cardToUpdate1 = self.feedsGenerated[3]
            cardToUpdate1.localizedDigestMessage = "Hey, I was updated... incl. unreadCount"
            cardToUpdate1.unreadCount = 89
            let cardUpdateTime = Int64(Date().timeIntervalSince1970)
            cardToUpdate1.rankTime = cardUpdateTime
            cardToUpdate1.displayTime = cardUpdateTime

            // 更新第5个feed中的内容，但是不改变位置
            var cardToUpdate2 = self.feedsGenerated[4]
            cardToUpdate2.localizedDigestMessage = "Hey, I was updated too"
            cardToUpdate2.isRemind = true
            cardToUpdate2.unreadCount = 31

            updates[cardToUpdate1.pair.id] = cardToUpdate1
            updates[cardToUpdate2.pair.id] = cardToUpdate2

            response.updatePreviews = updates

            // 删除第6个feed
            let pairToDelete = self.feedsGenerated[5].pair
            response.removePreviews = [pairToDelete]

            MockInterceptionManager.shared.postMessage(command: .pushInboxCards, message: response)
        }

        RunLoop.main.add(updateTimer, forMode: .common)

        return ret
    }
}
