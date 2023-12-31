//
//  WorkplacePreviewControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/11.
//

import Foundation
import EENavigator
import Swinject
import LKCommonsLogging
import LarkNavigator
import LarkContainer
import LarkNavigation
import LarkAccountInterface

struct WorkplacePreviewBody: CodableBody {
    static let prefix = "//client/workplace/preview"

    // 路由上使用 token 作为 path 的一部分，因为不同 token 是不同的预览，避免被路由过滤掉
    static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:token", type: .path)
    }

    var _url: URL {
        // swiftlint:disable:next force_unwrapping
        return URL(string: "\(WorkplacePreviewBody.prefix)/\(token)")!
    }

    let token: String

    init(token: String) {
        self.token = token
    }
}

final class WorkplacePreviewControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(WorkplacePreviewControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: WorkplacePreviewBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle WorkplacePreviewBody route", additionalData: ["token": body.token])
        let traceService = try userResolver.resolve(assert: WPTraceService.self)
        let networkService = try userResolver.resolve(assert: WPNetworkService.self)
        let viewModel = WorkplacePreviewViewModel(
            token: body.token, traceService: traceService, networkService: networkService
        )
        let navigationService = try userResolver.resolve(assert: NavigationService.self)
        let userService = try userResolver.resolve(assert: PassportUserService.self)
        let vc = WorkplacePreviewController(
            userResolver: userResolver,
            userId: userResolver.userID,
            tenantId: userService.userTenant.tenantID,
            navigator: userResolver.navigator,
            viewModel: viewModel,
            navigationService: navigationService,
            traceService: traceService
        )
        res.end(resource: vc)
    }
}
