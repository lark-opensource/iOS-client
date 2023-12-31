//
//  InMeetGridDataSource.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/1/31.
//

import Foundation
import ByteViewCommon
import ByteViewSetting
import ByteViewNetwork

protocol InMeetGridDataSourceListener: AnyObject {
    func sortResultDidChange(_ sortedParticipants: [InMeetGridCellViewModel])
    func sorterDidChange()
}

private enum GridSorterType: CustomStringConvertible {
    case activeSpeaker(ActiveSpeakerGridSorter)
    case customOrder(CustomOrderGridSorter)

    var description: String {
        switch self {
        case .activeSpeaker: return "ActiveSpeakerSorter"
        case .customOrder: return "CustomOrderSorter"
        }
    }
}

class InMeetGridDataSource {
    private static let logger = Logger.grid

    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    let gridContext: InMeetGridSortContext
    let dataStore: InMeetGridParticipantStore

    private var sorterType: GridSorterType {
        didSet {
            delegate?.sorterDidChange()
        }
    }
    private var sorter: GridSorter {
        switch sorterType {
        case .activeSpeaker(let sorter): return sorter
        case .customOrder(let sorter): return sorter
        }
    }
    private let asSorter: ActiveSpeakerGridSorter
    private lazy var customSorter = CustomOrderGridSorter(myself: meeting.myself.user)

    // 处理临时上屏参会人的计时器
    private var temporaryTimer: Timer?
    @RwAtomic
    private var temporaryParticipants: [GridSortOutputEntry] = []

