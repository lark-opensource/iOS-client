//
//  SendSingleEmotionHandler.swift
//  LarkForward
//
//  Created by huangjianming on 2019/9/3.
//

import Foundation
import Swinject
import EENavigator
import LarkUIKit
import LarkFeatureGating
import LarkSendMessage
import LarkAccountInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator

final class SendSingleEmotionHandler: UserTypedRouterHandler {

    public func handle(_ body: SendSingleEmotionBody, req: EENavigator.Request, res: Response) throws {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            try openForwardComponent(body: body, req: req, res: res)
        } else {
            try openForward(body: body, req: req, res: res)
        }
    }

    private func openForward(body: SendSingleEmotionBody, req: EENavigator.Request, res: Response) throws {
        let messageAPI = try resolver.resolve(assert: SendMessageAPI.self)
        let content = SendSingleEmotionContent(sticker: body.sticker, sendMessageAPI: messageAPI, message: body.message)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    private func openForwardComponent(body: SendSingleEmotionBody, req: EENavigator.Request, res: Response) throws {
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .transmitSingleMessage, forwardResultCallback: { _ in
            Tracer.trackStickerForward(from: .emotionDetailPage)
        })
        let chooseConfig = ForwardChooseConfig(enableSwitchSelectMode: false)
        let messageAPI = try resolver.resolve(assert: SendMessageAPI.self)
        let content = SendSingleEmotionContent(sticker: body.sticker, sendMessageAPI: messageAPI, message: body.message)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return }
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          chooseConfig: chooseConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
