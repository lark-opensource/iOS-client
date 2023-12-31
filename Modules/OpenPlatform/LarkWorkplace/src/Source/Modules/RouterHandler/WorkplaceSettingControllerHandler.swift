//
//  WorkplaceSettingControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/26.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging
import LarkAccountInterface

struct WorkplaceSettingBody: PlainBody {
    static let pattern = "//client/workplace/setting"

    /// 是否显示 Badge 相关设置
    let showBadge: Bool

    /// 常用应用更新回调
    let commonItemsUpdate: (() -> Void)?

    init(showBadge: Bool, commonItemsUpdate: (() -> Void)?) {
        self.showBadge = showBadge
        self.commonItemsUpdate = commonItemsUpdate
    }
}

final class WorkplaceSettingControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(WorkplaceSettingControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: WorkplaceSettingBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle WorkplaceSettingBody route", additionalData: [
            "showBadge": "\(body.showBadge)"
        ])
        let dataManager = try userResolver.resolve(assert: AppCenterDataManager.self)
        let configService = try userResolver.resolve(assert: WPConfigService.self)
        let userService = try userResolver.resolve(assert: PassportUserService.self)
        let vc = WPNativeSettingViewController(
            userId: userResolver.userID,
            tenantId: userService.userTenant.tenantID,
            navigator: userResolver.navigator,
            dataManager: dataManager,
            configService: configService,
            showBadge: body.showBadge,
            commonItemsUpdate: body.commonItemsUpdate
        )
        res.end(resource: vc)
    }
}
