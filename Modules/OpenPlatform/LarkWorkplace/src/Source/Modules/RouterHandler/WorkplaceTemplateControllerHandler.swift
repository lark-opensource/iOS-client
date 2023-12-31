//
//  WorkplaceTemplateControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/12.
//

import Foundation
import EENavigator
import LKCommonsLogging
import Swinject
import LarkNavigator
import LarkContainer
import LarkAccountInterface
import LarkQuickLaunchInterface

struct WorkplaceTemplateBody: PlainBody {
    static let pattern = "//client/workplace/template"

    let rootDelegate: WPHomeRootVCProtocol
    let initData: WPHomeVCInitData.LowCode
    let firstLoadCache: Bool
    let isPreview: Bool
    let previewToken: String?

    init(
        rootDelegate: WPHomeRootVCProtocol,
        initData: WPHomeVCInitData.LowCode,
        firstLoadCache: Bool,
        isPreview: Bool = false,
        previewToken: String? = nil
    ) {
        self.rootDelegate = rootDelegate
        self.initData = initData
        self.firstLoadCache = firstLoadCache
        self.isPreview = isPreview
        self.previewToken = previewToken
    }
}

final class WorkplaceTemplateControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(WorkplaceTemplateControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: WorkplaceTemplateBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle WorkplaceTemplateBody route", additionalData: [
            "firstLoadCache": "\(body.firstLoadCache)",
            "isPreview": "\(body.isPreview)",
            "previewToken": body.previewToken ?? ""
        ])
        let traceService = try userResolver.resolve(assert: WPTraceService.self)
        let trace = traceService.regenerateTrace(for: .lowCode, with: body.initData.id)
        let context = try userResolver.resolve(assert: WorkplaceContext.self, argument: trace)
        let templateDataManager = try userResolver.resolve(
            assert: TemplateDataManager.self, arguments: body.isPreview, body.previewToken
        )
        let blockDataService = try userResolver.resolve(assert: WPBlockDataService.self)
        let pageDisplayStateService = try userResolver.resolve(assert: WPHomePageDisplayStateService.self)
        let navigator = userResolver.navigator
        let pushCenter = try userResolver.userPushCenter
        let dataManager = try userResolver.resolve(assert: AppCenterDataManager.self)
        let openService = try userResolver.resolve(assert: WorkplaceOpenService.self)
        let dependency = try userResolver.resolve(assert: WPDependency.self)
        let badgeService = try userResolver.resolve(assert: WorkplaceBadgeService.self)
        let configService = try userResolver.resolve(assert: WPConfigService.self)
        let userService = try userResolver.resolve(assert: PassportUserService.self)
        let dialogMgr = try userResolver.resolve(assert: OperationDialogMgr.self)
        let quickLaunchService = try userResolver.resolve(assert: QuickLaunchService.self)

        let vc = TemplateViewController(
            context: context,
            rootDelegate: body.rootDelegate,
            data: body.initData,
            templateDataManager: templateDataManager,
            firstLoadCache: true, /* 原逻辑在初始化的时候使用了默认值，并没有使用 body 传递的值，此处先保持一致，后续优化 */
            blockDataService: blockDataService,
            pageDisplayStateService: pageDisplayStateService,
            dataManager: dataManager,
            openService: openService,
            dependency: dependency,
            badgeService: badgeService,
            dialogMgr: dialogMgr,
            quickLaunchService: quickLaunchService
        )
        res.end(resource: vc)
    }
}
