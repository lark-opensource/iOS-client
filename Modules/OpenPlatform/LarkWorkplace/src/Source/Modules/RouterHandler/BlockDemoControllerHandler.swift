//
//  BlockDemoControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/27.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging

// Block 示例应用首页
struct BlockDemoBody: PlainBody {
    static let pattern = "//client/workplace/block/demo"

    let params: [String: Any]

    init(params: [String: Any]) {
        self.params = params
    }
}

final class BlockDemoControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(BlockDemoControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: BlockDemoBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle BlockDemoBody route", additionalData: [
            "paramKeys": "\(body.params.keys)"
        ])
        let navigator = userResolver.navigator
        let vc = BlockDemoViewController(
            navigator: navigator,
            params: body.params
        )
        res.end(resource: vc)
    }
}
