//
//  ShareMomentsPostHandler.swift
//  LarkForward
//
//  Created by zc09v on 2021/1/22.
//

import Foundation
import LarkMessengerInterface
import EENavigator
import Swinject
import LarkSDKInterface
import LarkAccountInterface
import LarkFeatureGating
import LarkUIKit
import LarkOpenFeed
import LarkNavigator

final class ShareMomentsPostHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    func handle(_ body: ShareMomentsPostBody, req: EENavigator.Request, res: Response) throws {
        let content = ShareMomentsPostAlertContent(post: body.post)
        let provider = ShareMomentsPostAlertProvider(userResolver: userResolver,
                                                     content: content,
                                                     action: body.action,
                                                     cancel: body.cancel)
        let canForwardToTopic = true
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: canForwardToTopic)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
