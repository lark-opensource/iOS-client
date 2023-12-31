//
//  UnfoldMoreViewModel.swift
//  LarkSearch
//
//  Created by bytedance on 2022/3/18.
//

import UIKit
import Foundation
import LarkSDKInterface

final class UnfoldMoreViewModel: SearchCellViewModel {
    var searchResult: SearchResultType

    var searchClickInfo: String {
        "unfoldLoadMore"
    }

    var resultTypeInfo: String {
        "LoadMore"
    }

    var hideItemNum: Int {
        (searchResult as? OpenJumpResult)?.moreResult.count ?? 0
    }
    init(searchResult: SearchResultType) {
        self.searchResult = searchResult
    }
    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {

        // 跳转到tab类history就是空
        return nil
    }
    func supprtPadStyle() -> Bool {
        return false
    }
}
