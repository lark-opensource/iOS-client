//
//  ChatterSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSearchFilter
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct CommonTopicSearchViewModelFactory: MainSearchCellFactory {
    let userResolver: UserResolver

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return TopicSearchNewTableViewCell.self
    }

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        return TopicSearchViewModel(
            searchResult: searchResult,
            enableDocCustomIcon: SearchFeatureGatingKey.docIconCustom.isUserEnabled(userResolver: userResolver),
            enableThreadMiniIcon: false,
            router: context.router
        )
    }
}
