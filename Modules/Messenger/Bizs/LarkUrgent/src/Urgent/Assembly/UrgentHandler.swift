//
//  UrgentHandler.swift
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
import UniverseDesignToast
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import RustPB
import Homeric
import LKCommonsTracker
import LarkCore
import LarkNavigator
import LarkSetting
import LarkRustClient
import CTADialog
import LarkContainer

struct CTADisplyInfo {
    let featureKey: String = "buzz_limit"
    let scene: String = "scene_buzz_FeatureKEY"
    var checkpointTenantId: String { _checkpointTenantId }
    var checkpointUserId: String { _checkpointUserId }

    private var _checkpointTenantId: String = ""
    private var _checkpointUserId: String = ""
    init(userResolver: UserResolver) {
        _checkpointUserId = userResolver.userID
        let userService = try? userResolver.resolve(assert: PassportUserService.self)
        _checkpointTenantId = userService?.userTenant.tenantID ?? ""
    }
}
/// 群聊加急
final class UrgentHandler: UserTypedRouterHandler {
    private static let logger = Logger.log(UrgentHandler.self, category: "UrgentHandler")

    private let disposeBag = DisposeBag()

    private var ctaDialog: CTADialog?

    private var isSendingUrgent = false

    func handle(_ body: UrgentBody, req: EENavigator.Request, res: Response) throws {

        let messageAPI = try userResolver.resolve(assert: MessageAPI.self)
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)

