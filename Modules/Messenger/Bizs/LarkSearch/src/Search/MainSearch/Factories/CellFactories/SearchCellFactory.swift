//
//  SearchCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/17.
//

import Foundation
import LarkSDKInterface
import LarkContainer
protocol SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type
    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel
}
