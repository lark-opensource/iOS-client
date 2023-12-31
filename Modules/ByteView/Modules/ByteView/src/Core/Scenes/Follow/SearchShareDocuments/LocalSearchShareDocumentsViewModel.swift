//
//  LocalSearchShareDocumentViewModel.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/6/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Action
import ByteViewNetwork
import ByteViewMeeting

class LocalSearchShareDocumentsViewModel: SearchShareDocumentsVMProtocol {

    let isSearch: Bool

    let disposeBag = DisposeBag()

    var didSelectedModel = PublishSubject<SearchDocumentResultCellModel>()

    let pagination: MatchPaginatedList<VcDocs>

    var scenario: ShareContentScenario {
        .local
    }

    /// 正在进行的会议的meetingID，如没有返回nil
    var currentOngoingMeetingId: String? {
        if let meetingSession = MeetingManager.shared.currentSession, meetingSession.state == .onTheCall {
            return meetingSession.meetingId
        }
        return nil
    }

    var httpClient: HttpClient

    private static func buildSearchAction(httpClient: HttpClient) -> Action<(String?, Range<Int>), ([VcDocs], Bool)> {
        let workFactory = { (query: String?, range: Range<Int>) -> Single<([VcDocs], Bool)> in
            let offset = Int32(range.lowerBound)
            let limit = Int32(range.upperBound - range.lowerBound)
            let queryString = query ?? ""
            let request = QueryDocsRequest(query: queryString, limit: limit, offset: offset, source: .searchListPage)
            return RxTransform.single {
                httpClient.getResponse(request, completion: $0)
            }.map { ($0.docs, $0.hasMore) }
        }
        return Action(workFactory: workFactory)
    }

    var searchText: AnyObserver<String?> {
        return pagination.text
    }

    var loadNext: AnyObserver<Void> {
        return pagination.loadNext
    }

    var resultData: Observable<[SearchDocumentResultCellModel]> {
        let docValues = pagination.result
            .flatMap { result -> Observable<[VcDocs]> in
                switch result {
                case .results(let value, _):
                    return .just(value)
                case .loading:
                    return .empty()
                case .noMatch:
                    return .just([])
                }
            }
        return docValues
            .map { (values) -> [SearchDocumentResultCellModel] in
                return values.enumerated().map { (index, element) in
                    return SearchDocumentResultCellModel(element, isSharing: false, rank: index, isFileMeetingRelated: false)
                }
            }
    }

    var resultStatus: Observable<SearchContainerView.Status> {
        return pagination.result.map { result -> SearchContainerView.Status in
            switch result {
            case .results(_, let hasMore):
                return .result(hasMore)
            case .loading:
                return .loading
            case .noMatch:
                return .noResult
            }
        }
    }

    var meetingRelatedDocumentsSubject = PublishSubject<[SearchDocumentResultCellModel]>()

    var meetingRelatedDocument: Observable<[SearchDocumentResultCellModel]> {
        self.meetingRelatedDocumentsSubject.asObservable()
    }

    private func updateMeetingRelatedDocuments() {
        guard let meetingId = currentOngoingMeetingId else {
            self.meetingRelatedDocumentsSubject.onNext([])
            return
        }
        httpClient.getResponse(QueryMeetingRelatedDocsRequest(meetingId: meetingId)) { [weak self] getQueryResult in
            guard let self = self else { return }
            switch getQueryResult {
            case .success(let getQueryRsp):
                Logger.shareContent.info("query meeting related docs, count: \(getQueryRsp.meetingRelatedDocs.count)")
                let docs = getQueryRsp.meetingRelatedDocs
                let ids = docs.map { $0.ownerId }
                self.httpClient.getResponse(GetChattersRequest(chatterIds: ids)) { getChattersResult in
                    switch getChattersResult {
                    case .success(let getChattersRsp):
                        Logger.shareContent.info("query meeting related docs.chatters, count: \(getChattersRsp.chatters.count)")
                        let chatters = getChattersRsp.chatters
                        var relatedDocuments = [SearchDocumentResultCellModel]()
                        for doc in docs {
                            if let chatter = chatters.first(where: { $0.id == doc.ownerId }) {
                                let docItem = self.createDocumentResultCellModel(doc: doc, name: chatter.name)
                                relatedDocuments.append(docItem)
                            }
                        }
                        self.meetingRelatedDocumentsSubject.onNext(Array(relatedDocuments.prefix(SearchShareDocumentsDefines.meetingRelatedDocumentMaxDisplayCount)))
                    case .failure(let getChattersError):
                        Logger.shareContent.error("query meeting related docs.chatters failed with error: \(getChattersError.toErrorCode())")
                    }
                }
            case .failure(let getQueryError):
                Logger.shareContent.error("query meeting related docs failed with error: \(getQueryError.toErrorCode())")
            }
        }
    }

    private func createDocumentResultCellModel(doc: VcDocs, name: String) -> SearchDocumentResultCellModel {
        var document = doc
        document.ownerName = name
        return SearchDocumentResultCellModel(document, isSharing: false, rank: 0, isFileMeetingRelated: true)
    }

    var dismissPublishSubject = PublishSubject<Void>()
    var showLoadingObservable: Observable<Bool>

    let accountInfo: AccountInfo
    let startSharing: StartSharing

    init(accountInfo: AccountInfo, httpClient: HttpClient, startSharing: @escaping StartSharing,
         showLoadingObservable: Observable<Bool>, isSearch: Bool) {
        self.accountInfo = accountInfo
        self.httpClient = httpClient
        let searchAction = LocalSearchShareDocumentsViewModel.buildSearchAction(httpClient: httpClient)
        self.startSharing = startSharing
        self.showLoadingObservable = showLoadingObservable
        self.isSearch = isSearch
        // 由于服务端会过滤不支持的类型，可能导致展示数量不足，因此增加一些额外数量
        // nolint-next-line: magic number
        pagination = MatchPaginatedList(searchAction, step: 20)
        buildFlow()
        updateMeetingRelatedDocuments()
    }

    private func buildFlow() {
        didSelectedModel
            .subscribe(onNext: { [weak self] (docs) in
                guard let self = self else {
                    Logger.vcFollow.warn("didSelectedModel failed due to invalid self, isLocal = true")
                    return
                }
                if self.isSearch {
                    MagicShareTracksV2.trackOpenSearchedFile(rank: docs.rank, isLocal: true)
                } else {
                    MagicShareTracksV2.trackClickMagicShare(rank: docs.rank, token: docs.docToken, isLocal: true, isFileMeetingRelated: docs.isFileMeetingRelated)
                }
                self.startSharing(.shareDoc(docs.url))
            })
            .disposed(by: disposeBag)
    }
}
