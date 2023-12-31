//
//  AtUserHandler.swift
//  LarkForward
//
//  Created by Jiang Chun on 2022/4/12.
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

final class AtUserHandler: UserTypedRouterHandler {

    func handle(_ body: AtUserBody, req: EENavigator.Request, res: Response) throws {
        guard let from = req.context.from() else {
            assertionFailure()
            return
        }
        let vc = AtUserViewController(provider: body.provider, canForwardToTopic: true, successCallBack: body.atSuccessCallBack, cancelCallBack: body.atCancelCallBack)
        let nvc = LkNavigationController(rootViewController: vc)
        res.end(resource: nvc)
        return
    }
}
