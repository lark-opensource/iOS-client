//
//  TranscriptViewModel.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/6/17.
//

import Foundation
import ByteViewNetwork
import ByteViewUI
import ByteViewTracker

class TranscriptData {
    static let expireSeconds = 30
    static let maxCount = 50
    static let minCount = 40

    var transcripts: [SubtitleViewData] = []
    var idSet: Set<Int> = []

    var isEmpty: Bool {
        transcripts.isEmpty
    }

    func appendTranscripts(_ tripts: [SubtitleViewData]) {
        var oldData = transcripts
        for data in tripts where !idSet.contains(data.segId) {
            idSet.insert(data.segId)
            add(subtitleViewData: data, to: &oldData)
        }
        transcripts = oldData
    }

    func insertTranscripts(_ tripts: [SubtitleViewData], at index: Int) {
        var oldData = transcripts
        let newData = tripts.filter { data in
            if idSet.contains(data.segId) { return false }
            idSet.insert(data.segId)
            return true
        }
        oldData.insert(contentsOf: newData, at: index)
        transcripts = mergeTranscripts(oldData)
    }

    func clearData() {
        transcripts = []
        idSet = []
    }

    func clipDataIfNeeded(completion: @escaping () -> Void) {
        let count = transcripts.count
        guard count > Self.maxCount else { return }
        let slice = transcripts[(count - Self.minCount)..<count]
        transcripts = Array(slice)
        let sids = slice.map { $0.segId }
        idSet = Set(sids)
        completion()
    }

    func add(subtitleViewData: SubtitleViewData, to transcripts: inout [SubtitleViewData]) {
        if transcripts.isEmpty {
            subtitleViewData.needMerge = false
            transcripts.append(subtitleViewData)
            return
        }
        let count = transcripts.count
        var index = count - 1
        while index > 0 {
            if transcripts[index].needMerge == false {
                break
            }
            index -= 1
        }
        let lastSeg = transcripts[index]
        if lastSeg.type == .translation
            && subtitleViewData.type == .translation
            && lastSeg.participantId == subtitleViewData.participantId
            && count - index <= 2
            && abs(subtitleViewData.subtitle.timestamp - lastSeg.subtitle.timestamp) < Self.expireSeconds * 1000 {
            subtitleViewData.needMerge = true
            transcripts.append(subtitleViewData)
        } else {
            subtitleViewData.needMerge = false
            transcripts.append(subtitleViewData)
        }
    }

    func mergeTranscripts(_ origin: [SubtitleViewData]) -> [SubtitleViewData] {
        var newList: [SubtitleViewData] = []
        if origin.isEmpty {
            return newList
        }

        var preSeg = origin[0]
        preSeg.needMerge = false
        newList.append(preSeg)

        var counter = 1

        for i in 1..<origin.count {
            let curSeg = origin[i]
            if preSeg.type == .translation
                && curSeg.type == .translation
                && preSeg.participantId == curSeg.participantId
                && abs(curSeg.subtitle.timestamp - preSeg.subtitle.timestamp) < Self.expireSeconds * 1000
            && counter < 3 {
                curSeg.needMerge = true
                counter += 1
            } else {
                curSeg.needMerge = false
                preSeg = curSeg
                counter = 1
            }
            newList.append(curSeg)
        }
        return newList
    }

    func highlightTranscripts(block: @escaping ([SubtitleViewData]) -> [SubtitleViewData]) {
        transcripts = block(transcripts)
    }

}

protocol TranscriptViewModelDelegate: AnyObject {
    func transcriptsDidUpdated()
    func transcriptsDataWillClear()
    func didReceivedNewTranscript()
    func searchEnabledDidChanged()
    func searchPrevButtonEnabledDidChanged()
    func searchNextButtonEnabledDidChanged()
    func selectedSearchResultDidChangeTo(row: Int)
    func filterModeDidChanged()
    func searchModeDidChanged()
    func transcribeStatusDidChanged(status: TranscriptInfo.TranscriptStatus)
    func pullRefreshVisibleDidChanged()
    func loadMoreVisibleDidChanged()
}

extension TranscriptViewModelDelegate {
    func transcriptsDidUpdated() {}
    func transcriptsDataWillClear() {}
    func didReceivedNewTranscript() {}
    func searchEnabledDidChanged() {}
    func searchPrevButtonEnabledDidChanged() {}
    func searchNextButtonEnabledDidChanged() {}
    func selectedSearchResultDidChangeTo(row: Int) {}
    func filterModeDidChanged() {}
    func searchModeDidChanged() {}
    func transcribeStatusDidChanged(status: TranscriptInfo.TranscriptStatus) {}
    func pullRefreshVisibleDidChanged() {}
    func loadMoreVisibleDidChanged() {}
}

