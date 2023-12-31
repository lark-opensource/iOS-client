//
//  UpdateShortcutsMockFeedAPI.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by 袁平 on 2020/5/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB
import LarkRustClient

/// case:
///     1. 拖动置顶过程中，删除/更新shortcut
///     2. 置顶展开收起过程中，删除/更新shortcut
/// 发现的问题：拖动困难
class UpdateShortcutsMockFeedAPI: LoadShortcutsMockFeedAPI {
    private let maxCount = 50
    private var currentCount = 0

    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()

        currentCount = maxCount
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] timer in
            guard let self = self, self.currentCount > 0 else {
                timer.invalidate()
                return
            }
            self.currentCount -= 1
            var message = Feed_V1_PushShortcutsResponse()

            var shortcut = Shortcut()
            shortcut.position = Int32(0)
            shortcut.channel.id = MockFeedsGenerator.getRandomID(5)
            shortcut.channel.type = Channel.TypeEnum.allCases.randomElement()!

            var preview = MockFeedsGenerator.getRandomFeed(.inbox, 0)
            preview.pair = MockFeedsGenerator.getRandomPairWithType(.chat)
            preview.parentCardID = "0"
            preview.name = "New#\(self.maxCount - self.currentCount)"
            preview.chatType = .p2P
            preview.chatRole = .member
            self.shortcuts[0] = ShortcutResult(shortcut: shortcut, preview: preview)

            message.shortcuts = self.shortcuts.compactMap({ $0.shortcut })
            var previews = [String: Feed_V1_FeedCardPreview]()
            self.shortcuts.forEach { (result) in
                previews[result.shortcut.channel.id] = result.preview
            }
            message.previews = previews

            MockInterceptionManager.shared.postMessage(command: .pushShortcuts, message: message)
        }

        RunLoop.main.add(timer, forMode: .common)

        return ret
    }
}
