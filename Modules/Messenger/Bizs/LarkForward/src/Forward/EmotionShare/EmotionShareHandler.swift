//
//  EmotionShareHandlee.swift
//  LarkForward
//
//  Created by huangjianming on 2019/8/20.
//

import Foundation
import Swinject
import EENavigator
import LarkUIKit
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkContainer
import LarkNavigator

final class EmotionShareHandler: UserTypedRouterHandler {

    public func handle(_ body: EmotionShareBody, req: EENavigator.Request, res: Response) throws {
        let content = EmotionShareAlertContent(stickerSet: body.stickerSet)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
