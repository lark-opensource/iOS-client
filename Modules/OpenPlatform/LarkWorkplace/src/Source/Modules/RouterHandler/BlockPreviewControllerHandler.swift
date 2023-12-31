//
//  BlockPreviewControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/26.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging

// public 是因为目前 Ecosystem demo 工程会用到，后续考虑优化
public struct BlockPreviewBody: PlainBody {
    public static let pattern = "//client/workplace/block/preview"

    public let url: URL

    public init(url: URL) {
        self.url = url
    }
}

final class BlockPreviewControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(BlockPreviewControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: BlockPreviewBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle BlockPreviewBody route", additionalData: [
            "url": "\(body.url)"
        ])
        let openService = try userResolver.resolve(assert: WorkplaceOpenService.self)
        let dataManager = try userResolver.resolve(assert: AppCenterDataManager.self)
        let configService = try userResolver.resolve(assert: WPConfigService.self)
        let vc = BlockPreviewController(
            url: body.url,
            userResolver: userResolver,
            navigator: userResolver.navigator,
            openService: openService,
            dataManager: dataManager,
            userId: userResolver.userID,
            configService: configService
        )
        res.end(resource: vc)
    }
}
