//
//  ExternalSearchViewModel.swift
//  LarkSearch
//
//  Created by SuPeng on 7/22/19.
//

import UIKit
import Foundation
import LarkModel
import EENavigator
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

final class ExternalSearchViewModel: SearchCellViewModel {
    let router: SearchRouter
    let searchResult: SearchResultType

    var searchClickInfo: String {
        return "external"
    }

    var resultTypeInfo: String {
        return "external"
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver, searchResult: SearchResultType, router: SearchRouter) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.router = router
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        guard case let .external(meta) = searchResult.meta,
            let url = URL(string: meta.url) else {
                SearchRootViewController.logger.error("[LarkSerch] external search can not jump with error url")
            return nil
        }
        userResolver.navigator.pushOrShowDetail(url, from: vc) { (_, res) in
            if let err = res.error {
                SearchRootViewController.logger.error("[LarkSerch] external search jump error", error: err)
            } else {
                SearchRootViewController.logger.info("[LarkSerch] external search jump to url success")
            }
        }
        return nil
    }

    func supprtPadStyle() -> Bool {
        return false
    }
}