class TranscriptViewModel {
    static let logger = Logger.getLogger("Transcript")
    static let transcriptCount: Int64 = 30
    static let pCount = 30

    private let inMeetViewModel: InMeetTranscribeViewModel


    var transcripts: [SubtitleViewData] {
        transcriptsData.transcripts
    }

    let transcriptsData = TranscriptData()


    let meeting: InMeetMeeting
    let listeners = Listeners<TranscriptViewModelDelegate>()

    @RwAtomic
    var isTranscribing: Bool = false
    @RwAtomic
    var transcriptStatus: TranscriptInfo.TranscriptStatus = .none

    /// 当前的筛选人（nil代表没有筛选）
    @RwAtomic
    private var filterPeople: ParticipantId?

    @RwAtomic
    private var isPullCompleted: Bool = false

    var shouldClearData: Bool = true {
        didSet {
            guard shouldClearData else { return }
            Util.runInMainThread {
                self.listeners.forEach { $0.transcriptsDataWillClear() }
            }
        }
    }

    @RwAtomic
    var isSearchEnabled: Bool = false {
        didSet {
            guard isSearchEnabled != oldValue else { return }
            DispatchQueue.main.async {
                self.listeners.forEach { $0.searchEnabledDidChanged() }
            }
        }
    }
    private(set) var isSearchMode: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.listeners.forEach { $0.searchModeDidChanged() }
            }
        }
    }
    var isPrevButtonEnabled: Bool = false {
        didSet {
            guard isPrevButtonEnabled != oldValue else { return }
            DispatchQueue.main.async {
                self.listeners.forEach { $0.searchPrevButtonEnabledDidChanged() }
            }
        }
    }
    var isNextButtonEnabled: Bool = false {
        didSet {
            guard isNextButtonEnabled != oldValue else { return }
            DispatchQueue.main.async {
                self.listeners.forEach { $0.searchNextButtonEnabledDidChanged() }
            }
        }
    }

    @RwAtomic
    var isFilterMode = false { // 筛选模式
        didSet {
            DispatchQueue.main.async {
                self.listeners.forEach { $0.filterModeDidChanged() }
            }
        }
    }
    //搜索后定位定到第一个检索结果的标识符
    var isFirstLocation: Bool = false
    // 在搜索和筛选状态时，如果来了新消息，显示置底按钮，当点击置底按钮时，不是跳转到底部而是重新请求数据
    var isOpenAutoScrollInSearchFilter = false
    // 在搜索和筛选状态时，来了新消息
    var isFetchNewDataInSearchFilter = false
    //搜索相关
    var searchData: SubtitlesSearchModel?
    var currentSelectedId: Int? //当前选中的segId
    var currentSelectedRange: NSRange? //当前选中的segId下的range
    private var currentTempSelectedId: Int? //当前选中的segId临时值
    private var currentSelectedTempRange: NSRange? //当前选中的segId下的range临时值

    var isAlignRight: Bool = false

    var isAllMuted: Bool  {
        let participantsCount = meeting.participant.activePanel.count
        if participantsCount > Self.pCount {
            return false
        }
        for participant in meeting.participant.activePanel.all {
            if !participant.settings.isMicrophoneMutedOrUnavailable {
                return false
            }
        }
        return true
    }

    lazy var filterViewModel: TranscriptFilterViewModel = {
        let viewModel = TranscriptFilterViewModel(meeting: meeting, state: .none) {_ in } clearBlock: { }
        return viewModel
    }()

    var hasBeforeData: Bool = false {
        didSet {
            guard hasBeforeData != oldValue else { return }
            listeners.forEach { $0.pullRefreshVisibleDidChanged() }
        }
    }
    var hasAfterData: Bool = false {
        didSet {
            guard hasAfterData != oldValue else { return }
            listeners.forEach { $0.loadMoreVisibleDidChanged() }
        }
    }

    var keepPosition: Bool = false


    init(meeting: InMeetMeeting, transcribeViewModel: InMeetTranscribeViewModel) {
        self.meeting = meeting
        self.inMeetViewModel = transcribeViewModel
        meeting.push.extraInfo.addObserver(self)
        meeting.addMyselfListener(self)
        meeting.data.addListener(self)
    }

    func addListener(_ listener: TranscriptViewModelDelegate) {
        listeners.addListener(listener)
    }

    func fetchLatestTranscritps(forceSync: Bool = false) {
        syncTranscripts(forceSync: forceSync)
        fetchTranscripts()
    }

    func fetchBeforeTranscritps() {
        let batchID = transcripts.first?.batchID
        fetchTranscripts(isForward: true, batchID: batchID)
        keepPosition = true
    }

    func fetchAfterTranscritps() {
        let batchID = transcripts.last?.batchID
        fetchTranscripts(isForward: false, batchID: batchID)
    }

    func syncTranscripts(forceSync: Bool = false, completion: (() -> Void)? = nil) {
        let request = SyncTranscriptRequest(meetingID: meeting.meetingId, forceSync: forceSync)
        meeting.httpClient.getResponse(request) { _ in
            completion?()
        }
    }

    func fetchTranscripts(isForward: Bool = true, batchID: Int64? = nil) {
        let request = PullTranscriptRequest(meetingID: meeting.meetingId, isForward: isForward, batchID: batchID, count: Self.transcriptCount)
        meeting.httpClient.getResponse(request) { [weak self] response in
            guard let self = self else { return }
            self.isPullCompleted = true
            switch response {
            case .success(let res):
                Self.logger.info("pull transcript success, batchID: \(batchID ?? 0), isForward: \(isForward), hasMore: \(res.hasMore)")
                DispatchQueue.main.async {
                    if batchID == nil {
                        self.hasBeforeData = res.hasMore
                        self.hasAfterData = false
                    } else {
                        if isForward {
                            self.hasBeforeData = res.hasMore
                            self.hasAfterData =  false
                        } else {
                            self.hasAfterData = res.hasMore
                            self.hasBeforeData = false
                        }
                    }
                    self.handlePulledTranscripts(res.transcripts, isForward: isForward)
                }
            case .failure(let error):
                Self.logger.info("pull transcript failure: \(error)")
            }
        }
    }

    func willPullNewData() {
        shouldClearData = true
        isPullCompleted = false

    }

    func transcriptsDidUpdated() {
        Util.runInMainThread {
            self.listeners.forEach { $0.transcriptsDidUpdated() }
            if self.isFirstLocation, self.isSearchMode {
                self.locationToFirst()
                self.isFirstLocation = false
            }
        }
    }

    func handlePulledTranscripts(_ list: [MeetingSubtitleData], isForward: Bool) {
        let sid = list.map { String($0.segID) }.joined(separator: ";")
        Self.logger.info("pull content: \(sid)")
        if shouldClearData {
            transcriptsData.clearData()
        }
        getTranscriptsViewData(with: list) { newList in
            if isForward {
                self.shouldClearData = true
                self.transcriptsData.insertTranscripts(newList, at: 0)
            } else {
                self.transcriptsData.appendTranscripts(newList)
            }
            self.isSearchEnabled = !self.transcriptsData.isEmpty
            if self.isSearchMode {
                self.transcriptsData.highlightTranscripts(block: self.highlightTranscripts(transcripts:))
                self.setSearchArrowHighlight()
            }
            self.shouldClearData = false
            self.transcriptsDidUpdated()
        }
    }

    func getTranscriptsViewData(with data: [MeetingSubtitleData], completion: @escaping (([SubtitleViewData]) -> Void)) {
        let meetingId = meeting.meetingId
        let participantService = meeting.httpClient.participantService
        let pids = data.map { $0.participantId }
        participantService.participantInfo(pids: pids, meetingId: meetingId) { aps in
            let transcripts = zip(aps, data).map { (ap, data) -> SubtitleViewData in
                let subtitle = Subtitle(data: data, meeting: self.meeting, name: ap.name, avatarInfo: ap.avatarInfo)
                let viewdata = SubtitleViewData(subtitle: subtitle, phraseStatus: .unknown)
                return viewdata
            }
            completion(transcripts)
        }
    }

    func clipDataIfNeeded() {
        transcriptsData.clipDataIfNeeded { [weak self] in
            self?.hasBeforeData = true
            self?.transcriptsDidUpdated()
        }
    }

    deinit {
        clearFilter(excuteClearBlock: false)
    }
}

