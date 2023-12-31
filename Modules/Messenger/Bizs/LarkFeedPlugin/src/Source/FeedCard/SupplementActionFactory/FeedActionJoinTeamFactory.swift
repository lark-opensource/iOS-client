//
//  FeedActionTeamFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/6/28.
//

import Homeric
import LarkOpenFeed
import LarkUIKit
import LarkMessengerInterface
import LKCommonsTracker

final class FeedActionJoinTeamFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .joinTeam
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionJoinTeamViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionJoinTeamHandler(type: type, model: model, context: context)
    }
}

final class FeedActionJoinTeamViewModel: FeedActionViewModelInterface {
    let title: String
    let contextMenuImage: UIImage
    init(model: FeedActionModel) {
        self.title = BundleI18n.LarkFeedPlugin.Project_T_AddToTeam_MenuItem
        self.contextMenuImage = Resources.LarkFeedPlugin.communityTabOutlined
    }
}

final class FeedActionJoinTeamHandler: FeedActionHandler {
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let vc = model.fromVC ?? context.feedContextService.page else { return }
        self.willHandle()
        let body = EasilyJoinTeamBody(feedpreview: model.feedPreview)
        context.userResolver.navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: vc,
            prepare: { $0.modalPresentationStyle = .formSheet })
        self.didHandle()
    }
}
