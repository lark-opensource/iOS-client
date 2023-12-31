//
//  MeetingDetailViewModel.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/1/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewNetwork

struct MeetingDetailViewContext {
    var meetingTime: String?
}

class MeetingDetailViewModel {

    static let logger = Logger.meetingDetail

    enum Source {
        case unknown
        case call
        case bot
        case collection
    }

    @RwAtomic var viewContext = MeetingDetailViewContext()

    // === Data Notifier ===
    let joinStatus = MeetingDetailJoinStatusNotifier()
    let commonInfo = MeetingDetailCommonInfoNotifier()
    let appLinkInfo = MeetingDetailAppLinkInfoNotifier()
    let audienceInfo = MeetingDetailAudienceInfoNotifier()
    let statisticsInfo = MeetingDetailStatisticsInfoNotifier()
    let chatHistory = MeetingDetailChatHistoryNotifier()
    let notesInfo = MeetingDetailNotesInfoNotifier()
    let recordInfo = MeetingDetailRecordInfoNotifier()
    let historyInfos = MeetingDetailHistoryInfoNotifier()
    let checkinInfo = MeetingDetailCheckinInfoNotifier()
    let voteStatisticsInfo = MeetingDetailVoteStatisticsInfoNotifier()
    let collections = MeetingDetailCollectionInfoNotifier()
    let participantAbbrInfos = MeetingDetailParticipantAbbrInfoNotifier()
    let followInfos = MeetingDetailFollowInfoNotifier()

    // === Base Data ===
    var historyInfo: HistoryInfo? { historyInfos.value?.last }

    @RwAtomic private(set) var meetingURL: String?
    @RwAtomic private(set) var calendarEventRule: String?
    @RwAtomic private(set) var accessInfos: TabAccessInfos?
    @RwAtomic private(set) var bitableInfo: BitableInfo?

    @RwAtomic private(set) var meetingBaseInfo: TabMeetingBaseInfo?
    @RwAtomic private(set) var userSpecInfo: TabMeetingUserSpecInfo?

    @RwAtomic private var itemSpecVersion: Int32 = .min {
        didSet {
            Self.logger.debug("version changed to: \(self)")
        }
    }

    private(set) lazy var participantsPopover = ParticipantsPopover(viewModel: tabViewModel)

    // === Input ===
    let tabViewModel: MeetTabViewModel
    private(set) var tabListItem: TabListItem?
    let source: Source

    /// 注意！！！
    /// queryID 根据 source 不同代表的意义也不同
    let queryID: String

    // 拉取详情数据后二次赋值
    @RwAtomic private(set) var meetingID: String?
    @RwAtomic private(set) var meetingNumber: String?

    weak var hostViewController: UIViewController?

    var userId: String { tabViewModel.userId }
    var httpClient: HttpClient { tabViewModel.httpClient }
    var router: TabRouteDependency? { tabViewModel.router }
    var account: AccountInfo { tabViewModel.account }
//    var meetingService: MeetingService? { tabViewModel.meetingService }
    var globalDependency: TabGlobalDependency { tabViewModel.dependency.global }

    init(tabViewModel: MeetTabViewModel,
         queryID: String,
         tabListItem: TabListItem?,
         source: Source = .unknown) {
        self.tabViewModel = tabViewModel
        self.tabListItem = tabListItem
        self.source = source
        self.queryID = queryID
        self.meetingID = tabListItem?.meetingID
        self.meetingNumber = tabListItem?.meetingNumber

        tabViewModel.addObserver(self)
        TabPush.meetingJoinStatus.inUser(tabViewModel.userId).addObserver(self) { [weak self] in
            self?.didReceiveJoinInfo($0)
        }
    }

    func fetchData(completion: @escaping (Result<Void, Error>) -> Void) {
        fetchMeetingDetailInfo(completion: completion)
        fetchJoinInfo()
    }

