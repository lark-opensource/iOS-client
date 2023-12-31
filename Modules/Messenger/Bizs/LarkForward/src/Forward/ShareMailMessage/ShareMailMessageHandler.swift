//
//  MailMessageShareHandler.swift
//  LarkForward
//
//  Created by tefeng liu on 2019/12/10.
//

import EENavigator
import Foundation
import LarkAccountInterface
import LarkFeatureGating
import LarkMessengerInterface
import LarkSDKInterface
import LarkUIKit
import Swinject
import LarkOpenFeed
import LarkNavigator

public final class ShareMailMessageHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    public func handle(_ body: MailMessageShareBody, req: EENavigator.Request, res: Response) throws {
        createForward(body: body, req: req, res: res)
    }

    private func createForward(body: MailMessageShareBody, req _: EENavigator.Request, res: Response) {
        var content = ShareMailMessageContent(threadId: body.threadId, messageIds: body.messageIds, title: body.summary)
        content.statisticsParams = body.statisticsParams
        let factory = ForwardAlertFactory(userResolver: userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
