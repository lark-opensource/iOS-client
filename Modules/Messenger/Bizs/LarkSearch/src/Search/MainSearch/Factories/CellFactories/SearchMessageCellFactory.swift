//
//  SearchMessageCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkContainer
struct SearchMessageCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return MessageSearchTableViewCell.self
    }

    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
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
