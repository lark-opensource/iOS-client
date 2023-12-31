//
//  PreviewParticipantsViewModel.swift
//  ByteView
//
//  Created by yangyao on 2020/11/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting

/// 列表上拉加载更多的状态
enum ListLoadMoreState: Int {
    /// 未知状态
    case none
    /// 还有更多（未触发）
    case hasMore
    /// 触发加载（已触发）
    case loading
    /// 没有更多（没有更多了）
    case noMore
    /// 错误
    case error
}

final class PreviewParticipantWrapper {
    let participant: PreviewParticipant
    let isInterview: Bool
    let isExternal: Bool
    var isPopover: Bool = false

    private let relationType: VCRelationTag.User.TypeEnum
    private(set) var relationTag: VCRelationTag?
    private let httpClient: HttpClient
    private let account: AccountInfo
    private let isRelationTagEnabled: Bool

    init(participant: PreviewParticipant, account: AccountInfo, isInterview: Bool, isRelationTagEnabled: Bool, httpClient: HttpClient) {
        self.participant = participant
        self.httpClient = httpClient
        self.isExternal = PreviewParticipantsViewModel.isExternalParticipant(participant, accountInfo: account)
        self.isInterview = isInterview
        self.isRelationTagEnabled = isRelationTagEnabled
        self.account = account
        var relationType: VCRelationTag.User.TypeEnum
        switch participant.participantType {
        case .larkUser:
            relationType = .larkUser
        case .room:
            relationType = .room
        default:
            relationType = .unknown
        }
        self.relationType = relationType
    }

    func getRelationTag(_ completion: @escaping ((String?) -> Void)) {
        guard isExternal, isRelationTagEnabled else {
            completion(nil)
            return
        }

        if let relationText = relationTag?.relationText {
            completion(relationText)
            return
        }

        let relationUid = participant.userId
        let user = VCRelationTag.User(type: relationType, id: relationUid)
        httpClient.participantRelationTagService.relationTagsByUsers([user], useCache: false) { tags in
            let relationTag = tags.first
            guard relationTag?.userID == relationUid else {
                completion(nil)
                return
            }
            completion(relationTag?.relationText)
        }
    }
}

class PreviewParticipantsViewModel {
    static let logger = Logger.ui
    var numberHints: Driver<String> {
        return participantsRelay
            .map({ [weak self] (participants: [PreviewParticipantWrapper]) -> Int in
                guard let self = self else {
                    return 0
                }
                if self.totalParticipantNum > 0 {
                    return self.totalParticipantNum
                } else {
                    return participants.count
                }
            })
            .map { [weak self] (count) -> String in
                let isWebinar = self?.isWebinar ?? false
                if isWebinar {
                    return I18n.View_G_PanelistTab(number: count)
                } else {
                    return String(format: I18n.View_M_ParticipantsPercentDee, count)
                }
            }
            .distinctUntilChanged()
            .asDriver(onErrorRecover: { _ in return .empty() })
    }
    let participantsRelay: BehaviorRelay<[PreviewParticipantWrapper]>
    let rxLoadMoreState = BehaviorRelay<ListLoadMoreState>(value: .none)
    var participantsCount: Int {
        return participantsRelay.value.count
    }
    let isPopover: Bool
    var didSelectCellCallback: ((PreviewParticipant, UIViewController) -> Void)?
    var alreadyHasSponsor = false
    private let meetingID: String?
    private let totalParticipantNum: Int
    private var nextRequestToken: String?
    private let disposeBag = DisposeBag()
    private let chatID: String?
    private var httpClient: HttpClient
    private let account: AccountInfo
    private let larkRouter: LarkRouter // = LarkRouter(dependency: dependency.router)
    private let isInterview: Bool
    private let isWebinar: Bool
    let isRelationTagEnabled: Bool

    convenience init(params: PreviewParticipantParams, service: MeetingBasicService) {
        let setting = service.setting
        self.init(params: params, account: service.accountInfo, httpClient: service.httpClient, larkRouter: service.larkRouter,
                  isRelationTagEnabled: setting.isRelationTagEnabled)
    }

