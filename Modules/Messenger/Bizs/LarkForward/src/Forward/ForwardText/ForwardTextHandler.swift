//
//  ForwardTextHandler.swift
//  LarkForward
//
//  Created by Miaoqi Wang on 2020/4/21.
//

import Foundation
import EENavigator
import LarkMessengerInterface
import Swinject
import LarkSDKInterface
import LarkAccountInterface
import LarkFeatureGating
import LarkUIKit
import LarkOpenFeed
import LarkNavigator
import LarkModel

final class ForwardTextHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    func handle(_ body: ForwardTextBody, req: EENavigator.Request, res: Response) throws {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            openForwardComponent(body: body, req: req, res: res)
        } else {
            openForward(body: body, req: req, res: res)
        }
    }

    private func openForward(body: ForwardTextBody, req: Request, res: Response) {
        let content = ForwardTextAlertContent(text: body.text, sentHandler: body.sentHandler)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        vc.shareResultsCallBack = body.shareResultsCallBack
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    private func getIncludeConfig() -> IncludeConfigs {
        let includeConfigs: IncludeConfigs = [
            ForwardUserEntityConfig(),
            ForwardGroupChatEntityConfig(),
            ForwardBotEntityConfig(),
            ForwardMyAiEntityConfig(),
            ForwardThreadEntityConfig()
        ]
        return includeConfigs
    }

    private func getEnabledConfig() -> IncludeConfigs {
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig(),
            ForwardMyAiEnabledEntityConfig()
        ]
        return includeConfigs
    }

    private func openForwardComponent(body: ForwardTextBody, req: Request, res: Response) {
        let targetConfig = ForwardTargetConfig(includeConfigs: getIncludeConfig(),
                                               enabledConfigs: getEnabledConfig())
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .sendText,
                                               forwardResultCallback: { result in
            let forwardRes = result?.forwardResults
            let selectChatIds = result?.chatIDs
            let selectUserIds = result?.userIDs
            body.sentHandler?(selectUserIds ?? [""], selectChatIds ?? [""])
            switch forwardRes {
            case .success(let data):
                body.shareResultsCallBack?(data.compactMap { $0 }.map { ($0.chatID, $0.isSuccess) })
            case .failure(_), .none:
                break
            }
        })
        let content = ForwardTextAlertContent(text: body.text,
                                              sentHandler: body.sentHandler)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return }
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: targetConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