extension TranscriptViewModel {

    @objc func transcriptSwitchAction() {
        inMeetViewModel.transcribeAction()
    }
}

extension TranscriptViewModel: VideoChatExtraInfoPushObserver {

    func didReceiveExtraInfo(_ extraInfo: VideoChatExtraInfo) {
        guard extraInfo.type == .transcript, isPullCompleted, isTranscribing, !extraInfo.transcripts.isEmpty, !hasAfterData else { return }
        getTranscriptsViewData(with: extraInfo.transcripts) { trans in
            DispatchQueue.main.async {
                self.transcriptsData.appendTranscripts(trans)
                self.isSearchEnabled = !self.transcripts.isEmpty
                self.listeners.forEach { $0.didReceivedNewTranscript() }
                self.transcriptsDidUpdated()
                let sid = trans.map { String($0.segId) }.joined(separator: ";")
                Self.logger.info("push content: \(sid)")
            }
        }
    }
}

extension TranscriptViewModel: MyselfListener {

    ///  改变翻译语言回调
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        if oldValue?.settings.transcriptLanguage == nil { return }
        if !myself.settings.transcriptLanguage.isEmpty, myself.settings.transcriptLanguage != oldValue?.settings.transcriptLanguage {
            DispatchQueue.main.async {
                self.isAlignRight = myself.settings.transcriptLanguage == "ar"
                self.willPullNewData()
                self.clearSearchMode()
                self.clearFilter(excuteClearBlock: false) { [weak self] in
                    self?.fetchLatestTranscritps(forceSync: true)
                    self?.clearFilterMode()
                }
            }
            VCTracker.post(name: .vc_meeting_transcribe_click, params: ["click": "translate"])
            Self.logger.info("didChange transcript language: \(myself.settings.transcriptLanguage)")
        }
    }
}

