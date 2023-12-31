//
//  SearchTopicCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct SearchTopicCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return TopicSearchNewTableViewCell.self
    }

    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        return TopicSearchViewModel(
            searchResult: searchResult,
            enableDocCustomIcon: SearchFeatureGatingKey.docIconCustom.isUserEnabled(userResolver: userResolver),
            enableThreadMiniIcon: false,
            router: context.router
        )
    }
}
