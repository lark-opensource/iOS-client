//
//  ForwardMentionHandler.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/17.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LarkCore
import Swinject
import LarkModel
import EENavigator
import UniverseDesignToast
import LarkFeatureGating
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigator

final class ForwardMentionHandler: UserTypedRouterHandler {
    func handle(_ body: ForwardMentionBody, req: EENavigator.Request, res: Response) throws {
        guard let from = req.context.from() else {
            assertionFailure()
            return
        }
        let vc = ForwardMentionViewController(forwardConfig: body.forwardConfig,
                                              successCallBack: body.atSuccessCallBack,
                                              cancelCallBack: body.atCancelCallBack)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
        return
    }
}
