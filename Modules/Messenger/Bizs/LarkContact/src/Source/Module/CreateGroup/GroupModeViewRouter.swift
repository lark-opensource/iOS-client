//
//  GroupModeViewRouter.swift
//  LarkContact
//
//  Created by shane on 2019/5/14.
//

import Foundation
import Swinject
import LarkCore
import LarkModel
import EENavigator
import LarkMessengerInterface
import LarkFeatureGating
import LarkSDKInterface
import SuiteAppConfig
import RxSwift
import LarkContainer
import LarkAccountInterface
import LarkNavigator

final class GroupModeViewRouter: UserTypedRouterHandler {

    func handle(_ body: GroupModeViewBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let viewController = GroupModeViewController(
            modeType: body.modeType,
            ability: body.ability,
            completion: body.completion,
            hasSelectedExternalChatter: body.hasSelectedExternalChatter,
            hasSelectedChatOrDepartment: body.hasSelectedChatOrDepartment,
            resolver: userResolver
        )
        res.end(resource: viewController)
    }
}
