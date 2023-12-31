//
//  ThreadFeedActionJumpFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/17.
//

import LarkModel
import LarkOpenFeed
import LarkAccountInterface
import LarkMessengerInterface
import RustPB
import LarkUIKit

final class ThreadFeedActionJumpFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .jump
    }

    var bizType: FeedPreviewType? {
        return .thread
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return ThreadFeedActionJumpHandler(type: type, model: model, context: context)
    }
}

final class ThreadFeedActionJumpHandler: FeedActionHandler {
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let vc = model.fromVC ?? context.feedContextService.page else { return }
        self.willHandle()
        self.routerToThread(feedPreview: model.feedPreview, from: vc)
        self.didHandle()
    }

    private func routerToThread(feedPreview: FeedPreview,
                                from: UIViewController) {
        let context: [String: Any] = [FeedSelection.contextKey: FeedSelection(feedId: feedPreview.id)]
        if feedPreview.preview.threadData.entityType == .msgThread {
            /// 从feed进入，需要定位到未读的消息
            let body = ReplyInThreadByIDBody(threadId: feedPreview.id,
                                             loadType: .unread,
                                             sourceType: .feed)
            self.context.userResolver.navigator.showDetailOrPush(body: body,
                                                                 context: context,
                                                                 wrap: LkNavigationController.self,
                                                                 from: from)

        } else {
            let body = ThreadDetailByIDBody(threadId: feedPreview.id,
                                            loadType: .unread,
                                            sourceType: .feed)
            self.context.userResolver.navigator.showDetailOrPush(body: body,
                                                                 context: context,
                                                                 wrap: LkNavigationController.self,
                                                                 from: from)
        }
    }
}