    func fetchMeetingDetailInfo(completion: @escaping (Result<Void, Error>) -> Void) {
        let request = GetTabMeetingDetailRequest(historyId: queryID, queryType: source.queryType, source: source.pbType)
        self.httpClient.getResponse(request) { [weak self] result in
            switch result {
            case .success(let info):
                self?.handleDetailInfoFetch(info)
                self?.didReceiveMeetingDetailInfo(info)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchJoinInfo() {
        self.httpClient.getResponse(GetMeetingJoinStatusRequest()) { [weak self] result in
            switch result {
            case .success(let info):
                self?.didReceiveJoinInfo(info)
            case .failure:
                break
            }
        }
    }

    func handleDetailInfoFetch(_ info: GetTabMeetingDetailResponse) {
        if source == .call {
            TabService.shared.scrollToHistoryID.onNext(info.historyID)
        }

        guard let detailInfo = info.infos.first else { return }

        let downVersion = detailInfo.meetingBaseInfo.downVersion
        if tabListItem?.subscribeDetailChange == true {
            tabViewModel.openGrootChannel(type: .vcTabMeetingChannel, channelID: detailInfo.meetingID, downVersion: downVersion)
        }
        tabViewModel.openGrootChannel(type: .vcTabUserChannel, channelID: nil, downVersion: downVersion)

        let meetingInfo = detailInfo.meetingBaseInfo.meetingInfo
        MeetTabTracks.trackEnterMeetingDetail(isOngoing: meetingInfo.meetingStatus == .meetingOnTheCall,
                                              isCall: meetingInfo.meetingType == .call,
                                              meetingID: meetingID,
                                              ifCallkit: source == .call)
    }

    func applyMinutesCollectionPermission() {
        guard let meetingID = self.meetingID, let intID = Int64(meetingID) else { return }
        let request = ApplyMinutesCollectionPermRequest(meetingID: intID)
        httpClient.send(request) { res in
            if case let .failure(error) = res {
                Self.logger.error("\(error)")
            }
        }
    }

    var isJoined: Bool {
        guard let currentModule = tabViewModel.currentMeeting else { return false }
        return currentModule.isOnTheCall && currentModule.id == self.meetingID
    }

    var isInLobby: Bool {
        guard let currentModule = tabViewModel.currentMeeting else { return false }
        return currentModule.isInLobby && currentModule.id == self.meetingID
    }

    func getJoinedDeviceNames(callback: @escaping (([String]) -> Void)) {
        if isJoined || isInLobby {
            callback([])
            return
        }
        httpClient.getResponse(GetJoinedDeviceInfoRequest(), completion: { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let response):
                let devices = response.devices
                    .filter { $0.meetingID == self.meetingID }
                    .sorted(by: { $0.joinTime < $1.joinTime })
                    .map { $0.defaultDeviceName }
                callback(devices)
                Self.logger.info("getJoinedDevices success, total:\(response.devices.count), currentMeeting:\(devices.count)")
            case .failure:
                callback([])
            }
        })
    }
}

extension MeetingDetailViewModel {

    func didReceiveMeetingDetailInfo(_ info: GetTabMeetingDetailResponse) {
        self.meetingNumber = info.meetingNumber
        self.meetingURL = info.meetingURL
        self.calendarEventRule = info.calendarEventRule
        self.accessInfos = info.accessInfos

        guard let detailInfo = info.infos.first else { return }
        self.meetingID = detailInfo.meetingID
        self.meetingBaseInfo = detailInfo.meetingBaseInfo
        self.userSpecInfo = detailInfo.userSpecInfo

        self.commonInfo.send(data: detailInfo.meetingBaseInfo.meetingInfo)
        self.audienceInfo.send(data: AudienceInfo(audienceNum: detailInfo.meetingBaseInfo.audienceNum))
        self.followInfos.send(data: detailInfo.userSpecInfo.followInfo)
        self.participantAbbrInfos.send(data: detailInfo.meetingBaseInfo.participants)
        self.collections.send(data: detailInfo.userSpecInfo.collection.filter { collection in
            // 智能聚合 FG 关闭时不显示
            if collection.collectionType == .ai {
                return self.tabViewModel.fg.isSmartFolderEnabled
            } else {
                return true
            }
        })
        if let recordInfo = detailInfo.userSpecInfo.recordInfo {
            self.recordInfo.send(data: recordInfo)
        }
        if let notesInfo = detailInfo.userSpecInfo.notesInfo {
            self.notesInfo.send(data: notesInfo)
        }
        if let appLinkInfo = detailInfo.userSpecInfo.sourceApplink {
            self.appLinkInfo.send(data: appLinkInfo)
        }
        if let statisticsInfo = detailInfo.userSpecInfo.statisticsInfo {
            self.statisticsInfo.send(data: statisticsInfo)
        }
        if let chatHistory = detailInfo.userSpecInfo.chatHistoryV2 {
            self.chatHistory.send(data: chatHistory)
        }
        if let checkinInfo = detailInfo.userSpecInfo.checkinInfo {
            self.checkinInfo.send(data: checkinInfo)
        }
        if let voteStatisticsInfo = detailInfo.userSpecInfo.voteStatisticsInfo {
            self.voteStatisticsInfo.send(data: voteStatisticsInfo)
        }
        if detailInfo.userSpecInfo.version > itemSpecVersion {
            itemSpecVersion = detailInfo.userSpecInfo.version
            self.historyInfos.send(data: info.infos.flatMap { $0.userSpecInfo.historyInfo }.compactMap { $0 })
        }
    }

