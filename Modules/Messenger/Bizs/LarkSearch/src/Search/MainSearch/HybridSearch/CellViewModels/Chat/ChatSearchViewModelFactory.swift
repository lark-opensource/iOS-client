//
//  ChatSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSearchFilter
import LarkAccountInterface
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct CommonChatSearchViewModelFactory: MainSearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return ChatSearchNewTableViewCell.self
    }

    let userResolver: UserResolver

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard let chatAPI = try? userResolver.resolve(assert: ChatAPI.self) else {
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