    // 保护 sorterType 等变量的多线程访问
    private static let processQueueKey = DispatchSpecificKey<Void>()
    private lazy var processQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "lark.byteview.gridDataProcess")
        queue.setSpecific(key: Self.processQueueKey, value: ())
        return queue
    }()
    // 实际排序操作所在的 queue
    private var sortQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "lark.byteview.girdDataSource"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    weak var delegate: InMeetGridDataSourceListener? {
        didSet {
            gridContextDidChange()
        }
    }

    var allGridViewModels: [ByteviewUser: InMeetGridCellViewModel] { dataStore.allGridViewModels }
    let batteryManager: InMeetBatteryStatusManager

    init(meeting: InMeetMeeting, context: InMeetViewContext, activeSpeakerViewModel: InMeetActiveSpeakerViewModel, batteryManager: InMeetBatteryStatusManager) {
        self.meeting = meeting
        self.context = context
        self.batteryManager = batteryManager
        self.gridContext = InMeetGridSortContext(
            videoSortConfig: meeting.setting.videoSortConfig,
            nonVideoConfig: meeting.setting.hideNonVideoConfig,
            activeSpeakerConfig: meeting.setting.activeSpeakerConfig,
            isSelfSharingContent: meeting.shareData.isSelfSharingContent,
            shareSceneType: meeting.shareData.shareContentScene.shareSceneType,
            isHost: meeting.myself.isHost,
            focusID: meeting.participant.focusing?.user,
            isHideSelf: context.isHideSelf,
            isHideNonVideo: context.isHideNonVideoParticipants,
            isVoiceMode: meeting.setting.isVoiceModeOn,
            isWebinar: meeting.subType == .webinar
        )
        self.dataStore = InMeetGridParticipantStore(meeting: meeting, context: context, activeSpeakerViewModel: activeSpeakerViewModel, batteryManager: batteryManager)
        self.asSorter = ActiveSpeakerGridSorter(myself: meeting.myself.user)
        self.sorterType = .activeSpeaker(self.asSorter)

        self.dataStore.addListener(self)
        meeting.participant.addListener(self)
        meeting.shareData.addListener(self)
        meeting.addMyselfListener(self)
        meeting.setting.addListener(self, for: .isVoiceModeOn)
        context.addListener(self, for: [.hideSelf, .hideNonVideoParticipants])

        self.gridContext.allParticipants = self.dataStore.allGridViewModels
        self.gridContext.asInfos = self.dataStore.activeSpeakerQueue
        self.gridContext.currentActiveSpeaker = self.dataStore.activeSpeakerIdentifier
    }

    func useGridOrderFromServer(_ order: [ByteviewUser], sharePosition: Int, refresh: Bool) {
        let allParticipants = gridContext.allParticipants
        let idMap = Dictionary(allParticipants.values.map { ($0.pid.id, $0) }) { $1 }
        var entries = order.compactMap { (user: ByteviewUser) -> GridSortOutputEntry? in
            if let vm = allParticipants[user] {
                return GridSortOutputEntry(type: .participant(vm.participant.value), strategy: .normal)
            } else if user.deviceIdIsEmpty, let vm = idMap[user.id] {
                return GridSortOutputEntry(type: .participant(vm.participant.value), strategy: .normal)
            }
            return nil
        }
        let shareInsertPosition = max(min(sharePosition, entries.count), 0)
        entries.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: shareInsertPosition)
        Self.logger.info("Use grid order from server, share index = \(shareInsertPosition), total count = \(entries.count)")
        // 更新 context 里记录的后端同步顺序，被同步参会方在同步期间都将使用该数据
        gridContext.updateOrderFromServer(entries)
        // 同时更新当前排序结果，主持人侧的后续排序将依据当前排序结果
        gridContext.updateCurrentSortResult(entries)
        if refresh {
            forceRefresh()
        }
    }

    func beginUsingCustomOrder(function: String = #function, completion: @escaping () -> Void) {
        processQueue.async {
            if case .customOrder = self.sorterType {
                completion()
                return
            }
            Self.logger.info("Begin using custom order from function \(function)")
            self.sorterType = .customOrder(self.customSorter)
            completion()
        }
    }

    func endUsingCustomOrder(function: String = #function) {
        processQueue.async {
            guard case .customOrder = self.sorterType else { return }
            Self.logger.info("End using custom order from function \(function)")
            self.sorterType = .activeSpeaker(self.asSorter)
            self.forceRefresh()
        }
    }

    var isUsingCustomOrder: Bool {
        let sorterType: GridSorterType
        if DispatchQueue.getSpecific(key: Self.processQueueKey) != nil {
            sorterType = self.sorterType
        } else {
            sorterType = processQueue.sync { self.sorterType }
        }
        if case .customOrder = sorterType {
            return true
        }
        return false
    }

    func apply(_ change: GridSortTrigger, with value: Any) {
        switch change {
        case .shareGridEnabled:
            if let enabled = value as? Bool {
                Self.logger.info("[Sort] did change shareGridEnabled to \(enabled)")
                gridContext.shareGridEnabled = enabled
            }
        case .displayInfo:
            if let info = value as? GridDisplayInfo {
                Self.logger.info("[Sort] did change displayInfo to \(info)")
                gridContext.displayInfo = info
            }
        case .reorder:
            if let action = value as? GridReorderAction {
                Self.logger.info("[Sort] did change reorder to \(action)")
                gridContext.reorderAction = action
            }
        case .isGridDragging:
            if let value = value as? Bool {
                Self.logger.info("[Sort] did change isGridDragging to \(value)")
                gridContext.isGridDragging = value
            }
        case .isGridOrderSyncing:
            if let value = value as? Bool {
                Self.logger.info("[Sort] did change isGridOrderSyncing to \(value)")
                gridContext.isGridOrderSyncing = value
            }
        default:
            return
        }
        gridContextDidChange()
    }

    // 强制刷新宫格排序，无论当前 sortContext 有无变化
    func forceRefresh(file: String = #fileID, line: Int = #line, function: String = #function) {
        Self.logger.info("[Sort] Force refresh grid order, file: \(file), line: \(line), function: \(function)")
        gridContext.markDirty()
        gridContextDidChange()
    }

    /// 同步执行宫格排序刷新，如果forced==false且当前 sortContext 没有发生变化，不会有实际数据刷新；否则将同步调用排序方法，完成后通知排序结果
    func refreshAndWait(forced: Bool = false, file: String = #fileID, line: Int = #line, function: String = #function) {
        Self.logger.info("[Sort] Refresh grid order synchronously, forced: \(forced), file: \(file), line: \(line), function: \(function)")
        if forced {
            gridContext.markDirty()
        }
        _sortParticipants(true)
    }

    private func gridContextDidChange() {
        // 共享态切换时同步刷新宫格，避免宫格模式切换时的共享宫格显示问题
        let sortSynchronously = !gridContext.changedTypes.isDisjoint(with: [.shareGridEnabled, .displayInfo])
        _sortParticipants(sortSynchronously)
        if sortSynchronously {
            // 为了不阻塞主线程，同步刷新宫格只处理共享宫格和兜底宫格，此时在后台线程额外发起一次全量排序，确保最终宫格数据是正确的
            gridContext.markDirty()
            _sortParticipants(false)
        }
    }

    private func _sortParticipants(_ sync: Bool) {
        guard delegate != nil, gridContext.isDirty || !gridContext.changedTypes.isEmpty else { return }

        let gridContext = self.gridContext.snapshot
        let task = GridSortTask(context: gridContext,
                                sorter: sorter,
                                participants: meeting.participant.activePanel.all)
        let operation = GridSortOperation(task: task)
        operation.sortCompletionBlock = { [weak self, weak operation] result in
            Self.logger.info("[Sort] Sort task completed. isCancelled = \(operation?.isCancelled) changes: \(gridContext.changedTypes)")
            guard let self = self, let operation = operation, !operation.isCancelled else { return }
            self.handleSortResult(result)
        }

        Self.logger.info("[Sort] Start sort task with changes: \(gridContext.changedTypes), sync: \(sync)")
        if sync {
            sortQueue.cancelAllOperations()
            operation.start()
        } else {
            sortQueue.addOperation(operation)
        }
    }

    private func handleSortResult(_ sortResult: SortResult) {
        gridContext.markClean()
        guard case .sorted(let result) = sortResult else {
            Self.logger.info("[Sort] finish sort with unchanged result")
            return
        }

        let allParticipants = gridContext.allParticipants
        var sortedParticipants = result.compactMap { item -> InMeetGridCellViewModel? in
            switch item.type {
            case .participant(let p):
                return allParticipants[p.user]
            case .share:
                return shareGridCellVM
            case .activeSpeaker:
                return asGridCellVM

            }
        }
        if sortedParticipants.isEmpty {
            // sorter 内部会保证兜底显示 AS，所以如果这里在结合 allParticipants 字典之后发现输出到屏幕上的宫格为空，
            // 原因只能是 allParticipants 内不包含 sorter 输出的结果。
            // 目前 allParticipants 监听会中参会人变化，并整理一份 [ByteviewUser: InMeetGridCellViewModel] 字典，
            // 排序使用的参会人数组是 meeting.participantData.panelParticipants，
            // 走到这里说明“参会人模块输出的参会人数据”和“参会人模块维护的参会人数据”不一致
            Self.logger.warn("[Sort] \(sorterType) returns empty sort result after processing from allParticipants. There may be something wrong in articipant change listener.")
            sortedParticipants = [asGridCellVM]
        }

        let temporaryParticipants = result.filter {
            if case .temporary = $0.strategy {
                return true
            }
            return false
        }

        Self.logger.info("[Sort] finish sort with count \(sortedParticipants.count), temporary participants count \(temporaryParticipants.count)")
        gridContext.updateCurrentSortResult(result)
        delegate?.sortResultDidChange(sortedParticipants)
        Util.runInMainThread {
            self.handleTemporaryParticipants(temporaryParticipants)
        }
    }

    private lazy var shareGridCellVM = InMeetGridCellViewModel(meeting: meeting,
                                                               context: self.context,
                                                               dependency: self.dataStore.cellViewModelDependency,
                                                               participant: .init(meetingId: "", id: "share_id", type: .larkUser, deviceId: "share_did", interactiveId: ""), batteryManager: batteryManager,
                                                               type: .share)
    private lazy var asGridCellVM = InMeetGridCellViewModel(meeting: meeting,
                                                            context: self.context,
                                                            dependency: self.dataStore.cellViewModelDependency,
                                                            participant: .init(meetingId: "", id: "as_id", type: .larkUser, deviceId: "as_did", interactiveId: ""), batteryManager: batteryManager,
                                                            type: .activeSpeaker)

    // MARK: - Temporary Participants Handler

    private func handleTemporaryParticipants(_ temporaryParticipants: [GridSortOutputEntry]) {
        self.temporaryParticipants = temporaryParticipants
        guard !temporaryParticipants.isEmpty else {
            stopTemporaryTimer()
            return
        }
        if temporaryTimer != nil {
            return
        }
        temporaryTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.checkTemporaryParticipants()
        })
    }

    private func checkTemporaryParticipants() {
        let now = Date().timeIntervalSinceReferenceDate
        for item in temporaryParticipants {
            if case .temporary(let dismissTime) = item.strategy, now >= dismissTime {
                stopTemporaryTimer()
                forceRefresh()
                return
            }
        }
    }

    private func stopTemporaryTimer() {
        temporaryTimer?.invalidate()
        temporaryTimer = nil
    }
}

