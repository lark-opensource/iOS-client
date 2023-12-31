//
//  ForwardLingoHandler.swift
//  LarkForward
//
//  Created by Patrick on 6/12/2022.
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

public final class ForwardLingoHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    public func handle(_ body: ForwardLingoBody, req: EENavigator.Request, res: Response) throws {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            openForwardComponent(body: body, req: req, res: res)
        } else {
            createForward(body: body, req: req, res: res)
        }
    }

    private func openForwardComponent(body: ForwardLingoBody, req: EENavigator.Request, res: Response) {
        guard let from = req.context.from() else {
            assertionFailure()
            return
        }
        let commonConfig = ForwardCommonConfig(forwardTrackScene: .sendText,
                                               forwardResultCallback: { result in
            let selectChatIds = result?.chatIDs
            let selectUserIds = result?.userIDs
            body.sentCompletion(selectUserIds ?? [""], selectChatIds ?? [""])
        })
        let content = ForwardLingoAlertContent(content: body.content, title: body.title, sentCompletion: body.sentCompletion)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: content) else { return }
        let forwardConfig = ForwardConfig(alertConfig: alertConfig, commonConfig: commonConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        let nvc = LkNavigationController(rootViewController: vc)
        self.userResolver.navigator.present(
            nvc,
            from: from,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
    }

    private func createForward(body: ForwardLingoBody, req: EENavigator.Request, res: Response) {
        guard let from = req.context.from() else {
            assertionFailure()
            return
        }

        let content = ForwardLingoAlertContent(content: body.content, title: body.title, sentCompletion: body.sentCompletion)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        let nvc = LkNavigationController(rootViewController: vc)
        self.userResolver.navigator.present(
            nvc,
            from: from,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
    }
}
