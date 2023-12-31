//
//  ChatAddPinSearchViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/6.
//

import Foundation
import RustPB
import LarkUIKit
import LarkModel
import LarkCore
import LarkSDKInterface
import LarkTag
import LKCommonsLogging
import Swinject
import RxSwift
import RxCocoa
import LarkContainer

final class ChatAddPinSearchViewModel: UserResolverWrapper {
    var userResolver: UserResolver
    private static let logger = Logger.log(ChatAddPinSearchViewModel.self, category: "Module.IM.ChatPin")
    static var pageCount: Int32 { 20 }

    enum SearchScene {
        case doc
        case url
    }
    private(set)var searchScene: SearchScene = .doc

    enum SearchStatus {
        case noload
        case loading
        case normal
    }

    private let reloadSubject = PublishSubject<Void>()
    lazy var reloadDriver = self.reloadSubject.asDriver(onErrorJustReturn: Void())

    @ScopedInjectedLazy private var searchAPI: SearchAPI?

    let disposeBag: DisposeBag = DisposeBag()
    var chat: Chat {
        return self.chatWrapper.chat.value
    }
    let chatWrapper: ChatPushWrapper

    init(chatWrapper: ChatPushWrapper, userResolver: UserResolver) {
        self.chatWrapper = chatWrapper
        self.userResolver = userResolver
        self.pullDocsHistory()
    }

    private(set) var showDocs: [ChatAddPinDocSearchModel] = []
    private var docsHistory: [ChatAddPinDocSearchModel] = []
    private(set) var searchKey: String = ""
    private var searchResults: [ChatAddPinDocSearchModel] = []
    private(set) var searchResult: SearchStatus = .noload

    // 搜索翻页需要
    private var moreToken: Any?

    private lazy var linkDetector: NSDataDetector? = {
        return try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    func search(_ text: String) {
        if self.searchKey == text { return }
        if text.hasPrefix("https://") || text.hasPrefix("http://") {
            self.searchURL(text)
        } else {
            self.searchDoc(text)
        }
    }

    // 搜索 URL
    private func searchURL(_ url: String) {
        self.searchKey = url
        searchScene = .url
        self.reloadSubject.onNext(())
    }

    // 搜索 Doc
    private func searchDoc(_ text: String) {
        self.searchKey = text
        searchScene = .doc
        self.searchResult = .noload
        self.searchResults = []
        self.updateShowItems()
        if !self.searchKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.loadMoreIfNeeded()
        } else {
            self.searchResult = .normal
            self.reloadSubject.onNext(())
        }
    }

    func loadMoreIfNeeded() {
        if self.searchKey.isEmpty { return }
        if self.searchResult != .noload { return }
        self.searchResult = .loading
        let begin: Int32 = Int32(self.searchResults.count)
        let end: Int32 = begin + Self.pageCount
        let searchText = self.searchKey
        self.searchAPI?
            .universalSearch(query: searchText,
                             scene: .rustScene(.searchDoc),
                             begin: begin,
                             end: end,
                             moreToken: moreToken,
                             filter: nil,
                             needSearchOuterTenant: false,
                             authPermissions: [])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self, (searchText == self.searchKey || self.searchKey.isEmpty) else {
                    return
                }
                let results = response.results
                self.moreToken = response.moreToken
                self.searchResults += results.map({ (result) -> ChatAddPinDocSearchModel in
                    return self.transform(result)
                })

                self.updateShowItems()
                self.searchResult = response.hasMore ? .noload : .normal
            }, onError: { [weak self] (error) in
                Self.logger.error("search doc failed", error: error)
                guard let `self` = self, (searchText == self.searchKey || self.searchKey.isEmpty) else {
                    return
                }
                self.searchResult = .noload
            }).disposed(by: self.disposeBag)
    }

    private func pullDocsHistory() {
        self.searchAPI?
            .universalSearch(query: "",
                             scene: .rustScene(.searchDoc),
                             begin: 0,
                             end: Self.pageCount,
                             moreToken: nil,
                             filter: nil,
                             needSearchOuterTenant: false,
                             authPermissions: [])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                self.docsHistory = response.results.map({ (result) -> ChatAddPinDocSearchModel in
                    return self.transform(result)
                })
                if self.searchKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.updateShowItems()
                }
            }, onError: { (error) in
                Self.logger.error("get doc history failed", error: error)
            }).disposed(by: self.disposeBag)
    }

    private func transform(_ result: SearchResultType) -> ChatAddPinDocSearchModel {
        let searchResult = result
        var id: String = ""
        let title: String = searchResult.title.string
        let attributedTitle: NSAttributedString = searchResult.title
        var ownerName: String = ""
        var url: String = ""
        var docType: RustPB.Basic_V1_Doc.TypeEnum = .unknown
        var updateTime: Int64 = 0
        var isCrossTenant: Bool = false
        var wikiSubType: RustPB.Basic_V1_Doc.TypeEnum = .unknown
        var ownerID: String = ""
        var relationTag: Basic_V1_TagData?
        var iconInfo: String = ""

        switch result.meta {
        //https://bytedance.feishu.cn/docs/doccnxfesEvyuhMPt3AU0hgiPFb
        case let .doc(meta):
            id = meta.id
            ownerName = meta.ownerName
            docType = meta.type
            url = meta.url
            updateTime = meta.updateTime
            isCrossTenant = meta.isCrossTenant
            ownerID = meta.ownerID
            var tagData = Basic_V1_TagData()
            // transform Search_V2_TagData to Basic_V1_TagData
            tagData.tagDataItems = meta.relationTag.tagDataItems.map({ item in
                var new = Basic_V1_TagData.TagDataItem()
                new.textVal = item.textVal
                new.tagID = item.tagID
                switch item.respTagType {
                case .relationTagExternal:
                    new.respTagType = .relationTagExternal
                case .relationTagPartner:
                    new.respTagType = .relationTagPartner
                case .relationTagTenantName:
                    new.respTagType = .relationTagTenantName
                case .relationTagUnset:
                    new.respTagType = .relationTagUnset
                @unknown default:
                    assertionFailure("unknown respTagType")
                }
                return new
            })
            relationTag = tagData
            iconInfo = meta.iconInfo
        case let .wiki(meta):
            id = meta.id
            ownerName = meta.ownerName
            ownerID = meta.ownerID
            docType = .wiki
            url = meta.url
            wikiSubType = meta.type
            updateTime = meta.updateTime
            isCrossTenant = meta.isCrossTenant
            iconInfo = meta.iconInfo
        default:
            break
        }
        return ChatAddPinDocSearchModel(
            id: id,
            title: title,
            attributedTitle: attributedTitle,
            ownerID: ownerID,
            ownerName: ownerName,
            url: url,
            docType: docType,
            updateTime: updateTime,
            titleHitTerms: [],
            isCrossTenant: isCrossTenant,
            wikiSubType: wikiSubType,
            relationTag: relationTag,
            iconInfo: iconInfo,
            userResolver: self.userResolver
        )
    }

    private func updateShowItems() {
        DispatchQueue.main.async {
            if self.searchKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.showDocs = self.docsHistory
            } else {
                self.showDocs = self.searchResults
            }
            self.reloadSubject.onNext(())
        }
    }
}