        messageAPI.fetchLocalMessage(id: body.messageId)
            .flatMap { (message) -> Observable<(Message, Chat)> in
                return chatAPI.fetchChats(by: [message.channel.id], forceRemote: false)
                    .flatMap { (chatMap) -> Observable<(Message, Chat)> in
                        if let chat = chatMap[message.channel.id] {
                            return .just((message, chat))
                        }
                        return .error(RouterError.invalidParameters("chat miss \(message.channel.id)"))
                    }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (message, chat) in
                guard let self = self else { return }
                do {
                    /// 获取加急确认Controller
                    let urgentConfirmController = try self.getUrgentConfirmController(
                        message: message,
                        chat: chat,
                        scene: body.urgentScene,
                        navigatorFrom: req.context.from(),
                        chatFromWhere: body.chatFromWhere)
                    urgentConfirmController.modalPresentationStyle = .fullScreen
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
    private func getUrgentConfirmController(message: Message,
                                            chat: Chat,
                                            scene: UrgentScene,
                                            navigatorFrom: NavigatorFrom?,
                                            chatFromWhere: ChatFromWhere) throws -> UIViewController {
        let modelService = try self.userResolver.resolve(assert: ModelService.self)
        let configurationAPI = try self.userResolver.resolve(assert: ConfigurationAPI.self)
        let fgService = try userResolver.resolve(assert: FeatureGatingService.self)
        let rustService = try self.userResolver.resolve(assert: RustService.self)
        let enableTurnOffReadReceipt = fgService.staticFeatureGatingValue(with: "messenger.buzz.turn_off_read_receipt")
        let provider: UrgentConfirmControllerProvider = { [userResolver](message, mode, callback) in
            let confirmVC = UrgentConfirmViewController(
                userResolver: userResolver,
                message: message,
                chat: chat,
                mode: mode,
                channelId: message.channel.id,
                scene: scene,
                modelService: modelService,
                configurationAPI: configurationAPI,
                enableTurnOffReadReceipt: enableTurnOffReadReceipt,
                rustService: rustService
            )
            confirmVC.sendSelected = callback
            return confirmVC
        }

        let viewmModel = UrgentPickerViewModel(
            message: message,
            chat: chat,
            accountService: try self.userResolver.resolve(assert: PassportUserService.self),
            chatAPI: try self.userResolver.resolve(assert: ChatAPI.self),
            chatterAPI: try self.userResolver.resolve(assert: ChatterAPI.self),
            messageAPI: try self.userResolver.resolve(assert: MessageAPI.self),
            serverNTPTimeService: try self.userResolver.resolve(assert: ServerNTPTimeService.self),
            urgentAPI: try self.userResolver.resolve(assert: UrgentAPI.self),
            contactAPI: try self.userResolver.resolve(assert: ContactAPI.self))

        let controller = UrgentPickerController(
            viewModel: viewmModel,
            confirmControllerProvider: provider)

        let navigation = LkNavigationController(rootViewController: controller)
        controller.sendSelected = { [unowned navigation] type, cancelPushAck in
            switch type {
            case .selectAllChatter(let disableList, let additionalList):
                try? self.sendUrgent(
                    selectType: .selectAllChatter,
                    chatId: chat.id,
                    disableList: disableList,
                    additionalList: additionalList,
                    messageId: message.id,
                    from: navigation,
                    navigatorFrom: navigatorFrom,
                    cancelPushAck: cancelPushAck)
            case .selectSomeChatter(let urgentResults):
                try? self.sendUrgent(
                    selectType: .selectSomeChatter,
                    messageId: message.id,
                    urgentResults: urgentResults,
                    from: navigation,
                    navigatorFrom: navigatorFrom,
                    cancelPushAck: cancelPushAck)
            case .selectUnreadChatter(let disableList, let additionalList):
                try? self.sendUrgent(
                    selectType: .selectUnreadChatter,
                    chatId: chat.id,
                    disableList: disableList,
                    additionalList: additionalList,
                    messageId: message.id,
                    from: navigation,
                    navigatorFrom: navigatorFrom,
                    cancelPushAck: cancelPushAck)
            }
        }
        return navigation
    }

    /// 发送加急
    private func sendUrgent(
        selectType: RustPB.Im_V1_CreateUrgentRequest.SelectType,
        chatId: String? = nil,
        disableList: [String]? = nil,
        additionalList: [String]? = nil,
        messageId: String,
        urgentResults: [UrgentResult]? = nil,
        from controller: UIViewController,
        navigatorFrom: NavigatorFrom?,
        cancelPushAck: Bool) throws {
        let toastDisplayView: UIView = controller.view.window ?? controller.view
        let hud = UDToast.showLoading(with: BundleI18n.LarkUrgent.Lark_Legacy_BaseUiLoading, on: toastDisplayView)
        /// 发送加急
        let urgentAPI = try self.userResolver.resolve(assert: UrgentAPI.self)
        let urgentInfo: UrgentBasicInfos? = urgentResults?.map { (urgentType, chatters) -> (RustPB.Basic_V1_Urgent.TypeEnum, [String]) in
            return (urgentType, chatters.map { $0.id })
        }
        if isSendingUrgent { return }
        self.isSendingUrgent = true
        urgentAPI.createUrgent(targetModel: UrgentTargetModel(messageId: messageId, chatId: chatId),
                               extraList: UrgentExtraList(disableList: disableList, additionalList: additionalList),
                               selectType: selectType,
                               basicInfos: urgentInfo,
                               cancelPushAck: cancelPushAck,
                               strictMode: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak controller, weak self] (response) in
                self?.isSendingUrgent = false
                hud.remove()
                if !response.invisibleChatterIds.isEmpty, let window = controller?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_Group_UnableViewBuzzMessageChatHistoryOff, on: window)
                }
                controller?.dismiss(animated: true, completion: nil)
            }, onError: { [weak controller, weak self] (error) in
                guard let self = self else { return }
                self.isSendingUrgent = false
                hud.remove()
                guard let fromVC = controller else {
                    assertionFailure("缺少 FromVC")
                    return
                }

                /// 其他错误
                guard let apiError = error.underlyingError as? APIError else {
                    hud.showFailure(
                        with: BundleI18n.LarkUrgent.Lark_Legacy_ChatViewSendFailed,
                        on: toastDisplayView,
                        error: error
                    )
                    return
                }
                switch apiError.type {
                /// 加急失败
                case .urgentLimited:
                    try? self.handleUrgentFailedError(from: fromVC,
                                                 navigatorFrom: navigatorFrom) { error in
                        hud.showFailure(
                            with: BundleI18n.LarkUrgent.Lark_Legacy_ChatViewSendFailed,
                            on: toastDisplayView,
                            error: error
                        )
                    }
                /// 所有被加急的人都是高管 || 无密聊权限
                case .notUrgetToAllWhoIsExecutive(let message), .noSecretChatUrgentPermission(let message):
                    self.handleNotUrgetToAllWhoIsExecutive(message: message, from: fromVC)
                /// 被加急的人部分是高管
                case .notUrgetToPartWhoIsExecutive(let message):
                    try? self.handleNotUrgetToPartWhoIsExecutive(
                        message: message,
                        messageId: messageId,
                        urgentResults: urgentResults,
                        cancelPushAck: cancelPushAck,
                        from: fromVC)
                    /// 无法使用密聊
                case .noSecretChatPermission(let message):
                    hud.showFailure(with: message, on: toastDisplayView)
                /// 其他错误
                default:
                    hud.showFailure(
                        with: BundleI18n.LarkUrgent.Lark_Legacy_ChatViewSendFailed,
                        on: toastDisplayView,
                        error: error
                    )
                }
            }).disposed(by: self.disposeBag)
    }

    /// 处理被加急的人部分是高管
    private func handleNotUrgetToPartWhoIsExecutive(
        message: String,
        messageId: String,
        urgentResults: [UrgentResult]?,
        cancelPushAck: Bool,
        from controller: UIViewController) throws {
        let alertController = LarkAlertController()
        alertController.setContent(text: message)
        alertController.addSecondaryButton(text: BundleI18n.LarkUrgent.Lark_Chat_ExecutiveModeCancel)
        alertController.addPrimaryButton(text: BundleI18n.LarkUrgent.Lark_Chat_ExecutiveModeIgnoreAndSend, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            let urgentInfo = urgentResults?.map { (urgentType, chatters) -> (RustPB.Basic_V1_Urgent.TypeEnum, [String]) in
                return (urgentType, chatters.map { $0.id })
            }
            /// 发送加急
            let urgentAPI = try? self.userResolver.resolve(assert: UrgentAPI.self)
            // 忽略高管并重新给其他人发送加急
            urgentAPI?.createUrgent(targetModel: UrgentTargetModel(messageId: messageId, chatId: nil),
                                   extraList: UrgentExtraList(disableList: nil, additionalList: nil),
                                   selectType: .selectSomeChatter,
                                   basicInfos: urgentInfo,
                                   cancelPushAck: cancelPushAck,
                                   strictMode: false)
            .subscribe(onNext: { [weak controller] response in
                UrgentHandler.logger.info("resend success")

                if !response.invisibleChatterIds.isEmpty, let window = controller?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkUrgent.Lark_Group_UnableViewBuzzMessageChatHistoryOff, on: window)
                }
            }, onError: { (error) in
                UrgentHandler.logger.error("resend error", error: error)
            }).disposed(by: self.disposeBag)
        })
        self.userResolver.navigator.present(alertController, from: controller)
    }

    /// 处理所有被加急的人都是高管
    private func handleNotUrgetToAllWhoIsExecutive(message: String, from controller: UIViewController) {
        let alertController = LarkAlertController()
        alertController.setContent(text: message)
        alertController.addPrimaryButton(text: BundleI18n.LarkUrgent.Lark_Legacy_Sure)
        self.userResolver.navigator.present(alertController, from: controller)
    }

    /// 处理加急失败
    private func handleUrgentFailedError(from controller: UIViewController,
                                         navigatorFrom: NavigatorFrom?,
                                         errorTask: @escaping (Error) -> Void) throws {
        let userAPI = try self.userResolver.resolve(assert: UserAPI.self)
        userAPI.isSuperAdministrator().asObservable()
            .timeout(.seconds(2), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isAdmin) in
                guard let self = self else { return }
                Tracker.post(TeaEvent(Homeric.COMMON_PRICING_POPUP_VIEW, params: [
                    "function_type": "buzz_limit",
                    "admin_flag": isAdmin ? "true" : "false"
                ]))
                let dialog = CTADialog(userResolver: self.userResolver)
                let info = CTADisplyInfo(userResolver: self.userResolver)
                dialog.show(from: controller,
                                  featureKey: info.featureKey,
                                  scene: info.scene,
                                  checkpointTenantId: info.checkpointTenantId,
                                  checkpointUserId: info.checkpointUserId, with: { [weak self] succeed in
                    self?.ctaDialog = nil
                    Self.logger.info("handleUrgentFailedError -- with result: \(succeed)")
                })
                self.ctaDialog = dialog
            }, onError: { error in
                Self.logger.error("isSuperAdministrator error", error: error)
                errorTask(error)
            }).disposed(by: self.disposeBag)
    }
}
