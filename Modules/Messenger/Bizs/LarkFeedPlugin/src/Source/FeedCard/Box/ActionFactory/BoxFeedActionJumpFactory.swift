//
//  BoxFeedActionJumpFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/17.
//

import LarkModel
import LarkOpenFeed
import LarkMessengerInterface
import RustPB
import LarkUIKit

final class BoxFeedActionJumpFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .jump
    }

    var bizType: FeedPreviewType? {
        return .box
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return BoxFeedActionJumpHandler(type: type, model: model, context: context)
    }
}

final class BoxFeedActionJumpHandler: FeedActionHandler {
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let vc = model.fromVC ?? context.feedContextService.page else { return }
        self.willHandle()
        self.routerToBox(feedPreview: model.feedPreview, from: vc)
        self.didHandle()
    }

    private func routerToBox(feedPreview: FeedPreview, from: UIViewController) {
        let id = feedPreview.id
        let body = ChatBoxBody(chatBoxId: id)
        self.context.userResolver.navigator.push(body: body, from: from)
    }
}
