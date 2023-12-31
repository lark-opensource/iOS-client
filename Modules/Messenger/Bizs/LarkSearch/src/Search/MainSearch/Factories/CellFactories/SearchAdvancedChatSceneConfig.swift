//
//  SearchAdvancedChatCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkContainer
struct SearchAdvancedChatCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return ChatAdvancedSearchNewTableViewCell.self
    }

    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard
              let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
        else {
            return DemoSearchCellViewModel(searchResult: searchResult)
        }
        return ChatSearchViewModel(userResolver: userResolver,
                                   searchResult: searchResult,
                                   currentChatterId: userResolver.userID,
                                   chatAPI: chatAPI,
                                   context: context,
                                   enableDocCustomAvatar: SearchFeatureGatingKey.docIconCustom.isUserEnabled(userResolver: userResolver),
                                   enableThreadMiniIcon: false)
    }
}
