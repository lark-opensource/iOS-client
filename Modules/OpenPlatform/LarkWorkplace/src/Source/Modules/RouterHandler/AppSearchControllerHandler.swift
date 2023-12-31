//
//  AppSearchControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/25.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging
import LarkAccountInterface

struct AppSearchBody: PlainBody {
    static let pattern = "//client/workplace/app/search"

    // 原来的耦合太深，解偶临时这样写，最终需要改造
    let viewModel: AppCategoryViewModel

    init(viewModel: AppCategoryViewModel) {
        self.viewModel = viewModel
    }
}

final class AppSearchControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(AppSearchControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: AppSearchBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle AppSearchBody route")
        let searchModel = try userResolver.resolve(assert: WPAppSearchModel.self)
        let userService = try userResolver.resolve(assert: PassportUserService.self)
        let vc = AppSearchController(
            userId: navigator.userID,
            tenantId: userService.userTenant.tenantID,
            navigator: userResolver.navigator,
            model: body.viewModel,
            searchModel: searchModel
        )
        res.end(resource: vc)
    }
}
