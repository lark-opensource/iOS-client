//
//  WikiSearchViewModel.swift
//  LarkSearch
//
//  Created by SuPeng on 8/12/19.
//

import Foundation
import UIKit
import LarkModel
import RustPB
import LarkUIKit
import RxSwift
import LKCommonsLogging
import LarkTag
import LarkCore
import UniverseDesignToast
import LarkSDKInterface
import LarkSceneManager
import LarkSearchCore
import LarkContainer

final class WikiSearchViewModel: SearchCellViewModel {
    static let logger = Logger.log(WikiSearchViewModel.self, category: "Module.IM.Search")

    private let docAPI: DocAPI
    private let feedAPI: FeedAPI
    let router: SearchRouter
    let searchResult: SearchResultType
    private let context: SearchViewModelContext

    var searchClickInfo: String {
        var clickTarget = ""
        switch searchResult.meta {
        case .wiki(let wikiMeta):
            let docMeta = wikiMeta.docMetaType
            switch docMeta.type {
            case .bitable:
                clickTarget = "bitable"
            case .doc:
                clickTarget = "doc"
            case .file:
                clickTarget = "file"
            case .mindnote:
                clickTarget = "mindnote"
            case .sheet:
                clickTarget = "sheet"
            case .slide:
                clickTarget = "slide"
            case .slides:
                clickTarget = "slides"
            case .docx:
                clickTarget = "docx"
            case .wiki:
                clickTarget = "wiki"
            case .unknown:
                clickTarget = "unknown"
            case .folder:
                clickTarget = "folder"
            case .catalog:
                clickTarget = "catalog"
            case .shortcut:
                clickTarget = "shortcut"
            @unknown default:
                assert(false, "new value")
                clickTarget = "unknown"
            }
        default:
            break
        }
        return clickTarget
    }

    // wiki和docs 不对齐，wiki统一上报“wiki”, docs根据格式区分
    var resultTypeInfo: String {
        return "wiki"
    }

    let enableDocCustomAvatar: Bool

    let disposeBag = DisposeBag()
    let userResolver: UserResolver
    init(userResolver: UserResolver,
        searchResult: SearchResultType,
         docAPI: DocAPI,
         feedAPI: FeedAPI,
         enableDocCustomAvatar: Bool,
         router: SearchRouter,
         context: SearchViewModelContext) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.docAPI = docAPI
        self.feedAPI = feedAPI
        self.enableDocCustomAvatar = enableDocCustomAvatar
        self.router = router
        self.context = context
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        switch searchResult.meta {
        case .wiki(let wikiMeta):
            self.router.gotoDocs(withURL: URL(string: wikiMeta.url), infos: ["from": "wiki_search_default"], fromVC: vc)
            return nil
        default:
            break
        }
        return nil
    }

    func supportDragScene() -> Scene? {
        switch searchResult.meta {
        case .wiki(let wikiMeta):
            return LarkSceneManager.Scene(
                key: "Docs",
                id: wikiMeta.url,
                title: searchResult.title.string,
                windowType: "docs",
                createWay: "drag"
            )
        default:
            return nil
        }
    }

    private func peakDocFeed(by feedId: String) {
        feedAPI.peakFeedCard(by: feedId, entityType: .docFeed)
            .subscribe(onError: { (error) in
                Self.logger.error("Peak feed card faild", additionalData: [
                    "feedCardId": feedId,
                    "entityType": "docFeed"], error: error)
            }).disposed(by: disposeBag)
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
