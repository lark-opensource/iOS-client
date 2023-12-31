//
//  SearchOncallCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkContainer
struct SearchOncallCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return OncallSearchNewTableViewCell.self
    }

    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard
            let chatAPI = try? userResolver.resolve(assert: ChatAPI.self),
            let oncallAPI = try? userResolver.resolve(assert: OncallAPI.self)
        else {
            return DemoSearchCellViewModel(searchResult: searchResult)
        }
        return OncallSearchViewModel(userResolver: userResolver,
                                     searchResult: searchResult,
                                     router: context.router,
                                     currentChatterID: userResolver.userID,
                                     oncallAPI: oncallAPI,
                                     chatAPI: chatAPI,
                                     context: context)
    }
}
