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

final class ServiceCardSearchViewModel: SearchCardViewModel {
    var userResolver: LarkContainer.UserResolver
    var searchResult: SearchResultType
    let router: SearchRouter
    weak var jsBridgeDependency: ASLynxBridgeDependencyDelegate?
    var searchClickInfo: String = ""
    var resultTypeInfo: String = "service_card"
    var indexPath: IndexPath?
    var preferredWidth: CGFloat?
    var isMainTab: Bool = true
    var isContentChangeByJSB = false

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
