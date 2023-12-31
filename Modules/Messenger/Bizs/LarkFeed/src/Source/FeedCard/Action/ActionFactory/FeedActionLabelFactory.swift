//
//  FeedActionLabelFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/6/28.
//

import Homeric
import LarkOpenFeed
import LarkUIKit
import LKCommonsTracker
import UniverseDesignIcon

final class FeedActionLabelFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .label
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionLabelViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionLabelHandler(type: type, model: model, context: context)
    }
}

final class FeedActionLabelViewModel: FeedActionViewModelInterface {
    let title: String
    let contextMenuImage: UIImage
    var swipeEditImage: UIImage?
    var swipeBgColor: UIColor?
    init(model: FeedActionModel) {
        self.title = BundleI18n.LarkFeed.Lark_Core_LabelTab_Title
        self.contextMenuImage = Resources.label_contextmenu

        self.swipeEditImage = Resources.feed_label_icon
        self.swipeBgColor = UIColor.ud.colorfulWathet
    }
}

final class FeedActionLabelHandler: FeedActionHandler {
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let feedId = Int64(model.feedPreview.id),
              let vc = context.feedContextService.page else { return }
        self.willHandle()

        let feedPreview = model.feedPreview
        let basicData = model.basicData
        let body = AddItemInToLabelBody(feedId: feedId,
                                        infoCallback: { (mode, hasRelation) in
            FeedTracker.Press.Click.CreateOrEditLabel(
                mode: mode,
                hasRelation: hasRelation,
                feedPreview: feedPreview,
                basicData: basicData
            )
        })
        context.userResolver.navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: vc,
            prepare: { $0.modalPresentationStyle = .formSheet })
        self.didHandle()
    }
}
