//
//  DocsSearchViewModel.swift
//  LarkSearch
//
//  Created by ChalrieSu on 2018/4/13.
//  Copyright © 2018 liuwanlin. All rights reserved.
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
import CryptoSwift
import LarkSearchCore
import LarkSceneManager
import LarkContainer

final class DocsSearchViewModel: SearchCellViewModel {
    static let logger = Logger.log(DocsSearchViewModel.self, category: "Module.IM.Search")

    private let docAPI: DocAPI
    private let feedAPI: FeedAPI
    let router: SearchRouter
    let searchResult: SearchResultType
    private let context: SearchViewModelContext

    var searchClickInfo: String {
        guard let docMeta = docMeta else { return "" }

        switch docMeta.type {
        case .bitable:
            return "bitable"
        case .doc:
            return "doc"
        case .file:
            return "file"
        case .mindnote:
            return "mindnote"
        case .sheet:
            return "sheet"
        case .slide:
            return "slide"
        case .slides:
            return "slides"
        case .docx:
            return "docx"
        case .folder:
            return "folder"
        case .wiki:
            return "wiki"
        case .unknown:
            return "unknown"
        case .catalog, .shortcut:
            fallthrough // use unknown default setting to fix warning
        @unknown default:
            assert(false, "new value")
            return "unknown"
        }
    }

    var resultTypeInfo: String {
        guard let docMeta = docMeta else { return "" }
        guard docMeta.wikiInfo.isEmpty else {
            return "wiki"
        }
        switch docMeta.type {
        case .bitable:
            return "bitable"
        case .doc:
            return "doc"
        case .file:
            return "file"
        case .mindnote:
            return "mindnote"
        case .sheet:
            return "sheet"
        case .slide:
            return "slide"
        case .slides:
            return "slides"
        case .shortcut:
            return "shortcut"
        case .docx:
            return "docx"
        case .wiki:
            return "wiki"
        case .folder:
            return "folder"
        case .unknown:
            return "docs_unknown"
        case .catalog:
            fallthrough // use unknown default setting to fix warning
        @unknown default:
            assert(false, "new value")
            return "none"
        }
    }

    var docMeta: SearchMetaDocType? {
        switch searchResult.meta {
        case .wiki(let wikiMeta):
            return wikiMeta.docMetaType
        case .doc(let v):
            return v
        default:
            return nil
        }
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
        guard let docMeta = docMeta else { return nil }

        self.gotoDocs(from: vc, result: self.searchResult, meta: docMeta, feed: nil)
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

    func gotoDocs(from vc: UIViewController, result: SearchResultType, meta: SearchMetaDocType, feed: Basic_V1_DocFeed?) {
        var wikiURL: String?
        if case .wiki(let wiki) = result.meta, case let url = wiki.url, !url.isEmpty {
            wikiURL = url
        } else if let url = meta.wikiInfo.first?.url, !url.isEmpty {
            wikiURL = url
        }
        if let wikiURL = wikiURL {
            // wiki暂不支持feed，不需要传feedID
            self.router.gotoDocs(withURL: URL(string: wikiURL), infos: ["from": "wiki_search_default"], fromVC: vc)
        } else {
            if let feed = feed {
                self.router.gotoDocs(withURL: URL(string: meta.url), infos: ["feed_id": feed.id], feedId: feed.id, fromVC: vc)
            } else {
                self.router.gotoDocs(withURL: URL(string: meta.url), infos: nil, fromVC: vc)
            }
        }
        if let feed = feed { self.peakDocFeed(by: feed.id) }
    }

    func supportDragScene() -> Scene? {
        switch searchResult.meta {
        case .doc(let docMeta):
            if let wikiURL = docMeta.wikiInfo.first?.url {
                return LarkSceneManager.Scene(
                    key: "Docs",
                    id: wikiURL,
                    title: searchResult.title.string,
                    windowType: "docs",
                    createWay: "drag"
                )
            }
            return LarkSceneManager.Scene(
                key: "Docs",
                id: docMeta.url,
                title: searchResult.title.string,
                windowType: "docs",
                createWay: "drag"
            )
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

    func docSearchClickInfo() -> [String: String] {
        switch searchResult.meta {
        case .doc(let docMeta):
            return ["file_id": SearchTrackUtil.encrypt(id: docMeta.url),
                    "file_type": docType(type: docMeta.type)]
        default:
            return [:]
        }
    }

    private func docType(type: Basic_V1_Doc.TypeEnum) -> String {
        switch type {
        case .unknown:
            return "unknown"
        case .doc:
            return "doc"
        case .sheet:
            return "sheet"
        case .bitable:
            return "bitable"
        case .mindnote:
            return "mindnote"
        case .file:
            return "file"
        case .slide:
            return "slide"
        case .slides:
            return "slides"
        case .docx:
            return "docx"
        case .wiki:
            return "wiki"
        case .folder, .catalog, .shortcut:
            fallthrough // use unknown default setting to fix warning
        @unknown default:
            assert(false, "new value")
            return "unknown"
        }
    }
}
