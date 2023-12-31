//
//  InMeetHandsUpViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/4/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewSetting

enum HandsUpType {
    case mic
    case camera
    case localRecord

    var desc: String {
        switch self {
        case .mic: return "mic"
        case .camera: return "camera"
        case .localRecord: return "localRecord"
        }
    }

    var trackContent: String {
        switch self {
        case .mic: return "microphone_application"
        case .camera: return "camera_application"
        case .localRecord: return ThemeAlertTrackerV2.ThemeAlertContent.recordRequestConfirm.rawValue
        }
    }
}

enum HandsUpAttention: Equatable {
    case none
    case participant(Participant, String)
    case participants(Int)
}

protocol InMeetHandsUpViewModelObserver: AnyObject {
    func shouldShowHandsUpAttention(_ attention: HandsUpAttention, handsupType: HandsUpType)
    func shouldShowHandsUpRedTip(_ count: Int)
}

class HandsUpData {
    var participants: [Participant] = []
    var attention: HandsUpAttention = .none
    var shouldShow = false
}

final class InMeetHandsUpViewModel: InMeetDataListener, MeetingSettingListener, InMeetParticipantListener {
    let meeting: InMeetMeeting
    private(set) var micHandsUpData = HandsUpData()
    private(set) var cameraHandsUpData = HandsUpData()
    private(set) var localRecordHandsUpData = HandsUpData()
    private(set) var redTipCount = 0
    private var shouldShowRedTip = false
    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
        meeting.setting.addListener(self, for: .hasCohostAuthority)
        resolver.viewContext.addListener(self, for: [.participantsDidAppear, .participantsDidDisappear])
    }

    private let observers = Listeners<InMeetHandsUpViewModelObserver>()
    func addObserver(_ observer: InMeetHandsUpViewModelObserver, fireImmediately: Bool = true) {
        observers.addListener(observer)
        if fireImmediately {
            if redTipCount > 0 {
                observer.shouldShowHandsUpRedTip(redTipCount)
            }
        }
    }

    func removeObserver(_ observer: InMeetHandsUpViewModelObserver) {
        observers.removeListener(observer)
    }

    private var isParticipantsViewAppeared = false {
        didSet {
            if oldValue != isParticipantsViewAppeared {
                didChangeParticipantsAppear()
            }
        }
    }

    /// 举手attention被用户点掉(展示过又消失)
    func closeAttention(handsupType: HandsUpType) {
        let data: HandsUpData
        switch handsupType {
        case .mic:
            data = micHandsUpData
        case .camera:
            data = cameraHandsUpData
        case .localRecord:
            data = localRecordHandsUpData
        }
        data.attention = .none
        data.shouldShow = false
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasCohostAuthority {
            if isOn {
                let ps = meeting.participant.currentRoom.nonRingingDict.map(\.value)
                updateHandsUpParticipants(ps.micHandsUp, ps.cameraHandsUp, ps.localRecordHandsUp)
            } else {
                updateHandsUpParticipants([], [], [])
            }
        }
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        var isMicRemoved: Bool = false
        var isCameraRemoved: Bool = false
        var isLocalRecordRemoved: Bool = false
        let ifRemoved: (inout Bool, Bool) -> Void = { isRemoved, result in
            guard isRemoved == false else { return }
            if result { isRemoved = true }
        }
        output.modify.nonRinging.removes.forEach {
            ifRemoved(&isMicRemoved, $0.value.isMicHandsUp)
            ifRemoved(&isCameraRemoved, $0.value.isCameraHandsUp)
            ifRemoved(&isLocalRecordRemoved, $0.value.isLocalRecordHandsUp)
        }

        var isMicIncreased: Bool = false
        var isCameraIncreased: Bool = false
        var isLocalRecordIncreased: Bool = false
        let ifIncreased: (inout Bool, Participant, Dictionary<ByteviewUser, Participant>, (Participant) -> Bool) -> Void = { (isIncreased, p, oldDict, condition) in
            guard isIncreased == false else { return }
            if condition(p) {
                if let old = oldDict[p.user], !condition(old) {
                    isIncreased = true
                } else {
                    isIncreased = true
                }
            }
        }
        let dict = output.oldData.nonRingingDict
        output.modify.nonRinging.inserts.forEach {
            ifIncreased(&isMicIncreased, $0.value, dict) { $0.isMicHandsUp }
            ifIncreased(&isCameraIncreased, $0.value, dict) { $0.isCameraHandsUp }
            ifIncreased(&isLocalRecordIncreased, $0.value, dict) { $0.isLocalRecordHandsUp }
        }

        let ifRemovedByUpdate: (inout Bool, Participant, Dictionary<ByteviewUser, Participant>, (Participant) -> Bool) -> Void = { (isRemoved, p, old, condition) in
            if !isRemoved, !condition(p), let oldp = old[p.user], condition(oldp) {
                isRemoved = true
            }
        }
        output.modify.nonRinging.updates.forEach {
            ifIncreased(&isMicIncreased, $0.value, dict) { $0.isMicHandsUp }
            ifIncreased(&isCameraIncreased, $0.value, dict) { $0.isCameraHandsUp }
            ifIncreased(&isLocalRecordIncreased, $0.value, dict) { $0.isLocalRecordHandsUp }

            ifRemovedByUpdate(&isMicRemoved, $0.value, dict) { $0.isMicHandsUp }
            ifRemovedByUpdate(&isCameraRemoved, $0.value, dict) { $0.isCameraHandsUp }
            ifRemovedByUpdate(&isLocalRecordRemoved, $0.value, dict) { $0.isLocalRecordHandsUp }
        }
        let hasCohostAuthority = meeting.setting.hasCohostAuthority
        let ps = output.newData.nonRingingDict.map(\.value)
        let micHandsup = hasCohostAuthority ? ps.micHandsUp : []
        let cameraHandsup = hasCohostAuthority ? ps.cameraHandsUp : []
        let localRecordHandsup = hasCohostAuthority ? ps.localRecordHandsUp : []
        updateHandsUpParticipants(micHandsup, isMicIncreased: isMicIncreased, isMicChanged: isMicIncreased || isMicRemoved,
                                  cameraHandsup, isCameraIncreased: isCameraIncreased, isCameraChanged: isCameraIncreased || isCameraRemoved,
                                  localRecordHandsup, isLocalRecordIncreased: isLocalRecordIncreased, isLocalRecordChanged: isLocalRecordIncreased || isLocalRecordRemoved)
    }

    private func updateHandsUpParticipants(_ micHandsup: [Participant], isMicIncreased: Bool = false, isMicChanged: Bool = true,
                                           _ cameraHandsup: [Participant], isCameraIncreased: Bool = false, isCameraChanged: Bool = true,
                                           _ localRecordHandsup: [Participant], isLocalRecordIncreased: Bool = false, isLocalRecordChanged: Bool = true) {
        if !isParticipantsViewAppeared, isMicIncreased, !micHandsUpData.shouldShow {
            micHandsUpData.shouldShow = true
            shouldShowRedTip = true
        }
        if isMicChanged {
            micHandsUpData.participants = micHandsup
        }

        if !isParticipantsViewAppeared, isCameraIncreased, !cameraHandsUpData.shouldShow {
            cameraHandsUpData.shouldShow = true
            shouldShowRedTip = true
        }
        if isCameraChanged {
            cameraHandsUpData.participants = cameraHandsup
        }

        if !isParticipantsViewAppeared, isLocalRecordIncreased, !localRecordHandsUpData.shouldShow {
            localRecordHandsUpData.shouldShow = true
            shouldShowRedTip = true
        }
        if isLocalRecordChanged {
            localRecordHandsUpData.participants = localRecordHandsup
        }

        if !isParticipantsViewAppeared {
            var types: [HandsUpType] = []
            if isMicIncreased { types.append(.mic) }
            if isCameraIncreased { types.append(.camera) }
            if isLocalRecordIncreased { types.append(.localRecord) }
            if isMicChanged, !types.contains(.mic) { types.insert(.mic, at: 0) }
            if isCameraChanged, !types.contains(.camera) { types.insert(.camera, at: 0) }
            if isLocalRecordChanged, !types.contains(.localRecord) { types.insert(.localRecord, at: 0) }
            types.forEach { handleHandsup($0) }
            updateTips()
        }
    }

    private func updateTips() {
        if shouldShowRedTip {
            let set: Set<String> = Set(
                cameraHandsUpData.participants.map { $0.identifier } +
                micHandsUpData.participants.map { $0.identifier } +
                localRecordHandsUpData.participants.map { $0.identifier }
            )
            updateRedTip(set.count)
        }
    }

    private func handleHandsup(_ type: HandsUpType) {
        let data: HandsUpData
        switch type {
        case .mic:
            data = micHandsUpData
        case .camera:
            data = cameraHandsUpData
        case .localRecord:
            data = localRecordHandsUpData
        }
        if data.shouldShow {
            // 没有被关闭过，或者有新增
            if data.participants.count > 1 {
                updateAttention(.participants(data.participants.count), handsupType: type)
            } else if let first = data.participants.first {
                let participantService = meeting.httpClient.participantService
                participantService.participantInfo(pid: first, meetingId: meeting.meetingId) { [weak self] (ap) in
                    self?.updateAttention(.participant(first, ap.name), handsupType: type)
                }
            } else {
                updateAttention(.none, handsupType: type)
            }
        }
    }

    private func didChangeParticipantsAppear() {
        if isParticipantsViewAppeared {
            updateAttention(.none, handsupType: .mic)
            updateAttention(.none, handsupType: .camera)
            updateAttention(.none, handsupType: .localRecord)
            updateRedTip(0)
        }
    }

    private func updateAttention(_ attention: HandsUpAttention, handsupType: HandsUpType) {
        switch handsupType {
        case .mic:
            micHandsUpData.attention = attention
        case .camera:
            cameraHandsUpData.attention = attention
        case .localRecord:
            localRecordHandsUpData.attention = attention
        }
        observers.forEach { $0.shouldShowHandsUpAttention(attention, handsupType: handsupType) }

        // 参会人举手（仅主持人/联席主持人）
        let number: Int
        switch attention {
        case .participant:
            number = 1
        case .participants(let count):
            number = count
        default:
            number = 0
        }
        Logger.meeting.info("Receive participant request: \(handsupType.desc) handsUp: \(number)")
    }

    private func updateRedTip(_ count: Int) {
        self.redTipCount = count
        observers.forEach { $0.shouldShowHandsUpRedTip(count) }
    }

    func passHandsUpOfParticipant(_ participant: Participant, handsupType: HandsUpType, completion: ((Result<Void, Error>) -> Void)?) {
        let request: NetworkRequest
        switch handsupType {
        case .mic, .camera:
            request = VCManageApprovalRequest(meetingId: meeting.meetingId, breakoutRoomId: meeting.setting.breakoutRoomId,
                                              approvalType: handsupType == .mic ? .putUpHands : .putUpHandsInCam,
                                              approvalAction: .pass, users: [participant.user])
        case .localRecord:
            request = RecordMeetingRequest(meetingId: meeting.meetingId, action: .manageApproveLocalRecord, requester: meeting.account, targetParticipant: participant.user)
        }
        meeting.httpClient.send(request, completion: completion)
    }
}

extension InMeetHandsUpViewModelObserver {
    func shouldShowHandsUpAttention(_ attention: HandsUpAttention, handsupType: HandsUpType) {}
    func shouldShowHandsUpRedTip(_ count: Int) {}
}

extension InMeetHandsUpViewModel: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .participantsDidAppear:
            isParticipantsViewAppeared = true
        case .participantsDidDisappear:
            isParticipantsViewAppeared = false
        default:
            break
        }
    }
}
