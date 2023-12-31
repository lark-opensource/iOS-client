//
//  ShareContentHandler.swift
//  LarkForward
//
//  Created by zc09v on 2018/8/6.
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
import LarkAlertController

public final class ShareContentHandler: UserTypedRouterHandler, ForwardAndShareHandler {
    static let shareLogger = Logger.log(ShareContentHandler.self, category: "Module.IM.Share")

    public func handle(_ body: ShareContentBody, req: EENavigator.Request, res: Response) throws {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            openForwardComponent(body: body, request: req, response: res)
        } else {
            createForward(body: body, request: req, response: res)
        }
    }

    private func getEnabledConfigs() -> IncludeConfigs {
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    private func openForwardComponent(body: ShareContentBody, request: EENavigator.Request, response: Response) {
        let targetConfig = ForwardTargetConfig(enabledConfigs: self.getEnabledConfigs())
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .sendText, forwardResultCallback: { _ in
            if let sourceAppName = body.sourceAppName, let sourceAppUrl = body.sourceAppUrl {
                if let sourceAppUrlStr = sourceAppUrl.removingPercentEncoding,
                    let sourceAppUrl = URL(string: sourceAppUrlStr) {
                    let alertController = LarkAlertController()
                    alertController.setContent(view: ShareFinishView())
                    alertController.addSecondaryButton(text: "\(BundleI18n.LarkForward.Lark_Legacy_ShareBack) \(sourceAppName)", dismissCompletion: {
                        UIApplication.shared.open(sourceAppUrl)
                    })
                    alertController.addSecondaryButton(text: BundleI18n.LarkForward.Lark_Legacy_StayFeishu(), dismissCompletion: {})
                    self.userResolver.navigator.present(alertController, from: request.from)
                } else {
                    Self.shareLogger.error("no valid sourceAppUrl",
                                           additionalData: ["sourceAppName": sourceAppName])
                }
            }
        })
        let content = ShareContentAlertContent(title: body.title,
                                               content: body.content,
                                               sourceAppName: body.sourceAppName,
                                               sourceAppUrl: body.sourceAppUrl,
                                               shouldShowInputViewWhenShareToTopicCircle: body.shouldShowInputViewWhenShareToTopicCircle)
        let factory = ForwardAlertFactory(userResolver: userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return }
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: targetConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        response.end(resource: nvc)
    }

    private func createForward(body: ShareContentBody, request: EENavigator.Request, response: Response) {

        let content = ShareContentAlertContent(title: body.title,
                                               content: body.content,
                                               sourceAppName: body.sourceAppName,
                                               sourceAppUrl: body.sourceAppUrl,
                                               shouldShowInputViewWhenShareToTopicCircle: body.shouldShowInputViewWhenShareToTopicCircle)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        let nvc = LkNavigationController(rootViewController: vc)
        response.end(resource: nvc)
    }
}
