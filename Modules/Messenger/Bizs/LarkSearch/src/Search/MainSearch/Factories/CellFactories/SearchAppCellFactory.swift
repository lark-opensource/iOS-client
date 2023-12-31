//
//  SearchAppCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct SearchAppCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        switch item {
        case is ChatterSearchViewModel: return ChatterSearchTableViewCell.self
        default: return AppSearchNewTableViewCell.self
        }
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
        switch searchResult.type {
        case .chatter, .bot:
            return ChatterSearchViewModel(userResolver: userResolver,
                                          searchResult: searchResult,
                                          chatService: chatService,
                                          chatAPI: chatAPI,
                                          feedAPI: feedAPI,
                                          serverNTPTimeService: serverNTPTimeService,
                                          context: context)
        default:
            return AppSearchViewModel(userResolver: userResolver,
                                      searchResult: searchResult,
                                      currentChatterId: userResolver.userID,
                                      chatService: chatService,
                                      enableDocCustomIcon: SearchFeatureGatingKey.docIconCustom.isUserEnabled(userResolver: userResolver),
                                      router: context.router,
                                      context: context)
        }
    }
}
