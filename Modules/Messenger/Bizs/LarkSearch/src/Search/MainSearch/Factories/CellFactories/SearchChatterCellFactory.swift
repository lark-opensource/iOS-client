//
//  SearchChatterCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkContainer
struct SearchChatterCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return ChatterSearchTableViewCell.self
    }

    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard
            let chatService = try? userResolver.resolve(assert: ChatService.self),
            let chatAPI = try? userResolver.resolve(assert: ChatAPI.self),
            let feedAPI = try? userResolver.resolve(assert: FeedAPI.self),
            let serverNTPTimeService = try? userResolver.resolve(assert: ServerNTPTimeService.self)
        else {
            return DemoSearchCellViewModel(searchResult: searchResult)
        }
        let model = ChatterSearchViewModel(userResolver: userResolver,
                                           searchResult: searchResult,
                                           chatService: chatService,
                                           chatAPI: chatAPI,
                                           feedAPI: feedAPI,
                                           serverNTPTimeService: serverNTPTimeService,
                                           context: context)
        return model
    }
}
