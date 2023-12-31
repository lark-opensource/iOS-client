//
//  InvitedParticipantCellModel+Construction.swift
//  Logger
//
//  Created by wulv on 2022/2/28.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon
import ByteViewSetting

extension Participant {

    /// 是否有呼叫反馈
    var hasInviteFeedback: Bool {
        status == .idle && inviteFeedback != nil
    }

    /// 呼叫反馈文案
    var inviteFeedback: String? {
        switch offlineReason {
        case .refuse:
            return I18n.View_G_Declined_Status
        case .ringTimeout:
            return I18n.View_G_NoAnswer_Status
        default: return nil
        }
    }

    /// 是否有拒绝回复
    func hasRefuseReply(inviterID: String) -> Bool {
        refuseReply(inviterID: inviterID) != nil
    }

    /// 拒绝回复文案
    func refuseReply(inviterID: String) -> String? {
        guard inviter?.id == inviterID else {
            return nil
        }
        guard status == .idle, offlineReason == .refuse, joinTime < refuseReplyTime else {
            return nil
        }

        guard let refuseReply = settings.refuseReply, !refuseReply.isEmpty else {
            return nil
        }
        return refuseReply
    }
}

// MARK: - Construction
extension InvitedParticipantCellModel {

    static func create(with participant: Participant,
                       userInfo: ParticipantUserInfo?,
                       meeting: InMeetMeeting,
                       hasCohostAuthority: Bool,
                       meetingSubType: MeetingSubType) -> InvitedParticipantCellModel {
        let isExternal = participant.isExternal(localParticipant: meeting.myself)

        // 头像
        let avatarInfo: AvatarInfo? = userInfo?.avatarInfo
        // 别名FG
        let enableAnotherName: Bool = meeting.setting.isShowAnotherNameEnabled
        // 昵称
        let displayName: String? = enableAnotherName ? userInfo?.user?.anotherName ?? userInfo?.originalName : userInfo?.originalName
        // 昵称小尾巴
        var nameTail: String?
        if participant.isLarkGuest {
            if meeting.isInterviewMeeting {
                nameTail = I18n.View_G_CandidateBracket
            } else {
                nameTail = I18n.View_M_GuestParentheses
            }
        }
        // 头像涟漪
        let playRipple: Bool = !participant.hasInviteFeedback
        // 是否是快捷电话邀请
        var isConveniencePSTN: Bool = false
        if participant.type == .pstnUser, let pstn = participant.pstnInfo, ConveniencePSTN.isConvenience(pstn) {
            isConveniencePSTN = true
        }
        // 设备标识
        var deviceImg: ParticipantImgKey = .empty
        if isConveniencePSTN {
            deviceImg = .conveniencePstn
        }
        // 呼叫反馈
        let inviteFeedback: String? = participant.hasInviteFeedback ? participant.inviteFeedback : nil
        // 用户标签(外部)
        let userFlag: UserFlagType = isExternal ? .external : .none
        // 「转为电话呼叫」按钮
        let convertPSTNStyle = constructConvertPSTNStyle(localParticipant: meeting.myself, featureManager: meeting.setting, participant: participant, meetingTenantId: meeting.info.tenantId, meetingSubType: meetingSubType)
        // 「取消」按钮
        let showCancel = !participant.hasInviteFeedback && (participant.inviter == meeting.account || hasCohostAuthority)
        let cancelStyle: ParticipantButton.Style = showCancel ? .cancel : .none
        // webinar 不显示拒绝回复
        let inviterID = meeting.account.id
        let refuseReply: String? = meetingSubType != .webinar ? participant.refuseReply(inviterID: inviterID) : nil

        let model = InvitedParticipantCellModel(avatarInfo: avatarInfo,
                                                displayName: displayName,
                                                nameTail: nameTail,
                                                playRipple: playRipple,
                                                deviceImg: deviceImg,
                                                inviteFeedback: inviteFeedback,
                                                refuseReply: refuseReply,
                                                userFlag: userFlag,
                                                room: "",
                                                convertPSTNStyle: convertPSTNStyle,
                                                cancelStyle: cancelStyle,
                                                participant: participant,
                                                isConveniencePSTN: isConveniencePSTN,
                                                enableAnotherName: enableAnotherName,
                                                service: meeting.service)
        return model
    }
}

// MARK: - private
extension InvitedParticipantCellModel {

    /// 转为电话呼叫
    private static func constructConvertPSTNStyle(localParticipant: Participant, featureManager: MeetingSettingManager, participant: Participant, meetingTenantId: String?, meetingSubType: MeetingSubType) -> ParticipantButton.Style {
        guard !participant.hasInviteFeedback else { return .none }
        var enableInvitePSTN: Bool = false
        let canOperate = participant.inviter == localParticipant.user || featureManager.hasCohostAuthority
        if canOperate {
            enableInvitePSTN = ConveniencePSTN.enableInviteParticipant(participant, local: localParticipant,
                                                                       featureManager: featureManager, meetingTenantId: meetingTenantId, meetingSubType: meetingSubType)
        }
        let convertPSTNStyle: ParticipantButton.Style = enableInvitePSTN ? .convertPstn : .none
        return convertPSTNStyle
    }
}

// MARK: - public
extension InvitedParticipantCellModel {
    /// 拉取昵称、头像等详细信息
    func getDetailInfo(_ callback: @escaping (() -> Void)) {
        if avatarInfo != nil, displayName != nil {
            callback()
            return
        }
        httpClient.participantService.participantInfo(pid: participant, meetingId: participant.meetingId) { userInfo in
            // 该回调在主线程
            guard userInfo.pid == self.participant.participantId else { return } // 避免重用
            // 头像
            let avatarInfo: AvatarInfo = userInfo.avatarInfo
            self.avatarInfo = avatarInfo
            // 昵称
            let displayName: String = self.enableAnotherName ? userInfo.user?.anotherName ?? userInfo.originalName : userInfo.originalName
            self.displayName = displayName
            callback()
        }
    }
}
