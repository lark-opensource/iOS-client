//
//  UpdateURLTitlePinCardActionHandler.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/30.
//

import Foundation
import LarkUIKit
import LarkOpenChat
import LarkModel
import LarkCore
import UniverseDesignToast
import LarkSDKInterface
import EENavigator
import LKCommonsLogging
import RxSwift
import RxCocoa
import LarkSetting

// 更新卡片标题
final class UpdateURLTitlePinCardActionHandler: ChatPinActionHandler {
    private static let logger = Logger.log(UpdateURLTitlePinCardActionHandler.self, category: "Module.IM.ChatPin")

    private let chatAPI: ChatAPI?
    private let currentChatterId: String
    private let disposeBag = DisposeBag()
    private weak var targetVC: UIViewController?
    private let nav: Navigatable
    private let featureGatingService: FeatureGatingService

    init(targetVC: UIViewController?, chatAPI: ChatAPI?, currentChatterId: String, nav: Navigatable, featureGatingService: FeatureGatingService) {
        self.targetVC = targetVC
        self.chatAPI = chatAPI
        self.currentChatterId = currentChatterId
        self.nav = nav
        self.featureGatingService = featureGatingService
    }

    func handle(pin: ChatPin, chat: Chat) {
        IMTracker.Chat.Sidebar.Click.edit(chat, topId: pin.id)
        guard let targetVC = self.targetVC else { return }

        switch ChatPinPermissionConfig.checkPermission(chat, userID: currentChatterId, featureGatingService: featureGatingService) {
        case .success:
            guard let title = (pin.payload as? URLPreviewChatPinPayload)?.displayTitle,
                  let chatId = Int64(chat.id) else {
                return
            }

            let updateTitleVC = ChatPinUpdateTitleViewController(
                editTitle: title,
                saveHandler: { [weak self] newTitle, targetView, completeHandler in
                    guard let self = self else { return }
                    guard title != newTitle else {
                        Self.logger.info("chatPinCardTrace title not modified chatId: \(chatId)")
                        completeHandler()
                        return
                    }

                    DelayLoadingObservableWraper
                        .wraper(observable: self.chatAPI?.updateURLChatPinTitle(chatId: chatId, pinId: pin.id, title: newTitle) ?? .empty(),
                                delay: 0.3,
                                showLoadingIn: targetView)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] _ in
                            guard let self = self, let targetView = self.targetVC?.view.window else { return }
                            UDToast.showSuccess(with: BundleI18n.LarkChat.Lark_IM_NewPin_EditName_Saved_Toast, on: targetView)
                            completeHandler()
                        }, onError: { [weak targetView] error in
                            guard let targetView = targetView else { return }
                            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_NewPin_ActionFailedRetry_Toast, on: targetView, error: error)
                            Self.logger.error("chatPinCardTrace updateURLChatPinTitle fail chatId: \(chatId)", error: error)
                        }).disposed(by: self.disposeBag)
                }
            )
            self.nav.present(
                updateTitleVC,
                wrap: LkNavigationController.self,
                from: targetVC,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        case .failure(reason: let reason):
            UDToast.showTips(with: reason, on: targetVC.view)
        }
    }
}
