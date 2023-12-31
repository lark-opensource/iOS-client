//
//  WikiSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 8/12/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface
import LarkSearchCore
import LarkSearchFilter
import LarkContainer

struct WikiSearchViewModelFactory: SearchSceneConfig {
    var searchScene: SearchSceneSection {
        return .rustScene(.searchWikiScene)
    }

    var searchDisplayTitle: String {
        return BundleI18n.LarkSearch.Lark_Search_Wiki
    }

    var searchDisplayImage: UIImage? {
        return Resources.search_wiki
    }

    var searchLocation: String {
        return "wiki"
    }

    var newSearchLocation: String {
        return "wiki"
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return WikiSearchNewTableViewCell.self
    }

    var supportedFilters: [SearchFilter] {
        return []
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard
            let docAPI = try? userResolver.resolve(assert: DocAPI.self),
            let feedAPI = try? userResolver.resolve(assert: FeedAPI.self)
        else {
            return DemoSearchCellViewModel(searchResult: searchResult)
        }
        return WikiSearchViewModel(userResolver: userResolver,
                                   searchResult: searchResult,
                                   docAPI: docAPI,
                                   feedAPI: feedAPI,
                                   enableDocCustomAvatar: SearchFeatureGatingKey.docIconCustom.isUserEnabled(userResolver: userResolver),
                                   router: context.router,
                                   context: context)
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
