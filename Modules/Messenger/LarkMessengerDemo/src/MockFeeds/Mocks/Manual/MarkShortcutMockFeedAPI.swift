//
//  MarkShortcutMockFeedAPI.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by 袁平 on 2020/5/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import RustPB
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface

/// 通过模拟断网模拟添加/删除置顶失败成功：每30s网络状态反转一次，在添加/删除置顶过程中随机更新Feed
/// 观察Feed左滑的状态以及Toast
class MarkShortcutMockFeedAPI: ChatCellMockFeedAPI {

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

    override func deleteShortcuts(_ shortcuts: [Shortcut]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            guard self.networkAvailable else {
                let err = NSError(domain: "", code: -1, userInfo: nil)
                observer.onError(err)
                return Disposables.create()
            }
            observer.onNext(())
            // pushFeedPreviewOb更新Feed
            self.updateFeed(shortcuts: shortcuts, isShortcut: false)
            // 置顶过程中收到Feed更新
            if Bool.random() {
                self.receiveUpdate()
            }
            return Disposables.create()
        }
    }

    override func createShortcuts(_ shortcuts: [Shortcut]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            guard self.networkAvailable else {
                let err = NSError(domain: "", code: -1, userInfo: nil)
                observer.onError(err)
                return Disposables.create()
            }
            observer.onNext(())
            // pushFeedPreviewOb更新Feed
            self.updateFeed(shortcuts: shortcuts, isShortcut: true)
            // 置顶过程中收到Feed更新
            if Bool.random() {
                self.receiveUpdate()
            }
            return Disposables.create()
        }
    }

    private func updateFeed(shortcuts: [Shortcut], isShortcut: Bool) {
        // pushFeedPreviewOb更新Feed
        let feeds = self.feedsGenerated.filter { (feed) -> Bool in
            return shortcuts.contains(where: { $0.channel.id == feed.pair.id })
        }.compactMap { (feed) -> FeedCardPreview? in
            var feed = feed
            feed.isShortcut = isShortcut
            return feed
        }
        let message = FeedPreviewResponse(updatePreviews: feeds)
        MockFeedPreviewPushGenerator.shared.post(message: message)
    }

    private func receiveUpdate() {
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
}