extension TranscriptViewModel: InMeetDataListener {

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        isTranscribing = inMeetingInfo.isTranscribing
        guard let status = inMeetingInfo.transcriptInfo?.transcriptStatus else { return }
        transcriptStatus = status
        DispatchQueue.main.async {
            self.listeners.forEach { $0.transcribeStatusDidChanged(status: status) }
        }
        Self.logger.info("transcript status did changed to: \(status)")
    }
}

// MARK: - filter
extension TranscriptViewModel {
    // 进入筛选页面
    func filterAction(_ button: UIButton, text: String?) -> SubtitlesFilterViewController {

        filterViewModel.filterBlock = { [weak self] (filterPeople) in
            guard let `self` = self else { return }
            //  筛选成功回调
            self.startFilterMode(filterPeople: filterPeople)
            self.handleFilterDataTask(text: text)
            VCTracker.post(name: .vc_meeting_transcribe_click, params: ["click": "filter"])
        }
        filterViewModel.clearBlock = { [weak self] in
            guard let `self` = self else { return }
            //  清除筛选回调
            self.clearFilterMode()
            self.handleFilterDataTask(text: text)
        }

        let viewController = SubtitlesFilterViewController(viewModel: filterViewModel)


        if Display.pad {
            let popoverConfig = DynamicModalPopoverConfig(sourceView: button,
                                                          sourceRect: button.bounds,
                                                          backgroundColor: UIColor.clear,
                                                          permittedArrowDirections: .up)
            let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                                   popoverConfig: popoverConfig,
                                                   backgroundColor: .clear,
                                                   needNavigation: true)
            meeting.router.presentDynamicModal(viewController,
                                               regularConfig: regularConfig,
                                               compactConfig: regularConfig)
        } else {
            let vc = NavigationController(rootViewController: viewController)
            vc.modalPresentationStyle = .pageSheet
            meeting.larkRouter.present(vc, animated: true)
        }

        return viewController
    }

    func startFilterMode(filterPeople: ParticipantId) {
        isFilterMode = true
        self.filterPeople = filterPeople
    }

    // 处理筛选状态下的数据任务
    private func handleFilterDataTask(text: String?) {
        // 重新拉取数据
        if let searchText = text, !searchText.isEmpty {
            // 如果搜索框有文字，使用搜索接口，拉最旧的数据
            self.startSearch(text: searchText)
        } else {
            // 清除数据
            self.willPullNewData()
            // 如果搜索框没有文字，走普通的pull接口
            // 拉最新的数据
            fetchLatestTranscritps()
        }
    }

    // 清除筛选模式
    private func clearFilterMode() {
        filterPeople = nil
        isFilterMode = false
    }

    func clearFilter(excuteClearBlock: Bool = true, completion: (() -> Void)? = nil) {
        filterViewModel.clear(excuteClearBlock: excuteClearBlock, completion: completion)
    }

}

