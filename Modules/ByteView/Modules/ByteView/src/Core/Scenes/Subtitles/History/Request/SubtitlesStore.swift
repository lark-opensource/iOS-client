//
//  SubtitlesStore.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/8/12.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewNetwork

class SubtitlesStore {

    static let logger = Logger.getLogger("Subtitles")

    private enum Configuration {
        static let count = 30
        static let bufferCount = 15
    }

    let meetingID: String
    let meeting: InMeetMeeting
    private let disposeBag = DisposeBag()
    private var isLoading = false
    weak var viewModel: SubtitlesViewModel?
    private var retryRequestSyncTimes = 5

    // 获取字幕数据的流
    private let stateRelay = BehaviorRelay<SubtitlesViewState>(value: .emptyData)
    var stateObservable: Observable<SubtitlesViewState> {
        return stateRelay.asObservable()
            .distinctUntilChanged()
    }
    var state: SubtitlesViewState {
        get {
            return stateRelay.value
        }
        set(newState) {
            stateRelay.accept(newState)
        }
    }

    //搜索相关
    var searchData: SubtitlesSearchModel?
    // 获取搜索命中数据的流，供vm监听
    private let searchDataSubject = PublishSubject<SubtitlesSearchModel>()
    var searchDataObservable: Observable<SubtitlesSearchModel> {
        return searchDataSubject.asObservable()
    }
    // 当处于搜索状态或者是筛选状态时，阻止push消息插入，并显示置底按钮
    private let searchPushArriveSubject = PublishSubject<Void>()
    var searchPushArriveObservable: Observable<Void> {
        return searchPushArriveSubject.asObservable()
    }

    // 搜索是否可用
    private let searchFilterEnableSubject = PublishSubject<Bool>()
    var searchFilterEnableObservable: Observable<Bool> {
        return searchFilterEnableSubject.asObservable()
            .distinctUntilChanged()
    }

    let asrStatusValue = BehaviorRelay<AsrSubtitleStatus>(value: .unknown)
    let subtitleViewModel: InMeetSubtitleViewModel

    var hasFirstCallSyncSubtitles = false

    var isPullSubtitleCompleted: Bool = false

    var reloadRows: Set<Int> = []
    @RwAtomic
    var reloadAllNum: Int = 0

    init(meeting: InMeetMeeting, subtitle: InMeetSubtitleViewModel) {
        self.subtitleViewModel = subtitle
        self.meetingID = meeting.meetingId
        self.meeting = meeting
        subtitle.addObserver(self)
        asrStatusValue.accept(subtitle.lastAsrSubtitleStatus)
    }

    // 主动拉取数据
    func fetchSubtitles(isForward: Bool, targetSeqID: Int?) -> Completable {
        return fetchSubtitlesData(isForward: isForward, forwardBufferCount: nil, backwardBufferCount: nil, targetSeqID: targetSeqID)
    }

    func fetchSubtitlesInSearchMode(isForward: Bool, targetSeqID: Int? = nil) -> Completable {
        let bufferCount = Configuration.bufferCount
        return fetchSubtitlesData(isForward: isForward, forwardBufferCount: bufferCount, backwardBufferCount: bufferCount, targetSeqID: targetSeqID, needJump: true)
    }

