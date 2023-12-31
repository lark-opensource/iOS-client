//
//  UrgentChatterHandler.swift
//  LarkUrgent
//
//  Created by 李勇 on 2019/6/13.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import EENavigator
import LKCommonsLogging
import LarkUIKit
import Swinject
import LarkAlertController
import LarkSDKInterface
import LarkMessengerInterface
import RustPB
import Homeric
import LKCommonsTracker
import UniverseDesignToast
import LarkCore
import LarkNavigator
import LarkSetting
import LarkRustClient
import CTADialog

/// 单聊加急
final class UrgentChatterHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Urgent.userScopeCompatibleMode }

    private static let logger = Logger.log(UrgentChatterHandler.self, category: "UrgentChatterHandler")

    private let disposeBag = DisposeBag()
    private var isSendingUrgent = false

    private var ctaDialog: CTADialog?

    func handle(_ body: UrgentChatterBody, req: EENavigator.Request, res: Response) throws {

        let chatterAPI = try self.userResolver.resolve(assert: ChatterAPI.self)
        let messageAPI = try self.userResolver.resolve(assert: MessageAPI.self)
        let urgentAPI = try self.userResolver.resolve(assert: UrgentAPI.self)
        guard let from = req.context.from() else {
            assertionFailure("缺少 From")
            return
        }

        let messageRes = messageAPI.fetchLocalMessage(id: body.messageId)
            .flatMap { (message) -> Observable<(Message, Chatter)> in
                let chatId = message.channel.type == .chat ? message.channel.id : ""
                return chatterAPI.fetchChatChatters(ids: [body.chatterId], chatId: chatId)
                    .flatMap { (chatterMap) -> Observable<(Message, Chatter)> in
                        if let chatter = chatterMap[body.chatterId] {
                            return .just((message, chatter))
                        }
                        return .error(RouterError.invalidParameters("chatter miss \(body.chatterId)"))
                    }
            }

        let urgentExtraInfo = urgentAPI.pullChattersUrgentInfoRequest(chatterIds: [body.chatterId], isSuperChat: false, messageId: body.messageId)
            .map({ res -> UrgentExtraInfo in
                if let info = res.chatterInfos.first { $0.chatterID == body.chatterId } {
                    return UrgentExtraInfo(isRead: info.readState == .read, unSupportChatterType: UnSupportChatterType(rawValue: info.code.rawValue) ?? .none)
                }
                return UrgentExtraInfo()
            })

        Observable.zip(messageRes, urgentExtraInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (messageRes, urgentExtraInfo) in
                guard let self = self else { return }
                do {
                    /// 加急确认控制器
                    let chatterWrapper = ChatterWrapper(chatter: messageRes.1, unSupportChatterType: urgentExtraInfo.unSupportChatterType)
                    let urgentConfirmController = try self.getUrgentConfirmController(message: messageRes.0,
                                                                                  chatterWrpper: chatterWrapper,
                                                                                  chat: body.chat,
                                                                                  navigatorFrom: from,
                                                                                  chatFromWhere: body.chatFromWhere)
                    /// 可以直接加急对方
                    res.end(resource: urgentConfirmController)
                } catch {
                    res.end(error: error)
                }
            }, onError: { (error) in
                res.end(error: error)
            }).disposed(by: self.disposeBag)
        res.wait()
    }

    /// 获取加急确认Controller
    private func getUrgentConfirmController(message: Message, chatterWrpper: ChatterWrapper, chat: Chat, navigatorFrom: NavigatorFrom, chatFromWhere: ChatFromWhere) throws -> UIViewController {
        let chatId = message.channel.type == .chat ? message.channel.id : ""
        let chatter = chatterWrpper.chatter
        let fgService = try userResolver.resolve(assert: FeatureGatingService.self)
        let enableTurnOffReadReceipt = fgService.staticFeatureGatingValue(with: "messenger.buzz.turn_off_read_receipt")
        let confirmVc = UrgentConfirmViewController(
            userResolver: userResolver,
            message: message,
            chat: chat,
            mode: .single([chatterWrpper]),
            channelId: message.channel.id,
            scene: .p2PChat,
            modelService: try self.userResolver.resolve(assert: ModelService.self),
            configurationAPI: try self.userResolver.resolve(assert: ConfigurationAPI.self),
            enableTurnOffReadReceipt: enableTurnOffReadReceipt,
            rustService: try self.userResolver.resolve(assert: RustService.self)
        )
        let nav = LkNavigationController(rootViewController: confirmVc)
        confirmVc.addCloseButton = true
        confirmVc.sendSelected = { [unowned nav, weak self] type, cancelPushAck in
            do {
                guard let self = self, case .selectSomeChatter(let urgentResults) = type else {
                    assertionFailure("unexpected result")
                    return
                }
                UrgentTracker.trackMessageUrgentSend()
                /// 如果对方是勿扰模式，则需要弹窗确认
                let serverNTPTimeService = try self.userResolver.resolve(assert: ServerNTPTimeService.self)
                guard !serverNTPTimeService.afterThatServerTime(time: chatter.doNotDisturbEndTime) else {
                    let alertController = LarkAlertController()
                    alertController.setTitle(text: BundleI18n.LarkUrgent.Lark_Notification_DndBuzzConfirmTitle)
                    alertController.setContent(text: BundleI18n.LarkUrgent.Lark_Notification_DndBuzzConfirmDetail(chatter.displayName), alignment: .left)
                    alertController.addSecondaryButton(text: BundleI18n.LarkUrgent.Lark_Notification_DndBuzzCancel, dismissCompletion: {
                        nav.dismiss(animated: true, completion: nil)
                    })
                    alertController.addPrimaryButton(text: BundleI18n.LarkUrgent.Lark_Notification_DndBuzzConfirm, dismissCompletion: {
                        try? self.sendUrgent(
                            messageId: message.id,
                            chatId: chatId,
                            urgentResults: urgentResults,
                            from: nav,
                            navigatorFrom: navigatorFrom,
                            cancelPushAck: cancelPushAck
                        )
                    })
                    self.userResolver.navigator.present(alertController, from: nav)
                    return
                }
                /// 可以直接发送加急
                try? self.sendUrgent(
                    messageId: message.id,
                    chatId: chatId,
                    urgentResults: urgentResults,
                    from: nav,
                    navigatorFrom: navigatorFrom,
                    cancelPushAck: cancelPushAck
                )
            } catch {}
        }
        return nav
    }

    /// 发送加急
    private func sendUrgent(
        messageId: String,
        chatId: String,
        urgentResults: [UrgentResult],
        from controller: UIViewController,
        navigatorFrom: NavigatorFrom,
        cancelPushAck: Bool) throws {
        let toastDisplayView: UIView = controller.view.window ?? controller.view
        let hud = UDToast.showLoading(with: BundleI18n.LarkUrgent.Lark_Legacy_BaseUiLoading, on: toastDisplayView)
        /// 发送加急
        let urgentAPI = try self.userResolver.resolve(assert: UrgentAPI.self)

        let urgentInfo = urgentResults.map { (urgentType, chatters) -> (RustPB.Basic_V1_Urgent.TypeEnum, [String]) in
            return (urgentType, chatters.map { $0.id })
        }
        try? sendUrgent(hud: hud,
                   urgentAPI: urgentAPI,
                   urgentInfo: urgentInfo,
                   targetModel: UrgentTargetModel(messageId: messageId, chatId: chatId),
                   cancelPushAck: cancelPushAck,
                   from: controller,
                   urgentResults: urgentResults,
                   toastDisplayView: toastDisplayView,
                   navigatorFrom: navigatorFrom)
    }

    private func sendUrgent(hud: UDToast,
                            urgentAPI: UrgentAPI,
                            urgentInfo: [(Basic_V1_Urgent.TypeEnum, [String])],
                            targetModel: UrgentTargetModel,
                            cancelPushAck: Bool,
                            from controller: UIViewController,
                            urgentResults: [UrgentResult],
                            toastDisplayView: UIView,
                            navigatorFrom: NavigatorFrom) throws {
        if isSendingUrgent { return }
        self.isSendingUrgent = true
        urgentAPI.createUrgent(targetModel: targetModel,
                               extraList: UrgentExtraList(disableList: nil, additionalList: nil),
                               selectType: .selectSomeChatter,
                               basicInfos: urgentInfo,
                               cancelPushAck: cancelPushAck,
                               strictMode: true)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak controller, weak self] (_) in
            self?.handleSuccess(controller, hud)
        }, onError: { [weak controller, weak self] (error) in
            guard let chatId = targetModel.chatId else { return }
            try? self?.handleError(controller,
                                   hud,
                                   error,
                                   urgentResults,
                                   chatId: chatId,
                                   toastDisplayView: toastDisplayView,
                                   navigatorFrom: navigatorFrom)
        }).disposed(by: self.disposeBag)
    }

    private func handleSuccess(_ controller: UIViewController?, _ hud: UDToast) {
        hud.remove()
        self.isSendingUrgent = false
        controller?.dismiss(animated: true, completion: nil)
    }

    private func handleError(_ controller: UIViewController?,
                             _ hud: UDToast,
                             _ error: Error,
                             _ urgentResults: [UrgentResult],
                             chatId: String,
                             toastDisplayView: UIView,
                             navigatorFrom: NavigatorFrom) throws {
        self.isSendingUrgent = false
        guard let fromController = controller else {
            assertionFailure("缺少 From VC")
            return
        }
        hud.remove()
        guard let apiError = error.underlyingError as? APIError else {
            fromController.dismiss(animated: true, completion: nil)
            hud.showFailure(
                with: BundleI18n.LarkUrgent.Lark_Legacy_ChatViewSendFailed,
                on: toastDisplayView,
                error: error
            )
            return
        }

        switch apiError.type {
        /// 加急次数达到限制
        case .urgentLimited:
            let userAPI = try self.userResolver.resolve(assert: UserAPI.self)
            userAPI.isSuperAdministrator().asObservable()
                .timeout(.seconds(2), scheduler: MainScheduler.instance)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak fromController, weak self] (isAdmin) in
                    guard let fromController = fromController, let self = self else { return }
                    Tracker.post(TeaEvent(Homeric.COMMON_PRICING_POPUP_VIEW, params: [
                        "function_type": "buzz_limit",
                        "admin_flag": isAdmin ? "true" : "false"
                    ]))
                    let dialog = CTADialog(userResolver: self.userResolver)
                    let info = CTADisplyInfo(userResolver: self.userResolver)
                    dialog.show(from: fromController,
                                      featureKey: info.featureKey,
                                      scene: info.scene,
                                      checkpointTenantId: info.checkpointTenantId,
                                      checkpointUserId: info.checkpointUserId, with: { [weak self] succeed in
                        self?.ctaDialog = nil
                        Self.logger.info("handleError -- with result: \(succeed)")
                    })
                    self.ctaDialog = dialog
                }, onError: { error in
                    Self.logger.error("isSuperAdministrator error", error: error)
                    hud.showFailure(with: BundleI18n.LarkUrgent.Lark_Legacy_ChatViewSendFailed,
                                    on: toastDisplayView,
                                    error: error)
                }).disposed(by: self.disposeBag)
        /// 对方是高管 || 无密聊权限
        case .notUrgetToAllWhoIsExecutive(let message), .noSecretChatUrgentPermission(let message):
            let alertController = LarkAlertController()
            alertController.setContent(text: message)
            alertController.addPrimaryButton(text: BundleI18n.LarkUrgent.Lark_Legacy_Sure)
            self.userResolver.navigator.present(alertController, from: fromController)
        case .forbidPutUrgent(let message):
            let alertController = LarkAlertController()
            alertController.setContent(text: message)
            alertController.addPrimaryButton(text: BundleI18n.LarkUrgent.Lark_Legacy_ApplicationPhoneCallTimeButtonKnow)
            self.userResolver.navigator.present(alertController, from: fromController)
        case .collaborationAuthFailedNoRights:
            guard let chatter = urgentResults.first?.chatters.first else { return }
            var source = Source()
            source.sourceType = .chat
            source.sourceID = chatId
            let topMost = WindowTopMostFrom(vc: fromController)
            fromController.dismiss(animated: true) {
                let content = BundleI18n.LarkUrgent.Lark_NewContacts_NeedToAddToContactstBuzzOneDialogContent
                let addContactBody = AddContactApplicationAlertBody(userId: chatter.id,
                                                                    chatId: chatId,
                                                                    source: source,
                                                                    displayName: chatter.displayName,
                                                                    content: content,
                                                                    targetVC: navigatorFrom.fromViewController,
                                                                    businessType: .buzzConfirm)
                self.userResolver.navigator.present(body: addContactBody, from: topMost)
            }
        case .collaborationAuthFailedBlocked(let message):
            UrgentTracker.trackBuzzCancelBlock()
            fromController.dismiss(animated: true, completion: nil)
            hud.showFailure(with: message, on: toastDisplayView, error: error)
        case .collaborationAuthFailedBeBlocked(let message):
            fromController.dismiss(animated: true, completion: nil)
            hud.showFailure(with: message, on: toastDisplayView, error: error)
        /// 无法使用密聊
        case .noSecretChatPermission(let message):
            hud.showFailure(with: message, on: toastDisplayView)
        case .externalCoordinateCtl, .targetExternalCoordinateCtl:
            hud.showFailure(
                with: BundleI18n.LarkUrgent.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission,
                on: toastDisplayView,
                error: error
            )
        default:
            fromController.dismiss(animated: true, completion: nil)
            hud.showFailure(
                with: BundleI18n.LarkUrgent.Lark_Legacy_ChatViewSendFailed,
                on: toastDisplayView,
                error: error
            )
        }
    }
}
