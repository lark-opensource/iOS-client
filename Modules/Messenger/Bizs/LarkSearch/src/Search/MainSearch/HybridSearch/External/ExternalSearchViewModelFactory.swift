//
//  ExternalSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 7/22/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

final class ExternalSearchViewModelFactory: SearchSceneConfig {
    var searchScene: SearchSceneSection {
        return .rustScene(.searchExternalScene)
    }

    var searchDisplayTitle: String {
        return BundleI18n.LarkSearch.Lark_Search_MoreContent
    }

    var searchLocation: String {
        return "external"
    }

    var newSearchLocation: String {
        return "external"

    }

    var searchDisplayImage: UIImage? {
        return Resources.search_external
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return ExternalTableViewCell.self
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        return ExternalSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router)
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
