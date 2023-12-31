//
//  ForwardCopyFromFolderMessageHandler.swift
//  LarkForward
//
//  Created by 赵家琛 on 2021/4/21.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LarkCore
import Swinject
import LarkModel
import EENavigator
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator

public final class ForwardCopyFromFolderMessageHandler: UserTypedRouterHandler, ForwardAndShareHandler {

    public func handle(_ body: ForwardCopyFromFolderMessageBody, req: EENavigator.Request, res: Response) throws {
        try createForward(body: body, req: req, res: res)
    }

    private func createForward(body: ForwardCopyFromFolderMessageBody, req: EENavigator.Request, res: Response) throws {
        let content = ForwardCopyFromFolderMessageAlertContent(
            folderMessageId: body.folderMessageId,
            key: body.key,
            name: body.name,
            size: body.size,
            copyType: body.copyType
        )

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }

        let router = try userResolver.resolve(assert: ForwardViewControllerRouter.self)
        let vc = NewForwardViewController(provider: provider, router: ForwardViewControllerRouterImpl(userResolver: userResolver))
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
