//
//  FeedActionClearBadgeFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/6/28.
//

import LarkModel
import LarkOpenFeed
import LarkSDKInterface
import RustPB
import RxSwift
import UniverseDesignDialog

final class FeedActionClearBadgeFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .clearBadge
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionClearBadgeViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionClearBadgeHandler(type: type, model: model, context: context)
    }
}

final class FeedActionClearBadgeViewModel: FeedActionViewModelInterface {
    let title: String
    let contextMenuImage: UIImage
    init(model: FeedActionModel) {
        self.title = BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Button
        self.contextMenuImage = Resources.clearUnreadBaged
    }
}

final class FeedActionClearBadgeHandler: FeedActionHandler {
    private let disposeBag = DisposeBag()
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        self.willHandle()
        let feedAPI = try? context.userResolver.resolve(assert: FeedAPI.self)
        if let feedGuideDependency = try? context.userResolver.resolve(assert: FeedGuideDependency.self),
           feedGuideDependency.needShowGuide(key: GuideKey.feedClearBadgeGuide.rawValue),
           let vc = model.fromVC ?? context.feedContextService.page {
            let dialog = UDDialog()
            dialog.setContent(text: BundleI18n.LarkFeed.Lark_Core_DismissSingularChat_Title)
            dialog.addPrimaryButton(text: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_MessagesWontShownAsRead_GotIt_Button)
            vc.present(dialog, animated: true, completion: nil)
            feedGuideDependency.didShowGuide(key: GuideKey.feedClearBadgeGuide.rawValue)
        }
        var feed = Feed_V1_FeedCardBadgeIdentity()
        feed.feedID = model.feedPreview.id
        feed.feedEntityType = model.feedPreview.basicMeta.feedPreviewPBType
        let taskID = UUID().uuidString
        feedAPI?.clearSingleBadge(taskID: taskID, feeds: [feed])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.didHandle()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.didHandle(error: error)
            }).disposed(by: self.disposeBag)
        FeedContext.log.info("feedlog/clearBadge/clearSignleBadge taskID: \(taskID), feedid: \(feed.feedID), feedEntityType: \(feed.feedEntityType.rawValue)")
    }

    override func trackHandle(status: FeedActionStatus) {
        guard let event = model.event else { return }
        if case .willHandle = status {
            if event == .longPress {
                FeedTracker.Press.Click.ClearSingleBadge(
                    feedPreview: model.feedPreview,
                    unreadCount: model.feedPreview.basicMeta.unreadCount,
                    isRemind: model.feedPreview.basicMeta.isRemind,
                    basicData: model.basicData)
            }
        }
    }
}
