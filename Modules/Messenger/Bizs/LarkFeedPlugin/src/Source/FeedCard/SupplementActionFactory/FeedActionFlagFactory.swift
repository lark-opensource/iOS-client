//
//  FeedActionFlagFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/6/28.
//

import Homeric
import LarkModel
import LarkOpenFeed
import LarkSDKInterface
import LKCommonsTracker
import RustPB
import RxSwift
import UniverseDesignDialog
import UniverseDesignIcon
import UniverseDesignToast

final class FeedActionFlagFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .flag
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionFlagViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionFlagHandler(type: type, model: model, context: context)
    }
}

final class FeedActionFlagViewModel: FeedActionViewModelInterface {
    let title: String
    let contextMenuImage: UIImage
    let swipeEditImage: UIImage?
    let swipeBgColor: UIColor?
    init(model: FeedActionModel) {
        self.title = model.feedPreview.basicMeta.isFlaged ? BundleI18n.LarkFeedPlugin.Lark_IM_MarkAMessageToArchive_CancelButton :
                                                  BundleI18n.LarkFeedPlugin.Lark_IM_MarkAMessageToArchive_Button
        self.contextMenuImage = model.feedPreview.basicMeta.isFlaged ? Resources.LarkFeedPlugin.flagUnavailableOutlined :
                                                             Resources.LarkFeedPlugin.flagOutlined
        let flagImage = UDIcon.getIconByKey(.flagOutlined,
                                            iconColor: UIColor.ud.primaryOnPrimaryFill,
                                            size: CGSize(width: 18, height: 18))
        let unFlagImage = UDIcon.getIconByKey(.flagUnavailableOutlined,
                                              iconColor: UIColor.ud.primaryOnPrimaryFill,
                                              size: CGSize(width: 18, height: 18))
        self.swipeEditImage = model.feedPreview.basicMeta.isFlaged ? unFlagImage : flagImage
        self.swipeBgColor = UIColor.ud.R600
    }
}

final class FeedActionFlagHandler: FeedActionHandler {
    private let disposeBag = DisposeBag()
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        self.willHandle()

        let toMark = !model.feedPreview.basicMeta.isFlaged
        // 标记Feed：如果是话题消息（msgThread）的话要特殊处理下
        var entityType = model.feedPreview.basicMeta.feedPreviewPBType
        let threadType = model.feedPreview.preview.threadData.entityType
        if entityType == .thread, threadType == .msgThread {
            entityType = .msgThread
        }
        let feedAPI = try? context.userResolver.resolve(assert: FeedAPI.self)
        feedAPI?.flagFeedCard(model.feedPreview.id, isFlaged: toMark, entityType: entityType)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.didHandle()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.didHandle(error: error)
            }).disposed(by: self.disposeBag)
    }

    override func handleResultByDefault(error: Error?) {
        if error == nil {
            let toMark = !model.feedPreview.basicMeta.isFlaged
            guard let window = model.fromVC?.view.window else { return }
            UDToast.showTips(with: toMark ? BundleI18n.LarkFeedPlugin.Lark_IM_Marked_Toast : BundleI18n.LarkFeedPlugin.Lark_IM_Marked_Unmakred_Toast,
                             on: window)
        } else {
            guard let window = model.fromVC?.view.window,
                  let apiError = error?.underlyingError as? APIError else { return }
            let message = BundleI18n.LarkFeedPlugin.Lark_Core_Label_ActionFailed_Toast
            UDToast.showFailure(with: message, on: window, error: apiError)
        }
    }
}
