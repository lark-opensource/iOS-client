//
//  StickToTopActionHandler.swift
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

/// 固定到首位
final class StickToTopActionHandler: ChatPinActionHandler {
    private static let logger = Logger.log(StickToTopActionHandler.self, category: "Modsule.IM.ChatPin")

    static var maxCount: Int { 3 }

    private let chatAPI: ChatAPI?
    private let currentChatterId: String
    private let disposeBag = DisposeBag()
    private weak var targetVC: UIViewController?
    private let nav: Navigatable
    private let featureGatingService: FeatureGatingService

    private let limitTopPin: () -> Bool

    init(targetVC: UIViewController?, chatAPI: ChatAPI?, currentChatterId: String, nav: Navigatable, featureGatingService: FeatureGatingService, limitTopPin: @escaping () -> Bool) {
        self.targetVC = targetVC
        self.chatAPI = chatAPI
        self.currentChatterId = currentChatterId
        self.nav = nav
        self.featureGatingService = featureGatingService
        self.limitTopPin = limitTopPin
    }

    func handle(pin: ChatPin, chat: Chat) {
        guard let targetVC = self.targetVC, let chatID = Int64(chat.id) else { return }
        switch ChatPinPermissionConfig.checkPermission(chat, userID: currentChatterId, featureGatingService: featureGatingService) {
        case .success:
            let stickHandler: () -> Void = { [weak self] in
                guard let self = self else { return }
                IMTracker.Chat.Sidebar.Click.moveToTop(chat)
                self.chatAPI?.stickChatPinToTop(chatID: chatID, pinID: pin.id, stick: true)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        Self.logger.info("chatPinCardTrace stick to top pin success chatID: \(chatID) pinId: \(pin.id)")
                    }, onError: { [weak self] error in
                        guard let targetVC = self?.targetVC else { return }
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_NewPin_ActionFailedRetry_Toast, on: targetVC.view, error: error)
                        Self.logger.error("chatPinCardTrace stick to top pin fail chatID: \(chatID) pinId: \(pin.id)", error: error)
                    })
                    .disposed(by: self.disposeBag)
            }

            if limitTopPin() {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkChat.Lark_IM_SuperApp_ReplacePrioritize_Short_Title)
                alertController.setContent(text: BundleI18n.LarkChat.Lark_IM_SuperApp_ReplacePrioritize_Title)
                alertController.addSecondaryButton(text: BundleI18n.LarkChat.Lark_IM_SuperApp_ReplacePrioritize_Cancel_Button)
                alertController.addPrimaryButton(
                    text: BundleI18n.LarkChat.Lark_IM_SuperApp_ReplacePrioritize_Replace_Button,
                    dismissCompletion: {
                        IMTracker.Chat.Sidebar.Confirm.replace(chat)
                        stickHandler()
                    }
                )
                self.nav.present(alertController, from: targetVC)
            } else {
                stickHandler()
            }
        case .failure(reason: let reason):
            UDToast.showTips(with: reason, on: targetVC.view)
        }
    }
}
