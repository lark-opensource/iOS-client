//
//  UnPinCardActionHandler.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/30.
//

import Foundation
import UniverseDesignToast
import LarkContainer
import RxSwift
import RxCocoa
import LarkOpenChat
import LarkModel
import LKCommonsLogging
import LarkSDKInterface
import LarkAlertController
import EENavigator
import LarkCore
import LarkSetting

// 移除 Pin 卡片
final class UnPinCardActionHandler: ChatPinActionHandler {
    private static let logger = Logger.log(UnPinCardActionHandler.self, category: "Module.IM.ChatPin")

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
        IMTracker.Chat.Sidebar.Click.remove(chat, topId: pin.id, messageId: nil, topType: IMTrackerChatPinType(type: pin.type))
        guard let targetVC = self.targetVC, let chatId = Int64(chat.id) else { return }
        switch ChatPinPermissionConfig.checkPermission(chat, userID: currentChatterId, featureGatingService: featureGatingService) {
        case .success:
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkChat.Lark_IM_NewPin_RemoveFromPinned_Title)
            if chat.type != .p2P {
                alertController.setContent(text: BundleI18n.LarkChat.Lark_IM_NewPin_RemoveFromPinned_Desc)
            }
            alertController.addSecondaryButton(text: BundleI18n.LarkChat.Lark_IM_NewPin_RemoveFromPinnedCancel_Button)
            alertController.addDestructiveButton(
                text: BundleI18n.LarkChat.Lark_IM_NewPin_RemoveFromPinnedRemove_Button,
                dismissCompletion: { [weak self] in
                    guard let self = self else { return }
                    self.chatAPI?.deleteChatPin(chatId: chatId, pinId: pin.id)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] _ in
                            guard let targetVC = self?.targetVC else { return }
                            UDToast.showSuccess(with: BundleI18n.LarkChat.Lark_IM_NewPin_RemovedFromPinned_Toast, on: targetVC.view)
                            Self.logger.info("chatPinCardTrace delete pin success chatId: \(chatId) pinId: \(pin.id)")
                        }, onError: { [weak self] error in
                            guard let targetVC = self?.targetVC else { return }
                            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_NewPin_ActionFailedRetry_Toast, on: targetVC.view, error: error)
                            Self.logger.error("chatPinCardTrace delete pin fail chatId: \(chatId) pinId: \(pin.id)", error: error)
                        })
                        .disposed(by: self.disposeBag)
                }
            )
            self.nav.present(alertController, from: targetVC)
        case .failure(reason: let reason):
            UDToast.showTips(with: reason, on: targetVC.view)
        }
    }
}
