//
//  ChatControllerFactory.swift
//  Lark
//
//  Created by zhuchao on 2017/8/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkCore
import LarkUIKit
import Swinject
import EENavigator
import UniverseDesignToast
import LarkMessageCore
import LarkAlertController
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import LarkGuide
import LarkFeatureGating
import RxCocoa
import LarkQuickLaunchInterface

final class ChatControllerDependency: UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var docAPI: DocAPI?
    @ScopedInjectedLazy var guideService: GuideService?
    @ScopedInjectedLazy var newGuideService: NewGuideService?
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var docSDKAPI: ChatDocDependency?
    @ScopedInjectedLazy(\SendMessageAPI.statusDriver) var sendMessageStatusDriver: Driver<(LarkModel.Message, Error?)>?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy var modelService: ModelService?
    let pushCenter: PushNotificationCenter
    let pushHandlerRegister: ChatPushHandlersRegister

    init(userResolver: UserResolver, pushCenter: PushNotificationCenter, pushHandlerRegister: ChatPushHandlersRegister) {
        self.userResolver = userResolver
        self.pushCenter = pushCenter
        self.pushHandlerRegister = pushHandlerRegister
    }
}

protocol ChatControllerRouter {
    func pushChatSettingController(_ controller: UIViewController,
                                   action: EnterChatSettingAction,
                                   chat: Chat,
                                   type: P2PChatSettingBody.ChatSettingType)

    func presentOrPushProfileController(_ controller: UIViewController,
                                        chatterId: String)

    func presentFinishOncallAlert(
        chatId: String,
        oncallId: String,
        oncallRola: Chatter.ChatExtra.OncallRole?,
        disposeBag: DisposeBag,
        fromVC: UIViewController)
}

final class ChatControllerRouterImpl: ChatControllerRouter, UserResolverWrapper {
    public let userResolver: UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func pushChatSettingController(_ controller: UIViewController,
                                   action: EnterChatSettingAction,
                                   chat: Chat,
                                   type: P2PChatSettingBody.ChatSettingType) {
        let body = ChatInfoBody(chat: chat, action: action, type: type)
        navigator.push(body: body, from: controller)
    }

    func presentOrPushProfileController(_ controller: UIViewController,
                                        chatterId: String) {
        let body = PersonCardBody(chatterId: chatterId,
                                  source: .chat)
        navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: controller,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    func presentFinishOncallAlert(
        chatId: String,
        oncallId: String,
        oncallRola: Chatter.ChatExtra.OncallRole?,
        disposeBag: DisposeBag,
        fromVC: UIViewController) {

        let message: String

        if let type = oncallRola {
            switch type {
            case .user:
                message = BundleI18n.LarkChat.Lark_HelpDesk_EndServiceTipDescforUser
            case .oncall, .oncallHelper, .userHelper, .unknown:
                message = BundleI18n.LarkChat.Lark_HelpDesk_EndServiceTipDescforAgent
            @unknown default:
                assert(false, "new value")
                message = BundleI18n.LarkChat.Lark_HelpDesk_EndServiceTipDescforAgent
            }
        } else {
            message = BundleI18n.LarkChat.Lark_Legacy_FinishDutyTipTitle
        }

        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChat.Lark_HelpDesk_EndServiceTipTitle)
        alertController.setContent(text: message)

        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Legacy_LarkConfirm, dismissCompletion: {
            try? self.resolver.resolve(type: OncallAPI.self)
                .finishOncallChat(chatId: chatId, oncallId: oncallId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (_) in
                    fromVC.navigationController?.popToRootViewController(animated: true)
                }, onError: { error in
                    UDToast.showFailure(
                        with: BundleI18n.LarkChat.Lark_Legacy_FinishFailToast,
                        on: fromVC.view,
                        error: error
                    )
                }).disposed(by: disposeBag)
        })

        navigator.present(alertController, from: fromVC)
    }
}
