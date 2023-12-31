//
//  InMeetGridParticipantStore.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/1/31.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting
import RxSwift
import RxRelay

protocol InMeetGridParticipantStoreDelegate: AnyObject {
    func allGridViewModelsDidChange(_ viewModels: [ByteviewUser: InMeetGridCellViewModel])
    func activeSpeakerInfoDidChange(asInfos: [ActiveSpeakerInfo], currentActiveSpeaker: ByteviewUser?)
}

struct CellViewModelDependency {
    let inMeetInfoRelay = BehaviorRelay<VideoChatInMeetingInfo?>(value: nil)
    let rtcNetworkStatusRelay = BehaviorRelay<[RtcUID: RtcNetworkStatus]?>(value: nil)
    let activeSpeakerSdkUidRelay = BehaviorRelay<RtcUID?>(value: nil)
    let isConnectedRelay: BehaviorRelay<Bool>
    let meetingLayoutStyleRelay: BehaviorRelay<MeetingLayoutStyle>
    let hasHostAuthority: BehaviorRelay<Bool>
}

class InMeetGridParticipantStore {
    private static let logger = Logger.grid

    // MARK: - Input

    private let meeting: InMeetMeeting
    private let context: InMeetViewContext
    private let asViewModel: InMeetActiveSpeakerViewModel
    private let listeners = Listeners<InMeetGridParticipantStoreDelegate>()
    private lazy var isWebinarAttendee = meeting.subType == .webinar && meeting.myself.meetingRole == .webinarAttendee

    // MARK: - Output

    @RwAtomic
    var allGridViewModels: [ByteviewUser: InMeetGridCellViewModel] = [:]
    var activeSpeakerQueue: [ActiveSpeakerInfo] = []
    var activeSpeakerIdentifier: ByteviewUser?

    let cellViewModelDependency: CellViewModelDependency


    let batteryManager: InMeetBatteryStatusManager

    init(meeting: InMeetMeeting, context: InMeetViewContext, activeSpeakerViewModel: InMeetActiveSpeakerViewModel, batteryManager: InMeetBatteryStatusManager) {
        self.meeting = meeting
        self.context = context
        self.asViewModel = activeSpeakerViewModel
        self.batteryManager = batteryManager

        self.cellViewModelDependency = CellViewModelDependency(isConnectedRelay: BehaviorRelay(value: meeting.isCallConnected),
                                                               meetingLayoutStyleRelay: BehaviorRelay(value: context.meetingLayoutStyle),
                                                               hasHostAuthority: BehaviorRelay(value: meeting.setting.hasCohostAuthority))

        activeSpeakerViewModel.addListener(self)
        if meeting.subType == .webinar {
            if meeting.isWebinarAttendee {
                meeting.participant.addGridWebinarAttendeeListener(self)
            } else {
                meeting.participant.addGridWebinarParticipantListener(self)
            }
        } else {
            meeting.participant.addGridParticipantListener(self)
        }
        meeting.participant.addListener(self)
        meeting.data.addListener(self)
        meeting.rtc.network.addListener(self)
        meeting.setting.addListener(self, for: .hasCohostAuthority)
        context.addListener(self, for: [.containerLayoutStyle])
    }

    // MARK: - Public

    func addListener(_ listener: InMeetGridParticipantStoreDelegate) {
        listeners.addListener(listener)
        listener.allGridViewModelsDidChange(self.allGridViewModels)
    }

    // MARK: - Private

    private func notifyFullParticipants() {
        listeners.forEach { $0.allGridViewModelsDidChange(allGridViewModels) }
    }

    private func createGridCellViewModel(participant: Participant) -> InMeetGridCellViewModel {
        let cellVM = InMeetGridCellViewModel(meeting: meeting,
                                             context: self.context,
                                             dependency: self.cellViewModelDependency,
                                             participant: participant,
                                             batteryManager: batteryManager)
        return cellVM
    }

    // MARK: - Active Speaker

    private func updateActiveSpeakerQueue(_ asId: RtcUID?) {
        let stopLastAS = { [weak self] in
            guard let self = self, !self.activeSpeakerQueue.isEmpty, self.activeSpeakerQueue[0].isSpeaking else { return }
            self.activeSpeakerQueue[0].isSpeaking = false
            let speakingTimes = self.activeSpeakerQueue[0].speakingTimes
            if !speakingTimes.isEmpty && speakingTimes.last?.end == nil {
                self.activeSpeakerQueue[0].speakingTimes[speakingTimes.count - 1].end = Date().timeIntervalSinceReferenceDate
            }
        }

        if let id = asId {
            // 当前有活跃as
            if let index = activeSpeakerQueue.firstIndex(where: { $0.rtcUid == id }) {
                // 当前as已在队列中
                if index > 0 {
                    // 当前as不在队首
                    stopLastAS()
                    var asInfo = activeSpeakerQueue.remove(at: index)
                    asInfo.speakingTimes.append(.init(start: Date().timeIntervalSinceReferenceDate))
                    asInfo.isSpeaking = true
                    activeSpeakerQueue.insert(asInfo, at: 0)
                } else if !activeSpeakerQueue[0].isSpeaking {
                    // 当前as在队首，但是之前没有发言
                    activeSpeakerQueue[0].speakingTimes.append(.init(start: Date().timeIntervalSinceReferenceDate))
                    activeSpeakerQueue[0].isSpeaking = true
                } else {
                    // 当前as在队首、且连续发言，则无需处理
                }
            } else {
                // 新的as还不在队列中，新建相关info
                if let pid = self.meeting.participant.find(rtcUid: id, in: .activePanels)?.user {
                    stopLastAS()
                    let asInfo = ActiveSpeakerInfo(rtcUid: id,
                                                   pid: pid,
                                                   speakingTimes: [.init(start: Date().timeIntervalSinceReferenceDate)])
                    activeSpeakerQueue.insert(asInfo, at: 0)
                }
            }
            self.activeSpeakerIdentifier = activeSpeakerQueue.first?.pid
        } else {
            // 当前无人说话
            stopLastAS()
            self.activeSpeakerIdentifier = nil
        }
    }

