//
//  LDRGuideHandler.swift
//  LarkContact
//
//  Created by Aslan on 2021/6/28.
//

import Foundation
import EENavigator
import Swinject
import LarkSDKInterface
import LarkAppConfig
import LarkNavigator
import LarkAccountInterface

final class LDRGuideHandler: UserTypedRouterHandler {

    func handle(_ body: LDRGuideBody, req: EENavigator.Request, res: Response) throws {
        let passportService = try resolver.resolve(assert: PassportService.self)
        let isOversea = passportService.isOversea
        let viewModel = try LDRGuideViewModel(isOversea: isOversea, resolver: userResolver)
        let ldrGuideVC = LDRGuideViewController(vm: viewModel, showBackItem: false, resolver: userResolver)
        res.end(resource: ldrGuideVC)
    }
}
