//
//  FavoriteSettingControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/26.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging
import LarkAccountInterface

struct FavoriteSettingBody: PlainBody {
    static let pattern = "//client/workplace/favorite/setting"

    let showCommonBar: Bool
    let actionCallbackToHomePage: (() -> Void)?

    init(showCommonBar: Bool, actionCallbackToHomePage: (() -> Void)? = nil) {
        self.showCommonBar = showCommonBar
        self.actionCallbackToHomePage = actionCallbackToHomePage
    }
}

final class FavoriteSettingControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(FavoriteSettingControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: FavoriteSettingBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle FavoriteSettingBody route", additionalData: [
            "showCommonBar": "\(body.showCommonBar)"
        ])
        let dataManager = try userResolver.resolve(assert: AppCenterDataManager.self)
        let openService = try userResolver.resolve(assert: WorkplaceOpenService.self)
        let configService = try userResolver.resolve(assert: WPConfigService.self)
        let userService = try userResolver.resolve(assert: PassportUserService.self)
        let vc = WPFavoriteSettingController(
            userId: userResolver.userID,
            navigator: userResolver.navigator,
            showCommonBar: body.showCommonBar,
            dataManager: dataManager,
            openService: openService,
            configService: configService,
            userService: userService,
            actionCallbackToHomePage: body.actionCallbackToHomePage
        )
        res.end(resource: vc)
    }
}
