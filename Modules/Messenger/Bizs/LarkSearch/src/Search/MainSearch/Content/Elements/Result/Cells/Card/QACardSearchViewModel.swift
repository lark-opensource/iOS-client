//
//  QACardSearchViewModel.swift
//  LarkSearch
//
//  Created by ZhangHongyun on 2021/7/15.
//

import Foundation
import UIKit
import LarkSearchCore
import LarkSDKInterface
import LarkContainer

final class QACardSearchViewModel: SearchCardViewModel {
    weak var jsBridgeDependency: ASLynxBridgeDependencyDelegate?
    var searchResult: SearchResultType
    let router: SearchRouter
    var searchClickInfo: String = ""
    var resultTypeInfo: String = "kg_card"
    var indexPath: IndexPath?
    var preferredWidth: CGFloat?
    var isMainTab: Bool = true
    var isContentChangeByJSB = false

    var userResolver: UserResolver
    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        return nil
    }

    func supprtPadStyle() -> Bool {
        return false
    }

    init(userResolver: UserResolver, searchResult: SearchResultType, router: SearchRouter) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.router = router
    }

}
