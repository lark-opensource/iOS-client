//
//  UnStickToTopActionHandler.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/8/15.
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

/// 取消固定到首位
final class UnStickToTopActionHandler: ChatPinActionHandler {
    private static let logger = Logger.log(UnStickToTopActionHandler.self, category: "Module.IM.ChatPin")

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
        guard let targetVC = self.targetVC, let chatID = Int64(chat.id) else { return }
        switch ChatPinPermissionConfig.checkPermission(chat, userID: currentChatterId, featureGatingService: featureGatingService) {
        case .success:
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkChat.Lark_IM_SuperApp_NoLongerPrioritize_Title)
            alertController.setContent(text: BundleI18n.LarkChat.Lark_IM_SuperApp_NoLongerPrioritize_Desc_Mobile )
            alertController.addSecondaryButton(text: BundleI18n.LarkChat.Lark_IM_SuperApp_NoLongerPrioritize_Keep_Button)
            alertController.addPrimaryButton(
                text: BundleI18n.LarkChat.Lark_IM_SuperApp_NoLongerPrioritize_Dont_Button,
                dismissCompletion: { [weak self] in
                    guard let self = self else { return }
                    IMTracker.Chat.Sidebar.Click.cancelmMoveToTop(chat)
                    IMTracker.Chat.Sidebar.Confirm.cancelFix(chat)
                    self.chatAPI?.stickChatPinToTop(chatID: chatID, pinID: pin.id, stick: false)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: {  _ in
                            Self.logger.info("chatPinCardTrace unStick to top pin success chatID: \(chatID) pinId: \(pin.id)")
                        }, onError: { [weak self] error in
                            guard let targetVC = self?.targetVC else { return }
                            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_NewPin_ActionFailedRetry_Toast, on: targetVC.view, error: error)
                            Self.logger.error("chatPinCardTrace unStick to top pin fail chatID: \(chatID) pinId: \(pin.id)", error: error)
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
