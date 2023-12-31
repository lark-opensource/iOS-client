//
//  OpenAppFeedActionJumpFactory.swift
//  LarkFeedPlugin
//
//  Created by ByteDance on 2023/10/23.
//

import Foundation
import LarkOpenFeed
import LarkModel
import LarkAppLinkSDK
import LarkMessengerInterface
import LarkUIKit

final class OpenAppFeedActionJumpFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .jump
    }

    var bizType: FeedPreviewType? {
        return .openAppFeed
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return OpenFeedActionJumpHandler(type: type, model: model, context: context)
    }
}

final class OpenFeedActionJumpHandler: FeedActionHandler {
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let vc = model.fromVC ?? context.feedContextService.page else { return }
        self.willHandle()
        self.routerToLink(feedPreview: model.feedPreview, from: vc)
        self.didHandle()
    }

    private func routerToLink(feedPreview: FeedPreview, from: UIViewController) {
        let linkData = feedPreview.preview.appFeedCardData.linkData
        guard let url = URL(string: linkData.link) else {
            return
        }
        var context: [String: Any] = [FeedSelection.contextKey: FeedSelection(feedId: feedPreview.id),
                                      "from": "feed",
                                      "showTemporary": false,
                                      "feedInfo": ["appID": feedPreview.id,
                                                   "type": feedPreview.basicMeta.feedPreviewPBType]] as [String: Any]
        self.context.userResolver.navigator.showDetailOrPush(url,
                                                             context: context,
                                                                 wrap: LkNavigationController.self,
                                                                 from: from)
    }
  }
