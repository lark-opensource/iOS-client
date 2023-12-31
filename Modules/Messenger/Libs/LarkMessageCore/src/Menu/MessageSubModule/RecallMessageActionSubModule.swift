//
//  Recall.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/17.
//

import Foundation
import LarkModel
import RxSwift
import LarkOpenChat
import Homeric
import LarkUIKit
import LarkContainer
import UniverseDesignToast
import LKCommonsTracker
import LarkMessageBase
import LarkAlertController
import EENavigator
import LarkSDKInterface
import LarkCore
import LKCommonsLogging
import LarkSetting
import LarkAccountInterface

open class RecallMessageActionSubModule: MessageActionSubModule {
    private let disposeBag = DisposeBag()
    static let logger = Logger.log(RecallMessageActionSubModule.self, category: "RecallMessageActionSubModule")

    public override var type: MessageActionType {
        return .recall
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public enum RecallMenuActionLocationType {
        case chat
        case threadList
        case threadTopic
    }

    private lazy var currentChatterId: String = self.context.userResolver.userID

    @ScopedInjectedLazy private var messageAPI: MessageAPI?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy public var tenantUniversalSettingService: TenantUniversalSettingService?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    private let locationType: RecallMenuActionLocationType = .chat

    private func handle(message: Message, chat: Chat) {
        let chat = chatAPI?.getLocalChat(by: message.channel.id)
        // 提示的消息
        var alertMessage = ""
        // 判断消息是否是自己发送的
        let recallByMessageSend = message.fromId == self.currentChatterId
        if recallByMessageSend {
            alertMessage = BundleI18n.LarkMessageCore.Lark_Legacy_MessageRecallTip
        } else if let fromChatter = message.fromChatter {
            let name = fromChatter.displayName(chatId: message.channel.id, chatType: .group, scene: .groupOwnerRecall)
            alertMessage = BundleI18n.LarkMessageCore.Lark_Legacy_MessageGroupRecallTip(name)
        }

        self.showAlert(
            title: "",
            message: alertMessage,
            sureHandler: { [weak self] in
                guard let `self` = self else {
                    return
                }

                switch self.locationType {
                case .threadList:
                    Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_MESSAGE_RECALL_CONFIRM))
                case .threadTopic:
                    Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_MESSAGE_RECALL_CONFIRM))
                    if self.currentChatterId == chat?.ownerId {
                        Tracker.post(
                            TeaEvent(
                                "message_admin_recall",
                                category: "message",
                                params: [
                                    "chatid": chat?.id ?? "",
                                    "chat_type": "group_topic"
                                ]
                            )
                        )
                    }
                case .chat:
                    break
                }