extension InMeetGridDataSource: InMeetGridParticipantStoreDelegate {
    func activeSpeakerInfoDidChange(asInfos: [ActiveSpeakerInfo], currentActiveSpeaker: ByteviewUser?) {
        gridContext.currentActiveSpeaker = currentActiveSpeaker
        gridContext.asInfos = asInfos
        Self.logger.info("[Sort] did change active speaker infos, currentAS: \(currentActiveSpeaker)")
        gridContextDidChange()
    }

    func allGridViewModelsDidChange(_ viewModels: [ByteviewUser: InMeetGridCellViewModel]) {
        gridContext.allParticipants = viewModels
        Self.logger.info("[Sort] did change allParticipants, count: \(viewModels.count)")
        gridContextDidChange()
    }
}

extension InMeetGridDataSource: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: ByteViewSetting.MeetingSettingManager, key: ByteViewSetting.MeetingSettingKey, isOn: Bool) {
        if key == .isVoiceModeOn {
            gridContext.isVoiceMode = isOn
            Self.logger.info("[Sort] did change isVoiceMode to \(isOn)")
            gridContextDidChange()
        }
    }
}

extension InMeetGridDataSource: InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        gridContext.shareSceneType = newScene.shareSceneType
        gridContext.selfSharing = meeting.shareData.isSelfSharingContent
        Self.logger.info("[Sort] did change share info, shareType: \(newScene.shareSceneType), selfSharing: \(meeting.shareData.isSelfSharingContent)")
        gridContextDidChange()
    }
}

