//
//  ChatChooseHandler.swift
//  Action
//
//  Created by yin on 2019/6/6.
//

import EENavigator
import Foundation
import LarkAccountInterface
import LarkContainer
import LarkFeatureGating
import LarkMessengerInterface
import LarkSDKInterface
import LarkUIKit
import RxSwift
import Swinject
import LarkOpenFeed
import LarkNavigator

public final class ChatChooseHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    public func handle(_ body: ChatChooseBody, req: EENavigator.Request, res: Response) throws {
        try createForward(body: body, req: req, res: res)
    }

    private func createForward(body: ChatChooseBody, req _: EENavigator.Request, res: Response) throws {
        var content = ChatChooseAlertContent(allowCreateGroup: body.allowCreateGroup,
                                             multiSelect: body.multiSelect,
                                             ignoreSelf: body.ignoreSelf,
                                             ignoreBot: body.ignoreBot,
                                             needSearchOuterTenant: body.needSearchOuterTenant,
                                             includeMyAI: body.includeMyAI,
                                             includeOuterChat: body.includeOuterChat,
                                             selectType: body.selectType,
                                             confirmTitle: body.confirmTitle,
                                             confirmDesc: body.confirmDesc,
                                             confirmOkText: body.confirmOkText,
                                             showInputView: body.showInputView,
                                             preSelectInfos: body.preSelectInfos,
                                             showRecentForward: body.showRecentForward,
                                             callback: body.callback,
                                             blockingCallback: body.blockingCallback,
                                             forwardVCDismissBlock: body.forwardVCDismissBlock)
        content.targetPreview = body.targetPreview
        let factory = ForwardAlertFactory(userResolver: userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }
        provider.permissions = body.permissions
        let router = try userResolver.resolve(assert: ForwardViewControllerRouter.self)
        if body.isWithinContainer {
            let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
            let vc = NewChatChooseViewController(provider: provider, router: router, canForwardToTopic: false)
            res.end(resource: vc)
        } else {
            let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
            let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
            let nvc = LkNavigationController(rootViewController: vc)
            res.end(resource: nvc)
        }
    }
}
