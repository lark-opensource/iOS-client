//
//  URLSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 5/24/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSearchFilter
import LarkSDKInterface
import LarkFeatureGating
import LarkSearchCore
import LarkContainer

struct URLSearchViewModelFactory: SearchSceneConfig {
    private let chatMode: ChatFilterMode

    let userResolver: UserResolver
    init(userResolver: UserResolver, chatMode: ChatFilterMode) {
        self.chatMode = chatMode
        self.userResolver = userResolver
    }

    var searchScene: SearchSceneSection {
        return .rustScene(.searchLinkScene)
    }

    var noQuerySource: SearchHistoryInfoSource {
        return .messageTab
    }

    var searchDisplayTitle: String {
        return BundleI18n.LarkSearch.Lark_Search_Link
    }

    var searchDisplayImage: UIImage? {
        return UIImage()
    }

    var supportedFilters: [SearchFilter] {
        return [.chatter(mode: chatMode, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false),
                .chat(mode: chatMode, picker: []),
                .date(date: nil, source: .message),
                .messageMatch([]), // URL没有这个过滤器，只是保持和message一致
                .messageType(.link)]
    }

    var supportNoQuery: Bool { return true }

    var searchLocation: String {
        return "link"
    }

    var newSearchLocation: String {
        return "link"
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return URLSearchTableViewCell.self
    }

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard let chatAPI = try? userResolver.resolve(assert: ChatAPI.self) else {
            return DemoSearchCellViewModel(searchResult: searchResult)
        }
        let model = URLSearchViewModel(userResolver: userResolver,
                                       searchResult: searchResult,
                                       chatAPI: chatAPI,
                                       router: context.router,
                                       context: context)
        return model
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
