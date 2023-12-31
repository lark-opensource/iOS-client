//
//  SearchDocCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkContainer
struct SearchDocCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return DocsSearchNewTableViewCell.self
    }

    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
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
}
