//
//  MarkLaterMockFeedAPI.swift
//  LarkMessengerDemo
//
//  Created by 袁平 on 2020/5/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import LarkModel
import RustPB
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeed

/// 通过模拟断网模拟添加/移除稍后处理失败成功：每30s网络状态反转一次，在添加/移除稍后处理过程中随机更新Feed
/// 观察Feed左滑的状态以及Toast
class MarkLaterMockFeedAPI: ChatCellMockFeedAPI {

    private let maxCount = 30
    private var currentCount = 0
    // 模拟网络状态是否可用
    private var networkAvailable = true

    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()

        // 每30s网络状态反转
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] timer in
            guard let self = self, self.currentCount < self.maxCount else {
                timer.invalidate()
                return
            }
            self.currentCount += 1
            self.networkAvailable.toggle()
            print("networkAvailable = \(self.networkAvailable)")
        }

        RunLoop.main.add(timer, forMode: .common)

        return ret
    }

    override func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedCardPreview> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            // 模拟网络无连接时，稍后处理失败提示
            guard self.networkAvailable else {
                let err = NSError(domain: "Service Not Available", code: -1, userInfo: nil)
                observer.onError(err)
                return Disposables.create()
            }
            if var feed = self.feedsGenerated.first(where: { $0.pair.id == id }) {
                observer.onNext(feed)
                // 发送更新push给pushFeedPreviewOb更新Feed
                feed.isDelayed = isDelayed
                let message = FeedPreviewResponse(updatePreviews: [feed])
                MockFeedPreviewPushGenerator.shared.post(message: message)
                // 随机模拟标记稍后处理过程中收到Feed更新
                if Bool.random() {
                    var updateFeed = self.feedsGenerated.randomElement()!
                    updateFeed.name = "\(updateFeed.name) New"
                    updateFeed.displayTime = Int64(Date().timeIntervalSince1970)
                    updateFeed.rankTime = updateFeed.displayTime
                    updateFeed.updateTime = updateFeed.displayTime
                    let removeFeed = self.feedsGenerated.removeFirst()
                    let message = FeedPreviewResponse(updatePreviews: [updateFeed],
                                                      removePreviews: [removeFeed])
                    MockFeedPreviewPushGenerator.shared.post(message: message)
                }
            } else {
                let err = NSError(domain: "Match No FeedCardPreview", code: -1, userInfo: nil)
                observer.onError(err)
            }
            return Disposables.create()
        }
    }
}
