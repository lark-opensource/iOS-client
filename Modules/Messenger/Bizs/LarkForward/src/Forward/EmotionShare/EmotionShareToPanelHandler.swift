//
//  EmotionShareToPanelHandler.swift
//  LarkForward
//
//  Created by huangjianming on 2019/9/3.
//

import Foundation
import Swinject
import EENavigator
import LarkUIKit
import LarkFeatureGating
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigator

final class EmotionShareToPanelHandler: UserTypedRouterHandler {

    func handle(_ body: EmotionShareToPanelBody, req: EENavigator.Request, res: Response) throws {
        let content = EmotionShareToPanelContent(stickerSet: body.stickerSet)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) as? EmotionShareToPanelProvider else { return }

        let vc = ChatterPickerEmotionForwardViewController(provider: provider,
                                                           canForwardToTopic: true)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
}
