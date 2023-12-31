//
//  AppBadgeSettingControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/25.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging
import LarkAccountInterface

struct AppBadgeSettingBody: PlainBody {
    static let pattern = "//client/workplace/app/badge/setting"

    init() {}
}

final class AppBadgeSettingControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(AppBadgeSettingControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: AppBadgeSettingBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle AppBadgeSettingBody route")
        let viewModel = try userResolver.resolve(assert: AppBadgeSettingViewModel.self)
        let dataManager = try userResolver.resolve(assert: AppCenterDataManager.self)
        let userService = try userResolver.resolve(assert: PassportUserService.self)
        let vc = AppBadgeSettingViewController(
            userId: userResolver.userID,
            tenantId: userService.userTenant.tenantID,
            navigator: userResolver.navigator,
            viewModel: viewModel,
            dataManager: dataManager
        )
        res.end(resource: vc)
    }
}
