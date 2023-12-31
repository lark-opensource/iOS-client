//
//  AppSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkAccountInterface
import LarkModel
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct AppSearchViewModelFactory: SearchSceneConfig {

    var searchScene: SearchSceneSection {
        return .rustScene(.searchOpenAppScene)
    }

    var searchDisplayTitle: String {
        return BundleI18n.LarkSearch.Lark_Search_Apps
    }

    var searchDisplayImage: UIImage? {
        return Resources.search_app
    }

    var searchLocation: String {
        return "apps"
    }

    var newSearchLocation: String {
        return "apps"
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard let chatService = try? userResolver.resolve(assert: ChatService.self),
              let chatAPI = try? userResolver.resolve(assert: ChatAPI.self),
              let feedAPI = try? userResolver.resolve(assert: FeedAPI.self),
              let serverNTPTimeService = try? userResolver.resolve(assert: ServerNTPTimeService.self) else {
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
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        switch item {
        case is ChatterSearchViewModel: return ChatterSearchTableViewCell.self
        default: return AppSearchNewTableViewCell.self
        }
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
