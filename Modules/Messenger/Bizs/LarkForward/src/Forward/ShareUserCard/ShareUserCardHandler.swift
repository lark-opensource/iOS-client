//
//  ShareUserCardHandler.swift
//  LarkForward
//
//  Created by 赵家琛 on 2020/4/24.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LKCommonsLogging
import EENavigator
import Swinject
import LarkModel
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator

public final class ShareUserCardHandler: UserTypedRouterHandler, ForwardAndShareHandler {
    private let disposeBag = DisposeBag()

    public func handle(_ body: ShareUserCardBody, req: EENavigator.Request, res: Response) throws {
        guard !body.shareChatterId.isEmpty,
              let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self) else {
            res.end(error: RouterError.invalidParameters("chatterId"))
            return
        }

        chatterAPI.getChatter(id: body.shareChatterId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatter) in
                guard let self = self, let chatter = chatter else {
                    res.end(error: RouterError.invalidParameters("chatterId"))
                    return
                }
                let mainFG = self.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
                let subFG = self.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
                if mainFG && subFG {
                    self.openForwardComponent(chatter: chatter, req: req, res: res)
                } else {
                    self.createForward(chatter: chatter, req: req, res: res)
                }
            }, onError: { _ in
                res.end(error: RouterError.invalidParameters("chatterId"))
            })
            .disposed(by: self.disposeBag)
        res.wait()
    }

    private func getEnabledConfigs() -> IncludeConfigs {
        // 话题置灰
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    private func openForwardComponent(chatter: Chatter, req: EENavigator.Request, res: Response) {
        let targetConfig = ForwardTargetConfig(enabledConfigs: getEnabledConfigs())
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .sendUserCard)
        let content = ShareUserCardAlertContent(shareChatter: chatter)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return }
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: targetConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    private func createForward(chatter: Chatter, req: EENavigator.Request, res: Response) {
        let content = ShareUserCardAlertContent(shareChatter: chatter)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let canForwardToTopic = true
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: canForwardToTopic)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
