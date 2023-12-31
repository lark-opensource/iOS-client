//
//  OpenSearchSceneConfig.swift
//  LarkSearch
//
//  Created by SolaWing on 2021/4/20.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct OpenSearchSceneConfig: SearchSceneConfig {

    var info: SearchTab.OpenSearch
    let userResolver: UserResolver
    init(userResolver: UserResolver, info: SearchTab.OpenSearch) {
        self.userResolver = userResolver
        self.info = info
    }
    var searchScene: SearchSceneSection { return .rustScene(.searchOpenSearchScene) }
    var searchDisplayTitle: String { info.label }
    var searchDisplayImage: UIImage? { return nil }

    var searchLocation: String {
        return "open_search"
    }

    var newSearchLocation: String {
        return "slash"
    }

    var supportLocalSearch: Bool { return false }
    var supportNoQuery: Bool { return true } // opensearch默认页请求二级filter

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        if case .slash(let meta) = item.searchResult.meta, meta.slashCommand == .filter {
            return OpenSearchFilterTableViewCell.self
        } else if item.searchResult.type == .customization {
            return CustomizationCardTableViewCell.self
        }
        return OpenSearchNewTableViewCell.self
    }

    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        if searchResult.type == .customization {
            return StoreCardSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router, isMainTab: false)
        }
        return OpenSearchViewModel(userResolver: userResolver, searchResult: searchResult, router: context.router, context: context)
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