// MARK: - search
extension TranscriptViewModel {

    var indexOfSearchData: Int? {
        let currentSelectedId = self.currentSelectedId
        guard let currentStartPos = self.currentSelectedRange?.location else {
            return nil
        }
        return flatMatchData?.firstIndex(where: { (segID, pos) -> Bool in
            segID == currentSelectedId && pos == currentStartPos
        })
    }

    var numOfSearchData: Int? {
        return flatMatchData?.count
    }

    var flatMatchData: [(segID: Int, pos: Int)]? {
        return searchData?.matches.reduce([], { (data, match) -> [(Int, Int)] in
            var d = data
            for m in match.startPos {
                d.append((match.segId, m))
            }
            return d
        })
    }

    func fetchSearchMacthData(pattern: String) {
        let startSegId = self.searchData?.matches.last?.segId
        let request = SearchTranscriptRequest(pattern: pattern, startSegId: startSegId)
        meeting.httpClient.getResponse(request) { [weak self] r in
            guard let self = self else { return }
            switch r {
            case .success(let response):
                self.handleSearchResponse(pattern: pattern, response: response)
            case .failure(let error):
                Self.logger.error("Subtitle fetchSearchMacthData error: pattern = \(pattern) error = \(error)")
            }
        }
    }

    // 通过快速跳转进行pull接口请求返回字幕列表数据
    func fetchTranscriptsInSearchMode(isForward: Bool, batchID: Int64? = nil) {
        isSearchMode = true
        fetchTranscripts(isForward: isForward, batchID: batchID)
    }

    // 开始搜索
    func startSearch(text: String) {
        clearSelectedInfo()
        fetchSearchMacthData(pattern: text)
        VCTracker.post(name: .vc_meeting_transcribe_click, params: ["click": "search"])
    }

    private func handleSearchResponse(pattern: String, response: SearchTranscriptResponse) {
        if response.matches.isEmpty {
            Self.logger.info("Subtitle fetchSearchMacthData pattern = \(pattern) response = 0")
        } else {
            Self.logger.info("Subtitle fetchSearchMacthData pattern = \(pattern) response = \(response)")
        }
        var data = self.searchData ?? SubtitlesSearchModel()
        data.matches = (data.matches + response.matches).uniqued(by: { $0.segId }, option: .keepLast)
        data.pattern = response.pattern
        data.hasMore = response.hasMore
        self.searchData = data
        if response.hasMore {
            fetchSearchMacthData(pattern: response.pattern)
        } else {
            willPullNewData()
            isFirstLocation = true
            fetchTranscriptsInSearchMode(isForward: false, batchID: data.matches.first?.batchId)
        }
    }

    // 对拉下来的数据，进行高亮处理
    private func highlightTranscripts(transcripts: [SubtitleViewData]) -> [SubtitleViewData] {

        guard let searchData = self.searchData else {
            isFirstLocation = true
            return transcripts
        }

        // 用于快速跳转，设置Selected信息
        if self.currentTempSelectedId != nil, self.currentSelectedTempRange != nil {
            self.currentSelectedId = self.currentTempSelectedId
            self.currentSelectedRange = self.currentSelectedTempRange
            self.currentTempSelectedId = nil
            self.currentSelectedTempRange = nil
        }

        for subtitle in transcripts { //遍历字幕
            subtitle.changeMatch(range: [])// 重置
            for match in searchData.matches where match.segId == subtitle.segId {//遍历搜索命中的match数组
                // 给字幕数据添加ranges数组
                var ranges: [NSRange] = []
                for start in match.startPos {
                    if subtitle.eventType == .follow, let docTitle = subtitle.behaviorDocLinkTitle {
                        if start + searchData.pattern.count <= docTitle.count {
                            // 纠错
                            ranges.append(NSRange(location: start, length: searchData.pattern.count))
                        }
                    } else {
                        if start + searchData.pattern.count <= subtitle.translatedContent.length {
                            // 纠错
                            ranges.append(NSRange(location: start, length: searchData.pattern.count))
                        }
                    }
                }
                subtitle.changeMatch(range: ranges)
                if self.currentSelectedId == nil && !ranges.isEmpty {
                    // 用于第一次获取，给一个默认值
                    self.currentSelectedId = subtitle.segId
                    self.currentSelectedRange = ranges.first
                }
                if subtitle.segId == self.currentSelectedId, let currentSelectedRange = self.currentSelectedRange, !subtitle.ranges.contains(currentSelectedRange) {
                    // 纠错
                    self.currentSelectedRange = subtitle.ranges.first // last也可以
                }
            }
        }
        return transcripts
    }

