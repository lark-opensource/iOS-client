//
//  ThreadSearchViewModel.swift
//  LarkSearch
//
//  Created by zc09v on 2019/3/21.
//

import UIKit
import Foundation
import LarkModel
import LKCommonsLogging
import LarkUIKit
import LarkTag
import LarkSDKInterface
import LarkSceneManager
import LarkSearchCore

final class TopicSearchViewModel: SearchCellViewModel {
    let router: SearchRouter
    let searchResult: SearchResultType

    var searchClickInfo: String { return "thread" }

    var resultTypeInfo: String { return "thread" }

    let enableDocCustomIcon: Bool
    let enableThreadMiniIcon: Bool

    init(searchResult: SearchResultType,
         enableDocCustomIcon: Bool,
         enableThreadMiniIcon: Bool,
         router: SearchRouter) {
        self.searchResult = searchResult
        self.enableDocCustomIcon = enableDocCustomIcon
        self.enableThreadMiniIcon = enableThreadMiniIcon
        self.router = router
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        switch searchResult.meta {
        case .thread(let searchMeta):
            router.gotoThreadDetail(withThreadId: searchMeta.id, position: -1, fromVC: vc)
            return searchResult
        case .message(let searchMeta):
            router.gotoThreadDetail(withThreadId: searchMeta.threadID, position: -1, fromVC: vc)
            return searchResult
        default:
            return nil
        }
    }

    func supportDragScene() -> Scene? {
        switch searchResult.meta {
        case .thread(let searchMeta):
            return LarkSceneManager.Scene(
                key: "Thread",
                id: searchMeta.id,
                title: searchResult.title.string,
                userInfo: ["postion": "-1"],
                windowType: "channel",
                createWay: "drag"
            )
        case .message(let searchMeta):
            return LarkSceneManager.Scene(
                key: "Thread",
                id: searchMeta.threadID,
                title: searchResult.title.string,
                userInfo: ["postion": "-1"],
                windowType: "channel",
                createWay: "drag"
            )
        default:
            return nil
        }
    }

    func supprtPadStyle() -> Bool {
        return false
    }
}