    func didReceiveJoinInfo(_ info: GetMeetingJoinStatusResponse) {
        let joinStatus = info.meetingJoinInfos.meetingID == meetingID ? info.meetingJoinInfos.joinStatus : .joinable
        self.joinStatus.send(data: joinStatus)
    }
}

extension MeetingDetailViewModel {
    var isPhoneCall: Bool {
        tabListItem?.phoneType == .outsideEnterprisePhone || tabListItem?.phoneType == .insideEnterprisePhone || isPstnIpPhone || historyInfo?.interacterUserType == .pstnUser
    }

    var isPstnIpPhone: Bool {
        tabListItem?.phoneType == .ipPhone && tabListItem?.historyAbbrInfo.interacterUserType == .pstnUser
    }

    /// 是否是 call 类型（pstn、办公电话）
    var isCall: Bool {
        commonInfo.value?.meetingType == .call || isPhoneCall || isPstnIpPhone
    }

    /// 1v1 会中详情需要显示时间信息, 1v1通话接通需要显示时间（办公电话无会议Number）
    var isValid1v1Call: Bool {
        guard let commonInfo = commonInfo.value, let historyInfo = historyInfos.value?.last else { return false }
        return (.call == commonInfo.meetingType && commonInfo.meetingStatus == .meetingOnTheCall) || (commonInfo.meetingType == .call && commonInfo.meetingStatus == .meetingEnd && historyInfo.callStatus == .callAccepted)
    }

    var isMeetingEnd: Bool {
        commonInfo.value?.meetingStatus == .meetingEnd
    }

    var isMeetingOngoing: Bool {
        commonInfo.value?.meetingStatus == .meetingOnTheCall
    }

    /// webinar 会议
    var isWebinarMeeting: Bool {
        commonInfo.value?.meetingSubType == .webinar
    }

    /// webinar 观众
    var isWebinarAudience: Bool {
        isWebinarMeeting && userSpecInfo?.isWebinarAudience == true
    }

    /// webinar 组织者
    var isWebinarSpeaker: Bool {
        isWebinarMeeting && !isWebinarAudience
    }
}

extension MeetingDetailViewModel: TabDataObserver {
    func didChangeNetStatus(status: MeetTabViewModel.NetworkStatus) {

    }

    func didReceiveUserGrootCell(cells: [TabUserGrootCell]) {
        let cells = cells.filter { checkValid(cell: $0) }
        for cell in cells {
            switch cell.changeType {
            case .checkinInfo:
                guard let checkinInfo = cell.checkinInfo else { continue }
                self.checkinInfo.send(data: checkinInfo)
            case .statistics:
                guard let statisticsInfo = cell.statisticsInfo else { continue }
                self.statisticsInfo.send(data: statisticsInfo)
            case .chatHistoryV2:
                guard let chatHistory = cell.chatHistoryV2 else { continue }
                self.chatHistory.send(data: chatHistory)
            case .vote:
                guard let voteStatisticsInfo = cell.voteStatisticsInfo else { continue }
                self.voteStatisticsInfo.send(data: voteStatisticsInfo)
            case .detailPage:
                guard let event = cell.detailPageEvents.first else { continue }
                self.followInfos.send(data: event.followInfo)
                if let recordInfo = event.recordInfo {
                    self.recordInfo.send(data: recordInfo)
                }
                var historyInfos = self.historyInfos.value
                if event.replaceAllHistory.isEmpty {
                    if let historyInfo = event.historyInfo {
                        historyInfos?.append(historyInfo)
                    }
                } else {
                    historyInfos = event.replaceAllHistory
                }
                if let historyInfos = historyInfos {
                    self.historyInfos.send(data: historyInfos)
                }
            default:
                continue
            }
        }
    }

    func didReceiveMeetingGrootCell(meetingID: String, cells: [TabMeetingGrootCell]) {
        guard meetingID == self.meetingID else { return }
        for cell in cells {
            for change in cell.changes {
                switch change.changeType {
                case .participant:
                    self.participantAbbrInfos.send(data: change.participantChanges)
                case .meeting:
                    guard let commonInfo = change.meetingInfo else { continue }
                    self.commonInfo.send(data: commonInfo)
                case .audience:
                    guard let audienceInfo = change.audienceInfo else { continue }
                    self.audienceInfo.send(data: audienceInfo)
                }
            }
        }
    }

    func didGetMeetingJoinInfo(_ joinInfo: MeetingJoinInfo, userId: String) {
        // 只更新当前会议状态
        guard userId == self.userId, joinInfo.meetingID == meetingID else { return }
        self.joinStatus.send(data: joinInfo.joinStatus)
    }

