//
//  BlockDemoListControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/27.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging

// Block 示例应用首页
struct BlockDemoListBody: PlainBody {
    static let pattern = "//client/workplace/block/demo/list"

    let params: BlockDemoParams

    init(params: BlockDemoParams) {
        self.params = params
    }
}

final class BlockDemoListControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(BlockDemoListControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: BlockDemoListBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle BlockDemoListBody route")
        let navigator = userResolver.navigator
        let vc = BlockDemoListViewController(
            userResolver: userResolver,
            navigator: navigator,
            params: body.params
        )
        res.end(resource: vc)
    }
}