    // 通知rust拉取所有字幕数据
    func requestSyncSubtitles() {
        if !self.hasFirstCallSyncSubtitles {
            self.hasFirstCallSyncSubtitles = true
            SubtitlesStore.logger.info("Subtitle requestSyncSubtitles: startSync \(self.retryRequestSyncTimes)")
            //  调用SYNC_SUBTITLES
            let breakoutRoomId = self.meeting.data.breakoutRoomId
            let request = SyncSubtitlesRequest(meetingId: meetingID, breakoutRoomId: breakoutRoomId, forceSync: false)
            self.meeting.httpClient.getResponse(request) { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let response):
                    self.handleSyncResponse(response)
                case .failure(let error):
                    self.searchFilterEnableSubject.onNext(false)
                    if self.retryRequestSyncTimes > 0 {
                        SubtitlesStore.logger.error("Subtitle requestSyncSubtitles error: times = \(self.retryRequestSyncTimes) errorInfo: \(error)")
                        self.hasFirstCallSyncSubtitles = false
                        self.retryRequestSyncTimes -= 1
                        self.requestSyncSubtitles()
                    }
                }
            }
        }
    }

    // 拉取字幕数据
    func fetchSubtitlesData(isForward: Bool, forwardBufferCount: Int?, backwardBufferCount: Int?, targetSeqID: Int? = nil, needJump: Bool? = nil) -> Completable {
        SubtitlesStore.logger.info("fetchSubtitlesData(isForward:\(isForward)," +
            " forwardBufferCount:\(forwardBufferCount)," +
            " backwardBufferCount: \(backwardBufferCount)," +
            " targetSeqID:\(targetSeqID)," +
            " needJump:\(needJump))")
        let status = subtitleViewModel.phraseStatus
        return Completable.deferred({ [weak self] in
            guard let `self` = self, !self.state.isLoading, !self.isLoading else {
                SubtitlesStore.logger.warn("Skip pull subtitles")
                return .empty()
            }
            let oldState = self.state
            self.state.toLoading()
            self.isLoading = true
            let count = Configuration.count
            self.requestSyncSubtitles()
            let breakoutRoomId = self.meeting.data.breakoutRoomId
            let request = PullSubtitlesRequest(meetingId: self.meetingID, breakoutRoomId: breakoutRoomId, count: count, targetSegId: targetSeqID,
                                               forwardBufferCount: forwardBufferCount, backwardBufferCount: backwardBufferCount, isForward: isForward)
            let httpClient = self.meeting.httpClient
            return RxTransform.single {
                httpClient.getResponse(request, completion: $0)
            }.flatMap { [weak self] response -> Single<SubtitlesViewData> in
                guard let `self` = self else {
                    return .error(VCError.unknown)
                }
                response.subtitles.forEach {
                    SubtitlesStore.logger.info("Subtitle requestSubtitlesOfMeeting: type =  \($0.subtitleType)  event.type = \($0.event?.type)  segid: \($0.segID)")
                }
                SubtitlesStore.logger.info("requestSubtitlesOfMeeting: count =  \(response.subtitles.count)")
                let newSubtitles: [MeetingSubtitleData] = response.subtitles.compactMap({ [weak self] data in
                    guard let `self` = self else {
                        return nil
                    }
                    if self.meeting.data.isOpenBreakoutRoom == false {
                        return data
                    }
                    if BreakoutRoomUtil.isMainRoom(data.breakoutRoomId) && self.meeting.data.isMainBreakoutRoom {
                        return data
                    }
                    if data.breakoutRoomId == self.meeting.data.breakoutRoomId {
                        return data
                    }
                    SubtitlesStore.logger.info("requestSubtitlesOfMeeting: error \(data.breakoutRoomId)")
                    return nil
                })
                return Subtitle.makeSubtitles(from: newSubtitles, meeting: self.meeting)
                    .map({ [weak self] subtitles in
                        var data = self?.state.subtitlesViewData ?? SubtitlesViewData()
                        let subtitlesViewData: [SubtitleViewData] = subtitles.compactMap({
                            return SubtitleViewData(subtitle: $0, phraseStatus: status)
                        })
                        var newSubtitleViewDatas: [SubtitleViewData] = []
                        if isForward {
                            newSubtitleViewDatas = (subtitlesViewData + data.subtitleViewDatas).uniqued(by: { $0.segId })
                        } else {
                            newSubtitleViewDatas = (data.subtitleViewDatas + subtitlesViewData).uniqued(by: { $0.segId }, option: .keepLast)
                        }
                        data.update(subtitleViewDatas: newSubtitleViewDatas)
                        data.oldestSegID = Int(response.nextTargetSegID)
                        // 重新设置默认值
                        if targetSeqID == nil {
                            if isForward {
                                data.hasNewData = false
                            } else {
                                data.hasOlderData = false
                            }
                        }
                        if isForward {
                            SubtitlesStore.logger.info("Subtitle hasOlderData: \(response.hasMore)")
                            data.hasOlderData = response.hasMore
                            data.changeType = .olderInserted
                        } else {
                            SubtitlesStore.logger.info("Subtitle hasNewData: \(response.hasMore)")
                            data.hasNewData = response.hasMore
                            data.changeType = .newerInserted
                            if let s = self {
                                s.reloadAllNum += 1
                            }
                        }
                        if oldState == .emptyData {
                            data.changeType = .newerAppended(false)
                        }
                        if let theNeedJump = needJump {
                            data.needJump = theNeedJump
                        } else {
                            data.needJump = false
                        }
                        return data
                    })
            }
            .do(onSuccess: { [weak self] subtitlesData in
                self?.state.toLoaded(with: subtitlesData)
                self?.isLoading = false
                self?.isPullSubtitleCompleted = true
            }, onError: { [weak self] error in
                let vcerror = error.toVCError()
                self?.state.toError(with: vcerror)
                self?.isLoading = false
                SubtitlesStore.logger.error("Subtitle requestSubtitlesOfMeeting error = \(error)")
            }).asCompletable()
        })
    }

    // 获取搜索命中的match数组
    func fetchSearchMacthData(pattern: String) {
        let breakoutRoomId = self.meeting.data.breakoutRoomId
        let startSegId = self.searchData?.matches.last?.segId
        let request = SearchSubtitlesRequest(pattern: pattern, startSegId: startSegId, includeAnnotation: subtitleViewModel.phraseStatus == .on, breakoutRoomId: breakoutRoomId)
        meeting.httpClient.getResponse(request) { [weak self] r in
            guard let self = self else { return }
            switch r {
            case .success(let response):
                self.handleSearchResponse(pattern: pattern, response: response)
            case .failure(let error):
                self.searchDataSubject.onError(error.toVCError())
                SubtitlesStore.logger.error("Subtitle fetchSearchMacthData error: pattern = \(pattern) error = \(error)")
            }
        }
    }

    private func handleSyncResponse(_ response: SyncSubtitlesResponse) {
        if self.meeting.data.isOpenBreakoutRoom == false || (self.meeting.data.isMainBreakoutRoom && BreakoutRoomUtil.isMainRoom(response.breakoutRoomId)) || meeting.data.breakoutRoomId == response.breakoutRoomId {
            self.searchFilterEnableSubject.onNext(true)
            SubtitlesStore.logger.info("Subtitle requestSyncSubtitles success: endSync \(self.retryRequestSyncTimes)")
        } else {
            self.searchFilterEnableSubject.onError(VCError.unknown)
            SubtitlesStore.logger.info("Subtitle requestSyncSubtitles failed, breakoutroomid is not right")
        }
    }

    private func handleSearchResponse(pattern: String, response: SearchSubtitlesResponse) {
        if self.meeting.data.isOpenBreakoutRoom == false || (self.meeting.data.isMainBreakoutRoom && BreakoutRoomUtil.isMainRoom(response.breakoutRoomId)) || meeting.data.breakoutRoomId == response.breakoutRoomId {
            if response.matches.isEmpty {
                SubtitlesStore.logger.info("Subtitle fetchSearchMacthData pattern = \(pattern) response = 0")
            } else {
                SubtitlesStore.logger.info("Subtitle fetchSearchMacthData pattern = \(pattern) response = \(response)")
            }
            var data = self.searchData ?? SubtitlesSearchModel()
            data.matches = (data.matches + response.matches).uniqued(by: { $0.segId }, option: .keepLast)
            data.pattern = response.pattern
            data.hasMore = response.hasMore
            self.searchData = data
            SubtitlesStore.logger.info("Subtitle fetchSearchMacthData pattern = \(pattern) matches.count = \(data.matches.count)")
            self.searchDataSubject.onNext(data)
        } else {
            self.searchDataSubject.onError(VCError.unknown)
            SubtitlesStore.logger.error("Subtitle fetchSearchMacthData error, breakoutroomid is not right")
        }
    }
}