    private func checkValid(cell: TabUserGrootCell) -> Bool {
        guard let meetingID = meetingID else { return false }
        if cell.changeType == .checkinInfo && cell.checkinInfo?.meetingId == meetingID { return true }
        if cell.isActiveVersionEnabled(with: meetingID) && cell.activeVersion > itemSpecVersion {
            itemSpecVersion = cell.activeVersion
            return true
        }
        return false
    }
}

extension TabUserGrootCell {
    var activeVersion: Int32 {
        switch changeType {
        case .detailPage:
            return self.detailPageEvents.first?.version ?? 0
        case .statistics:
            return self.statisticsInfo?.version ?? 0
        case .missedCall:
            return -1
        case .chatHistoryV2:
            return self.chatHistoryV2?.version ?? 0
        case .vote:
            return self.voteStatisticsInfo?.version ?? 0
        case .chatHistory:
            return -1
        case .checkinInfo:
            return -1
        }
    }

    func isActiveVersionEnabled(with meetingId: String) -> Bool {
        switch changeType {
        case .detailPage:
            return detailPageEvents.first?.meetingID == meetingId
        case .statistics:
            return statisticsInfo?.meetingID == meetingId
        case .missedCall:
            return false
        case .chatHistoryV2:
            return chatHistoryV2?.meetingID == meetingId
        case .vote:
            return voteStatisticsInfo?.meetingID == meetingId
        case .chatHistory:
            return false
        case .checkinInfo:
            return false
        }
    }
}

extension MeetingDetailViewModel.Source {
    var pbType: GetTabMeetingDetailRequest.Source {
        switch self {
        case .collection:
            return .fromCollection
        case .bot:
            return .fromBot
        default:
            return .unknown
        }
    }

    var queryType: GetTabMeetingDetailRequest.QueryType {
        switch self {
        case .call, .collection, .bot:
            return .meetingID
        default:
            return .historyID
        }
    }
}

extension MeetingDetailFile {
    convenience init(followModel: FollowAbbrInfo, viewModel: MeetingDetailViewModel) {
        self.init(followModel: followModel, meetingID: viewModel.meetingID ?? "", participantService: viewModel.httpClient.participantService, docsIconDependency: viewModel.tabViewModel.dependency.docsIconDependency)
    }

    convenience init(statisticsInfo: TabStatisticsInfo, viewModel: MeetingDetailViewModel) {
        self.init(statisticsInfo: statisticsInfo, docsIconDependency: viewModel.tabViewModel.dependency.docsIconDependency)
    }

    convenience init(voteStatisticsInfo: TabVoteStatisticsInfo, viewModel: MeetingDetailViewModel) {
        self.init(voteStatisticsInfo: voteStatisticsInfo, meetingID: viewModel.meetingID ?? "", participantService: viewModel.httpClient.participantService, docsIconDependency: viewModel.tabViewModel.dependency.docsIconDependency)
    }

    convenience init(info: TabDetailRecordInfo.MinutesInfo, icon: UIImage?, viewModel: MeetingDetailViewModel, breakoutMinutesCount: Int = 0) {
        self.init(info: info, icon: icon, meetingID: viewModel.meetingID ?? "", participantService: viewModel.httpClient.participantService, breakoutMinutesCount: breakoutMinutesCount)
    }

    convenience init(info: TabNotesInfo, viewModel: MeetingDetailViewModel) {
        self.init(info: info, meetingID: viewModel.meetingID ?? "", participantService: viewModel.httpClient.participantService, docsIconDependency: viewModel.tabViewModel.dependency.docsIconDependency)
    }

    convenience init(info: TabDetailRecordInfo.RecordInfo, icon: UIImage?, viewModel: MeetingDetailViewModel, breakoutMinutesCount: Int = 0) {
        self.init(info: info, icon: icon, meetingID: viewModel.meetingID ?? "", participantService: viewModel.httpClient.participantService, breakoutMinutesCount: breakoutMinutesCount)
    }

    convenience init(info: TabDetailChatHistoryV2, viewModel: MeetingDetailViewModel) {
        self.init(info: info, meetingID: viewModel.meetingID ?? "", participantService: viewModel.httpClient.participantService, docsIconDependency: viewModel.tabViewModel.dependency.docsIconDependency)
    }

    convenience init(info: TabDetailCheckinInfo, viewModel: MeetingDetailViewModel) {
        self.init(info: info, meetingID: viewModel.meetingID ?? "", participantService: viewModel.httpClient.participantService, docsIconDependency: viewModel.tabViewModel.dependency.docsIconDependency)
    }

    convenience init(info: BitableInfo, viewModel: MeetingDetailViewModel) {
        self.init(info: info, meetingID: viewModel.meetingID ?? "", participantService: viewModel.httpClient.participantService, docsIconDependency: viewModel.tabViewModel.dependency.docsIconDependency)
    }
}
