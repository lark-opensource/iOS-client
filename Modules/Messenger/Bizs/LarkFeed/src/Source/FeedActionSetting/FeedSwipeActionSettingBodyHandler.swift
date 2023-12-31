//
//  FeedSwipeActionSettingHandler.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/10/31.
//

import UIKit
import Foundation
import LarkMessengerInterface
import Swinject
import LarkUIKit
import EENavigator
import LarkNavigator

final class FeedSwipeActionSettingHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: FeedSwipeActionSettingBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let store = try resolver.resolve(assert: FeedSettingStore.self)
        let viewModel = FeedSwipeActionSettingViewModel(resolver: resolver, settingStore: store)
        let vc: BaseUIViewController = FeedSwipeActionSettingViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