    private func correctActiveSpeakerQueue() {
        let videoSortConfig = meeting.setting.videoSortConfig
        let activeSpeakerQueue = self.activeSpeakerQueue
        let ids = Set(meeting.participant.activePanel.all.map(\.user))
        let now = Date().timeIntervalSinceReferenceDate
        let timeScope = Double(videoSortConfig.timeScope)
        var result: [ActiveSpeakerInfo] = []
        for info in activeSpeakerQueue {
            // 清除离会人
            if !ids.contains(info.pid) {
                continue
            }
            // 队列序号超过maxIndex且没有最近发言记录的人，应该直接从队列中移除
            if result.count < videoSortConfig.maxIndex {
                result.append(info)
                continue
            }
            if info.speakingTimes.last?.isSpeaking(in: timeScope, now: now) == true {
                result.append(info)
                continue
            }
        }
        self.activeSpeakerQueue = result
    }
}

extension InMeetGridParticipantStore: InMeetParticipantListener {
    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        guard !self.isWebinarAttendee else { return }
        notifyFullParticipants()
    }

    func didChangeWebinarAttendees(_ output: InMeetParticipantOutput) {
        guard self.meeting.subType == .webinar, !self.isWebinarAttendee else { return }
        notifyFullParticipants()
    }

    func didChangeWebinarParticipantForAttendee(_ output: InMeetParticipantOutput) {
        guard self.isWebinarAttendee else { return }
        notifyFullParticipants()
    }
}

extension InMeetGridParticipantStore: GridParticipantAggregatorListener {
    func handleFullParticipants(_ participants: [Participant]) {
        Self.logger.info("GridData full: \(participants.count)")
        var removedVMs = allGridViewModels
        var newVMs = [ByteviewUser: InMeetGridCellViewModel]()
        var hasInsertion = false
        for p in participants {
            if let vm = removedVMs.removeValue(forKey: p.user) {
                newVMs[p.user] = vm
            } else {
                hasInsertion = true
                newVMs[p.user] = self.createGridCellViewModel(participant: p)
            }
        }
        for vm in removedVMs {
            if vm.key == meeting.account {
                newVMs[vm.key] = vm.value
            } else {
                vm.value.isRemoved.accept(true)
            }
        }
        if hasInsertion || !removedVMs.isEmpty {
            allGridViewModels = newVMs
        }
    }

    func handleParticipantChange(removeParticipants: [Participant], upsertParticipants: [Participant]) {
        let beforeCount = allGridViewModels.count
        var vms = allGridViewModels
        var hasInsertion = false
        var hasDeletion = false
        for p in removeParticipants where p.user != meeting.account {
            if let vm = vms.removeValue(forKey: p.user) {
                hasDeletion = true
                vm.isRemoved.accept(true)
            }
        }
        for p in upsertParticipants {
            if let vm = vms[p.user] {
                vm.updateParticipant(participant: p)
            } else if p.status == .onTheCall,
                      !p.user.deviceId.isEmpty,
                      let vm = vms.removeValue(forKey: ByteviewUser(id: p.user.id, type: p.user.type, deviceId: "")) {
                hasDeletion = true
                vm.isRemoved.accept(true)

                hasInsertion = true
                vms[p.user] = createGridCellViewModel(participant: p)
            } else {
                hasInsertion = true
                vms[p.user] = createGridCellViewModel(participant: p)
            }
        }
        if hasInsertion || hasDeletion {
            allGridViewModels = vms
            Self.logger.info("GridData upsert: \(upsertParticipants.count), remove: \(removeParticipants.count), \(beforeCount) --> \(allGridViewModels.count)")
        }
    }
}

extension InMeetGridParticipantStore: InMeetActiveSpeakerListener {
    func didChangeActiveSpeaker(_ rtcUid: RtcUID?, oldValue: RtcUID?) {
        updateActiveSpeakerQueue(rtcUid)
        correctActiveSpeakerQueue()
        cellViewModelDependency.activeSpeakerSdkUidRelay.accept(rtcUid)
        listeners.forEach { $0.activeSpeakerInfoDidChange(asInfos: activeSpeakerQueue, currentActiveSpeaker: activeSpeakerIdentifier) }
    }
}


extension InMeetGridParticipantStore: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .containerLayoutStyle, let style = userInfo as? MeetingLayoutStyle {
            cellViewModelDependency.meetingLayoutStyleRelay.accept(style)
        }
    }
}

extension InMeetGridParticipantStore: InMeetDataListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        cellViewModelDependency.inMeetInfoRelay.accept(inMeetingInfo)
    }
}

extension InMeetGridParticipantStore: InMeetRtcNetworkListener {
    func onUserConnected() {
        if !cellViewModelDependency.isConnectedRelay.value {
            cellViewModelDependency.isConnectedRelay.accept(true)
        }
    }

    func didChangeRemoteNetworkStatus(_ status: [RtcUID: RtcNetworkStatus], upsertValues: [RtcUID: RtcNetworkStatus],
                                      removedValues: [RtcUID: RtcNetworkStatus], reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        cellViewModelDependency.rtcNetworkStatusRelay.accept(status)
    }
}

extension InMeetGridParticipantStore: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasCohostAuthority {
            cellViewModelDependency.hasHostAuthority.accept(isOn)
        }
    }
}
