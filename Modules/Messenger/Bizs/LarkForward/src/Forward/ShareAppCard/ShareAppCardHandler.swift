//
//  ShareAppCardHandler.swift
//  LarkForward
//
//  Created by qihongye on 2019/5/10.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LKCommonsLogging
import Swinject
import EENavigator
import UniverseDesignToast
import LarkModel
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator

public final class ShareAppCardHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    public func handle(_ body: AppCardShareBody, req: EENavigator.Request, res: Response) throws {
        createForward(body: body, request: req, response: res)
    }

    private func createForward(body: AppCardShareBody, request: EENavigator.Request, response: Response) {

        var content = ShareAppCardAlertContent(shareType: body.appShareType, appUrl: body.appUrl, callback: body.callback)
        content.multiSelect = body.multiSelect
        content.customView = body.customView

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        let nvc = LkNavigationController(rootViewController: vc)
        response.end(resource: nvc)
    }
}
