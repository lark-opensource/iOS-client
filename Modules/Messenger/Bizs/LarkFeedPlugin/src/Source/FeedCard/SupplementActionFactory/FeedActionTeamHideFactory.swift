//
//  FeedActionTeamHideFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/27.
//

import LarkOpenFeed
import LarkSDKInterface
import LarkUIKit
import LarkMessengerInterface
import RxSwift
import UniverseDesignColor
import UniverseDesignToast

final class FeedActionTeamHideFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .teamHide
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionTeamHideViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionTeamHideHandler(type: type, model: model, context: context)
    }
}

final class FeedActionTeamHideViewModel: FeedActionViewModelInterface {
    let title: String
    let contextMenuImage: UIImage
    let swipeEditImage: UIImage?
    let swipeBgColor: UIColor?
    init(model: FeedActionModel) {
        let showState: Bool
        if let chatItem = model.chatItem {
            showState = !chatItem.isHidden
        } else {
            showState = true
        }
        self.title = showState ? BundleI18n.LarkFeedPlugin.Project_MV_HideRightNow : BundleI18n.LarkFeedPlugin.Project_MV_ShowNow
        self.contextMenuImage = showState ? Resources.LarkFeedPlugin.visibleLockOutlined : Resources.LarkFeedPlugin.visibleOutlined
        self.swipeEditImage = showState ? Resources.LarkFeedPlugin.visibleLockOutlined : Resources.LarkFeedPlugin.visibleOutlined
        self.swipeBgColor = showState ? UIColor.ud.R600 : UIColor.ud.colorfulIndigo
    }
}

final class FeedActionTeamHideHandler: FeedActionHandler {
    private let disposeBag = DisposeBag()
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let chatItem = model.chatItem else { return }
        let showState = !chatItem.isHidden
        let chatId = Int(chatItem.id)
        self.willHandle()

        let feedAPI = try? context.userResolver.resolve(assert: FeedAPI.self)
        feedAPI?.hideTeamChat(chatId: chatId, isHidden: showState)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, let window = self.model.fromVC?.view.window else { return }
                let message = showState ? BundleI18n.LarkFeedPlugin.Project_MV_GroupIsHidden
                                        : BundleI18n.LarkFeedPlugin.Project_MV_GroupIsShown
                UDToast.showSuccess(with: message, on: window)
                self.didHandle()
            }, onError: { [weak self] error in
                guard let self = self, let window = self.model.fromVC?.view.window else { return }
                UDToast.showFailure(with: BundleI18n.LarkFeedPlugin.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                self.didHandle(error: error)
            }).disposed(by: self.disposeBag)
    }
}
