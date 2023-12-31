//
//  ParticipantLobbyRemoveAction.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/6/20.
//

import Foundation
import ByteViewUI
import ByteViewNetwork

class ParticipantLobbyRemoveAction: BaseParticipantAction {

    override var title: String { I18n.View_M_RemoveButton }

    override var color: UIColor { .ud.textTitle }

    override var show: Bool { true }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        guard let lobbyParticipant = lobbyParticipant else { return }
        BreakoutRoomTracksV2.removeLobby(self.meeting)
        LobbyTracks.trackRemovedWaitingParticipantOfLobby(userID: lobbyParticipant.user.id,
                                                          deviceID: lobbyParticipant.user.deviceId,
                                                          isSearch: true,
                                                          meeting: self.meeting)
        ParticipantTracks.trackCoreManipulation(isSelf: false,
                                                description: "lobby - " + I18n.View_M_RemoveButton,
                                                uid: lobbyParticipant.user.id,
                                                did: lobbyParticipant.user.deviceId)
        ByteViewDialog.Builder()
            .title(I18n.View_M_RemoveParticipantFromLobby(userInfo.display))
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler { _ in end(nil) }
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak self] _ in
                guard let self = self else { return }
                let request = VCManageApprovalRequest(meetingId: self.meeting.meetingId,
                                                      breakoutRoomId: self.meeting.setting.breakoutRoomId,
                                                      approvalType: .meetinglobby,
                                                      approvalAction: .reject,
                                                      users: [lobbyParticipant.user])
                self.meeting.httpClient.send(request)
                end(["action": "confirm"])
            })
            .needAutoDismiss(true)
            .show()
    }
}
