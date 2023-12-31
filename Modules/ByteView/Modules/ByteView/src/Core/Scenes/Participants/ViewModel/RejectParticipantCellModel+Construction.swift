//
//  RejectParticipantCellModel+Construction.swift
//  ByteView
//
//  Created by wulv on 2022/5/23.
//

import Foundation
import ByteViewNetwork

// MARK: - Construction
extension RejectParticipantCellModel {

    static func create(with participant: Participant,
                       userInfo: ParticipantUserInfo,
                       meetingSubType: MeetingSubType,
                       meeting: InMeetMeeting) -> RejectParticipantCellModel {
        let isExternal = participant.isExternal(localParticipant: meeting.myself)

        // 头像
        let avatarInfo = userInfo.avatarInfo
        // 昵称
        let displayName = userInfo.originalName
        // 昵称小尾巴
        var nameTail: String?
        if participant.isLarkGuest {
            if meeting.isInterviewMeeting {
                nameTail = I18n.View_G_CandidateBracket
            } else {
                nameTail = I18n.View_M_GuestParentheses
            }
        }
        if participant.status == .idle, (participant.offlineReason == .kickOut || participant.offlineReason == .leave) {
            nameTail = nameTail ?? "" + " (\(I18n.View_M_LeftMeeting))"
        }
        // 个人状态
        let customStatuses = userInfo.user?.customStatuses ?? []
        // 用户标签(外部)
        let userFlag: UserFlagType = isExternal ? .external : .none
        // 是否允许快捷电话邀请
        let enableInvitePSTN = ConveniencePSTN.enableInviteParticipant(participant, local: meeting.myself,
                                                                       featureManager: meeting.setting, meetingTenantId: meeting.info.tenantId, meetingSubType: meetingSubType)
        // 按钮样式
        var buttonStyle: ParticipantButton.Style = .call
        if enableInvitePSTN {
            buttonStyle = .moreCall
        }

        let model = RejectParticipantCellModel(avatarInfo: avatarInfo,
                                               displayName: displayName,
                                               nameTail: nameTail,
                                               customStatuses: customStatuses,
                                               userFlag: userFlag,
                                               room: "",
                                               buttonStyle: buttonStyle,
                                               participant: participant,
                                               enableInvitePSTN: enableInvitePSTN,
                                               service: meeting.service)
        return model
    }
}

// MARK: - public
extension RejectParticipantCellModel {}
