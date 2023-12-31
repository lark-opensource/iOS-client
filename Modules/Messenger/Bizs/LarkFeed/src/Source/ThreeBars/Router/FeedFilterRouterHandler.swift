//
//  FeedFilterRouterHandler.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/8.
//

import Foundation
import LarkOpenFeed
import Swinject
import EENavigator
import LarkAccountInterface
import LarkNavigator

final class FeedFilterHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: FeedFilterBody, req: EENavigator.Request, res: Response) throws {
        let filterListViewModel = try userResolver.resolve(assert: FeedFilterListViewModel.self)
        let vc = FeedFilterListViewController(viewModel: filterListViewModel)
        res.end(resource: vc)
    }
}
