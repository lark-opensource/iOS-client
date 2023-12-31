//
//  BlockDemoDetailControllerHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/27.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging

// Block 示例应用详情页
struct BlockDemoDetailBody: PlainBody {
    static let pattern = "//client/workplace/block/demo/detail"

    let params: BlockDemoParams
    let listPageData: [String: Any]

    init(params: BlockDemoParams, listPageData: [String: Any]) {
        self.params = params
        self.listPageData = listPageData
    }
}

final class BlockDemoDetailControllerHandler: UserTypedRouterHandler {
    static let logger = Logger.log(BlockDemoDetailControllerHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: BlockDemoDetailBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        Self.logger.info("handle BlockDemoDetailBody route", additionalData: [
            "listPageDataKeys": "\(body.listPageData.keys)"
        ])
        let navigator = userResolver.navigator
        let vc = BlockDemoDetailViewController(
            userResolver: userResolver,
            navigator: navigator,
            params: body.params,
            listPageData: body.listPageData
        )
        res.end(resource: vc)
    }
}
