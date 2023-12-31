//
//  FlagActionFactory.swift
//  LarkFeed
//
//  Created by Fan Hui on 2022/5/25.
//

import UIKit
import Foundation
import LarkContainer
import LarkCore
import Swinject
import LarkFeatureGating
import LarkSDKInterface
import LarkMessageCore
import LarkAI

final class FlagActionFactory {
    unowned let dispatcher: RequestDispatcher
    unowned let controller: UIViewController
    unowned let assetsProvider: HasAssets

    init(
        dispatcher: RequestDispatcher,
        controller: UIViewController,
        assetsProvider: HasAssets
    ) {
        self.dispatcher = dispatcher
        self.controller = controller
        self.assetsProvider = assetsProvider
    }

    func registerActions() {
        // 查看图片
        dispatcher.register(PreviewAssetActionMessage.self, loader: { [unowned assetsProvider, userResolver = dispatcher.userResolver] in
            return PreviewAssetAction(userResolver: userResolver, assetsProvider: assetsProvider)
        }, cacheHandler: true)

        /// click abbreviation show ner menu
        dispatcher.register(ShowEnterpriseEntityWordCardMessage.self, loader: { [unowned controller, userResolver = dispatcher.userResolver] in
            return ShowEnterpriseEntityWordCardAction(userResolver: userResolver, targetVC: controller)
        }, cacheHandler: true)
    }
}