extension SubtitlesStore: InMeetSubtitleViewModelObserver {
    func didReceiveSubtitle(_ subtitle: Subtitle) {
        guard isPullSubtitleCompleted else { return }
        var data = self.state.subtitlesViewData ?? SubtitlesViewData()
        let subtitleViewData = SubtitleViewData(subtitle: subtitle, phraseStatus: subtitleViewModel.phraseStatus)
        let foundIndex = data.subtitleViewDatas
            .firstIndex { [subtitle] (item) -> Bool in
                return item.subtitle.groupID == subtitle.groupID
            }
        if let index = foundIndex { // 纠错替换
            if !subtitle.isNoise {
                data.subtitleViewDatas[index].update(with: subtitle)
                reloadRows.insert(index)
            }
        } else if !subtitle.isNoise {
            data.add(subtitleViewData: subtitleViewData)
            reloadAllNum += 1
            if data.oldestSegID == nil {
                data.oldestSegID = subtitle.segID
            }
        }
        SubtitlesStore.logger.info("Subtitle push: segID = \(subtitle.segID) type = \(subtitle.data.user.type) event.type = \(subtitle.data.event?.type)")
        data.changeType = .newerAppended(true)
        self.state.update(data)
    }

    func didUpdateAsrSubtitleStatus(_ status: AsrSubtitleStatus) {
        asrStatusValue.accept(status)
    }

    func phraseStatusDidChanged() {
        // 开关注释，需刷新所有数据
        state.subtitlesViewData?.subtitleViewDatas.forEach({ [weak self] data in
            data.phraseStatus = self?.subtitleViewModel.phraseStatus ?? .unknown
        })
        reloadAllNum += 1
    }
}

struct SubtitlesSearchModel {
    var matches: [SubtitleSearchMatch] = [] // 当前所有字幕
    var hasMore: Bool = false// 是否存在更多命中的id
    var pattern: String = ""// 搜索的词
}
