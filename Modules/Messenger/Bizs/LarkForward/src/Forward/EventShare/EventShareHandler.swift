//
//  EventShareHandler.swift
//  Pods
//
//  Created by zhu chao on 2018/8/15.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LKCommonsLogging
import LarkModel
import LarkCore
import EENavigator
import Swinject
import UniverseDesignToast
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator

public final class EventShareHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    public func handle(_ body: EventShareBody, req: EENavigator.Request, res: Response) throws {
        createForward(body: body, request: req, response: res)
    }

    func createForward(body: EventShareBody, request: EENavigator.Request, response: Response) {
        let userResolver = self.userResolver
        let content = EventShareAlertContent(shareMessage: body.shareMessage,
                                             subMessage: body.subMessage,
                                             shareImage: body.shareImage,
                                             shouldShowExternalUser: body.shouldShowExternalUser,
                                             shouldShowHint: body.shouldShowHint,
                                             callBack: body.pickerCallBack)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        let nvc = LkNavigationController(rootViewController: vc)
        response.end(resource: nvc)
    }
}
