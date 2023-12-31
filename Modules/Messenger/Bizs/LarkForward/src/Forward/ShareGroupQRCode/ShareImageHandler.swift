//
//  ShareImageHandler.swift
//  LarkForward
//
//  Created by K3 on 2018/9/17.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LKCommonsLogging
import Swinject
import EENavigator
import UniverseDesignToast
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator
import LarkModel

final class ShareImageHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    public func handle(_ body: ShareImageBody, req: EENavigator.Request, res: Response) throws {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            openForwardComponent(body: body, req: req, res: res)
        } else {
            openForward(body: body, req: req, res: res)
        }
    }

    private func openForward(body: ShareImageBody, req: EENavigator.Request, res: Response) {
        let content = ShareImageAlertContent(image: body.image, type: body.type, needFilterExternal: body.needFilterExternal)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        vc.cancelCallBack = body.cancelCallBack
        vc.successCallBack = body.successCallBack
        vc.shareResultsCallBack = body.shareResultsCallBack
        vc.forwardResultsCallBack = body.forwardResultsCallBack
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    private func getEnabledConfigs(body: ShareImageBody) -> IncludeConfigs {
        let includeConfigs: IncludeConfigs = [
            //业务需要置灰帖子
            ForwardUserEnabledEntityConfig(tenant: body.needFilterExternal ? .inner : .all),
            ForwardGroupChatEnabledEntityConfig(tenant: body.needFilterExternal ? .inner : .all),
            ForwardBotEnabledEntityConfig(),
            ForwardMyAiEnabledEntityConfig()
        ]
        return includeConfigs
    }

    private func getIncludeConfigs() -> IncludeConfigs {
        let includeConfigs: IncludeConfigs = [
            ForwardUserEntityConfig(),
            ForwardGroupChatEntityConfig(),
            ForwardBotEntityConfig(),
            ForwardThreadEntityConfig(),
            ForwardMyAiEntityConfig()
        ]
        return includeConfigs
    }

    private func openForwardComponent(body: ShareImageBody, req: EENavigator.Request, res: Response) {
        let targetConfig = ForwardTargetConfig(includeConfigs: getIncludeConfigs(),
                                               enabledConfigs: getEnabledConfigs(body: body))
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .sendImage,
                                               dismissAction: body.cancelCallBack,
                                               forwardResultCallback: { result in
            // forwardResultCallback回调时间为转发完成后，承接successCallback/forwardResultsCallback/shareResultsCallback逻辑
            body.successCallBack?()
            let forwardRes = result?.forwardResults.map {
                return ForwardParam(forwardItems: $0.compactMap { $0 })
            }
            body.forwardResultsCallBack?(forwardRes)
            switch forwardRes {
            case .success(let data):
                body.shareResultsCallBack?(data.forwardItems.map { ($0.chatID, $0.isSuccess) })
            case .failure(_), .none:
                break
            }
        })
        let content = ShareImageAlertContent(image: body.image,
                                             type: body.type,
                                             needFilterExternal: body.needFilterExternal)
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
