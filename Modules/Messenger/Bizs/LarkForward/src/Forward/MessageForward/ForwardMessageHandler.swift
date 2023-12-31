//
//  ForwardMessageHandler.swift
//  LarkForward
//
//  Created by zc09v on 2018/8/6.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LarkCore
import Swinject
import LarkModel
import EENavigator
import UniverseDesignToast
import LarkFeatureGating
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator
import AppReciableSDK

public final class ForwardMessageHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    public func handle(_ body: ForwardMessageBody, req: EENavigator.Request, res: Response) throws {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            openForwardComponent(body: body, req: req, res: res)
        } else {
            createForward(body: body, req: req, res: res)
        }
    }

    private func openForwardComponent(body: ForwardMessageBody, req: EENavigator.Request, res: Response) {
        guard let from = req.context.from() else {
            assertionFailure()
            return
        }
        if memeStickerNotPaid(content: body.message.content) {
            showStickerNotPaidTips(from: from)
            return
        }
        let content = MessageForwardAlertContent(originMergeForwardId: body.originMergeForwardId,
                                                 message: body.message,
                                                 type: body.type,
                                                 from: body.from,
                                                 traceChatType: body.traceChatType,
                                                 supportToThread: body.supportToMsgThread,
                                                 context: body.context)
        // 目标配置
        let targetConfig = ForwardTargetConfig(includeConfigs: getFilterIncludeConfig(),
                                               enabledConfigs: getDisabledIncludeConfigs(body))
        // 通用配置
        let commonConfig = ForwardCommonConfig(enableCreateGroupChat: self.shouldCreateGroup(content),
                                               forwardTrackScene: .transmitSingleMessage,
                                               forwardResultCallback: { result in
            guard let result = result else { return }
            switch result.forwardResults {
            case .success(_):
                Self.trackForwaradMessageSuccess(beforeSendTime: result.beforeSendTime, content: content)
            case .failure(let error):
                //失败埋点
                Self.trackForwardMessageError(content: content,
                                              error: error,
                                              chatIds: result.chatIDs ?? [""],
                                              userIds: result.userIDs ?? [""])
            }
        })
        // 确认框配置
        let factroy = ForwardAlertFactory(userResolver: self.userResolver)
        guard let alertConfig = factroy.createAlertConfigWithContent(content: content) else { return }
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: targetConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    private static func trackForwaradMessageSuccess(beforeSendTime: CFTimeInterval, content: MessageForwardAlertContent) {
        //发送成功埋点
        let sdk_cost = CACurrentMediaTime() - beforeSendTime
        let extra = Extra(
            isNeedNet: true,
            latencyDetail: [
                "sdk_cost": Int(sdk_cost * 1000)
            ],
            metric: nil,
            category: [
                "message_type": "\(content.message.type.rawValue)",
                "chat_type": "\(content.traceChatType.rawValue)"
            ],
            extra: [
                "context_id": ""
            ]
        )
        AppReciableSDK.shared.end(key: AppReciableSDK.shared.start(biz: .Messenger, scene: .Chat, event: .forwardMessage, page: "ForwardComponentViewController"),
                                  extra: extra)
        if content.message.content is StickerContent {
            Tracer.trackStickerForward(from: .chat)
        }
        if content.message.type == .shareCalendarEvent {
            Tracer.trackEventShareForwardDone()
        }
    }

    private static func trackForwardMessageError(content: MessageForwardAlertContent,
                                                 error: Error,
                                                 chatIds: [String],
                                                 userIds: [String]) {
        AppReciableSDK.shared.error(
            params: ErrorParams(
                biz: .Messenger,
                scene: .Chat,
                event: .forwardMessage,
                errorType: .SDK,
                errorLevel: .Exception,
                errorCode: (error as NSError).code,
                userAction: nil,
                page: "ForwardComponentViewController",
                errorMessage: (error as NSError).description,
                extra: Extra(
                    isNeedNet: true,
                    category: [
                        "message_type": "\(content.message.type.rawValue)",
                        "chat_type": "\(content.traceChatType.rawValue)",
                        "transmit_type": "\(content.type.rawValue)"
                    ],
                    extra: [
                        "context_id": "",
                        "chat_count": "\(chatIds.count + userIds.count)",
                        "origin_id": "\(content.message.id)",
                        "include_static_resource": content.message.hasResource
                    ]
                )
            )
        )
    }

    private func shouldCreateGroup(_ content: MessageForwardAlertContent) -> Bool {
        return content.message.content is EventShareContent ? false : true
    }

    private func getDisabledIncludeConfigs(_ body: ForwardMessageBody) -> IncludeConfigs {
        var cannotShowOuterTenant = body.message.type == .shareCalendarEvent
        if let content = (body.message.content as? EventShareContent) {
            //仅在日程是内部日程且有会议群的情况下置灰外部用户
            cannotShowOuterTenant = content.isMeeting && !content.isCrossTenant
        }
        //产品预期日历消息置灰话题对齐日历分享
        let notCalendarMessage = !(body.message.type == .calendar || body.message.type == .shareCalendarEvent)
        let supprotToThread = notCalendarMessage
        let supprotToMsgThread = body.supportToMsgThread

        var includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(tenant: cannotShowOuterTenant ? .inner : .all),
            ForwardGroupChatEnabledEntityConfig(tenant: cannotShowOuterTenant ? .inner : .all),
            ForwardBotEnabledEntityConfig(),
            ForwardMyAiEnabledEntityConfig()
        ]
        if supprotToThread {
            let type = supprotToMsgThread ? ThreadTypeCondition.all : ThreadTypeCondition.normal
            includeConfigs.append(ForwardThreadEnabledEntityConfig(threadType: type))
        }
        return includeConfigs
    }

    private func getFilterIncludeConfig() -> [EntityConfigType] {
        return [ForwardUserEntityConfig(),
                ForwardGroupChatEntityConfig(),
                ForwardBotEntityConfig(),
                ForwardThreadEntityConfig(),
                ForwardMyAiEntityConfig()]
    }

    private func createForward(body: ForwardMessageBody, req: EENavigator.Request, res: Response) {
        guard let from = req.context.from() else {
            assertionFailure()
            return
        }
        // 如果是未付费表情包.需要提示
        if  let content = body.message.content as? StickerContent {
            let stickerSet = content.transformToSticker()
            if stickerSet.mode == .meme, !stickerSet.hasPaid_p {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkForward.Lark_Chat_StickerPackNeedBuy, font: .systemFont(ofSize: 17))
                alertController.addButton(text: BundleI18n.LarkForward.Lark_Chat_StickerPackKnow)
                userResolver.navigator.present(alertController, from: from)
                return
            }
        }

        let content = MessageForwardAlertContent(originMergeForwardId: body.originMergeForwardId,
                                                 message: body.message,
                                                 type: body.type,
                                                 from: body.from,
                                                 traceChatType: body.traceChatType,
                                                 supportToThread: body.supportToMsgThread,
                                                 context: body.context)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let canForwardToTopic = true
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider,
                                          router: router,
                                          canForwardToMsgThread: body.supportToMsgThread,
                                          canForwardToTopic: canForwardToTopic)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    private func memeStickerNotPaid(content: MessageContent) -> Bool {
        var memeStickerNotPaid: Bool = false
        if let content = content as? StickerContent {
            let stickerSet = content.transformToSticker()
            memeStickerNotPaid = stickerSet.mode == .meme && !stickerSet.hasPaid_p
        }
        return memeStickerNotPaid
    }

    private func showStickerNotPaidTips(from: NavigatorFrom) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkForward.Lark_Chat_StickerPackNeedBuy, font: .systemFont(ofSize: 17))
        alertController.addPrimaryButton(text: BundleI18n.LarkForward.Lark_Chat_StickerPackKnow)
        userResolver.navigator.present(alertController, from: from)
    }
}
