//
//  ShareChatHandler.swift
//  LarkForward
//
//  Created by zc09v on 2018/8/6.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LKCommonsLogging
import EENavigator
import Swinject
import UniverseDesignToast
import LarkModel
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator

public final class ShareChatHandler: UserTypedRouterHandler, ForwardAndShareHandler {
    private let disposeBag = DisposeBag()

    public func handle(_ body: ShareChatBody, req: EENavigator.Request, res: Response) throws {
        guard !body.chatId.isEmpty, let chatAPI = try? userResolver.resolve(assert: ChatAPI.self) else {
            res.end(error: RouterError.invalidParameters("chatId"))
            return
        }

        chatAPI.fetchChat(by: body.chatId, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                guard let self = self, let chat = chat else {
                    res.end(error: RouterError.invalidParameters("chatId"))
                    return
                }
                let mainFG = self.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
                let subFG = self.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
                if mainFG && subFG {
                    self.openForwardComponent(chat: chat, req: req, res: res)
                } else {
                    self.createForward(chat: chat, req: req, res: res)
                }
            }, onError: { _ in
                res.end(error: RouterError.invalidParameters("chatId"))
            })
            .disposed(by: self.disposeBag)

        res.wait()
    }

    private func getEnabledConfigs(chat: Chat) -> IncludeConfigs {
        // 内部群 -> 内部, 话题暂时无法判断内外部信息，都置灰，后续话题支持区分内外部后可优化策略
        // 外部群 -> 内部 + 外部
        var isCrossTenantGroupChat = chat.isCrossTenant
        var includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(tenant: isCrossTenantGroupChat ? .all : .inner),
            ForwardGroupChatEnabledEntityConfig(tenant: isCrossTenantGroupChat ? .all : .inner),
            ForwardBotEnabledEntityConfig()
        ]
        if isCrossTenantGroupChat { includeConfigs.append(ForwardThreadEnabledEntityConfig()) }
        return includeConfigs
    }

    private func openForwardComponent(chat: Chat, req: EENavigator.Request, res: Response) {
        let targetConfig = ForwardTargetConfig(enabledConfigs: self.getEnabledConfigs(chat: chat))
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .sendGroupCardForward)
        let content = ShareChatAlertContent(fromChat: chat)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return }
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: targetConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    private func createForward(chat: Chat, req: EENavigator.Request, res: Response) {

        let content = ShareChatAlertContent(fromChat: chat)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
