//
//  SearchRootDependencyContainer.swift
//  LarkSearch
//
//  Created by Patrick on 2022/5/20.
//

import Foundation
import LarkUIKit
import LarkSearchCore
import LarkMessengerInterface
import UniverseDesignTabs
import LarkContainer
import Swinject

final class SearchRootDependencyContainer: UserResolverWrapper {
    let sharedRootViewModel: SearchRootViewModel
    let searchSession: SearchSession
    let sourceOfSearch: SourceOfSearch
    let searchNavBar: SearchNaviBar
    let router: SearchRouter
    let historyStore: SearchQueryHistoryStore
    let initQuery: String?
    let jumpTab: SearchTab?
    let userResolver: UserResolver

    init(userResolver: UserResolver,
         sourceOfSearch: SourceOfSearch,
         searchSession: SearchSession,
         searchNavBar: SearchNaviBar,
         router: SearchRouter,
         historyStore: SearchQueryHistoryStore,
         initQuery: String?,
         applinkSource: String = "",
         jumpTab: SearchTab? = nil) {
        func makeRootViewModel() -> SearchRootViewModel {
            return SearchRootViewModel(userResolver: userResolver,
                                       searchSession: searchSession,
                                       historyStore: historyStore,
                                       applinkSource: applinkSource,
                                       jumpTab: jumpTab)
        }
        self.userResolver = userResolver
        self.sharedRootViewModel = makeRootViewModel()
        self.searchSession = searchSession
        self.historyStore = historyStore
        self.sourceOfSearch = sourceOfSearch
        self.router = router
        self.searchNavBar = searchNavBar
        self.initQuery = initQuery
        self.jumpTab = jumpTab
    }

    func makeSearchRootViewController() -> SearchRootViewController {
        let rootVC = SearchRootViewController(userResolver: userResolver,
                                              viewModel: sharedRootViewModel,
                                              searchNaviBar: searchNavBar,
                                              initQuery: initQuery,
                                              sourceOfSearch: sourceOfSearch,
                                              searchSession: searchSession,
                                              router: router,
                                              historyStore: historyStore)
        if let service = try? userResolver.resolve(assert: SearchOuterService.self) {
            service.setCurrentSearchRootVC(viewController: rootVC)
        }
        return rootVC
    }
}

final class SearchNewRootDependencyContainer {
    let sharedRootViewModel: SearchMainRootViewModel
    let searchSession: SearchSession
    let sourceOfSearch: SourceOfSearch
    let router: SearchRouter
    let resolver: Resolver
    let historyStore: SearchQueryHistoryStore
    let initQuery: String?
    let jumpTab: SearchTab?
    let userResolver: UserResolver

    init(userResolver: UserResolver,
         sourceOfSearch: SourceOfSearch,
         searchSession: SearchSession,
         router: SearchRouter,
         historyStore: SearchQueryHistoryStore,
         resolver: Resolver,
         initQuery: String?,
         applinkSource: String = "",
         jumpTab: SearchTab? = nil) {
        func makeRootViewModel() -> SearchMainRootViewModel {
            return SearchMainRootViewModel(userResolver: userResolver,
                                           searchSession: searchSession,
                                           historyStore: historyStore,
                                           sourceOfSearch: sourceOfSearch,
                                           applinkSource: applinkSource,
                                           jumpTab: jumpTab)
        }
        self.userResolver = userResolver
        self.sharedRootViewModel = makeRootViewModel()
        self.searchSession = searchSession
        self.historyStore = historyStore
        self.sourceOfSearch = sourceOfSearch
        self.router = router
        self.resolver = resolver
        self.initQuery = initQuery
        self.jumpTab = jumpTab
    }

    func makeSearchRootViewController() -> SearchMainRootViewController {
        let mainRootVC = SearchMainRootViewController(userResolver: userResolver,
                                                      viewModel: sharedRootViewModel,
                                                      initQuery: initQuery,
                                                      sourceOfSearch: sourceOfSearch,
                                                      searchSession: searchSession,
                                                      router: router,
                                                      historyStore: historyStore,
                                                      resolver: resolver)
        if let service = try? userResolver.resolve(assert: SearchOuterService.self) {
            service.setCurrentSearchRootVC(viewController: mainRootVC)
        }
        return mainRootVC
    }
}
