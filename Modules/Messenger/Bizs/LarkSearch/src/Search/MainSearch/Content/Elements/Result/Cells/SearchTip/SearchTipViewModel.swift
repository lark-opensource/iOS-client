//
//  SearchTipViewModel.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/2/17.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkSceneManager
import RustPB
import LarkContainer

final class SearchTipViewModel: SearchCellViewModel {
    let searchResult: SearchResultType

    var searchClickInfo: String { return "" }

    var resultTypeInfo: String { return "SearchTip" }

    var errorInfo: Search_V2_SearchCommonResponseHeader.ErrorInfo?

    var showHotTip: Bool
    let userResolver: UserResolver
    private let context: SearchViewModelContext
    init(userResolver: UserResolver, searchResult: SearchResultType, showHotTip: Bool, context: SearchViewModelContext) {
        self.searchResult = searchResult
        self.showHotTip = showHotTip
        self.context = context
        self.userResolver = userResolver
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        return nil
    }

    /// 返回支持 iPad 多 scene 场景的拖拽能力
    func supportDragScene() -> Scene? {
        return nil
    }

    func supprtPadStyle() -> Bool {
        if !UIDevice.btd_isPadDevice() {
            return false
        }
        if SearchTab.main == context.tab {
            return false
        }
        return isPadFullScreenStatus(resolver: userResolver)
    }
}
