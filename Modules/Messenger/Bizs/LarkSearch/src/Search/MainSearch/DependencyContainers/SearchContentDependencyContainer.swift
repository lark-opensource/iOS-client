//
//  SearchContentDependencyContainer.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/17.
//

import Foundation
import LarkSearchCore
import LarkMessengerInterface
import ServerPB
import LarkLocalizations
import LarkSDKInterface
import RxSwift
import Swinject
import LarkContainer
import SuiteAppConfig
import LarkAccountInterface

final class SearchContentDependencyContainer {
    private lazy var sharedSearchRepo: SearchRepo = {
        return UniversalSearchService(userResolver: self.userResolver,
                                      searchSession: searchSession,
                                      config: config)
    }()

    let sharedRootViewModel: SearchRootViewModelProtocol
    let tab: SearchTab
    let searchSession: SearchSession
    let sourceOfSearch: SourceOfSearch
    let router: SearchRouter
    let historyStore: SearchQueryHistoryStore
    let viewModelContext: SearchViewModelContext
    var commonlyUsedFiltersStore: SearchCommonlyUsedFilterStore?
    var config: SearchTabConfigurable
    let userResolver: UserResolver
    let feedAPI: FeedAPI
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver,
         sharedRootViewModel: SearchRootViewModelProtocol,
         tab: SearchTab,
         sourceOfSearch: SourceOfSearch,
         searchSession: SearchSession,
         router: SearchRouter,
         historyStore: SearchQueryHistoryStore,
         config: SearchTabConfigurable) throws {
        self.userResolver = userResolver
        self.sharedRootViewModel = sharedRootViewModel
        self.tab = tab
        self.sourceOfSearch = sourceOfSearch
        self.searchSession = searchSession
        self.router = router
        self.historyStore = historyStore
        self.commonlyUsedFiltersStore = sharedRootViewModel.commonlyUsedFilterStore
        self.config = config
        switch tab {
        case .message:
            if let store = self.commonlyUsedFiltersStore, let filters = store.commonlyUsedFilters[.messageTab] {
                self.config.commonlyUsedFilters = filters
            }
        case .doc:
            if let store = self.commonlyUsedFiltersStore, let filters = store.commonlyUsedFilters[.docsTab] {
                self.config.commonlyUsedFilters = filters
            }
        default:
            break
        }
        self.viewModelContext = SearchViewModelContext(router: router,
                                                       tab: tab,
                                                       searchRouteResponder: sharedRootViewModel)

        self.feedAPI = try userResolver.resolve(assert: FeedAPI.self)
    }

    func makeSearchContentViewController() -> SearchContentViewController {
        let contentViewModel = SearchContentViewModel(userResolver: userResolver,
                                                      config: config,
                                                      searchRepo: sharedSearchRepo,
                                                      historyStore: historyStore,
                                                      viewModelContext: viewModelContext,
                                                      rootViewModel: sharedRootViewModel,
                                                      searchResultViewModelFactory: self,
                                                      searchFilterViewModelFactory: self,
                                                      universalRecommendViewModelFactory: self)
        return SearchContentViewController(userResolver: userResolver, viewModel: contentViewModel)
    }
}

extension SearchContentDependencyContainer: SearchFilterViewModelFactory {
    func makeSearchFilterViewModel() -> SearchFilterViewModel? {
        guard !(SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: userResolver) && !AppConfigManager.shared.leanModeIsOn) else { return nil }
        guard sharedRootViewModel as? SearchRootViewModel != nil else { return nil }
        guard !config.supportedFilters.isEmpty else { return nil }
        let model = SearchFilterViewModel(recommender: sharedSearchRepo, config: config)
        var resultFilters = config.supportedFilters
        if tab.isOpenSearchCalendar, let allCalendars = sharedRootViewModel.tabService?.allCalendarItems, let index = resultFilters.firstIndex(where: { filter in
            switch filter {
            case .general(.calendar(_, _)): return true
            default: return false
            }
        }) {
            let filter = resultFilters[index]
            if case let .general(.calendar(info, calendars)) = filter, calendars.isEmpty {
                let selectedCalendars = allCalendars.filter({ $0.isSelected })
                resultFilters[index] = .general(.calendar(info, selectedCalendars))
            }
        }
        model.replaceAllFilters(resultFilters)
        return model
    }
}

extension SearchContentDependencyContainer: SearchResultViewModelFactory {
    func makeSearchResultViewModel() -> SearchResultViewModel {
        return SearchResultViewModel(userResolver: userResolver,
                                     searcher: sharedSearchRepo,
                                     config: config,
                                     feedAPI: feedAPI,
                                     viewModelContext: viewModelContext)}
}

extension SearchContentDependencyContainer: UniversalRecommendViewModelFactory {
    func makeUniversalRecommendViewModel() -> UniversalRecommendViewModel? {
        guard let user = (try? userResolver.resolve(assert: PassportUserService.self))?.user else { return nil }
        if case let .show(entityTypes, tagName) = config.universalRecommendType {
            var requestHeader = ServerPB_Search_urecommend_UniversalRecommendRequestHeader()
            requestHeader.locale = LanguageManager.currentLanguage.localeIdentifier
            requestHeader.recommendContext.tagName = tagName
            var sectionEntityType = ServerPB_Search_urecommend_SectionEntityType()
            sectionEntityType.entityTypes = entityTypes
            requestHeader.sections = [sectionEntityType]
            requestHeader.sessionID = searchSession.session
            var request = ServerPB_Search_urecommend_UniversalRecommendRequest()
            request.header = requestHeader
            let service = UniversalRecommendService(userResolver: userResolver, request: request, cacheKey: RecommendCacheKey(tab: tab, userId: userResolver.userID, tenantId: user.tenant.tenantID))
            return UniversalRecommendViewModel(userResolver: userResolver,
                                               repo: service,
                                               context: UniversalRecommendViewModel.Context(session: searchSession, searchContext: viewModelContext, tab: tab),
                                               searchVMFactory: SmartSearchSceneConfig(userResolver: userResolver),
                                               router: router)
        }
        return nil
    }
}

protocol UniversalRecommendViewModelFactory {
    func makeUniversalRecommendViewModel() -> UniversalRecommendViewModel?
}
