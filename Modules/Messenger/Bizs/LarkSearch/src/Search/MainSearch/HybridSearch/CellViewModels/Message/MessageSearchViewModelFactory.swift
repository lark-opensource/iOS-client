//
//  MessageSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSearchFilter
import LarkFeatureGating
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct CommonMessageSearchViewModelFactory: MainSearchCellFactory {
    let userResolver: UserResolver

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return MessageSearchTableViewCell.self
    }

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard
            let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
        else {
            return DemoSearchCellViewModel(searchResult: searchResult)
        }
        let messageSearchVM = MessageSearchViewModel(userResolver: userResolver,
                                                     searchResult: searchResult,
                                                     chatAPI: chatAPI,
                                                     router: context.router,
                                                     context: context)
        return messageSearchVM
    }
}
