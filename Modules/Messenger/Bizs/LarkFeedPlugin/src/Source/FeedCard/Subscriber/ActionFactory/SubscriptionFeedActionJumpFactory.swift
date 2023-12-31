//
//  SubscriptionFeedActionJumpFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/17.
//

import LarkModel
import LarkOpenFeed
import LarkMessengerInterface
import RustPB
import LarkUIKit

final class SubscriptionFeedActionJumpFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .jump
    }

    var bizType: FeedPreviewType? {
        return .subscription
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return SubscriptionFeedActionJumpHandler(type: type, model: model, context: context)
    }
}

final class SubscriptionFeedActionJumpHandler: FeedActionHandler {
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let vc = model.fromVC ?? context.feedContextService.page else { return }
        self.willHandle()
        self.routerToApp(feedPreview: model.feedPreview, from: vc)
        self.didHandle()
    }

    private func routerToApp(feedPreview: FeedPreview,
                                 from: UIViewController) {
        if let url = URL(string: feedPreview.preview.subscriptionsData.schema) {
            // 点击小程序仅进行跳转操作，不选中，连续点击 feed item 都做打开小程序的处理
            let contextData: [String: Any] = [
                FeedSelection.contextKey: FeedSelection(feedId: feedPreview.id),
                "from": "feed",
                "feedInfo": [
                    "appID": feedPreview.id,
                    "type": feedPreview.basicMeta.feedPreviewPBType
                ]
            ]
            self.context.userResolver.navigator.showDetailOrPush(url,
                                                                 context: contextData,
                                                                 wrap: LkNavigationController.self,
                                                                 from: from)
        }
    }
}
