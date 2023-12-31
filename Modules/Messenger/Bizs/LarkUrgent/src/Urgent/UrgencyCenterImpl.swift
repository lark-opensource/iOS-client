//
//  UrgencyCenter.swift
//  Lark
//
//  Created by zhuchao on 2018/4/15.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer
import LKCommonsLogging
import EENavigator
import LarkCore
import LarkSDKInterface
import LarkFeatureGating
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigation
import AnimatedTabBar
import SuiteAppConfig
import LarkTab
import LarkSceneManager
import LarkSuspendable
import RustPB
import UniverseDesignToast
import LarkPushCard
import LKWindowManager
import LarkStorage
import LarkAlertController
import LarkSetting

public typealias UrgentAck = (messageId: String, ackId: String)
public typealias UrgentAction = (title: String, action: (UrgentMessageModel) -> Void)

public final class UrgentMessageModel {
    public let summerize: (Message) -> String
    public var messageModel: LarkModel.Message
    public let chat: Chat
    public var urgent: RustPB.Basic_V1_Urgent

    public init(urgent: RustPB.Basic_V1_Urgent, message: LarkModel.Message, chat: Chat, summerize: @escaping (Message) -> String) {
        self.urgent = urgent
        self.messageModel = message
        self.summerize = summerize
        self.chat = chat
    }

    public var messageId: String {
        return urgent.messageID
    }

    public var ackID: String {
        return urgent.id
    }

    public var sendTime: TimeInterval {
        return TimeInterval(urgent.sendTime)
    }

    public var type: RustPB.Basic_V1_Urgent.TypeEnum {
        return urgent.type
    }

    public var status: RustPB.Basic_V1_Urgent.Status {
        return urgent.status
    }

    public var iconUrl: String {
        guard let url = self.messageModel.fromChatter?.avatarKey else {
            assertionFailure("shouldn't have fromChatter, please check self.messageModel")
            return ""
        }
        return url
    }

    public var urgentActions: [UrgentAction] = []

    public var customItem: (view: UIView, height: CGFloat)?

    public var iconImage: UIImage?

    public var id: String {
        return urgent.id
    }

    public var urgentBodyTapAction: ((UrgentMessageModel) -> Void)?

    public var isSpecialFocus: Bool {
        guard let chatter = self.messageModel.fromChatter else { return false }
        return chatter.isSpecialFocus
    }
}

extension UrgentMessageModel {

    public var extra: Any? {
        return ["isUrgency": true,
                "messageId": self.messageId]
    }

    public var userName: String {
        if let fromChatter = messageModel.fromChatter {
            if !fromChatter.alias.isEmpty {
                return fromChatter.alias
            } else if let nickName = fromChatter.chatExtra?.nickName, !nickName.isEmpty {
                return nickName
            }
            return fromChatter.displayName
        }
        return ""
    }

    public var message: String {
        if chat.isCrypto {
            return BundleI18n.LarkUrgent.Lark_Buzz_BuzzSecretChatPush
        }
        if self.messageModel.isOnTimeDel {
            return BundleI18n.LarkUrgent.Lark_IM_YouReceivedaMsg_Desc
        }
        let specialFocusStr = "[\(BundleI18n.LarkUrgent.Lark_IM_StarredContacts_FeatureName)] "
        let prefix = self.isSpecialFocus ? specialFocusStr : ""
        let text = prefix + summerize(messageModel)
        return text
    }
}

struct UrgentPushCard: Cardable {
    var id: String

    var priority: LarkPushCard.CardPriority = .normal

    var title: String?

    var buttonConfigs: [LarkPushCard.CardButtonConfig]?

    var icon: UIImage?

    var customView: UIView?

    var duration: TimeInterval?

    var bodyTapHandler: ((LarkPushCard.Cardable) -> Void)?

    var timedDisappearHandler: ((LarkPushCard.Cardable) -> Void)?

    var removeHandler: ((LarkPushCard.Cardable) -> Void)?

    var extraParams: Any?

    var urgency: UrgentMessageModel?

