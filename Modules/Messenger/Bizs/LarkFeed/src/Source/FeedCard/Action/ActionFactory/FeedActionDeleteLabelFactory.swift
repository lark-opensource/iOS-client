//
//  FeedActionDeleteLabelFactory.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/7/27.
//

import Homeric
import LarkContainer
import LarkOpenFeed
import LarkSDKInterface
import LKCommonsTracker
import RxSwift

final class FeedActionDeleteLabelFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .deleteLabel
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionDeleteLabelViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionDeleteLabelHandler(type: type, model: model, context: context)
    }
}

final class FeedActionDeleteLabelViewModel: FeedActionViewModelInterface {
    let title: String
    let contextMenuImage: UIImage
    init(model: FeedActionModel) {
        self.title = BundleI18n.LarkFeed.Lark_IM_Labels_RemoveChatFromLabel_Button
        self.contextMenuImage = Resources.delete_label_feed_contextmenu
    }
}

final class FeedActionDeleteLabelHandler: FeedActionHandler {
    private let disposeBag = DisposeBag()
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let feedId = Int64(model.feedPreview.id),
              let labelId = model.labelId else { return }
        self.willHandle()

        let feedAPI = try? context.userResolver.resolve(assert: FeedAPI.self)
        feedAPI?.deleteLabelFeed(feedId: feedId, labelId: labelId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.didHandle()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.didHandle(error: error)
            }).disposed(by: self.disposeBag)
    }

    override func trackHandle(status: FeedActionStatus) {
        guard let event = model.event else { return }
        if case .willHandle = status {
            if event == .longPress {
                FeedTracker.Press.Click.Item(
                    itemValue: FeedActionType.clickTrackValue(type: .deleteLabel, feedPreview: model.feedPreview),
                    feedPreview: model.feedPreview,
                    basicData: model.basicData)
            }
        }
    }
}