extension InMeetGridDataSource: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        gridContext.selfIsHost = myself.isHost
        Self.logger.info("[Sort] did change selfIsHost to \(myself.isHost)")
        gridContextDidChange()
    }
}

extension InMeetGridDataSource: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .hideSelf, let hideSelf = userInfo as? Bool {
            gridContext.isHideSelf = hideSelf
            Self.logger.info("[Sort] did change isHideSelf to \(hideSelf)")
            gridContextDidChange()
        } else if change == .hideNonVideoParticipants, let shouldHide = userInfo as? Bool {
            gridContext.isHideNonVideo = shouldHide
            Self.logger.info("[Sort] did change isHideNonVideo to \(shouldHide)")
            gridContextDidChange()
        }
    }
}

extension InMeetGridDataSource: InMeetParticipantListener {
    func didChangeFocusingParticipant(_ participant: Participant?, oldValue: Participant?) {
        gridContext.focusingParticipantID = participant?.user
        Self.logger.info("[Sort] did change focusingParticipantID to \(participant?.user)")
        gridContextDidChange()
    }
}

private class GridSortTask {
    let context: InMeetGridSortContext
    let sorter: GridSorter
    let participants: [Participant]

    init(context: InMeetGridSortContext, sorter: GridSorter, participants: [Participant]) {
        self.context = context
        self.sorter = sorter
        self.participants = participants
    }
}

private struct GridSortTaskResult {
    /// 排序结果
    let sortResult: [InMeetGridCellViewModel]
    /// 临时上屏的参会人
    let temporaryParticipants: [GridSortOutputEntry]
}

private class GridSortOperation: Operation {
    let task: GridSortTask
    /// 为了让 completionBlock 在 operation 里串行执行
    var sortCompletionBlock: ((SortResult) -> Void)?

    init(task: GridSortTask) {
        self.task = task
    }

    override func main() {
        if isCancelled {
            sortCompletionBlock?(.unchanged)
            return
        }

        let gridContext = task.context
        let participants = task.participants

        let sortResult = task.sorter.sort(participants: participants, with: gridContext)
        if isCancelled {
            sortCompletionBlock?(.unchanged)
            return
        }

        sortCompletionBlock?(sortResult)
    }
}
