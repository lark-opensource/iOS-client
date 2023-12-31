//
//  ParticipantCameraAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantCameraAction: BaseParticipantAction {

    override var title: String { cameraTitle }

    override var color: UIColor { (isSelf && Privacy.videoDenied) ? .ud.textDisabled : .ud.textTitle }

    override var icon: UIImage? { (isSelf && Privacy.videoDenied) ? ParticipantImageView.deniedImg : nil }

    override var show: Bool { showCamera }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        if isSelf {
            selfCameraAction()
        } else {
            otherCameraAction()
        }
        end(nil)
    }
}

extension ParticipantCameraAction {

    private var cameraTitle: String {
        if isSelf {
            return !Privacy.videoDenied ? (meeting.camera.isMuted ? I18n.View_VM_StartVideo : I18n.View_VM_StopVideo) : I18n.View_VM_AccessToCameraDenied
        }
        var title: String
        switch(participant.settings.isCameraMutedOrUnavailable, participant.isCameraHandsUp) {
        case (true, true):
            title = I18n.View_VM_StartVideo
        case (true, false):
            title = I18n.View_M_HostCameraRequest
        default:
            title = I18n.View_VM_StopVideo
        }
        return title
    }

    private var showCamera: Bool {
        if meeting.account == participant.user {
            return !meeting.isWebinarAttendee
        } else {
            if !canCancelInvite, meeting.setting.hasCohostAuthority, participant.type != .pstnUser, participant.meetingRole != .webinarAttendee {
                return true
            }
        }
        return false
    }

    private func selfCameraAction() {
        if !Privacy.videoDenied {
            ParticipantTracks.trackParticipantAction(meeting.camera.isMuted ? .openVideo : .stopVideo, isFromGridView: source.fromGrid, isSharing: meeting.shareData.isSharingContent)
            ParticipantTracks.trackEnableCamera(enabled: meeting.camera.isMuted, user: meeting.account, isSearch: source.isSearch)
            meeting.camera.muteMyself(!meeting.camera.isMuted, source: source.fromGrid ? .grid_action : .participant_action, completion: nil)
        } else {
            Privacy.requestCameraAccessAlert { _ in }
        }
    }

    private func otherCameraAction() {
        let isCameraMuted = participant.settings.isCameraMutedOrUnavailable
        let isHandsUp = participant.isCameraHandsUp
        ParticipantTracks.trackParticipantAction(isCameraMuted ? .openVideo : .stopVideo,
                                                 isFromGridView: source.fromGrid,
                                                 isSharing: meeting.shareData.isSharingContent)
        ParticipantTracks.trackEnableCamera(enabled: isCameraMuted, user: participant.user, isSearch: source.isSearch)
        if isCameraMuted {
            if isHandsUp {
                let request = VCManageApprovalRequest(meetingId: meeting.meetingId,
                                                      breakoutRoomId: meeting.setting.breakoutRoomId,
                                                      approvalType: .putUpHandsInCam,
                                                      approvalAction: .pass, users: [participant.user])
                meeting.httpClient.send(request)
            } else {
                provider?.toast(I18n.View_G_RequestSent)
                muteUserCamera(false)
            }
        } else {
            if isHandsUp {
                // 容错处理
                let request = VCManageApprovalRequest(meetingId: meeting.meetingId,
                                                      breakoutRoomId: meeting.setting.breakoutRoomId,
                                                      approvalType: .putUpHandsInCam,
                                                      approvalAction: .reject, users: [participant.user])
                meeting.httpClient.send(request)
            }
            muteUserCamera(true)
        }
        UserActionTracks.trackRequestCameraAction(isOn: isCameraMuted, targetUserID: participant.user.id, fromSource: source.fromGrid ? .grid : .participant_cell)
    }

    private func muteUserCamera(_ muted: Bool) {
        var request = HostManageRequest(action: .muteCamera, meetingId: meeting.meetingId)
        request.participantId = participant.user
        request.isMuted = muted
        meeting.httpClient.send(request)
    }
}
