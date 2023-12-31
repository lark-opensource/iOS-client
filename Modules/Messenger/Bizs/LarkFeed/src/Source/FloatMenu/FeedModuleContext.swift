//
//  FeedModuleContext.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/11/30.
//

import Foundation
import LarkOpenFeed
import Swinject
import LarkOpenIM
import LarkMessageBase
import AppContainer
import LarkFoundation
import LarkContainer

/// 该Context具备所有ModuleContext需要的能力
final class FeedModuleContext {
    let feedContext: FeedContextService
    var floatMenuContext: FeedFloatMenuContext { return self._floatMenuContext.wrappedValue }
    private var _floatMenuContext: ThreadSafeLazy<FeedFloatMenuContext>

    init(feedContext: FeedContextService) {
        self.feedContext = feedContext
        self._floatMenuContext = ThreadSafeLazy<FeedFloatMenuContext>(value: {
            return FeedFloatMenuContext(parent: BootLoader.container,
                                        store: Store(),
                                        userStorage: feedContext.userResolver.storage,
                                        compatibleMode: feedContext.userResolver.compatibleMode,
                                        feedContext: feedContext)
        })
    }
}
