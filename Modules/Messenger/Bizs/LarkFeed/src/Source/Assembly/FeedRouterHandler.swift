//
//  FeedRouterHandler.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/5.
//

import UIKit
import Foundation
import EENavigator
import Swinject
import LarkMessengerInterface
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkAccountInterface
import LarkNavigator

final class FeedRouterHandler: UserRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }

    func handle(req: Request, res: Response) throws {
        res.end(resource: try newVC(req: req))
    }

    private func newVC(req: Request) throws -> UIViewController {
        let resolver = self.userResolver

        let navigationBarViewModel = try resolver.resolve(assert: FeedNavigationBarViewModel.self)

        let dataStore = try resolver.resolve(assert: FilterDataStore.self)
        // 为读取更新后的Feature
        let feedSelection = try resolver.resolve(assert: FeedSelectionService.self)

        let mainViewModelDependency = try FeedMainViewModelDependencyImpl(
            resolver: resolver,
            filtersDriver: dataStore.allFiltersDSDriver,
            feedSelection: feedSelection)
        let allFeedsViewModel = try resolver.resolve(assert: AllFeedListViewModel.self)
        let context = try resolver.resolve(assert: FeedContext.self)

        let mainViewModel = try FeedMainViewModel(
            dependency: mainViewModelDependency,
            allFeedsViewModel: allFeedsViewModel,
            context: context)
        context.dataSourceAPI = mainViewModel

        let filterFixedViewModel = try resolver.resolve(assert: FilterFixedViewModel.self)
        let filterTabViewModel = FilterContainerViewModel(resolver: resolver,
                                                          dataStore: dataStore,
                                                          filterFixedViewModel: filterFixedViewModel)
        let styleService = try resolver.resolve(assert: Feed3BarStyleService.self)
        let feedVC = try FeedMainViewController(
            navigationBarViewModel: navigationBarViewModel,
            mainViewModel: mainViewModel,
            filterTabViewModel: filterTabViewModel,
            context: context,
            styleService: styleService)
        context.page = feedVC
        return feedVC
    }
}