    convenience init(params: PreviewParticipantParams, dependency: MeetingDependency) {
        let setting = dependency.setting
        self.init(params: params, account: dependency.account, httpClient: dependency.httpClient, larkRouter: LarkRouter(dependency: dependency.router), isRelationTagEnabled: setting.isRelationTagEnabled)
    }

    init(params: PreviewParticipantParams, account: AccountInfo, httpClient: HttpClient, larkRouter: LarkRouter,
         isRelationTagEnabled: Bool) {
        self.account = account
        self.httpClient = httpClient
        self.larkRouter = larkRouter
        let wrappers = params.participants.map { participant in
            PreviewParticipantWrapper(participant: participant, account: account, isInterview: params.isInterview, isRelationTagEnabled: isRelationTagEnabled, httpClient: httpClient)
        }
        self.participantsRelay = BehaviorRelay<[PreviewParticipantWrapper]>(value: wrappers)
        self.isPopover = params.isPopover
        self.didSelectCellCallback = params.selectCellAction
        self.meetingID = params.meetingId
        self.alreadyHasSponsor = params.participants.contains(where: { $0.isSponsor })
        self.totalParticipantNum = params.totalCount
        self.chatID = params.chatId
        self.isInterview = params.isInterview
        self.isWebinar = params.isWebinar
        self.isRelationTagEnabled = isRelationTagEnabled
        if totalParticipantNum > params.participants.count, chatID?.isEmpty == false {
            refresh()
        }
    }

    var isExternalParticipant: Bool?
    func refresh() {
        guard rxLoadMoreState.value != .loading else {
            return
        }
        getFirstPagePreviewdParticipants()
            .asObservable()
            .bind(to: participantsRelay)
            .disposed(by: disposeBag)
    }

    func loadMore() {
        guard rxLoadMoreState.value != .loading else {
            return
        }
        guard let nextRequestToken = nextRequestToken else {
            refresh()
            return
        }
        getNextPreviewdParticipants(nextRequestToken: nextRequestToken)
            .asObservable()
            .withLatestFrom(participantsRelay, resultSelector: { ($0, $1) })
            .map { $1 + $0 }
            .bind(to: participantsRelay)
            .disposed(by: disposeBag)
    }