    private func locationToFirst() {
        // 如果没有字幕数据就返回
        let transcripts = self.transcripts
        guard !transcripts.isEmpty  else {
            return
        }

        // 如果没有搜索数组就返回
        guard let searchData = self.searchData else {
            return
        }

        let matches = searchData.matches
        guard !matches.isEmpty else {
            return
        }

        guard let currentSelectedId = self.currentSelectedId else {
            let matchInfo = getLastTranscriptInfoWhenDataIsNoExist(searchText: searchData.pattern, transcripts: transcripts, matches: matches)
            guard let lastMatch = matchInfo.1, let lastRange = matchInfo.2 else {
                return
            }
            requestDataWhenSelectedDataIsNoExist(isForward: true, match: lastMatch, range: lastRange)
            return
        }

        guard let currentSelectSubtitle = getViewDataBySegId(segId: currentSelectedId, list: transcripts), let firstRange = currentSelectSubtitle.ranges.first else {
            return
        }

        self.setSelectData(currentSelectedId: self.currentSelectedId, currentSelectedRange: firstRange)

        if let index = getCurrentSelectIndex() {
            jumpSelectedAtRow(index: index)
        }
    }

    // 快速跳转 - 跳转到下一个结果
    func goToNext() {
        let transcripts = self.transcripts
        // 如果没有字幕数据就返回
        guard !transcripts.isEmpty  else {
            return
        }

        // 如果没有搜索数组就返回
        guard let searchData = self.searchData else {
            return
        }

        let matches = searchData.matches
        guard !matches.isEmpty else {
            return
        }

        // 如果没有当前选中的数据就返回，需要进一步查询
        guard let currentSelectedId = self.currentSelectedId, let currentSelectedRange = self.currentSelectedRange else {
            let nextMatchInfo = getNextTranscriptInfoWhenDataIsNoExist(searchText: searchData.pattern, transcripts: transcripts, matches: matches)
            guard let nextMatch = nextMatchInfo.1, let nextRange = nextMatchInfo.2 else {
                return
            }
            requestDataWhenSelectedDataIsNoExist(isForward: false, match: nextMatch, range: nextRange)
            return
        }

        // 根据id获取当前选中的subtitle
        guard let currentSelectSubtitle = getViewDataBySegId(segId: currentSelectedId, list: transcripts) else {
            return
        }

        if currentSelectSubtitle.ranges.last == currentSelectedRange {
            // 马上将变为不是同一行
            //获取下一个待命中的match的id
            var tempNextMatch: SubtitleSearchMatch?
            if let index = matches.firstIndex(where: { $0.segId == currentSelectedId }), (index + 1) < matches.count {
                tempNextMatch = matches[index + 1]
            }

            guard let nextMatch = tempNextMatch else {
                return
            }

            //获取下一个待命中的subtitle
            if let nextSubTitle = getViewDataBySegId(segId: nextMatch.segId, list: transcripts) {
                //  如果有足够的数据，不需要进行请求，也就是目标id在字幕数据里
                self.setSelectData(currentSelectedId: nextSubTitle.segId, currentSelectedRange: nextSubTitle.ranges.first)
                if let index = getCurrentSelectIndex() {
                    jumpSelectedAtRow(index: index)
                }
            } else {
                guard let nextRangeStart = nextMatch.startPos.first, !searchData.pattern.isEmpty else {
                    return
                }
                requestDataWhenSelectedDataIsNoExist(isForward: false, match: nextMatch, range: NSRange(location: nextRangeStart, length: searchData.pattern.count))
            }
        } else {
            // 同一行向后移动
            let ranges = currentSelectSubtitle.ranges
            if let index = ranges.firstIndex(of: currentSelectedRange), (index + 1) < ranges.count {
                self.setSelectData(currentSelectedId: self.currentSelectedId, currentSelectedRange: ranges[index + 1])
            }

            if let index = getCurrentSelectIndex() {
                jumpSelectedAtRow(index: index)
            }
        }
    }