    func calculateCardHeight(with width: CGFloat) -> CGFloat? {
        return max(UrgencyCustomView.heightOfContent(urgency?.message ?? "", width: width) + 28, UrgencyCustomView.Layout.avatarBorderSize)
    }
}

private struct MuteUrgentInfo: Hashable {
    let messageId: String
    let urgentId: String
}

public final class UrgencyCenterImpl: UrgencyCenter, UserResolverWrapper {
    public let userResolver: UserResolver
    private let urgentAPI: UrgentAPI
    private let messageAPI: MessageAPI
    private let chatAPI: ChatAPI
    private let modelService: ModelService
    private let messagePacker: MessagePacker
    private let currentChatterId: String
    private let urgencyManager = UrgencyManager()

    private let disposeBag = DisposeBag()
    private static let logger = Logger.log(UrgencyCenterImpl.self, category: "Module.urgency")

    private var confirmedACKIds: Set<String> = []
    private let enableDocCustomIcon: Bool

    private var urgentListEnable: Bool {
        return AppConfigManager.shared.feature(for: .urgentList).isOn
    }

    // UI不展示，但相关数据还要存储，加急确认需要
    private var muteUrgents: Set<MuteUrgentInfo> = Set<MuteUrgentInfo>()
    public init(
        userResolver: UserResolver,
        urgentAPI: UrgentAPI,
        messageAPI: MessageAPI,
        chatAPI: ChatAPI,
        modelService: ModelService,
        messagePacker: MessagePacker,
        currentChatterId: String,
        newUrgencyPush: Observable<UrgentMessageModel>,
        confirmUrgencyPush: Observable<UrgentAck>,
        networkStatusPush: Observable<PushWebSocketStatus>,
        urgentFailPush: Observable<PushUrgentFail>,
        enableDocCustomIcon: Bool) {

        self.userResolver = userResolver
        self.urgentAPI = urgentAPI
        self.messageAPI = messageAPI
        self.chatAPI = chatAPI
        self.modelService = modelService
        self.messagePacker = messagePacker
        self.currentChatterId = currentChatterId
        self.enableDocCustomIcon = enableDocCustomIcon
        newUrgencyPush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (urgentMessageModel) in
                guard let `self` = self, self.urgentListEnable else { return }
                if urgentMessageModel.urgent.isMuted {
                    UrgencyCenterImpl.logger.info("urgency trace urgency push isMute: \(urgentMessageModel.messageId) \(urgentMessageModel.urgent.id)")
                    self.muteUrgents.insert(MuteUrgentInfo(messageId: urgentMessageModel.messageId,
                                                           urgentId: urgentMessageModel.urgent.id))
                    self.removeUrgency(by: urgentMessageModel.urgent.id)
                } else {
                    let message = self.replaceMessage(message: urgentMessageModel.messageModel)
                    urgentMessageModel.messageModel = message
                    self.urgencyPushReceived(urgency: urgentMessageModel)
                }
            }).disposed(by: self.disposeBag)

        confirmUrgencyPush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, urgentAckId) in
                guard let `self` = self, self.urgentListEnable else { return }
                self.removeUrgency(by: urgentAckId)
            }).disposed(by: self.disposeBag)

        networkStatusPush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self, self.urgentListEnable else { return }
                if push.status == .success {
                    self.loadAll()
                }
            }).disposed(by: self.disposeBag)

        urgentFailPush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                self.urgencyFailPushReceived(model: push.urgentFailInfo)
            }).disposed(by: self.disposeBag)
    }

    private func replaceMessage(message: LarkModel.Message) -> LarkModel.Message {
        if var content = message.content as? TextContent {
            let textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: content.richText, docEntity: content.docEntity, replceStyle: .toText)
            content.richText = textDocsVM.richText
            message.content = content
        }
        return message
    }

    deinit {
        let urgencys = PushCardCenter.shared.showCards + urgencyManager.archiveCards
        urgencys.forEach { (urgency) in
            self.removeUrgency(by: urgency.id)
        }
    }

    public func loadAll() {
        guard self.urgentListEnable else { return }
        let modelService = self.modelService
        urgentAPI.requestUrgentList()
            .map { (urgencys) -> [UrgentMessageModel] in
                return urgencys.map { urgentInfo in
                    let model = UrgentMessageModel(urgent: urgentInfo.urgent,
                                                   message: urgentInfo.message,
                                                   chat: urgentInfo.chat,
                                                   summerize: { modelService.messageSummerize($0) })
                    return model
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] urgencys in
                let urgencyIds = urgencys.map { $0.id }
                UrgencyCenterImpl.logger.info("urgency trace load urgency totalcount: \(urgencys.count), ids: \(urgencyIds)")
                let showUrgencys = urgencys.filter { model in
                    if model.urgent.isMuted {
                        UrgencyCenterImpl.logger.info("urgency trace urgency is mute: \(model.urgent.id) \(model.messageId)")
                        self?.muteUrgents.insert(MuteUrgentInfo(messageId: model.messageId,
                                                                urgentId: model.urgent.id))
                    }
                    return !model.urgent.isMuted
                }
                self?.reloadUrgencys(showUrgencys)
            })
            .disposed(by: disposeBag)
    }

    private func allExistUrgentIds() -> [String] {
        let allUrgencyCards = PushCardCenter.shared.showCards + urgencyManager.archiveCards
        return allUrgencyCards.map { card in
            return card.id
        }
    }

    private func removeUrgency(by urgencyId: String) {
        PushCardCenter.shared.remove(with: urgencyId)
        urgencyManager.remove(with: urgencyId, animated: true)
    }

    private func reloadUrgencys(_ urgencys: [UrgentMessageModel]) {
        let allUrgency = PushCardCenter.shared.showCards + urgencyManager.archiveCards
        var urgencyCards: [Cardable] = []
        allUrgency.forEach { urgency in
            guard let extra = urgency.extraParams as? [String: Any],
                  extra["isUrgency"] as? Bool == true else {
                  return
            }
            PushCardCenter.shared.remove(with: urgency.id)
            urgencyManager.remove(with: urgency.id, animated: false)
        }
        urgencys.forEach { urgency in
            guard let card = createUrgentPushCard(urgency: urgency) else { return }
            urgencyCards.append(card)
        }
        urgencyManager.post(urgencyCards, animated: false)
    }

    private func urgencyPushReceived(urgency: UrgentMessageModel) {
        if self.allExistUrgentIds().contains(where: { $0 == urgency.id }) { return }
        //已经有的不显示, 自己发来的加急不显示
        guard let card = self.createUrgentPushCard(urgency: urgency) else { return }
        PushCardCenter.shared.post(card)
    }

    private func createUrgentPushCard(urgency: UrgentMessageModel) -> UrgentPushCard? {
        if urgency.messageModel.fromId == self.currentChatterId { return nil }

        let button1 = CardButtonConfig(title: BundleI18n.LarkUrgent.Lark_Legacy_DingLater,
                                       buttonColorType: .secondary) { [weak self] (card) in
            self?.urgencyManager.post(card, animated: true)
            PushCardCenter.shared.remove(with: card.id)
        }
        let button2 = CardButtonConfig(title: BundleI18n.LarkUrgent.Lark_Legacy_UrgentSeeDetails,
                                       buttonColorType: .primaryBlue) { [weak self] (card) in
            PushCardCenter.shared.remove(with: card.id, changeToStack: true)
            self?.confirmUrgent(urgency)
        }

        let bodyTapHandler: ((Cardable) -> Void)? = { [weak self] (card) in
            PushCardCenter.shared.remove(with: card.id, changeToStack: true)
            self?.confirmUrgent(urgency)
        }

        let removeHandler: ((Cardable) -> Void)? = { [weak self] (card) in
            self?.urgencyManager.post(card, animated: true)
        }

        let extra = ["isUrgency": true,
                     "messageId": urgency.messageId] as [String: Any]

        let customView = UrgencyCustomView(urgency: urgency)
        let card = UrgentPushCard(id: urgency.id,
                                  buttonConfigs: [button1, button2],
                                  customView: customView,
                                  bodyTapHandler: bodyTapHandler,
                                  removeHandler: removeHandler,
                                  extraParams: extra,
                                  urgency: urgency)
        return card
    }

    private func confirmUrgentFail(model: UrgentFailInfo) {

        /// 当前 urgent 所在 scene 的主 window
        var rootWindow: UIWindow

        if let urgencyWindow = PushCardCenter.shared.window,
           #available(iOS 13.0, *),
           SceneManager.shared.supportsMultipleScenes,
           let window = urgencyWindow.windowScene?.rootWindow() {
            rootWindow = window
        } else if let mainSceneWindow = self.navigator.mainSceneWindow {
            rootWindow = mainSceneWindow
        } else {
            assertionFailure()
            rootWindow = UIApplication.shared.keyWindow ??
                UIApplication.shared.windows.first ??
                UIWindow()
        }

        // jump to chat
        let body = ChatControllerByIdBody(
            chatId: model.chat.id,
            position: model.message.position,
            messageId: model.message.id
        )
        self.rotateToPortraitIfNeeded()
        self.navigator.push(body: body, from: rootWindow)
    }

    private func urgencyFailPushReceived(model: UrgentFailInfo) {
        let urgentFailureModel = UrgentFailureModel(urgentId: model.urgentId,
                                                    message: model.message,
                                                    failedTip: model.failedTip,
                                                    chat: model.chat)
        Self.logger.info("urgentFailureView show")

        guard let card = createUrgentFailPushCard(urgency: urgentFailureModel, model: model) else { return }
        PushCardCenter.shared.post(card)

        // track
        UrgentTracker.trackImDingFailedReturnView(chat: model.chat, message: model.message)
    }

    func createUrgentFailPushCard(urgency: UrgentFailureModel, model: UrgentFailInfo) -> UrgentPushCard? {

        let button1 = CardButtonConfig(title: BundleI18n.LarkUrgent.Lark_Buzz_BuzzFail_Close,
                                       buttonColorType: .secondary) { card in
            PushCardCenter.shared.remove(with: card.id)
            UrgentTracker.trackImDingFailedReturnClick(click: "close",
                                                       target: "none",
                                                       chat: model.chat,
                                                       message: model.message)
        }
        let button2 = CardButtonConfig(title: BundleI18n.LarkUrgent.Lark_Legacy_UrgentSeeDetails,
                                       buttonColorType: .primaryBlue) { [weak self] _ in
            PushCardCenter.shared.remove(with: model.urgentId, changeToStack: true)
            self?.confirmUrgentFail(model: model)
            UrgentTracker.trackImDingFailedReturnClick(click: "return_to_chat",
                                                       target: "im_chat_main_view",
                                                       chat: model.chat,
                                                       message: model.message)
        }

        let bodyTapHandler: ((Cardable) -> Void)? = { [weak self] (_) in
            UrgentTracker.trackImDingFailedReturnClick(click: "return_to_chat",
                                                       target: "im_chat_main_view",
                                                       chat: model.chat,
                                                       message: model.message)

            PushCardCenter.shared.remove(with: model.urgentId, changeToStack: true)
            self?.confirmUrgentFail(model: model)
        }

        let removeHandler: ((Cardable) -> Void)? = { [weak self] (card) in
            self?.urgencyManager.post(card, animated: true)
        }

        let customView = UrgencyFailView(urgency: urgency)
        switch model.urgentType {
        case .sms:
            customView.setContent(title: BundleI18n.LarkUrgent.Lark_Buzz_BuzzTextFailed_Alert, description: model.failedTip)
        case .phone:
            customView.setContent(title: BundleI18n.LarkUrgent.Lark_Buzz_BuzzCallFailed_Alert, description: model.failedTip)
        default:
            assertionFailure("error result")
            break
        }

        let card = UrgentPushCard(id: model.urgentId,
                                  buttonConfigs: [button1, button2],
                                  customView: customView,
                                  bodyTapHandler: bodyTapHandler,
                                  removeHandler: removeHandler)
        return card
    }

    //这个函数是原逻辑拷贝, 来自feedlistViewModel
    func confirmUrgent(_ urgentMessageModel: UrgentMessageModel) {
        let message = urgentMessageModel.messageModel

        /// 当前 urgent 所在 scene 的主 window
        var rootWindow: UIWindow

        if let urgencyWindow = PushCardCenter.shared.window,
           #available(iOS 13.0, *),
           SceneManager.shared.supportsMultipleScenes,
           let window = urgencyWindow.windowScene?.rootWindow() {
            rootWindow = window
        } else if let mainSceneWindow = self.navigator.mainSceneWindow {
            rootWindow = mainSceneWindow
        } else {
            assertionFailure()
            rootWindow = UIApplication.shared.keyWindow ??
                UIApplication.shared.windows.first ??
                UIWindow()
        }

        if message.channel.type == .chat {
            guard let chat = chatAPI
                .getLocalChat(by: message.channel.id) else {
                    UrgencyCenterImpl.logger.error("处理加急，未找得到回话", additionalData: ["chatId": message.channel.id])
                    UDToast.showFailure(with: BundleI18n.LarkUrgent.Lark_Legacy_MessageLoadFailed, on: rootWindow)
                    return
            }
            let body = ChatControllerByChatBody(
                chat: chat,
                position: message.position,
                fromWhere: .card
            )
            var params = NaviParams()
            params.switchTab = Tab.feed.url
            if Display.pad {
                let context: [String: Any] = [FeedSelection.contextKey: FeedSelection(feedId: chat.id)]
                if SceneManager.shared.supportsMultipleScenes {
                    /// 支持多 scene 场景中优先激活已经存在的辅助 scene
                    let scene: LarkSceneManager.Scene
                    if chat.type == .p2P {
                        var userInfo: [String: String] = [:]
                        userInfo["chatID"] = "\(chat.id)"
                        scene = LarkSceneManager.Scene(
                            key: chat.isCrypto ? "P2pCryptoChat" : "P2pChat",
                            id: chat.chatterId,
                            title: chat.displayName,
                            userInfo: userInfo
                        )
                    } else {
                        scene = LarkSceneManager.Scene(
                            key: "Chat",
                            id: chat.id,
                            title: chat.displayName
                        )
                    }
                    if SceneManager.shared.isConnected(scene: scene) {
                        SceneManager.shared.active(scene: scene, from: rootWindow) { (_, error) in
                            if error != nil {
                                UDToast.showTips(
                                    with: BundleI18n.LarkUrgent.Lark_Core_SplitScreenNotSupported,
                                    on: rootWindow
                                )
                            }
                        }
                    } else {
                        SceneManager.shared.active(scene: Scene.mainScene(), from: rootWindow) { (window, error) in
                            if let window = window {
                                self.navigator.showDetail(body: body, naviParams: params, context: context, wrap: LkNavigationController.self, from: window)
                            } else if error != nil {
                                UDToast.showTips(
                                    with: BundleI18n.LarkUrgent.Lark_Core_SplitScreenNotSupported,
                                    on: rootWindow
                                )
                            }
                        }
                    }
                } else {
                    self.navigator.showDetail(body: body, naviParams: params, context: context, wrap: LkNavigationController.self, from: rootWindow)
                }
            } else {
                self.rotateToPortraitIfNeeded()
                self.navigator.push(body: body, naviParams: params, from: rootWindow)
            }
        } else {
            assertionFailure()
        }
        urgentAPI.confirmUrgentMessage(ackID: urgentMessageModel.ackID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.removeUrgency(by: urgentMessageModel.ackID)
            }, onError: { [weak rootWindow] error in
                guard let rootWindow = rootWindow else { return }
                UDToast.showFailure(
                    with: BundleI18n.LarkUrgent.Lark_Legacy_FeedConfirmationFail,
                    on: rootWindow,
                    error: error
                )
            })
            .disposed(by: disposeBag)
        self.showAddUrgentNumOnboarding(urgentId: urgentMessageModel.ackID)
    }

    public func confirmUrgency(messageId: String, urgentConfirmSuccess: @escaping () -> Void) {
        var ackIds: [String] = []

        let ackIdsFromCard = (PushCardCenter.shared.showCards + urgencyManager.archiveCards)
            .filter { (card) -> Bool in
                guard let extra = card.extraParams as? [String: Any],
                    let id = extra["messageId"] as? String else {
                        return false
                }
                return id == messageId
            }
            .map { $0.id }
            .filter({ !confirmedACKIds.contains($0) })
        ackIds.append(contentsOf: ackIdsFromCard)
        if let ackIdFromMute = self.muteUrgents.first(where: { model in
            return model.messageId == messageId
        })?.urgentId, !confirmedACKIds.contains(ackIdFromMute) {
            ackIds.append(ackIdFromMute)
        }
        guard !ackIds.isEmpty else {
            return
        }
        for ackId in ackIds {
            confirmedACKIds.insert(ackId)
            //按产品设计，直接移走弹窗，不关心确认接口返回
            self.removeUrgency(by: ackId)
            self.urgentAPI.confirmUrgentMessage(ackID: ackId).subscribe().disposed(by: self.disposeBag)
            self.showAddUrgentNumOnboarding(urgentId: ackId)
        }
        urgentConfirmSuccess()
    }

    /// Push 页面前，强制竖屏，否则在如云文档等横屏场景时，无法跳转成功
    private func rotateToPortraitIfNeeded() {
        if let orientation = Utility.getCurrentInterfaceOrientation(), orientation.isLandscape {
            if #available(iOS 16.0, *),
               let window = self.navigator.mainSceneWindow,
               let windowScene = window.windowScene {
                Utility.focusRotateIfNeeded(to: .portrait, window: window, windowScene: windowScene)
            } else {
                Utility.focusRotateIfNeeded(to: .portrait)
            }
        }
    }

    private var addUrgentNumSettingFg: Bool { userResolver.fg.staticFeatureGatingValue(with: "messenger.buzzcall.numsetting") }
    private var addUrgentNumOnboardingFg: Bool { userResolver.fg.staticFeatureGatingValue(with: "messenger.buzzcall.onboarding") }
    private var addUrgentNumOnboardingShown = false
    /// 展示添加加急电话到通讯录引导弹窗
    private func showAddUrgentNumOnboarding(urgentId: String) {
        //  展示条件：
        //          1. 引导功能fg打开、引导fg打开
        //          2. 本地记录没有展示过，避免同时多个加急消息触发多个弹窗
        //          3. 「设置」-> 「通知」->「添加加急电话到通讯录」关闭
        //          4. 服务端接口返回true，控制展示频率
        guard addUrgentNumSettingFg,
              addUrgentNumOnboardingFg,
              !addUrgentNumOnboardingShown,
              !KVPublic.Setting.enableAddUrgentNum.value() else {
            return
        }
        urgentAPI.pullAllowedAddUrgentNumOnboarding(urgentId: urgentId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isAllowed) in
                guard let self, let vc = self.navigator.mainSceneTopMost, isAllowed else {
                    return
                }
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkUrgent.Lark_Settings_AvoidMissingBuzzCalls_Onboarding_Title)
                alertController.setContent(text: BundleI18n.LarkUrgent.Lark_Settings_AvoidMissingBuzzCalls_Onboarding_Desc())
                alertController.addSecondaryButton(text: BundleI18n.LarkUrgent.Lark_Settings_AvoidMissingBuzzCalls_Onboarding_Later_Button,
                                                   dismissCompletion: {
                    UrgentTracker.trackImDingMsgOnboardingClick(isAdd: false)
                })
                alertController.addPrimaryButton(text: BundleI18n.LarkUrgent.Lark_Settings_AvoidMissingBuzzCalls_GoToSettings_Button,
                                          dismissCompletion: { [weak self] in
                    UrgentTracker.trackImDingMsgOnboardingClick(isAdd: true)
                    let body = MineNotificationSettingBody(highlight: .AddUrgentNum)
                    self?.navigator.push(body: body, from: vc)
                })
                // 延迟0.5保证先进入会话页
                self.addUrgentNumOnboardingShown = true
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                    UrgentTracker.trackImDingMsgOnboardingView()
                    self.navigator.present(alertController, from: vc)
                })
        }).disposed(by: self.disposeBag)
    }
}
