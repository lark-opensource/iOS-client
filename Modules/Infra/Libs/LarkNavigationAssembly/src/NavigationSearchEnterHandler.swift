//
//  test.swift
//  LarkNavigationAssembly
//
//  Created by aslan on 2023/12/22.
//

#if canImport(LarkMessengerInterface)

import Foundation
import LarkMessengerInterface
import LarkContainer
import EENavigator
import LarkNavigator
import LarkNavigation
import AnimatedTabBar

final class NavigationSearchEnterHandler: UserTypedRouterHandler {
    func handle(_ body: NavigationSearchEnterBody, req: EENavigator.Request, res: Response) throws {
        let navigationDependency = try? self.userResolver.resolve(assert: NavigationDependency.self)
        guard let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() else { return }
        let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self)
        let animatedTabBar = RootNavigationController.shared.viewControllers.first as? AnimatedTabBarController
        let model = SearchEnterModel(fromTabURL: animatedTabBar?.currentTab?.url,
                                     sourceOfSearchStr: body.sourceOfSearchStr,
                                     initQuery: body.initQuery,
                                     appLinkSource: body.appLinkSource,
                                     jumpTab: body.jumpTab,
                                     appId: body.appId,
                                     searchTabName: body.searchTabName,
                                     entryAction: SearchEntryAction(rawValue: body.entryAction) ?? .unKnown)
        guard let vc = searchOuterService?.getCurrentSearchPadVC(searchEnterModel: model) else {
            res.end(resource: EmptyResource())
            return
        }
        RootNavigationController.shared.switchToSearchTab(vc: vc)
    }
}

#endif
