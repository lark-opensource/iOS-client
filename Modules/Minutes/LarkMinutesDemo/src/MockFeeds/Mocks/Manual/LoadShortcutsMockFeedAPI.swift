//
// Created by bytedance on 2020/5/21.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB

class LoadShortcutsMockFeedAPI: MockFeedAPIBaseImpl {

    var shortcuts = [ShortcutResult]()

    override func loadShortcuts(preCount: Int) -> Observable<FeedContextResponse> {
        _ = super.loadShortcuts(preCount: preCount)

        return Observable<FeedContextResponse>.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            self.shortcuts = []
            // 加载置顶是Rust控制返回的数量，preCount 貌似只是告知Rust预加载几个，但不表示要返回preCount个
            let contextID = "mockfeeds_load_shortcuts"

            for i in 0..<self.maxShortcutsLimit {
                var shortcut = Shortcut()
                shortcut.position = Int32(i)
                shortcut.channel.id = MockFeedsGenerator.getRandomID(5)
                shortcut.channel.type = Channel.TypeEnum.allCases.randomElement()!

                var preview = MockFeedsGenerator.getRandomFeed(.inbox, i)
                preview.pair = MockFeedsGenerator.getRandomPairWithType(.chat)
                preview.parentCardID = "0"
                preview.name = "Pos#\(i)"
                preview.chatType = .p2P
                preview.chatRole = .member

                let result = ShortcutResult(shortcut: shortcut, preview: preview)
                self.shortcuts.append(result)
            }

            let ret = (self.shortcuts, contextID)
            observer.onNext(ret)

            return Disposables.create()
        }
    }
}
