//
//  SuggestionParticipantCellModel+Construction.swift
//  ByteView
//
//  Created by wulv on 2022/3/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon

// MARK: - Construction
extension SuggestionParticipantCellModel {

    static func create(with participant: Participant,
                       sip: CalendarInfo.CalendarRoom?,
                       preInterpreterIds: [String],
                       userInfo: ParticipantUserInfo?,
                       meetingSubType: MeetingSubType,
                       meeting: InMeetMeeting) -> SuggestionParticipantCellModel {
        // sip信息
        let sip: CalendarInfo.CalendarRoom? = sip
        // 头像
        var avatarInfo: AvatarInfo? = userInfo?.avatarInfo
        if let sip = sip {
            if !sip.avatarKey.isEmpty {
                avatarInfo = .remote(key: sip.avatarKey, entityId: sip.roomID)
            } else {
                avatarInfo = .sip
            }
        }
        // 别名FG
        let enableAnotherName: Bool = meeting.setting.isShowAnotherNameEnabled
        // 昵称
        var displayName: String? = enableAnotherName ? userInfo?.user?.anotherName ?? userInfo?.originalName : userInfo?.originalName
        if let sip = sip {
            displayName = sip.fullNameParticipant
        }
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
        // 是否使用主端个人状态组件
        let newStatusEnabled: Bool = meeting.setting.isNewStatusEnabled
        // 传译员标签
        var interpret: String?
        if preInterpreterIds.contains(participant.user.id) {
            interpret = I18n.View_G_InterpreterGreyTag
        }
        // 呼叫反馈
        let inviteFeedback: String? = participant.hasInviteFeedback ? participant.inviteFeedback : nil
        // 当前用户（用于外部标签判断）
        let myself: Participant = meeting.myself
        // 用户标签(外部)
        let isExternal = participant.isExternal(localParticipant: myself)
        let userFlag: UserFlagType = isExternal ? .external : .none
        // 是否允许快捷电话邀请
        let meetingTenantId = meeting.info.tenantId
        let featureManager = meeting.setting
        let enableInvitePSTN = ConveniencePSTN.enableInviteParticipant(participant, local: myself,
                                                                       featureManager: featureManager, meetingTenantId: meetingTenantId, meetingSubType: meetingSubType)
        // 是否是快捷电话邀请
        var isConveniencePSTN: Bool = false
        if participant.type == .pstnUser, let pstn = participant.pstnInfo, ConveniencePSTN.isConvenience(pstn) {
            isConveniencePSTN = true
        }
        // 是否多选态，默认否
        let isMultiple = false
        // 多选态时，是否选中，默认否
        let isSelectd = false
        // 多选态时，是否可选，默认可
        let isEnabled = true
        // 按钮样式
        let buttonStyle: ParticipantButton.Style = isConveniencePSTN ? .phoneCall : (enableInvitePSTN ? .moreCall : .call)
        // 高亮效果
        let selectionStyle: UITableViewCell.SelectionStyle = .none
        // webinar 不显示拒绝回复
        let inviterID = meeting.account.id
        let refuseReply: String? = meetingSubType != .webinar ? participant.refuseReply(inviterID: inviterID) : nil

        let model = SuggestionParticipantCellModel(selectionStyle: selectionStyle,
                                                   sip: sip,
                                                   avatarInfo: avatarInfo,
                                                   displayName: displayName,
                                                   nameTail: nameTail,
                                                   newStatusEnabled: newStatusEnabled,
                                                   customStatuses: userInfo?.user?.customStatuses ?? [],
                                                   inviteFeedback: inviteFeedback,
                                                   refuseReply: refuseReply,
                                                   interpret: interpret,
                                                   myself: myself,
                                                   userFlag: userFlag,
                                                   room: "",
                                                   buttonStyle: buttonStyle,
                                                   participant: participant,
                                                   sipRoom: sip,
                                                   enableInvitePSTN: enableInvitePSTN,
                                                   meetingTenantId: meetingTenantId,
                                                   meetingSubType: meetingSubType,
                                                   isConveniencePSTN: isConveniencePSTN,
                                                   isMultiple: isMultiple,
                                                   isSelected: isSelectd,
                                                   isEnabled: isEnabled,
                                                   enableAnotherName: enableAnotherName,
                                                   featureManager: meeting.setting,
                                                   service: meeting.service)
        return model
    }
}

// MARK: - public
extension SuggestionParticipantCellModel {

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
            var avatarInfo: AvatarInfo = userInfo.avatarInfo
            if let sip = self.sip {
                if !sip.avatarKey.isEmpty {
                    avatarInfo = .remote(key: sip.avatarKey, entityId: sip.roomID)
                } else {
                    avatarInfo = .sip
                }
            }
            self.avatarInfo = avatarInfo
            // 昵称
            var displayName: String = self.enableAnotherName ? userInfo.user?.anotherName ?? userInfo.originalName : userInfo.originalName
            if let sip = self.sip {
                displayName = sip.fullNameParticipant
            }
            self.displayName = displayName
            // 个人状态
            self.customStatuses = userInfo.user?.customStatuses ?? []
            // 用户标签(外部)
            if !userInfo.isUnknown { // 过滤拉取用户信息失败的情况
                // 建议列表的participant不会返回userTenantID，需要从ParticipantUserInfo里取
                self.participant.tenantId = userInfo.tenantId
            }
            let isExternal = self.participant.isExternal(localParticipant: self.myself)
            let userFlag: UserFlagType = isExternal ? .external : .none
            self.userFlag = userFlag
            // 是否允许快捷电话邀请
            self.enableInvitePSTN = ConveniencePSTN.enableInviteParticipant(self.participant, local: self.myself,
                                                                            featureManager: self.featureManager, meetingTenantId: self.meetingTenantId, meetingSubType: self.meetingSubType)
            // 按钮样式
            if !self.isMultiple {
                self.buttonStyle = self.isConveniencePSTN ? .phoneCall : (self.enableInvitePSTN ? .moreCall : .call)
            } else {
                self.buttonStyle = .none
            }
            callback()
        }
    }

    func updateMultiple(_ isMultiple: Bool) {
        guard isMultiple != self.isMultiple else { return }
        self.isMultiple = isMultiple

        if isMultiple {
            buttonStyle = .none
        } else {
            buttonStyle = isConveniencePSTN ? .phoneCall : (enableInvitePSTN ? .moreCall : .call)
        }
        // 切换时，清空上次选择
        isSelected = false
        isEnabled = true

        selectionStyle = isMultiple ? (isEnabled ? .default : .none) : .none
    }

    func updateSelected(_ isSelected: Bool) {
        guard isMultiple, self.isSelected != isSelected else { return }
        self.isSelected = isSelected
    }

    func updateEnabled(_ isEnabled: Bool) {
        guard isMultiple, self.isEnabled != isEnabled else { return }
        self.isEnabled = isEnabled
    }

    var uniqueId: String {
        if let address = participant.sipAddress {
            // sip的participant.id可能为0
            return address
        }
        if let address = participant.pstnAddress {
            // 相同mainAddress的pstn/sip，其uid可能不同，不能用uid做标识符
            return address
        }
        return participant.user.id
    }
}

extension Participant {
    var sipAddress: String? {
        if type == .sipUser, let pstnInfo = pstnInfo {
            if !pstnInfo.mainAddress.isEmpty {
                return pstnInfo.mainAddress
            }
        }
        return nil
    }

    var pstnAddress: String? {
        if type == .pstnUser, let pstnInfo = pstnInfo {
            if !pstnInfo.mainAddress.isEmpty {
                return pstnInfo.mainAddress
            }
        }
        return nil
    }
}
