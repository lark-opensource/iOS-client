//
//  DocFeedActionJumpFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/17.
//
#if MessengerMod

import LarkModel
import LarkOpenFeed
import LarkMessengerInterface
import RustPB
import LarkUIKit

final class DocFeedActionJumpFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .jump
    }

    var bizType: FeedPreviewType? {
        return .docFeed
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return DocFeedActionJumpHandler(type: type, model: model, context: context)
    }
}

final class DocFeedActionJumpHandler: FeedActionHandler {
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let vc = model.fromVC ?? context.feedContextService.page else { return }
        self.willHandle()
        self.routerToDocs(feedPreview: model.feedPreview, from: vc)
        self.didHandle()
    }

    private func routerToDocs(feedPreview: FeedPreview,
                              from: UIViewController) {
        guard let url = URL(string: feedPreview.preview.docData.docURL) else {
            DocFeedCardModule.logger.error("feedlog/action/cell/tap. doc url transform failed: \(feedPreview.preview.docData.docURL)")
            return
        }
        let contextData: [String: Any] = [
            FeedSelection.contextKey: FeedSelection(feedId: feedPreview.id),
            "from": "docs_feed",
            "infos": [
                "feed_id": feedPreview.id,
                "doc_type": String(feedPreview.preview.docData.docType.rawValue),
                "doc_message_type": String(feedPreview.preview.docData.docMessageType.rawValue),
                "unread_count": String(feedPreview.basicMeta.unreadCount),
                "last_doc_message_id": feedPreview.preview.docData.lastDocMessageID
            ],
            "showTemporary": false
        ]
        self.context.userResolver.navigator.showDetailOrPush(url,
                                                             context: contextData,
                                                             wrap: LkNavigationController.self,
                                                             from: from)
    }
}
#endif
