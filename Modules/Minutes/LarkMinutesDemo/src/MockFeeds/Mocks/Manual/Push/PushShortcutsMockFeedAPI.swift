//
// Created by bytedance on 2020/5/21.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB
import LarkRustClient

class PushShortcutsMockFeedAPI: LoadShortcutsMockFeedAPI {
    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()

        let pushTimer = Timer(timeInterval: 20, repeats: false) { _ in
            // 推送3个shortcuts替换顶部
            let pushCount = 3

            var message = Feed_V1_PushShortcutsResponse()

            var shortcuts = [Shortcut]()
            var previews = [String: Feed_V1_FeedCardPreview]()

            for i in 0..<pushCount {
                var shortcut = Shortcut()
                shortcut.position = Int32(i)
                shortcut.channel.id = MockFeedsGenerator.getRandomID(5)
                shortcut.channel.type = Channel.TypeEnum.allCases.randomElement()!

                shortcuts.append(shortcut)

                var preview = MockFeedsGenerator.getRandomFeed(.inbox, i)
                preview.pair = MockFeedsGenerator.getRandomPairWithType(.chat)
                preview.parentCardID = "0"
                preview.name = "Push#\(i)"
                preview.chatType = .p2P
                preview.chatRole = .member

                previews[shortcut.channel.id] = preview
            }

            message.shortcuts = shortcuts
            message.previews = previews

            MockInterceptionManager.shared.postMessage(command: .pushShortcuts, message: message)
        }

        RunLoop.main.add(pushTimer, forMode: .common)

        return ret
    }
}
