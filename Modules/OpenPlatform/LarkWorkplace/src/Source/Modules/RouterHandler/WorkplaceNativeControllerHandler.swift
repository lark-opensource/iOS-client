//
//  WorkplaceNativeControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/26.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging
import LarkAccountInterface
import LarkQuickLaunchInterface
import LarkGuide

// 原生工作台
struct WorkplaceNativeBody: PlainBody {
    static let pattern = "//client/workplace/native"

    let initData: WPHomeVCInitData.Normal
    let rootDelegate: WPHomeRootVCProtocol

    init(initData: WPHomeVCInitData.Normal, rootDelegate: WPHomeRootVCProtocol) {
        self.initData = initData
        self.rootDelegate = rootDelegate
    }
}

final class WorkplaceNativeControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(WorkplaceNativeControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: WorkplaceNativeBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle WorkplaceNativeBody route")
        let traceService = try userResolver.resolve(assert: WPTraceService.self)
        let trace = traceService.regenerateTrace(for: .normal)
        let context = try userResolver.resolve(assert: WorkplaceContext.self, argument: trace)
        let blockDataService = try userResolver.resolve(assert: WPBlockDataService.self)
        let dataManager = try userResolver.resolve(assert: AppCenterDataManager.self)
        let pageDisplayStateService = try userResolver.resolve(assert: WPHomePageDisplayStateService.self)
        let openService = try userResolver.resolve(assert: WorkplaceOpenService.self)
        let widgetData = try userResolver.resolve(assert: WidgetDataManage.self)
        let dependency = try userResolver.resolve(assert: WPDependency.self)
        let badgeService = try userResolver.resolve(assert: WorkplaceBadgeService.self)
        let userService = try userResolver.resolver.resolve(assert: PassportUserService.self)
        let dialogMgr = try userResolver.resolve(assert: OperationDialogMgr.self)
        let quickLaunchService = try userResolver.resolve(assert: QuickLaunchService.self)
        let newGuideService = try userResolver.resolve(assert: NewGuideService.self)

        let vc = WorkPlaceViewController(
            context: context,
            blockDataService: blockDataService,
            dataManager: dataManager,
            rootDelegate: body.rootDelegate,
            initData: body.initData,
            pageDisplayStateService: pageDisplayStateService,
            openService: openService,
            widgetData: widgetData,
            dependency: dependency,
            badgeService: badgeService,
            dialogMgr: dialogMgr,
            quickLaunchService: quickLaunchService,
            newGuideService: newGuideService
        )
        res.end(resource: vc)
    }
}