    private func getPreviewParticipants(nextToken: String?) -> Single<[PreviewParticipantWrapper]> {
        guard let meetingID = self.meetingID else { return .error(VCError.unknown) }
        self.rxLoadMoreState.accept(.loading)
        let isFirst = nextToken == nil
        return requestCardParticipants(meetingID: meetingID, nextRequestToken: nextToken)
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] (result: CardInfoResult) -> Single<[PreviewParticipantWrapper]> in
                guard let self = self else { return .just([]) }
                self.rxLoadMoreState.accept(result.hasMore ? .hasMore : .noMore)
                self.nextRequestToken = result.nextRequestToken
                if isFirst { self.alreadyHasSponsor = false }
                return self.createPreviewedParticipants(with: result.meetingCard.participants, sponsorID: result.meetingCard.sponsorID)
            }
            .do(onError: { [weak self] error in
                guard let self = self else { return }
                self.rxLoadMoreState.accept(.error)
                Self.logger.error(error.localizedDescription)
            })
    }

    private func getFirstPagePreviewdParticipants() -> Single<[PreviewParticipantWrapper]> {
        self.getPreviewParticipants(nextToken: nil)
    }

    private func getNextPreviewdParticipants(nextRequestToken: String) -> Single<[PreviewParticipantWrapper]> {
        self.getPreviewParticipants(nextToken: nextRequestToken)
    }

    typealias PullCardMeetingParticipant = PullCardInfoResponse.MeetingParticipant
    private typealias PullCardMeetingCard = PullCardInfoResponse.MeetingCard
    private typealias CardInfoResult = (meetingCard: PullCardMeetingCard, hasMore: Bool, nextRequestToken: String?)
    private func requestCardParticipants(meetingID: String, nextRequestToken: String? = nil) -> Single<CardInfoResult> {
        Self.logger.info("start PullVCCardInfoRequest with meetingID:\(meetingID) nextRequestToken:\(nextRequestToken), chatID:\(chatID)")
        let chatId = self.chatID
        let httpClient = self.httpClient
        return RxTransform.single {
            let request = PullCardInfoRequest(meetingId: meetingID, chatId: chatId, nextRequestToken: nextRequestToken)
            httpClient.getResponse(request, completion: $0)
        }.map { ($0.videoChatContent.meetingCard, $0.isMore, $0.nextRequestToken) }
        .do(onSuccess: {
            Self.logger.debug("get PullVCCardInfoResponse sussess with hasMore: \($0.hasMore), nextRequestToken:\($0.nextRequestToken)")
        }, onError: {
            Self.logger.error("get PullVCCardInfoResponse error: \($0)")
        })
    }

    func createPreviewedParticipants(with participants: [PullCardMeetingParticipant], sponsorID: String) -> Single<[PreviewParticipantWrapper]> {
        guard !participants.isEmpty else {
            return .just([])
        }
        let ids = participants.map({ $0.userID })
        let duplicatedParticipantIds = Set(ids.reduce(into: [String: Int]()) { $0[$1] = ($0[$1] ?? 0) + 1 }
                                            .filter { $0.1 > 1 }.map { $0.key })
        return Single<[PreviewParticipantWrapper]>.create { [weak self] (ob) -> Disposable in
            guard let self = self,
                  let meetingID = self.meetingID else {
                ob(.error(VCError.unknown))
                return Disposables.create()
            }
            self.httpClient.participantService.participantInfo(pids: participants, meetingId: meetingID) { [weak self] aps in
                guard let self = self else {
                    ob(.success([]))
                    return
                }
                var previewParticipants: [PreviewParticipantWrapper] = []
                zip(participants, aps).forEach { (participant, ap) in
                    let showDevice = duplicatedParticipantIds.contains(participant.userID)
                        && (participant.deviceType == .mobile || participant.deviceType == .web)
                    let isSponsor: Bool
                    if self.alreadyHasSponsor {
                        isSponsor = false
                    } else {
                        isSponsor = sponsorID == participant.userID
                        self.alreadyHasSponsor = isSponsor
                    }
                    let previewedParticipant = PreviewParticipant(userId: participant.userID,
                                                                  userName: ap.name,
                                                                  avatarInfo: ap.avatarInfo,
                                                                  participantType: participant.userType,
                                                                  isLarkGuest: participant.isLarkGuest,
                                                                  isSponsor: isSponsor,
                                                                  deviceType: participant.deviceType,
                                                                  showDevice: showDevice,
                                                                  tenantId: participant.tenantID,
                                                                  tenantTag: participant.tenantTag,
                                                                  bindId: participant.bindID,
                                                                  bindType: participant.bindType,
                                                                  showCallme: participant.usedCallMe)
                    let wrapper = PreviewParticipantWrapper(participant: previewedParticipant, account: self.account, isInterview: self.isInterview, isRelationTagEnabled: self.isRelationTagEnabled, httpClient: self.httpClient)
                    previewParticipants.append(wrapper)
                }
                ob(.success(previewParticipants))
            }
            return Disposables.create()
        }
    }

    func gotoUserProfile(_ userId: String, from: UIViewController) {
        larkRouter.gotoUserProfile(userId: userId, meetingTopic: "", sponsorName: "", sponsorId: "", meetingId: meetingID ?? "", from: from)
    }

    static func isExternalParticipant(_ participant: PreviewParticipant, accountInfo: AccountInfo?) -> Bool {
        guard let localParticipant = accountInfo else {
            return false
        }
        if participant.userId == localParticipant.userId { // 自己
            return false
        }
        if localParticipant.tenantTag != .standard { // 自己是小 B 用户，则不关注 external
            return false
        }
        if participant.isLarkGuest {
            return false
        }
        // 当前用户租户 ID 未知
        if participant.tenantId == "" || participant.tenantId == "-1" {
            return false
        }
        let participantType = participant.participantType
        if participantType == .larkUser || participantType == .room || participantType == .neoUser || participantType == .neoGuestUser || participantType == .standaloneVcUser || (participantType == .pstnUser && participant.bindType == .lark) {
            return participant.tenantId != localParticipant.tenantId
        } else {
            return false
        }
    }
}
