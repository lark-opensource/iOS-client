//
//  ParticipantMicrophoneAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantMicrophoneAction: BaseParticipantAction {

    override var title: String { microphoneTitle }

    override var color: UIColor { (isSelf && Privacy.audioDenied) ? .ud.textDisabled : .ud.textTitle }

    override var icon: UIImage? { (isSelf && Privacy.audioDenied) ? ParticipantImageView.deniedImg : nil }

    override var show: Bool { showMicrophone }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        if isSelf {
            selfMicrophoneAction()
        } else if participant.meetingRole == .webinarAttendee {
            attendeeMicrophoneAction()
        } else {
            otherMicrophoneAction()
        }
        end(nil)
    }
}

extension ParticipantMicrophoneAction {

    private var showMicrophone: Bool {
        if isSelf {
            var show = true
            if meeting.isWebinarAttendee && meeting.microphone.isMuted {
                show = false
            } else if meeting.myself.settings.audioMode == .noConnect {
                show = false
            } else if meeting.audioModeManager.isPadMicSpeakerDisabled {
                show = false
            }
            return show
        }
        if !canCancelInvite, meeting.setting.hasCohostAuthority, (!meeting.isWebinarAttendee || participant.meetingRole == .webinarAttendee) {
            return true
        }
        return false
    }

    private func otherMicrophoneAction() {
        let isMicMuted = participant.settings.isMicrophoneMutedOrUnavailable
        let isHandsUp = participant.isMicHandsUp
        ParticipantTracks.trackParticipantAction(.participantMic(isOn: isMicMuted),
                                                 isFromGridView: source.fromGrid,
                                                 isSharing: meeting.shareData.isSharingContent)
        UserActionTracks.trackRequestMicAction(isOn: isMicMuted,
                                               targetUserID: participant.user.id,
                                               isHandsUp: isHandsUp,
                                               fromSource: source.fromGrid ? .grid : .participant_cell)
        if isMicMuted {
            if isHandsUp {
                let request = VCManageApprovalRequest(meetingId: meeting.meetingId,
                                                      breakoutRoomId: meeting.setting.breakoutRoomId,
                                                      approvalType: .putUpHands,
                                                      approvalAction: .pass, users: [participant.user])
                meeting.httpClient.send(request)
            } else {
                ParticipantTracks.trackEnableMic(enabled: isMicMuted,
                                                 user: participant.user,
                                                 isSearch: source.isSearch)
                if isMicMuted {
                    provider?.toast(I18n.View_G_RequestSent)
                }
                muteUserMicrophone(!isMicMuted)
            }
        } else {
            if isHandsUp {
                // 容错处理
                let request = VCManageApprovalRequest(meetingId: meeting.meetingId,
                                                      breakoutRoomId: meeting.setting.breakoutRoomId,
                                                      approvalType: .putUpHands,
                                                      approvalAction: .reject, users: [participant.user])
                meeting.httpClient.send(request)
            }
            ParticipantTracks.trackEnableMic(enabled: isMicMuted,
                                             user: participant.user,
                                             isSearch: source.isSearch)
            if isMicMuted {
                provider?.toast(I18n.View_G_RequestSent)
            }
            muteUserMicrophone(!isMicMuted)
        }
    }

    private func attendeeMicrophoneAction() {
        let isMicOff = participant.settings.isMicrophoneMutedOrUnavailable
        ParticipantTracks.trackEnableMic(enabled: isMicOff,
                                         user: participant.user,
                                         isSearch: source.isSearch)
        if isMicOff {
            provider?.toast(I18n.View_G_RequestSent)
        }
        muteUserMicrophone(!isMicOff)
    }

    private func selfMicrophoneAction() {
        if meeting.setting.isSystemPhoneCalling, meeting.audioMode == .internet {
            provider?.toast(I18n.View_MV_AnswerCallNoMic)
            return
        }
        if !Privacy.audioDenied {
            ParticipantTracks.trackParticipantAction(.participantMic(isOn: meeting.microphone.isMuted), isFromGridView: source.fromGrid, isSharing: meeting.shareData.isSharingContent)
            meeting.microphone.muteMyself(!meeting.microphone.isMuted, source: source.fromGrid ? .grid_action : .participant_action, completion: nil)
        } else {
            Privacy.requestMicrophoneAccessAlert { _ in }
        }
    }

    private var microphoneTitle: String {
        if isSelf {
            return !Privacy.audioDenied ? (meeting.microphone.isMuted ? I18n.View_M_Unmute : I18n.View_VM_Mute) : I18n.View_VM_AccessToMicDenied
        }

        if participant.meetingRole == .webinarAttendee {
            var title: String
            let isMicOff = participant.settings.isMicrophoneMutedOrUnavailable
            let isEmojiHandsUp = participant.settings.conditionEmojiInfo?.isHandsUp ?? false
            switch(isMicOff, isEmojiHandsUp) {
            case (true, true):
                title = I18n.View_G_AllowToSpeak
            case (true, false):
                title = I18n.View_G_RequestToSpeak_Button
            default:
                title = I18n.View_VM_Mute
            }
            return title
        }

        var title: String
        switch(participant.settings.isMicrophoneMutedOrUnavailable, participant.isMicHandsUp) {
        case (true, true):
            title = I18n.View_VM_TurnOnMic
        case (true, false):
            title = I18n.View_M_HostMicRequest
        default:
            title = I18n.View_VM_Mute
        }
        return title
    }
}
