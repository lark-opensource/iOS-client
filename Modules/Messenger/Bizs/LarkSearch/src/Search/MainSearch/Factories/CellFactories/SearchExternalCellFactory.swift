//
//  SearchExternalCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkContainer

struct SearchExternalCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return ExternalTableViewCell.self
    }

    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        return ExternalSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router)
    }
}
