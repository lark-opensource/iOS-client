//
//  SendDocViewModel.swift
//  Lark
//
//  Created by lichen on 2018/7/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LKCommonsLogging

#if MessengerMod
import LarkSDKInterface
#endif

import RustPB
import Swinject

/**
 云文档Cell是否可选中
 .sendDocOptionalType（可选）默认为可选
 .sendDocNotOptionalType（不可选）
 */
public enum SendDocCanSelectType: Int64 {
    case sendDocOptionalType = 1
    case sendDocNotOptionalType = 2
}

public final class SendDocViewModel {
    private let resolver: Resolver

    enum SearchStatus {
        case noload
        case loading
        case nomore
    }

    static let logger = Logger.log(SendDocViewModel.self, category: "Module.SendDocViewModel")

    private let reloadSubject = PublishSubject<Void>()
    lazy var reloadDriver = self.reloadSubject.asDriver(onErrorJustReturn: Void())

    private let selectedSubject = PublishSubject<[SendDocModel]>()
    lazy var selectedDriver = self.selectedSubject.asDriver(onErrorJustReturn: [])

    /**Cell是否可选*/
    public var sendDocCanSelectType: SendDocCanSelectType

    #if MessengerMod
    let docAPI: DocAPI
    let searchAPI: SearchAPI
    #endif

    var sendDocBlock: SendDocBlock

    let disposeBag: DisposeBag = DisposeBag()
    let context: SendDocBody.Context
    let chat: Chat?
    var didClickConfirm = false
    public init(context: SendDocBody.Context,

                resolver: Resolver,
                sendDocBlock: @escaping SendDocBlock) {
        self.chat = context.chat
        self.context = context
        self.resolver = resolver

        #if MessengerMod
        self.docAPI = resolver.resolve(DocAPI.self)!
        self.searchAPI = resolver.resolve(SearchAPI.self)!
        #endif

        self.sendDocBlock = sendDocBlock
        self.sendDocCanSelectType = context.sendDocCanSelectType ?? .sendDocOptionalType
        self.pullDocsHistory()
    }

    private(set) var showDocs: [SendDocModel] = []

    private var docsHistory: [SendDocModel] = []

    private(set) var searchKey: String = ""
    private var searchResults: [SendDocModel] = []

    private(set) var selected: [SendDocModel] = []
    private(set) var searchResult: SearchStatus = .noload

    // 搜索翻页需要
    private var moreToken: Any?

    func sendDoc() {
        self.sendDocBlock(true, self.selected)
    }

    func searchDoc(_ text: String) {
        if self.searchKey == text {
            return
        }
        self.searchKey = text
        self.searchResult = .noload
        self.searchResults = []
        self.updateShowItems()
        if !self.searchKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.loadMoreIfNeeded()
        } else {
            self.searchResult = .nomore
            self.reloadSubject.onNext(())
        }
    }

    func loadMoreIfNeeded() {
        #if MessengerMod
        if self.searchKey.isEmpty { return }
        if self.searchResult != .noload { return }
        self.searchResult = .loading
        let begin: Int32 = Int32(self.searchResults.count)
        let end: Int32 = begin + 20
        let searchText = self.searchKey
        self.searchAPI
            .universalSearch(query: searchText,
                             scene: .searchDocAndWiki,
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
                self.searchResults += results.map({ (result) -> SendDocModel in
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
                    var relationTag: Search_V2_TagData? = nil

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
                        relationTag = meta.relationTag
                    case let .wiki(meta):
                        id = meta.id
                        ownerName = meta.ownerName
                        ownerID = meta.ownerID
                        docType = .wiki
                        url = meta.url
                        wikiSubType = meta.type
                        updateTime = meta.updateTime
                        isCrossTenant = meta.isCrossTenant
                        relationTag = meta.relationTag
                    default:
                        break
                    }
                    return SendDocModel(
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
                        sendDocModelCanSelectType: self.sendDocCanSelectType == .sendDocOptionalType ? .optionalType : .notOptionalType,
                        searchRelationTag: relationTag
                    )
                })
                
                self.updateShowItems()
                self.searchResult = response.hasMore ? .noload : .nomore
            }, onError: { [weak self] (error) in
                SendDocViewModel.logger.error("search doc failed", error: error)
                guard let `self` = self, (searchText == self.searchKey || self.searchKey.isEmpty) else {
                    return
                }
                self.searchResult = .noload
            })
            .disposed(by: self.disposeBag)
        #endif
    }

    func pullDocsHistory() {
        #if MessengerMod
        self.docAPI.getDocsHistory(beginTime: 0, count: 30).subscribe(onNext: { [weak self] (result) in
            guard let `self` = self else { return }
            self.docsHistory = result.docs.map { (doc: RustPB.Space_Doc_V1_DocHistory) -> SendDocModel in
                let owner: Chatter? = result.chattersDic[doc.creatorID]
                let name = owner?.displayName(chatId: self.chat?.id ?? "", chatType: self.chat?.type, scene: .docList) ?? ""
                return SendDocModel(
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
                    sendDocModelCanSelectType: self.sendDocCanSelectType == .sendDocOptionalType ? .optionalType : .notOptionalType,
                    relationTag: doc.relationTag
                )
            }
            if self.searchKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.updateShowItems()
            }
        }, onError: { (error) in
            SendDocViewModel.logger.error("get doc history failed", error: error)
        }).disposed(by: self.disposeBag)
        #endif
    }

    func selectOrUnselected(_ doc: SendDocModel) {
        if self.isSelected(doc) {
            if let index = self.selected.firstIndex(where: { (selected) -> Bool in
                return selected.id == doc.id
            }) {
                self.selected.remove(at: index)
            }
        } else {
            self.selected.append(doc)
        }
        selectedSubject.onNext(self.selected)
    }

    func isSelected(_ doc: SendDocModel) -> Bool {
        return self.selected.contains(where: { (selected) -> Bool in
            return selected.id == doc.id
        })
    }

    private func updateShowItems() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.searchKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.showDocs = self.docsHistory
            } else {
                self.showDocs = self.searchResults
            }
            self.reloadSubject.onNext(())
        }
    }
}
