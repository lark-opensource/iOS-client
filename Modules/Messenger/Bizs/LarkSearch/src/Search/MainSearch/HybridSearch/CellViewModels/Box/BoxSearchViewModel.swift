//
//  BoxSearchViewModel.swift
//  LarkSearch
//
//  Created by Yuguo on 2018/9/30.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkSDKInterface
import LarkSearchCore
import LarkContainer

final class BoxSearchViewModel: SearchCellViewModel {
    let router: SearchRouter
    let searchResult: SearchResultType

    var searchClickInfo: String {
        return "box"
    }

    var resultTypeInfo: String {
        return "box"
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver, searchResult: SearchResultType, router: SearchRouter) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.router = router
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        switch searchResult.meta {
        case .box(let boxMeta):
            router.gotoChatBox(chatBoxId: boxMeta.id, from: vc)
            return searchResult
        default:
            return nil
        }
    }

    func supprtPadStyle() -> Bool {
        return false
    }
}
