//
//  SearchJumpMoreCellFactory.swift
//  LarkSearch
//
//  Created by Patrick on 2022/6/20.
//

import Foundation
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

struct SearchJumpMoreCellFactory: SearchCellFactory {
    func cellType(for item: SearchCellViewModel) -> SearchTableViewCellProtocol.Type {
        if item is UnfoldMoreViewModel {
            return UnfoldMoreCell.self
        } else {
            return OpenSearchJumpNewTableViewCell.self
        }
    }

    func createViewModel(userResolver: UserResolver, searchResult: SearchResultType, context: SearchViewModelContext) -> SearchCellViewModel {
        // 判断有没有jumpMore
        if let moreResult = (searchResult as? OpenJumpResult)?.moreResult, !moreResult.isEmpty {
            return UnfoldMoreViewModel(searchResult: searchResult)
        } else {
            if let searchRouteResponder = context.searchRouteResponder {
                return OpenSearchJumpViewModel(searchResult: searchResult,
                                               searchRouteResponder: searchRouteResponder)
            } else {
                return OpenSearchJumpViewModel(searchResult: searchResult)
            }
        }
    }
}
