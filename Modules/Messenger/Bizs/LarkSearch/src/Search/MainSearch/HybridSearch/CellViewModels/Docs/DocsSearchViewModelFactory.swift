//
//  DocsSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface
import LarkSearchCore
import LarkSearchFilter
import LarkContainer

struct DocsSearchViewModelFactory: SearchSceneConfig {

    private let source: SearchFilter.Source

    let userResolver: UserResolver
    init(userResolver: UserResolver, source: SearchFilter.Source) {
        self.userResolver = userResolver
        self.source = source
    }

    var searchScene: SearchSceneSection {
        return .rustScene(.searchDoc)
    }

    var searchDisplayTitle: String {
        return BundleI18n.LarkSearch.Lark_Search_DocsFile
    }

    var searchDisplayImage: UIImage? {
        return Resources.search_docs
    }

    var searchLocation: String {
        return "docs"
    }

    var newSearchLocation: String {
        return "docs"
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return DocsSearchNewTableViewCell.self
    }

    var supportNoQuery: Bool {
        return true
    }

    var supportedFilters: [SearchFilter] {
        var filters: [SearchFilter] = []
        filters.append(.docSortType(.mostRelated))
        filters.append(.docOwnedByMe(false, userResolver.userID))
        if SearchFeatureGatingKey.docWikiFilter.isUserEnabled(userResolver: userResolver) {
            filters.append(.docType(.all))
        }
        if SearchFeatureGatingKey.mainFilter.isUserEnabled(userResolver: userResolver) {
            filters.append(.docFrom(fromIds: [], recommends: [], fromType: .user, isRecommendResultSelected: false))
        }
        filters.append(.docPostIn([]))
        filters.append(.docFormat([], source))
        filters.append(.date(date: nil, source: .doc))
        filters.append(.docContentType(.fullContent))
        filters.append(.docCreator([], userResolver.userID))
        if SearchFeatureGatingKey.docFilterSharer.isUserEnabled(userResolver: userResolver) {
            filters.append(.docSharer([]))
        }
        return filters
    }

    var historyType: SearchHistoryInfoSource { return .docsTab }

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard
              let docAPI = try? userResolver.resolve(assert: DocAPI.self),
              let feedAPI = try? userResolver.resolve(assert: FeedAPI.self)
        else {
            return DemoSearchCellViewModel(searchResult: searchResult)
        }
        return DocsSearchViewModel(userResolver: userResolver,
                                   searchResult: searchResult,
                                   docAPI: docAPI,
                                   feedAPI: feedAPI,
                                   enableDocCustomAvatar: SearchFeatureGatingKey.docIconCustom.isUserEnabled(userResolver: userResolver),
                                   router: context.router,
                                   context: context)
    }

    var recommendFilterTypes: [FilterInTab] {
        return [.docFrom]
    }
}
