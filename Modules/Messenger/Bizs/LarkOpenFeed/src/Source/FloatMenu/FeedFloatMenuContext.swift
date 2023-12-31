//
//  FeedFloatMenuContext.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2022/11/29.
//

import EENavigator
import LarkContainer
import LarkOpenIM
import RxSwift
import Swinject

public final class FeedFloatMenuContext: BaseModuleContext {
    public let feedContext: FeedContextService
    public let dispose = DisposeBag()

    public init(parent: Container,
                store: Store,
                userStorage: UserStorage,
                compatibleMode: Bool,
                feedContext: FeedContextService) {
        self.feedContext = feedContext
        super.init(parent: parent, store: store, userStorage: userStorage, compatibleMode: compatibleMode)
    }
}
