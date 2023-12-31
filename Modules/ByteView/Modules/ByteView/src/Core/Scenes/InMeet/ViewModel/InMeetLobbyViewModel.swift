//
//  InMeetLobbyViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/4/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting
import ByteViewSetting

struct LobbyAttention {
    enum State: Equatable {
        case none
        case participant(LobbyParticipant, name: String)
        case participants(count: Int, onlyAttendee: Bool)
    }
    var state: State
    var sid: Int
    init(state: State = .none, sid: Int = 0) {
        self.state = state
        self.sid = sid
    }
}

protocol InMeetLobbyViewModelObserver: AnyObject {
    func shouldShowLobbyAttention(_ attention: LobbyAttention)
    func shouldShowLobbyRedTip(_ count: Int)
    /// 这里的participants是被hostAuthority过滤后的lobby
    func didChangeLobbyParticipants(_ participants: [LobbyParticipant])
}

final class InMeetLobbyViewModel: MeetingSettingListener, FullLobbyParticipantsPushObserver, VCManageNotifyPushObserver, VCManageResultPushObserver {
    let meeting: InMeetMeeting
    /// 原始lobby，没啥用，端上只用被hostAuthority过滤后的lobby
    @RwAtomic private var allParticipants: [LobbyParticipant] = []
    /// 被hostAuthority过滤后的lobby
    @RwAtomic private(set) var participants: [LobbyParticipant] = []
    private(set) var attention = LobbyAttention()
    private(set) var redTipCount = 0
    private var shouldShowAttention = false
    private var shouldShowRedTip = false
    /// 保序
    private var executingSid: Int = 0
    var httpClient: HttpClient { meeting.httpClient }
    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        meeting.setting.addListener(self, for: .canOperateLobbyParticipant)
        if let nameStrategy = meeting.participant.nameStrategy {
            addObserver(nameStrategy)
        }
        meeting.push.fullLobby.addObserver(self)
        meeting.push.vcManageNotify.addObserver(self)
        meeting.push.vcManageResult.addObserver(self)
        resolver.viewContext.addListener(self, for: [.participantsDidAppear, .participantsDidDisappear])
    }

    private let observers = Listeners<InMeetLobbyViewModelObserver>()
    func addObserver(_ observer: InMeetLobbyViewModelObserver, fireImmediately: Bool = true) {
        observers.addListener(observer)
        if fireImmediately {
            if redTipCount > 0 {
                observer.shouldShowLobbyRedTip(redTipCount)
            }
            if !participants.isEmpty {
                observer.didChangeLobbyParticipants(participants)
            }
        }
    }

    func removeObserver(_ observer: InMeetLobbyViewModelObserver) {
        observers.removeListener(observer)
    }

    private var isParticipantsViewAppeared = false {
        didSet {
            if oldValue != isParticipantsViewAppeared {
                didChangeParticipantsAppear()
            }
        }
    }

    func admitUsersInLobby(_ users: [ByteviewUser], completion: ((Result<Void, Error>) -> Void)?) {
        let request = VCManageApprovalRequest(meetingId: meeting.meetingId, breakoutRoomId: meeting.setting.breakoutRoomId,
                                              approvalType: .meetinglobby, approvalAction: .pass, users: users)
        httpClient.send(request, completion: completion)
    }

    /// 举手attention被用户点掉(展示过又消失)
    func closeAttention() {
        attention.state = .none
        shouldShowAttention = false
    }

    private func showMoveToLobbyToast(_ participant: LobbyParticipant) {
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pids: [participant, participant.moveOperator], meetingId: meeting.meetingId) { aps in
            if let target = aps.first, let `operator` = aps.last {
                if `operator`.pid?.deviceId == self.meeting.account.deviceId {
                    Toast.showOnVCScene(I18n.View_G_MovedNameIntoLobby(target.name))
                } else {
                    Toast.showOnVCScene(I18n.View_G_HostMovedNameLobby(`operator`.name, target.name))
                }
            }
        }
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        updateParticipants(allParticipants)
    }

    func didReceiveManageResult(_ result: VCManageResult) {
        guard result.meetingID == meeting.meetingId, result.type == .meetinglobby, result.action == .moveToLobby, let participant = result.vcLobbyParticipant, participant.user.id == meeting.userId else { return }
        Logger.meeting.info("did receive move self to lobby: \(participant)")
        meeting.router.setWindowFloating(false)
        meeting.beMovedToLobby(participant)
    }

    func didReceiveFullLobbyParticipants(meetingId: String, participants: [LobbyParticipant]) {
        if meetingId == meeting.meetingId {
            let full = participants
            Logger.meeting.info("\(meeting) didReceiveFullLobbyParticipants: count = \(full.count)")
            update(full, incoming: full)
        }
    }

    func didReceiveManageNotify(_ notify: VCManageNotify) {
        let change = notify.lobbyParticipants
        guard notify.meetingID == meeting.meetingId, notify.notificationType == .meetinglobby, !change.isEmpty else {
            return
        }
        Logger.meeting.info("\(meeting) didReceiveLobbyParticipantChange: \(change)")

        // 会中被移入等候室
        if let moveToLobby = change.first(where: { $0.joinReason == .hostMove && $0.isStatusWait && !$0.isInApproval }) {
            showMoveToLobbyToast(moveToLobby)
        }

        // 增加或者更新/移除
        // 当前找出不在notify中的
        let changedIdentifiers = Set(change.map { $0.identifier })
        let left = allParticipants.filter { !changedIdentifiers.contains($0.identifier) }
        let incoming = change.filter { $0.isStatusWait }
        let full = (left + incoming).sorted { $0.joinLobbyTime < $1.joinLobbyTime }
        return update(full, incoming: incoming)
    }

    private func update(_ full: [LobbyParticipant], incoming: [LobbyParticipant]) {
        if full == self.allParticipants { return }
        let currentIdentifiers = Set(allParticipants.map { $0.identifier })
        let isParticipantIncreased = incoming.contains(where: { !currentIdentifiers.contains($0.identifier) })
        if isParticipantIncreased && !isParticipantsViewAppeared {
            if !incoming.contains(where: { $0.joinReason != .hostMove }), attention.state == .none {
                // 会中被移入等候室，仅当attention正在展示时，提示人数变动，否则不提示
                shouldShowAttention = false
            } else {
                shouldShowAttention = true
            }
            shouldShowRedTip = true
        }
        self.allParticipants = full
        updateParticipants(full, forceUpdateTips: isParticipantIncreased)
    }

    private func updateParticipants(_ participants: [LobbyParticipant], forceUpdateTips: Bool = false) {
        let waiting = meeting.setting.canOperateLobbyParticipant ? participants.filter { !$0.isInApproval } : []
        let isChanged = waiting != self.participants
        if isChanged {
            self.participants = waiting
            observers.forEach { $0.didChangeLobbyParticipants(waiting) }
        }
        if !isParticipantsViewAppeared, forceUpdateTips || isChanged {
            updateTips()
        }
    }

    private func updateTips() {
        executingSid += 1
        if shouldShowAttention {
            if participants.count > 1 {
                let onlyAttendee = !participants.contains(where: { $0.participantMeetingRole != .webinarAttendee })
                updateAttention(.participants(count: participants.count, onlyAttendee: onlyAttendee), sid: executingSid)
            } else if let first = participants.first {
                let user = first.user
                let isLarkGuest = first.isLarkGuest
                let sid = executingSid
                let participantService = meeting.httpClient.participantService
                participantService.participantInfo(pid: user, meetingId: meeting.meetingId) { [weak self] (ap) in
                    guard let self = self else { return }
                    var name = ap.name
                    if isLarkGuest {
                        if self.meeting.info.meetingSource == .vcFromInterview {
                            name += I18n.View_G_CandidateBracket
                        } else {
                            name += I18n.View_M_GuestParentheses
                        }
                    }
                    self.updateAttention(.participant(first, name: name), sid: sid)
                }
            } else {
                updateAttention(.none, sid: executingSid)
            }
        } else {
            updateAttention(.none, sid: executingSid)
        }
        if shouldShowRedTip {
            updateRedTip(participants.count)
        }
    }

    private func didChangeParticipantsAppear() {
        if isParticipantsViewAppeared {
            closeAttention()
            executingSid += 1
            updateAttention(.none, sid: executingSid)
            updateRedTip(0)
        }
    }

    private func updateAttention(_ state: LobbyAttention.State, sid: Int) {
        guard sid > attention.sid else {
            // 丢弃旧数据
            return
        }
        attention.state = state
        attention.sid = sid
        observers.forEach { $0.shouldShowLobbyAttention(attention) }

        // 等候室变更（仅主持人/联席主持人）
        let number: Int
        switch attention.state {
        case .participant:
            number = 1
        case .participants(let count, _):
            number = count
        default:
            number = 0
        }
        Logger.meeting.info("Receive participant request: lobby: \(number)")
    }

    private func updateRedTip(_ count: Int) {
        self.redTipCount = count
        observers.forEach { $0.shouldShowLobbyRedTip(count) }
    }
}

extension InMeetLobbyViewModelObserver {
    func shouldShowLobbyAttention(_ attention: LobbyAttention) {}
    func shouldShowLobbyRedTip(_ count: Int) {}
    func didChangeLobbyParticipants(_ participants: [LobbyParticipant]) {}
}


extension InMeetLobbyViewModel: InMeetViewChangeListener {
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
