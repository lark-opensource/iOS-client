//
//  WorkplaceHomeControllerHandler.swift
//  Lark
//
//  Created by yin on 2018/7/26.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import EENavigator
import RxSwift
import LarkUIKit
import Swinject
import LarkContainer
import LarkNavigator
import LarkNavigation
import LarkAccountInterface
import LKCommonsLogging

/// 工作台 Tab 入口容器
final class WorkplaceHomeControllerHandler: UserRouterHandler {
    static let logger = Logger.log(WorkplaceHomeControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle WorkplaceHomeController route")
        let traceService = try userResolver.resolve(assert: WPTraceService.self)
        let context = try userResolver.resolve(assert: WorkplaceContext.self, argument: traceService.root)
        let navigationService = try userResolver.resolve(assert: NavigationService.self)
        let rootDataManager = try userResolver.resolve(assert: WPRootDataMgr.self)
        let badgeServiceContainer = try userResolver.resolve(assert: WPBadgeServiceContainer.self)
        let dependency = try userResolver.resolve(assert: WPDependency.self)

        let vc = WPHomeRootVC(
            context: context,
            navigationService: navigationService,
            rootDataManager: rootDataManager,
            badgeServiceContainer: badgeServiceContainer,
            dependency: dependency
        )
        res.end(resource: vc)
    }
}
