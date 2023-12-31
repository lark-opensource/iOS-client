//
//  ForwardViewControllerServiceImpl.swift
//  LarkForward
//
//  Created by Prontera on 2020/4/7.
//

import Foundation
import LarkAccountInterface
import LarkFeatureGating
import LarkSDKInterface
import Swinject
import LarkMessengerInterface
import UIKit
import LarkOpenFeed
import LarkContainer

final class ForwardViewControllerServiceImpl: ForwardViewControllerService {

    let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func forwardViewController(with content: ForwardAlertContent) -> UIViewController? {
        let factory = ForwardAlertFactory(userResolver: resolver)
        guard let provider = factory.createWithContent(content: content) else {
            return nil
        }
        let router = ForwardViewControllerRouterImpl(userResolver: resolver)
        let vc = NewForwardViewController(provider: provider, router: router)
        return vc
    }

    func forwardComponentViewController(alertContent: ForwardAlertContent,
                                        commonConfig: ForwardCommonConfig = ForwardCommonConfig(),
                                        targetConfig: ForwardTargetConfig = ForwardTargetConfig(),
                                        additionNoteConfig: ForwardAdditionNoteConfig = ForwardAdditionNoteConfig(),
                                        chooseConfig: ForwardChooseConfig = ForwardChooseConfig()) -> UIViewController? {
        let factory = ForwardAlertFactory(userResolver: resolver)
        guard let alertConfig = factory.createAlertConfigWithContent(content: alertContent) else { return nil }
        let forwardConfig = ForwardConfig(alertConfig: alertConfig,
                                          commonConfig: commonConfig,
                                          targetConfig: targetConfig,
                                          addtionNoteConfig: additionNoteConfig,
                                          chooseConfig: chooseConfig)
        let vc = ForwardComponentViewController(forwardConfig: forwardConfig)
        return vc
    }

    func getForwardVC(provider: ForwardAlertProvider, delegate: ForwardComponentDelegate?) -> ForwardComponentVCType {
        let router = ForwardViewControllerRouterImpl(userResolver: resolver)
        let vc = NewForwardViewController(provider: provider,
                                          router: router,
                                          delegate: delegate)
        return vc
    }
}
