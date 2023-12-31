//
//  SearchShareDocumentsViewModel.swift
//  ByteView
//
//  Created by lvdaqian on 2019/10/16.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Action
import UniverseDesignIcon
import ByteViewNetwork

final class SearchShareDocumentsViewModel: SearchShareDocumentsVMProtocol {

    let isSearch: Bool

    let disposeBag = DisposeBag()

    var didSelectedModel = PublishSubject<SearchDocumentResultCellModel>()

    let pagination: MatchPaginatedList<VcDocs>

    var scenario: ShareContentScenario {
        .inMeet
    }

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

    /// 当前妙享文档链接
    private var magicShareDocumentUrl: String = ""

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
            .map { [weak self] (values) -> [SearchDocumentResultCellModel] in
                let currentDocumentUrl = self?.magicShareDocumentUrl ?? ""
                let rawResult = values.enumerated().map { (index, element) -> SearchDocumentResultCellModel in
                    let isSharing = (element.docURL == currentDocumentUrl.vc.removeParams() && !currentDocumentUrl.vc.removeParams().isEmpty)
                    return SearchDocumentResultCellModel(element, isSharing: isSharing, rank: index, isFileMeetingRelated: false)
                }
                let result = rawResult.filter { $0.isSharing } + rawResult.filter { !$0.isSharing }
                return result
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

    var dismissPublishSubject = PublishSubject<Void>()
    var showLoadingObservable: Observable<Bool> = .just(false)

    // 共享内容权限相关
    let canShareContentRelay: BehaviorRelay<Bool>
    let canReplaceShareContentRelay: BehaviorRelay<Bool>
    let handleShareContentControlForbiddenPublisher: PublishSubject<ShareContentControlToastType>
    let meeting: InMeetMeeting
    var accountInfo: AccountInfo { meeting.accountInfo }

    init(meeting: InMeetMeeting,
         canShareContentRelay: BehaviorRelay<Bool>,
         canReplaceShareContentRelay: BehaviorRelay<Bool>,
         handleShareContentControlForbiddenPublisher: PublishSubject<ShareContentControlToastType>,
         isSearch: Bool) {
        let searchAction = SearchShareDocumentsViewModel.buildSearchAction(httpClient: meeting.httpClient)
        // 由于服务端会过滤不支持的类型，可能导致展示数量不足，因此增加一些额外数量
        // nolint-next-line: magic number
        pagination = MatchPaginatedList(searchAction, step: 20)
        self.canShareContentRelay = canShareContentRelay
        self.canReplaceShareContentRelay = canReplaceShareContentRelay
        self.handleShareContentControlForbiddenPublisher = handleShareContentControlForbiddenPublisher
        self.meeting = meeting
        self.isSearch = isSearch
        buildFlow(meeting: meeting)
        meeting.data.addListener(self)
        meeting.shareData.addListener(self)
        updateMeetingRelatedDocuments()
    }

    private func buildFlow(meeting: InMeetMeeting) {
        didSelectedModel
            .subscribe(onNext: { [weak self] (docs) in
                guard let self = self else {
                    Logger.vcFollow.warn("didSelectedModel failed due to invalid self, isLocal = false")
                    return
                }
                InMeetSettingsMagicShareTracks.trackSelectSearchFile(fromRecommendList: false,
                                                                     rank: docs.rank,
                                                                     docType: docs.docType.rawValue,
                                                                     docSubType: docs.docSubType.rawValue,
                                                                     token: docs.docToken)

                if self.isSearch {
                    MagicShareTracksV2.trackOpenSearchedFile(rank: docs.rank, isLocal: false)
                } else {
                    MagicShareTracksV2.trackClickMagicShare(rank: docs.rank, token: docs.docToken, isLocal: false, isFileMeetingRelated: docs.isFileMeetingRelated)
                }

                guard self.isShareContentControlLegal() else { return }
                if docs.isSharing,
                   let sharerUser = meeting.data.inMeetingInfo?.followInfo?.user,
                   sharerUser == meeting.account {
                    self.dismissPublishSubject.onNext(Void()) // 如果自己是当前共享人，什么都不做，页面dismiss
                } else {
                    let currentSharedDocumentUrl = meeting.data.inMeetingInfo?.followInfo?.url.vc.removeParams()
                    let executeBlock = {
                        self.meeting.httpClient.follow.startShareDocument(
                            docs.url,
                            meetingId: self.meeting.meetingId,
                            lifeTime: .ephemeral,
                            initSource: .initDirectly,
                            authorityMask: nil,
                            breakoutRoomId: meeting.data.breakoutRoomId,
                            shareId: self.meeting.data.inMeetingInfo?.followInfo?.shareID,
                            isSameToCurrent: (currentSharedDocumentUrl != nil) && (currentSharedDocumentUrl == docs.url.vc.removeParams())
                        ) { [weak self] result in
                            if let followInfo = result.value?.followInfo {
                                MagicShareTracks.trackStartShareContentOnOpenFile(token: followInfo.docToken,
                                                                                  shareType: followInfo.shareType,
                                                                                  shareSubType: followInfo.shareSubtype,
                                                                                  shareId: followInfo.shareID)
                                MagicShareTracksV2.trackEnterMagicShare()
                                self?.dismissPublishSubject.onNext(Void())
                            }
                        }
                    }
                    if meeting.shareData.isOthersSharingContent {
                        ShareContentViewController.showShareChangeAlert { result in
                            switch result {
                            case .success:
                                executeBlock()
                            case .failure:
                                break
                            }
                        }
                    } else {
                        executeBlock()
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    private func updateMeetingRelatedDocuments() {
        meeting.httpClient.getResponse(QueryMeetingRelatedDocsRequest(meetingId: meeting.meetingId)) { [weak self] getQueryResult in
            guard let self = self else { return }
            switch getQueryResult {
            case .success(let getQueryRsp):
                Logger.shareContent.info("query meeting related docs, count: \(getQueryRsp.meetingRelatedDocs.count)")
                let docs = getQueryRsp.meetingRelatedDocs
                let ids = docs.map { $0.ownerId }
                self.meeting.httpClient.getResponse(GetChattersRequest(chatterIds: ids)) { getChattersResult in
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
        var isSharing = false
        if let currentMSDocument = meeting.shareData.shareContentScene.magicShareDocument, currentMSDocument.hasEqualContentTo(document) {
            isSharing = true
        }
        return SearchDocumentResultCellModel(document, isSharing: isSharing, rank: 0, isFileMeetingRelated: true)
    }
}

extension VcDocs {
    var typeIcon: UIImage? {
        return getTypeIcon()
    }

    func getFileSubTypeIcon(subType: VcDocSubType) -> UIImage? {
        switch subType {
        case .photo:
            return UDIcon.getIconByKeyNoLimitSize(.fileImageColorful)
        case .pdf:
            return UDIcon.getIconByKeyNoLimitSize(.filePdfColorful)
        case .txt:
            return UDIcon.getIconByKeyNoLimitSize(.fileTextColorful)
        case .word:
            return UDIcon.getIconByKeyNoLimitSize(.fileWordColorful)
        case .excel:
            return UDIcon.getIconByKeyNoLimitSize(.fileExcelColorful)
        case .ppt:
            return UDIcon.getIconByKeyNoLimitSize(.filePptColorful)
        case .video:
            return UDIcon.getIconByKeyNoLimitSize(.fileVideoColorful)
        case .audio:
            return UDIcon.getIconByKeyNoLimitSize(.fileAudioColorful)
        case .zip:
            return UDIcon.getIconByKeyNoLimitSize(.fileZipColorful)
        case .psd:
            return UDIcon.getIconByKeyNoLimitSize(.filePsColorful)
        case .apk:
            return UDIcon.getIconByKeyNoLimitSize(.fileAndroidColorful)
        case .sketch:
            return UDIcon.getIconByKeyNoLimitSize(.fileSketchColorful)
        case .ae:
            return UDIcon.getIconByKeyNoLimitSize(.fileAeColorful)
        case .keynote:
            return UDIcon.getIconByKeyNoLimitSize(.fileKeynoteColorful)
        default:
            return UDIcon.getIconByKeyNoLimitSize(.fileUnknowColorful)
        }
    }

    private func getTypeIcon() -> UIImage? {
        switch self.docType {
        case .doc:
            return UDIcon.getIconByKeyNoLimitSize(.fileDocColorful)
        case .sheet:
            return UDIcon.getIconByKeyNoLimitSize(.fileSheetColorful)
        case .bitable:
            return UDIcon.getIconByKeyNoLimitSize(.fileBitableColorful)
        case .mindnote:
            return UDIcon.getIconByKeyNoLimitSize(.fileMindnoteColorful)
        case .file:
            return getFileSubTypeIcon(subType: docSubType)
        case .slide:
            return UDIcon.getIconByKeyNoLimitSize(.fileSlideColorful)
        case .folder:
            return UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        case .link:
            return UDIcon.getIconByKeyNoLimitSize(.fileLinkColorful)
        case .wiki:
            return UDIcon.getIconByKeyNoLimitSize(.fileDocColorful)
        case .docx:
            return UDIcon.getIconByKeyNoLimitSize(.fileDocxColorful)
        default:
            return UDIcon.getIconByKeyNoLimitSize(.fileUnknowColorful)
        }
    }
}

extension SearchShareDocumentsViewModel: InMeetDataListener {

    func isShareContentControlLegal() -> Bool {
        if !canShareContentRelay.value {
            // 如果无法保证有共享内容权限，toast提示并中止操作
            InMeetFollowViewModel.logger.debug("share content is denied due to lack of permission")
            handleShareContentControlForbiddenPublisher.onNext(.canShareContent)
            return false
        } else if meeting.shareData.isSharingContent && !meeting.shareData.isSelfSharingContent && !canReplaceShareContentRelay.value {
            // 如果此时已经在共享中，并且违背抢共享原则，toast提示并中止操作
            InMeetFollowViewModel.logger.debug("replace share content is denied due to meeting permission")
            handleShareContentControlForbiddenPublisher.onNext(.canReplaceShareContent)
            return false
        }
        return true
    }
}

extension SearchShareDocumentsViewModel: InMeetShareDataListener {

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        self.magicShareDocumentUrl = newScene.magicShareData?.urlString ?? ""
    }

}
