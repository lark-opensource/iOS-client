//
//  ParticipantAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

protocol ParticipantAction: ParticipantActionComponent {
    var type: ParticipantActionType { get }
    var title: String { get }
    var color: UIColor { get }
    var icon: UIImage? { get }
    var show: Bool { get }
    func didTap(end: @escaping (Dictionary<String, Any>?) -> Void)
}

class BaseParticipantAction: ParticipantAction {
    private lazy var logDescription = metadataDescription(of: self)
    let id: ParticipantActionType
    private let context: ParticipantActionContext
    weak var provider: ParticipantActionProvider?

    required init(resolver: ParticipantActionResolver, id: ParticipantActionType) {
        self.context = resolver.context
        self.provider = resolver.provider
        self.id = id
        Logger.ui.info("init action: \(logDescription)")
    }

    deinit {
        Logger.ui.info("deinit action: \(logDescription)")
    }

    final var type: ParticipantActionType { id }
    final func didTap(end: @escaping (Dictionary<String, Any>?) -> Void) { action(end) }

    /// ---- override point for subclass. Do not call directly ----
    var title: String { fatalError("title must be overridden") }
    var color: UIColor { .ud.textTitle }
    var icon: UIImage? { nil }
    var show: Bool { true }
    func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) { end(nil) }
}

extension BaseParticipantAction {
    var meeting: InMeetMeeting { context.meeting }
    var inMeetContext: InMeetViewContext { context.inMeetContext }
    var participant: Participant { context.participant }
    var lobbyParticipant: LobbyParticipant? { context.lobbyParticipant }
    var userInfo: ParticipantActionUserInfo { context.userInfo }
    var source: ParticipantActionSource { context.source }
    var isSelf: Bool { participant.user == meeting.account }

    var canCancelInvite: Bool {
        participant.status == .ringing && (participant.inviter?.id == meeting.userId || meeting.setting.canCancelInvite)
    }

    var showManageLocalRecord: Bool {
        !isSelf && !canCancelInvite && meeting.setting.hasCohostAuthority && meeting.setting.isLocalRecordEnabled && participant.isLocalRecordHandsUp && !source.fromGrid
    }

    func muteUserMicrophone(_ muted: Bool) {
        let action: HostManageAction = participant.meetingRole == .webinarAttendee ? .webinarMuteAttendeeMicrophone : .muteMicrophone
        var request = HostManageRequest(action: action, meetingId: meeting.meetingId)
        request.participantId = participant.user
        request.isMuted = muted
        meeting.httpClient.send(request)
    }
}
