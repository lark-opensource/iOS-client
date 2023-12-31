//
//  BoxSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct BoxSearchViewModelFactory: SearchSceneConfig {
    var searchScene: SearchSceneSection {
        return .rustScene(.searchBoxScene)
    }

    var searchDisplayTitle: String {
        return BundleI18n.LarkSearch.Lark_Legacy_Tool
    }

    var searchDisplayImage: UIImage? {
        return Resources.search_box
    }

    var searchLocation: String {
        return "box"
    }

    var newSearchLocation: String {
        return "box"
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return BoxSearchNewTableViewCell.self
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        return BoxSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router)
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
