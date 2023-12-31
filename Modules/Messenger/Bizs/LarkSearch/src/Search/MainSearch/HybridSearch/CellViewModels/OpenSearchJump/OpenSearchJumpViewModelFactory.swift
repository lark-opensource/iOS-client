//
//  OpenSearchJumpViewModelFactory.swift
//  LarkSearch
//
//  Created by bytedance on 2022/3/9.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkContainer
struct OpenSearchJumpViewModelFactory: SearchSceneConfig {
    var searchDisplayTitle: String { "" }
    var searchDisplayImage: UIImage? { return nil }

    // 需要确定下
    var searchLocation: String {
        return "open_search"
    }

    var newSearchLocation: String {
        return "slash"
    }

    var searchScene: SearchSceneSection {
        return .rustScene(.searchOpenSearchScene)
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    func createViewModel(searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        // 判断有没有jumpMore
        if let moreResult = (searchResult as? OpenJumpResult)?.moreResult, !moreResult.isEmpty {
            return UnfoldMoreViewModel(searchResult: searchResult)
        } else {
            return OpenSearchJumpViewModel(searchResult: searchResult)
        }
    }

    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        if item is UnfoldMoreViewModel {
            return UnfoldMoreCell.self
        } else {
            return OpenSearchJumpNewTableViewCell.self
        }
    }

    var recommendFilterTypes: [FilterInTab] { return [] }
}
