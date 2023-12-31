//
//  OncallSearchViewModelFactory.swift
//  LarkSearch
//
//  Created by SuPeng on 4/9/19.
//

import UIKit
import Foundation
import LarkModel
import LarkAccountInterface
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct OncallSearchViewModelFactory: SearchSceneConfig {
    var searchScene: SearchSceneSection {
        return .rustScene(.searchOncallScene)
    }

    var searchDisplayTitle: String {
        return BundleI18n.LarkSearch.Lark_HelpDesk_HelpDesk
    }

    var searchLocation: String {
        return "helpdesk"
    }

    var newSearchLocation: String {
        return "helpdesk"
    }

    var searchDisplayImage: UIImage? {
        return Resources.search_oncall
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        return OncallSearchNewTableViewCell.self
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        guard
            let chatAPI = try? userResolver.resolve(assert: ChatAPI.self),
            let oncallAPI = try? userResolver.resolve(assert: OncallAPI.self)
        else {
            return DemoSearchCellViewModel(searchResult: searchResult)
        }
        return OncallSearchViewModel(userResolver: userResolver,
                                     searchResult: searchResult,
                                     router: context.router,
                                     currentChatterID: userResolver.userID,
                                     oncallAPI: oncallAPI,
                                     chatAPI: chatAPI,
                                     context: context)
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
