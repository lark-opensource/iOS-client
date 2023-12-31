//
//  ChatAddTabViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/3/28.
//

import UIKit
import Foundation
import RustPB
import SnapKit
import LarkUIKit
import LarkModel
import LarkCore
import LarkSDKInterface
import LarkTag
import LarkFeatureGating
import LarkAvatar
import UniverseDesignColor
import LKCommonsLogging
import LarkKeyboardKit
import LKCommonsTracker
import Swinject
import RxSwift
import RxCocoa
import EENavigator
import LarkOpenChat
import LarkContainer
import TangramService

// URL 中台解析结果
struct URLPreviewInfo {
    var udIcon: String?
    var iconKey: String?
    var iconUrl: String?
    var imageSetPassThrough: Basic_V1_ImageSetPassThrough?
    let title: String
    init(title: String) {
        self.title = title
    }
}

final class ChatAddTabViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatAddTabViewModel.self, category: "Module.ChatAddTabViewModel")

    let addCompletion: (ChatTabContent) -> Void
    var updateTextField: ((String) -> Void)?
    var getCurrentInputText: (() -> String)?

    enum SearchScene {
        case doc
        case url(previewInfo: URLPreviewInfo?)
    }
    var searchScene: SearchScene = .doc

    enum SearchStatus {
        case noload
        case loading
        case normal
    }

    private let reloadSubject = PublishSubject<Void>()
    lazy var reloadDriver = self.reloadSubject.asDriver(onErrorJustReturn: Void())

    private let docAPI: DocAPI
    private let docSDKAPI: ChatDocDependency
    @ScopedInjectedLazy private var searchAPI: SearchAPI?
    @ScopedInjectedLazy private var urlPreviewAPI: URLPreviewAPI?

    let disposeBag: DisposeBag = DisposeBag()
    private var pharseURLDisposeBag: DisposeBag = DisposeBag()
    let chat: Chat
    init(userResolver: UserResolver, chat: Chat, addCompletion: @escaping (ChatTabContent) -> Void) throws {
        self.userResolver = userResolver
        self.chat = chat
        self.addCompletion = addCompletion
        self.docAPI = try userResolver.resolve(assert: DocAPI.self)
        self.docSDKAPI = try userResolver.resolve(assert: ChatDocDependency.self)
        self.pullDocsHistory()
    }

    private(set) var showDocs: [ChatTabDocSearchModel] = []

    private var docsHistory: [ChatTabDocSearchModel] = []

    private(set) var searchKey: String = ""
    private var searchResults: [ChatTabDocSearchModel] = []

    private(set) var searchResult: SearchStatus = .noload

    // 搜索翻页需要
    private var moreToken: Any?

    private lazy var linkDetector: NSDataDetector? = {
        return try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()

    func handlePaste(_ pasteText: String) {
        self.pharseURLDisposeBag = DisposeBag()
        guard checkIsURL(pasteText) else { return }
        self.generateURLPharseResult(pasteText)
            .drive(onNext: { [weak self] urlPharseResult in
                guard let self = self else { return }
                guard self.getCurrentInputText?() == pasteText else { return }
                switch urlPharseResult {
                case .link(let link):
                    self.searchURL(pasteText, urlPreviewInfo: nil)
                case .doc(let docTitle):
                    self.updateTextField?(docTitle)
                    self.searchDoc(docTitle)
                case .urlPreviewEntity(let urlPreviewInfo):
                    self.searchURL(pasteText, urlPreviewInfo: urlPreviewInfo)
                }
                Self.logger.info("handle URLPharseResult \(urlPharseResult)")
            }).disposed(by: self.pharseURLDisposeBag)
    }

    func search(_ text: String) {
        if self.searchKey == text { return }
        if checkIsURL(text) {
            self.searchURL(text, urlPreviewInfo: nil)
            return
        }
        self.searchDoc(text)
    }

    private func checkIsURL(_ text: String) -> Bool {
        if let res = linkDetector?.matches(in: text, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: text.utf16.count)),
           res.count == 1,
           res[0].range.location == 0,
           res[0].range.length == text.utf16.count {
            return true
        }
        return false
    }

    // 搜索 URL
    private func searchURL(_ url: String, urlPreviewInfo: URLPreviewInfo?) {
        self.searchKey = url
        searchScene = .url(previewInfo: urlPreviewInfo)
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

    enum URLPharseResult: CustomStringConvertible {
        case urlPreviewEntity(URLPreviewInfo) /// URL 中台解析结果
        case doc(String) /// 解析成 Doc 文档
        case link(String) /// 裸链

        var description: String {
            switch self {
            case .urlPreviewEntity: return "urlPreviewEntity"
            case .doc: return "doc"
            case .link: return "link"
            }
        }
    }

    private func generateURLPharseResult(_ urlText: String) -> Driver<URLPharseResult> {
        if let url = URL(string: urlText),
           !self.docSDKAPI.isSupportURLType(url: url).0 {
            return self.generateUrlPreviewEntity(urlText)
                .map { urlPreviewInfo in
                    if let urlPreviewInfo = urlPreviewInfo { return .urlPreviewEntity(urlPreviewInfo) }
                    return .link(urlText)
                }.asDriver(onErrorJustReturn: .link(urlText))
        }
        return self.generateDocTitle(urlText)
            .map { docTitle in
                if let docTitle = docTitle { return .doc(docTitle) }
                return .link(urlText)
            }.asDriver(onErrorJustReturn: .link(urlText))
    }

    private func generateUrlPreviewEntity(_ urlText: String) -> Observable<URLPreviewInfo?> {
        return self.urlPreviewAPI?.generateUrlPreviewEntity(url: urlText)
            .flatMap { (inlineEntity, _) -> Observable<URLPreviewInfo?> in
                guard let entity = inlineEntity, let title = entity.title, !title.isEmpty else { return .just(nil) }
                var info = URLPreviewInfo(title: title)
                info.imageSetPassThrough = entity.imageSetPassThrough
                if let key = entity.udIcon?.key {
                    info.udIcon = key
                    return .just(info)
                }
                if let key = entity.iconKey {
                    info.iconKey = key
                    return .just(info)
                }
                if let key = entity.iconUrl {
                    info.iconUrl = key
                    return .just(info)
                }
                return .just(nil)
            } ?? .error(UserScopeError.disposed)
    }

    private func generateDocTitle(_ urlText: String) -> Observable<String?> {
        return self.docAPI.getDocByURL(urls: [urlText])
            .flatMap { result -> Observable<String?> in
                if let docName = result.docs[urlText]?.name {
                    return .just(docName)
                }
                return .just(nil)
            }
    }

    func loadMoreIfNeeded() {
        if self.searchKey.isEmpty { return }
        if self.searchResult != .noload { return }
        self.searchResult = .loading
        let begin: Int32 = Int32(self.searchResults.count)
        let end: Int32 = begin + 20
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
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self, (searchText == self.searchKey || self.searchKey.isEmpty) else {
                    return
                }
                let results = response.results
                self.moreToken = response.moreToken
                self.searchResults += results.map({ (result) -> ChatTabDocSearchModel in
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
                    case let .wiki(meta):
                        id = meta.id
                        ownerName = meta.ownerName
                        ownerID = meta.ownerID
                        docType = .wiki
                        url = meta.url
                        wikiSubType = meta.type
                        updateTime = meta.updateTime
                        isCrossTenant = meta.isCrossTenant
                    default:
                        break
                    }
                    return ChatTabDocSearchModel(
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
                        iconKey: searchResult.icon?.value ?? "",
                        iconType: searchResult.icon?.type.rawValue ?? 0,
                        wikiSubType: wikiSubType,
                        relationTag: relationTag
                    )
                })

                self.updateShowItems()
                self.searchResult = response.hasMore ? .noload : .normal
            }, onError: { [weak self] (error) in
                Self.logger.error("search doc failed", error: error)
                guard let `self` = self, (searchText == self.searchKey || self.searchKey.isEmpty) else {
                    return
                }
                self.searchResult = .noload
            })
            .disposed(by: self.disposeBag)
    }

    private func pullDocsHistory() {
        self.docAPI.getDocsHistory(beginTime: 0, count: 30).subscribe(onNext: { [weak self] (result) in
            guard let `self` = self else { return }
            self.docsHistory = result.docs.map { (doc: RustPB.Space_Doc_V1_DocHistory) -> ChatTabDocSearchModel in
                let owner: Chatter? = result.chattersDic[doc.creatorID]
                let name = owner?.displayName(chatId: self.chat.id, chatType: self.chat.type, scene: .docList) ?? ""
                return ChatTabDocSearchModel(
                    id: doc.docID,
                    title: doc.title,
                    ownerID: doc.creatorID,
                    ownerName: name,
                    url: doc.url,
                    docType: doc.docType,
                    updateTime: doc.updateTime,
                    titleHitTerms: [],
                    isCrossTenant: doc.isCrossTenant,
                    iconKey: doc.icon.value,
                    iconType: doc.icon.type.rawValue,
                    wikiSubType: doc.wikiSubtype,
                    relationTag: doc.relationTag
                )
            }
            if self.searchKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.updateShowItems()
            }
        }, onError: { (error) in
            Self.logger.error("get doc history failed", error: error)
        }).disposed(by: self.disposeBag)
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
