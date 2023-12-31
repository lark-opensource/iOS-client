//
//  BoxFeedsRequestHandler.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/9.
//

import Foundation
import EENavigator
import LarkOpenFeed
import Swinject
import LarkNavigation
import RustPB
import LarkSDKInterface
import LarkNavigator

final class BoxFeedsRequestHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }

    func handle(_ body: ChatBoxBody, req: Request, res: Response) throws {
        let resolver = self.userResolver
        let feedApi = try resolver.resolve(assert: FeedAPI.self)
        let badgeDriver = try resolver.resolve(assert: TabbarService.self).badgeDriver(for: .feed)
        let feedContext = try resolver.resolve(assert: FeedContextService.self)
        let boxId = body.chatBoxId
        let dependency = BoxFeedsDependencyImp(feedAPI: feedApi,
                                               badgeDriver: badgeDriver,
                                               boxId: boxId)
        let baseDependency = try resolver.resolve(assert: BaseFeedsViewModelDependency.self)
        let vm = BoxFeedsViewModel(dependency: dependency,
                                   baseDependency: baseDependency,
                                   feedContext: feedContext)
        let vc = try BoxFeedsViewController(boxViewModel: vm)
        res.end(resource: vc)
    }
}
