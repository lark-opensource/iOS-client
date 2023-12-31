//
//  StoreCardSearchViewModel.swift
//  LarkSearch
//
//  Created by bytedance on 2021/8/9.
//

import Foundation
import UIKit
import LarkSearchCore
import LarkSDKInterface
import LarkContainer

final class StoreCardSearchViewModel: SearchCardViewModel {
    var userResolver: LarkContainer.UserResolver

    weak var jsBridgeDependency: ASLynxBridgeDependencyDelegate?
    let router: SearchRouter
    var searchResult: SearchResultType
    var searchClickInfo: String = ""
    var resultTypeInfo: String = "slash_command"
    var indexPath: IndexPath?
    var isContentChangeByJSB = false
    var isMainTab: Bool
    var preferredWidth: CGFloat?

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        return nil
    }

    func supprtPadStyle() -> Bool {
        return false
    }
    init(userResolver: UserResolver, searchResult: SearchResultType, router: SearchRouter, isMainTab: Bool = true) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.router = router
        self.isMainTab = isMainTab
    }

}
