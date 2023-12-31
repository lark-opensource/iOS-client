//
//  WorkplaceWebControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/27.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging

// Web 门户
struct WorkplaceWebBody: PlainBody {
    static let pattern = "//client/workplace/web"

    let rootDelegate: WPHomeRootVCProtocol
    let initData: WPHomeVCInitData.Web
    let path: String?
    let queryItems: [URLQueryItem]?

    init(
        rootDelegate: WPHomeRootVCProtocol,
        initData: WPHomeVCInitData.Web,
        path: String?,
        queryItems: [URLQueryItem]?
    ) {
        self.rootDelegate = rootDelegate
        self.initData = initData
        self.path = path
        self.queryItems = queryItems
    }
}

final class WorkplaceWebControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(WorkplaceWebControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: WorkplaceWebBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle WorkplaceWebBody route")
        let traceService = try userResolver.resolve(assert: WPTraceService.self)
        // 门户入口，门户 trace 需要重新创建。
        let trace = traceService.regenerateTrace(for: .web, with: body.initData.id)
        let context = try userResolver.resolve(assert: WorkplaceContext.self, argument: trace)
        let badgeAPI = try userResolver.resolve(assert: BadgeAPI.self)
        let badgeService = try userResolver.resolve(assert: WorkplaceBadgeService.self)
        let vc = WPHomeWebVC(
            resolver: userResolver,
            context: context,
            rootDelegate: body.rootDelegate,
            initData: body.initData,
            path: body.path,
            queryItems: body.queryItems,
            badgeAPI: badgeAPI,
            badgeService: badgeService
        )
        res.end(resource: vc)
    }
}
