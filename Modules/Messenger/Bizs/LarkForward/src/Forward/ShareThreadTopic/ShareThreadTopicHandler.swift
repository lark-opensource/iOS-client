//
//  ShareThreadTopicHandler.swift
//  LarkForward
//
//  Created by zc09v on 2019/6/17.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import EENavigator
import RxSwift
import LarkContainer
import Swinject
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator

final class ShareThreadTopicHandler: UserTypedRouterHandler {

    public func handle(_ body: ShareThreadTopicBody, req: EENavigator.Request, res: Response) throws {
        let content = ShareThreadTopicAlertContent(message: body.message, title: body.title)
        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
