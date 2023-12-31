//
//  ShareChatViaLinkHandler.swift
//  LarkForward
//
//  Created by 姜凯文 on 2020/4/19.
//

import Foundation
import EENavigator
import LarkMessengerInterface
import Swinject
import RxSwift
import LarkSDKInterface
import LarkAccountInterface
import LarkFeatureGating
import LarkModel
import LarkUIKit
import LarkSegmentedView
import LKCommonsLogging
import LarkCore
import LarkKAFeatureSwitch
import LarkOpenFeed
import LarkNavigator

public final class ShareChatViaLinkHandler: UserTypedRouterHandler {
    private let disposeBag = DisposeBag()

    public var currentChatterId: String {
        return userResolver.userID
    }

    private static let logger = Logger.log(ShareChatViaLinkHandler.self, category: "Module.IM.Forward.ShareChatViaLink")

    public func handle(_ body: ShareChatViaLinkBody, req: EENavigator.Request, res: Response) throws {
        guard !body.chatId.isEmpty,
              let chatAPI = try? userResolver.resolve(assert: ChatAPI.self) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }
        guard let from = req.context.from() else {
            assertionFailure()
            return
        }

        chatAPI.fetchChat(by: body.chatId, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                guard let self = self, let chat = chat else {
                    res.end(error: RouterError.invalidParameters("chatId"))
                    return
                }
                self.assembleContainerViewController(chat: chat, defaultSelected: body.defaultSelected, from: from)
            }, onError: { _ in
                ShareChatViaLinkHandler.logger.error("chat fetch fail", additionalData: ["chatID": body.chatId])
                res.end(error: RouterError.invalidParameters("chatId"))
            })
            .disposed(by: self.disposeBag)

        res.wait()
    }

    private func getForwardComponentVC(content: ShareChatAlertContent) -> ShareGroupCardForwardComponentViewController? {
        let targetConfig = ForwardTargetConfig(enabledConfigs: getEnabledConfigs(chat: content.fromChat))
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .sendGroupCardForward)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return nil }
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: targetConfig)
        return ShareGroupCardForwardComponentViewController(forwardConfig: forwardConfig) {
            Tracer.trackImChatSettingChatForwardPageView(chatId: content.fromChat.id,
                                                         isAdmin: self.currentChatterId == content.fromChat.ownerId,
                                                         chat: content.fromChat)
        }

        func getEnabledConfigs(chat: Chat) -> IncludeConfigs {
            // 内部群 -> 内部, 话题暂时无法判断内外部信息，都置灰，后续话题支持区分内外部后可优化策略
            // 外部群 -> 内部 + 外部
            let isCrossTenantGroupChat = chat.isCrossTenant
            var includeConfigs: IncludeConfigs = [
                ForwardUserEnabledEntityConfig(tenant: isCrossTenantGroupChat ? .all : .inner),
                ForwardGroupChatEnabledEntityConfig(tenant: isCrossTenantGroupChat ? .all : .inner),
                ForwardBotEnabledEntityConfig()
            ]
            if isCrossTenantGroupChat { includeConfigs.append(ForwardThreadEnabledEntityConfig()) }
            return includeConfigs
        }
    }

    private func assembleContainerViewController(chat: Chat, defaultSelected: ShareChatViaLinkType, from: NavigatorFrom) {
        let content = ShareChatAlertContent(fromChat: chat)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content),
              let feedSyncDispatchService = try? userResolver.resolve(assert: FeedSyncDispatchService.self),
              let serverNTPTimeService = try? userResolver.resolve(assert: ServerNTPTimeService.self),
              let modelService = try? userResolver.resolve(assert: ModelService.self),
              let shareQRCodeVC = try? userResolver.resolve(assert: ShareGroupQRCodeController.self, arguments: chat, false, true),
              let shareGroupLinkVC = try? userResolver.resolve(assert: ShareGroupLinkController.self, arguments: chat, true)
        else { return }

        let isAdmin = self.currentChatterId == chat.ownerId
        let chatId = chat.id
        Tracer.imShareGroupView(chat: chat)
        var shareGroupCardVC: JXSegmentedListContainerViewListDelegate
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            guard let vc = self.getForwardComponentVC(content: content) else { return }
            shareGroupCardVC = vc
        } else {
            shareGroupCardVC = NewShareGroupCardViewController(provider: provider, router: ForwardViewControllerRouterImpl(userResolver: userResolver)) {
                Tracer.trackImChatSettingChatForwardPageView(chatId: chatId, isAdmin: isAdmin, chat: chat)
            }
        }
        let groupLinkSwitchisOpen = userResolver.fg.staticFeatureGatingValue(with: .init(switch: .shareLink))
        let shareChatViaLinkTypes: [ShareChatViaLinkType] = [.card, groupLinkSwitchisOpen ? .link : nil, .QRcode].compactMap { $0 }
        let subViewControllers = [shareGroupCardVC, groupLinkSwitchisOpen ? shareGroupLinkVC : nil, shareQRCodeVC].compactMap { $0 }
        let containerVC = ShareChatViaLinkContainerViewController(
            isThreadGroup: chat.chatMode == .threadV2,
            subViewControllers: subViewControllers,
            shareChatViaLinkTypes: shareChatViaLinkTypes,
            defaultSelected: defaultSelected
        )
        let navigationController = LkNavigationController(rootViewController: containerVC)
        userResolver.navigator.present(
            navigationController,
            from: from,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
    }
}
