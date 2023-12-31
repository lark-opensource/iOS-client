//
//  FeedActionJumpFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/12.
//

import LarkOpenFeed

final class FeedActionJumpFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .jump
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionJumpHandler(type: type, model: model)
    }
}

final class FeedActionJumpHandler: FeedActionHandler {
    override func executeTask() {
        self.willHandle()
        self.didHandle()
    }
}