    // 快速跳转 - 跳转到上一个结果
    func goToLast() {

        let transcripts = self.transcripts
        // 如果没有字幕数据就返回
        guard !transcripts.isEmpty  else {
            return
        }

        // 如果没有搜索数组就返回
        guard let searchData = self.searchData else {
            return
        }

        let matches = searchData.matches
        guard !matches.isEmpty else {
            return
        }

        // 如果没有当前选中的数据就返回，因为没有方向去操作移动选中
        guard let currentSelectedId = self.currentSelectedId, let currentSelectedRange = self.currentSelectedRange else {
            let matchInfo = getLastTranscriptInfoWhenDataIsNoExist(searchText: searchData.pattern, transcripts: transcripts, matches: matches)
            guard let lastMatch = matchInfo.1, let lastRange = matchInfo.2 else {
                return
            }
            requestDataWhenSelectedDataIsNoExist(isForward: true, match: lastMatch, range: lastRange)
            return
        }

        // 根据id获取当前选中的subtitle
        guard let currentSelectSubtitle = getViewDataBySegId(segId: currentSelectedId, list: transcripts) else {
            return
        }

        if currentSelectSubtitle.ranges.first == currentSelectedRange {
            // 马上将变为不是同一行
            //获取上一个待命中的match的id
            var tempLastMatch: SubtitleSearchMatch?
            if let index = matches.firstIndex(where: { $0.segId == currentSelectedId }), index > 0 {
                tempLastMatch = matches[index - 1]
            }

            guard let lastMatch = tempLastMatch else {
                return
            }

            //获取上一个待命中的subtitle
            if let lastSubTitle = getViewDataBySegId(segId: lastMatch.segId, list: transcripts) {
                //  如果有足够的数据，不需要进行请求，也就是目标id在字幕数据里
                self.setSelectData(currentSelectedId: lastSubTitle.segId, currentSelectedRange: lastSubTitle.ranges.last)
                if let index = getCurrentSelectIndex() {
                    jumpSelectedAtRow(index: index)
                }
            } else {
                guard let lastRangeStart = lastMatch.startPos.last, !searchData.pattern.isEmpty else {
                    return
                }
                requestDataWhenSelectedDataIsNoExist(isForward: true, match: lastMatch, range: NSRange(location: lastRangeStart, length: searchData.pattern.count))
            }
        } else {
            // 同一行向前移动
            let ranges = currentSelectSubtitle.ranges
            if let index = ranges.firstIndex(of: currentSelectedRange), index > 0 {
                self.setSelectData(currentSelectedId: self.currentSelectedId, currentSelectedRange: ranges[index - 1])
            }

            if let index = getCurrentSelectIndex() {
                jumpSelectedAtRow(index: index)
            }
        }
    }

    private func getCurrentSelectIndex() -> Int? {
        if let currentSelectedId = self.currentSelectedId, !transcripts.isEmpty {
            return transcripts.firstIndex(where: { $0.segId == currentSelectedId })
        }
        return nil
    }

    // 根据id找到 SubtitleViewData
    private func getViewDataBySegId(segId: Int, list: [SubtitleViewData]) -> SubtitleViewData? {
        list.first(where: { $0.segId == segId })
    }

    // 设置命中的数据
    private func setSelectData(currentSelectedId: Int?, currentSelectedRange: NSRange?) {
        self.currentSelectedId = currentSelectedId
        self.currentSelectedRange = currentSelectedRange
        setSearchArrowHighlight()
    }

    // 通过快速跳转且没有足够的数据时，请求pull接口请求字幕列表数据，
    private func requestDataWhenSelectedDataIsNoExist(isForward: Bool, match: SubtitleSearchMatch, range: NSRange) {
         if self.currentTempSelectedId != nil, self.currentSelectedTempRange != nil {
             // 防止用户多次点击快速跳转按钮
             return
         }
        isFirstLocation = true
        self.currentTempSelectedId = match.segId
        self.currentSelectedTempRange = range
        self.fetchTranscriptsInSearchMode(isForward: isForward, batchID: match.batchId)
    }

    // 如果选中的不在当前数据源中，进一步判断inputView里的上下箭头按钮是否高亮
    private func getLastTranscriptInfoWhenDataIsNoExist(searchText: String, transcripts: [SubtitleViewData], matches: [SubtitleSearchMatch]) -> (Bool, SubtitleSearchMatch?, NSRange?) {
        guard let subtitle = transcripts.first else {
            return (false, nil, nil)
        }

        guard let lastMatch = matches.reversed().first(where: { $0.segId < subtitle.segId }) else {
            return (false, nil, nil)
        }

        guard let lastRangeStart = lastMatch.startPos.last, !searchText.isEmpty else {
            return (false, nil, nil)
        }
        return (true, lastMatch, NSRange(location: lastRangeStart, length: searchText.count))
    }

