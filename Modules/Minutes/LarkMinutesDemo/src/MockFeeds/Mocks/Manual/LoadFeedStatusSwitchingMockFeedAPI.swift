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

class LoadFeedStatusSwitchingMockFeedAPI: ChatCellMockFeedAPI {
    var toFireCount: Int?  // timer执行倒计次数
    let expectExecTimes = 4  // timer固定执行4次

    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()

        // 每15秒触发一次，inbox start -> inbox end -> done start -> done end
        self.toFireCount = expectExecTimes

        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] timer in
            guard let self = self, let times = self.toFireCount, times > 0 else {
                timer.invalidate()
                return
            }

            let states: [(Basic_V1_FeedCard.FeedType, Feed_V1_PushLoadFeedCardsStatus.Status)] = [
                (.inbox, .start),
                (.inbox, .finished),
                (.done, .start),
                (.done, .finished)
            ]

            let index = self.expectExecTimes - times
            var message = Feed_V1_PushLoadFeedCardsStatus()
            let (feedType, status) = states[index]
            message.feedType = feedType
            message.status = status
            self.toFireCount = times - 1

            MockInterceptionManager.shared.postMessage(command: .pushLoadFeedCardsStatus, message: message)
        }

        RunLoop.main.add(timer, forMode: .common)

        return ret
    }
}
