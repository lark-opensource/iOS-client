//
//  ChatterSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import LarkSearchCore
import LarkContainer

struct ChatterSearchViewModelFactory: SearchSceneConfig {
    var searchScene: SearchSceneSection {
        return .rustScene(.searchChatters)
    }

    var searchDisplayTitle: String {
        return BundleI18n.LarkSearch.Lark_Legacy_Contact
    }

    var searchDisplayImage: UIImage? {
        return Resources.search_contact
    }

    var searchLocation: String {
        return "contacts"
    }

    var newSearchLocation: String {
        return "contacts"
    }

    var supportLocalSearch: Bool {
        return true
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

        let model = ChatterSearchViewModel(userResolver: userResolver,
                                           searchResult: searchResult,
                                           chatService: chatService,
                                           chatAPI: chatAPI,
                                           feedAPI: feedAPI,
                                           serverNTPTimeService: serverNTPTimeService,
                                           context: context)
        return model
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return ChatterSearchTableViewCell.self
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