                guard let view = self.context.pageAPI?.view else {
                    return
                }
                let hud = UDToast.showLoading(with: BundleI18n.LarkMessageCore.Lark_Legacy_BaseUiLoading, on: view, disableUserInteraction: true)
                if recallByMessageSend {
                    self.recall(message: message, hide: { _ in
                        hud.remove()
                    })
                } else {
                    self.recallByGroupowner(message: message, hide: { _ in
                        hud.remove()
                    })
                }
            }
        )
    }

    open override func canHandle(model: MessageActionMetaModel) -> Bool {
        let isGroupOwner = model.chat.ownerId == self.context.userResolver.userID
        let isFromMe = model.message.fromId == self.context.userResolver.userID
        guard isFromMe || isGroupOwner || model.chat.isGroupAdmin else {
            return false
        }
        /// Admin配置不可撤回(有效时间为0时), 非管理员不展示撤回按钮
        if !(isGroupOwner || model.chat.isGroupAdmin), tenantUniversalSettingService?.getRecallEffectiveTime() ?? 0 == 0 {
            return false
        }
        switch model.message.type {
        case .hongbao, .commercializedHongbao:
            return false
        @unknown default:
            return true
        }
    }

    private func getOvertimeToastContent(_ effectiveTime: Int64) -> String {
        var num = effectiveTime //秒
        num /= 60               //分钟
        if num < 60 {           //60分钟要显示为1小时
            return BundleI18n.LarkMessageCore.Lark_IM_RecallMessage_AdminAllowRecallWithinNumMin_Toast(num)
        }
        num /= 60               //小时
        if num <= 24 {          //24小时要显示为24小时，而非1天
            return BundleI18n.LarkMessageCore.Lark_IM_RecallMessage_AdminAllowRecallWithinNumHr_Toast(num)
        }
        num /= 24               //天
        return BundleI18n.LarkMessageCore.Lark_IM_RecallMessage_AdminAllowRecallWithinNumDays_Toast(num)
    }

    private var errorMessage: String {
        self.getOvertimeToastContent(tenantUniversalSettingService?.getRecallEffectiveTime() ?? 0)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let hasExpired = !(tenantUniversalSettingService?.getIfMessageCanRecall(createTime: model.message.createTime) ?? false)
        let isGroupOwner = model.chat.ownerId == self.context.userResolver.userID
        let shouldGrey = hasExpired && !isGroupOwner
        && !model.chat.isGroupAdmin && (fgService?.staticFeatureGatingValue(with: "messenger.message.mobile_message_menu_transformation") ?? false)
        let action: () -> Void = { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_MenuRecall,
                                 icon: BundleResources.Menu.menu_recall,
                                 enable: !shouldGrey,
                                 disableActionType: .showToast(errorMessage),
                                 trackExtraParams: ["click": "withdraw",
                                                    "target": "none"],
                                 tapAction: action)
    }

    private func recall(message: Message, hide: @escaping (Bool) -> Void) {
        self.messageAPI?
            .recall(messageId: message.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                hide(true)
                self?.showRecallToast(for: message)
            }, onError: { [weak self] (error) in
                hide(false)
                guard let window = self?.context.pageAPI?.view.window else { return }
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .messageRecallOverTime(let errorInfo):
                        UDToast.showFailure(with: errorInfo, on: window, error: error)
                        self?.tenantUniversalSettingService?.loadTenantMessageConf(forceServer: true, onCompleted: nil)
                    default:
                        UDToast.showFailure(
                            with: BundleI18n.LarkMessageCore.Lark_Legacy_RecallMessageErr,
                            on: window,
                            error: error
                        )
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func recallByGroupowner(message: Message, hide: @escaping (Bool) -> Void) {
        self.messageAPI?
            .recallGroupMessage(messageId: message.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                hide(true)
                self?.showRecallToast(for: message)
            }, onError: { [weak self] (error) in
                hide(false)
                guard let window = self?.context.pageAPI?.view.window else { return }
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .messageRecallOverTime(let errorInfo):
                        UDToast.showFailure(with: errorInfo, on: window, error: error)
                    default:
                        UDToast.showFailure(
                            with: BundleI18n.LarkMessageCore.Lark_Legacy_RecallMessageErr,
                            on: window,
                            error: error
                        )
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func showRecallToast(for message: Message) {
        guard let window = self.context.pageAPI?.view.window else { return }
        if message.rootSourceId.isEmpty,
           let cardAnalyticsData = (message.content as? CardContent)?.extraInfo.customConfig.analyticsData.data(using: .utf8),
           let cardAnalyticsJson = try? JSONSerialization.jsonObject(with: cardAnalyticsData, options: []) as? [String: Any],
           let cardType = cardAnalyticsJson["card_type"] as? String, cardType == "email_share_card" {
            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_ChatMailMessageRecallTip,
                                   on: window)
        }
    }

    private func showAlert(title: String, message: String, sureHandler: (() -> Void)?) {
        guard let targetVC = self.context.pageAPI else { return }
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        alertController.addCancelButton(dismissCompletion: { [weak self] in
            guard let `self` = self else {
                return
            }

            switch self.locationType {
            case .threadList, .threadTopic:
                Tracker.post(TeaEvent(Homeric.GROUP_TOPICMODE_TOPIC_MESSAGE_RECALL_CANCEL))
            default:
                break
            }
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_RecallConfirm, dismissCompletion: sureHandler)
        self.context.nav.present(alertController, from: targetVC)
    }
}
