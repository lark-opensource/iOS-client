//
//  ParticipantLobbyAdmitAction.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/6/20.
//
import Foundation
import ByteViewNetwork

class ParticipantLobbyAdmitAction: BaseParticipantAction {

    override var title: String { I18n.View_M_AdmitButton }

    override var color: UIColor { .ud.textTitle }

    override var show: Bool { true }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        guard let lobbyParticipant = lobbyParticipant else { return }
        self.admitInLobby(lobbyParticipant)
        end(nil)
    }
}

extension ParticipantLobbyAdmitAction {
    private func admitInLobby(_ lobbyParticipant: LobbyParticipant) {
        guard !lobbyParticipant.isInApproval else { return }
        let request = VCManageApprovalRequest(meetingId: meeting.meetingId,
                                              breakoutRoomId: meeting.setting.breakoutRoomId,
                                              approvalType: .meetinglobby,
                                              approvalAction: .pass,
                                              users: [lobbyParticipant.user])
        meeting.httpClient.send(request)
    }
}
