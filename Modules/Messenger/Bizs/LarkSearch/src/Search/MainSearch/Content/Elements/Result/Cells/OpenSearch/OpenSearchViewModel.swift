//
//  ChatSearchViewModel.swift
//  Lark
//
//  Created by ChalrieSu on 02/04/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import UIKit
import LarkModel
import LarkUIKit
import LarkTag
import RxSwift
import LarkCore
import UniverseDesignToast
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkSceneManager
import LarkAppLinkSDK
import LarkSearchCore
import LarkContainer

final class OpenSearchViewModel: SearchCellViewModel, UserResolverWrapper {
    static let logger = Logger.log(OpenSearchViewModel.self, category: "Module.IM.Search")

    let router: SearchRouter
    let searchResult: SearchResultType
    private let context: SearchViewModelContext

    var searchClickInfo: String { return "open_search" }

    var resultTypeInfo: String { return "slash_command" }

    let userResolver: UserResolver
    init(userResolver: UserResolver, searchResult: SearchResultType, router: SearchRouter, context: SearchViewModelContext) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.router = router
        self.context = context
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        guard case .slash(let meta) = searchResult.meta else { return nil }
        switch meta.slashCommand {
        case .entity:
            goToURL(meta.appLink, from: vc)
        case .filter:
            assertionFailure("current should handle by page container")
            break
        @unknown default: break
        }
        return nil
    }
    private func goToURL(_ urlStr: String, from: UIViewController) {
        if let url = URL(string: urlStr)?.lf.toHttpUrl() {
            navigator.pushOrShowDetail(url, context: [FromSceneKey.key: FromScene.global_search.rawValue], from: from)
        } else {
            // 服务端应该给标准URL的，出现过特殊字符未编码导致双端打不开的情况的，留日志
            if let encodedURLStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: encodedURLStr)?.lf.toHttpUrl() {
                navigator.pushOrShowDetail(url, context: [FromSceneKey.key: FromScene.global_search.rawValue], from: from)
                Self.logger.error("[LarkSearch] useable url after encode \(urlStr)")
            } else {
                Self.logger.error("[LarkSearch] useless url \(urlStr)")
            }
        }
    }

    func supportDragScene() -> Scene? {
        // TODO:
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