    private func getNextTranscriptInfoWhenDataIsNoExist(searchText: String, transcripts: [SubtitleViewData], matches: [SubtitleSearchMatch]) -> (Bool, SubtitleSearchMatch?, NSRange?) {
        guard let subtitle = transcripts.last else {
            return (false, nil, nil)
        }

        guard let nextMatch = matches.first(where: { $0.segId > subtitle.segId }) else {
            return (false, nil, nil)
        }

        guard let nextRangeStart = nextMatch.startPos.first, !searchText.isEmpty else {
            return (false, nil, nil)
        }
        return (true, nextMatch, NSRange(location: nextRangeStart, length: searchText.count))
    }

    // 通知tableview跳转到指定的目标cell
    func jumpSelectedAtRow(index: Int) {
        DispatchQueue.main.async {
            self.listeners.forEach { $0.selectedSearchResultDidChangeTo(row: index) }
        }
    }

    // 如果在当前数据源中中没有找到当前选中的sedid，进一步判断是否可以高亮
    private func judgeButtonIsHighlight(searchText: String, list: [SubtitleViewData], matches: [SubtitleSearchMatch]) {
        let topIsHighlight = getLastTranscriptInfoWhenDataIsNoExist(searchText: searchText, transcripts: list, matches: matches).0
        isPrevButtonEnabled = topIsHighlight

        let bottomIsHighlight = getNextTranscriptInfoWhenDataIsNoExist(searchText: searchText, transcripts: list, matches: matches).0
        isNextButtonEnabled = bottomIsHighlight
    }

    //设置inputView里面的上下箭头是否可以点击
    private func setSearchArrowHighlight() {
        guard let matches = searchData?.matches, !matches.isEmpty,
              let searchText = searchData?.pattern, !searchText.isEmpty,
              !transcripts.isEmpty else {
            // 置灰
            resetSearchBottomButtonStatus()
            return
        }

        if let currentSelectedId = self.currentSelectedId, let currentSelectedRange = self.currentSelectedRange {
            // 根据id找到选中的subtitle
            guard let currentSelectSubtitle = getViewDataBySegId(segId: currentSelectedId, list: transcripts) else {
                // 如果在当前数据源中中没有找到，进一步查找确认
                judgeButtonIsHighlight(searchText: searchText, list: transcripts, matches: matches)
                return
            }

            // 设置topArrowButton是否可以点击
            let topIsNotHighlight = matches.first?.segId == currentSelectedId && currentSelectSubtitle.ranges.first == currentSelectedRange
            isPrevButtonEnabled = !topIsNotHighlight

            // 设置bottomArrowButton是否可以点击
            let bottomIsNotHighlight = matches.last?.segId == currentSelectedId && currentSelectSubtitle.ranges.last == currentSelectedRange
            isNextButtonEnabled = !bottomIsNotHighlight

        } else {
            // 如果在当前数据源中中没有找到当前选中的sedid，进一步判断是否可以高亮
            judgeButtonIsHighlight(searchText: searchText, list: transcripts, matches: matches)
        }
    }

    // 重置 viewData 的range
    func resetRanges() {
        let viewDatas = transcripts
        transcriptsData.clearData()
        for subtitle in viewDatas { //遍历字幕
            subtitle.changeMatch(range: [])// 重置
            transcriptsData.appendTranscripts([subtitle])
        }
    }

    // 清除搜索信息
    private func clearSelectedInfo() {
        self.currentSelectedRange = nil
        self.currentSelectedId = nil
        self.currentTempSelectedId = nil
        self.currentSelectedTempRange = nil
        self.searchData = nil
        resetSearchBottomButtonStatus()
    }

    // 清除搜索（当搜索框字符串为空的时候）
    func clearSearchMode() {
        clearSelectedInfo()
        if isSearchMode {
            isSearchMode = false
            //  重置 viewData 的range
            resetRanges()
            transcriptsData.clearData()
            fetchLatestTranscritps()
        }
    }

    func resetSearchBottomButtonStatus() {
        isPrevButtonEnabled = false
        isNextButtonEnabled = false
    }
}
