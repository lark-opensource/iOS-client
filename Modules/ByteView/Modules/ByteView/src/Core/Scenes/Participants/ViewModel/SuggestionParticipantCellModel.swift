//
//  SuggestionParticipantCellModel.swift
//  ByteView
//
//  Created by wulv on 2022/2/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting

/// 个人状态类型
enum UserStatusType: Equatable {
    /// 无
    case none
    /// 图片
    case image(key: String)
    /// 外部控件
    case dependency(status: CustomStatus)
}

class SuggestionParticipantCellModel: BaseParticipantCellModel {

    /// 高亮效果
    var selectionStyle: UITableViewCell.SelectionStyle
    // sip信息
    let sip: CalendarInfo.CalendarRoom?
    // 是否使用主端个人状态组件
    let newStatusEnabled: Bool
    /// 个人状态
    var customStatuses: [CustomStatus]
    /// 呼叫反馈
    let inviteFeedback: String?
    /// 拒绝回复内容
    var refuseReply: String?
    /// 传译标签
    let interpret: String?
    // 当前用户（用于外部标签判断）
    let myself: Participant
    /// 外部标签
    var userFlag: UserFlagType
    /// 会议室地点
    let room: String?
    /// 按钮样式
    var buttonStyle: ParticipantButton.Style
    /// 参会人
    var participant: Participant
    /// sip（sip 入会前无 uid，participant.id 为 0, participant.pstnInfo.mainAddress 是唯一标识）
    let sipRoom: CalendarInfo.CalendarRoom?
    /// 是否允许快捷电话邀请
    var enableInvitePSTN: Bool
    /// 会议归属租户
    let meetingTenantId: String
    /// 会议子类型
    let meetingSubType: MeetingSubType
    /// 是否是快捷电话邀请
    let isConveniencePSTN: Bool
    /// 是否多选态
    var isMultiple: Bool
    /// 多选态时，是否选中
    var isSelected: Bool
    /// 多选态时，是否可选
    var isEnabled: Bool
    /// 是否有别名FG
    let enableAnotherName: Bool

    let featureManager: MeetingSettingManager

    var hasRefuseReply: Bool {
        guard let refuseReply = refuseReply else {
            return false
        }
        return !refuseReply.isEmpty
    }

    init(selectionStyle: UITableViewCell.SelectionStyle,
         sip: CalendarInfo.CalendarRoom?,
         avatarInfo: AvatarInfo?,
         displayName: String?,
         nameTail: String?,
         newStatusEnabled: Bool,
         customStatuses: [User.CustomStatus],
         inviteFeedback: String?,
         refuseReply: String?,
         interpret: String?,
         myself: Participant,
         userFlag: UserFlagType,
         room: String?,
         buttonStyle: ParticipantButton.Style,
         participant: Participant,
         sipRoom: CalendarInfo.CalendarRoom?,
         enableInvitePSTN: Bool,
         meetingTenantId: String,
         meetingSubType: MeetingSubType,
         isConveniencePSTN: Bool,
         isMultiple: Bool,
         isSelected: Bool,
         isEnabled: Bool,
         enableAnotherName: Bool,
         featureManager: MeetingSettingManager,
         service: MeetingBasicService
    ) {
        self.selectionStyle = selectionStyle
        self.sip = sip
        self.newStatusEnabled = newStatusEnabled
        self.customStatuses = customStatuses
        self.inviteFeedback = inviteFeedback
        self.refuseReply = refuseReply
        self.interpret = interpret
        self.myself = myself
        self.userFlag = userFlag
        self.room = room
        self.buttonStyle = buttonStyle
        self.participant = participant
        self.sipRoom = sipRoom
        self.enableInvitePSTN = enableInvitePSTN
        self.meetingTenantId = meetingTenantId
        self.meetingSubType = meetingSubType
        self.isConveniencePSTN = isConveniencePSTN
        self.isMultiple = isMultiple
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.enableAnotherName = enableAnotherName
        self.featureManager = featureManager
        super.init(avatarInfo: avatarInfo, showRedDot: false, displayName: displayName, nameTail: nameTail, pID: participant.user.id, service: service)
    }

    override func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        guard let subRhs = rhs as? SuggestionParticipantCellModel else { return false }
        return rhs.canEqual(self) && super.isEqual(rhs)
        && selectionStyle == subRhs.selectionStyle
        && sip == subRhs.sip
        && newStatusEnabled == subRhs.newStatusEnabled
        && customStatuses == subRhs.customStatuses
        && inviteFeedback == subRhs.inviteFeedback
        && interpret == subRhs.interpret
        && myself == subRhs.myself
        && userFlag == subRhs.userFlag
        && room == subRhs.room
        && buttonStyle == subRhs.buttonStyle
        && participant == subRhs.participant
        && sipRoom == subRhs.sipRoom
        && enableInvitePSTN == subRhs.enableInvitePSTN
        && meetingTenantId == subRhs.meetingTenantId
        && meetingSubType == subRhs.meetingSubType
        && isConveniencePSTN == subRhs.isConveniencePSTN
        && isMultiple == subRhs.isMultiple
        && isSelected == subRhs.isSelected
        && isEnabled == subRhs.isEnabled
        && refuseReply == subRhs.refuseReply
        && enableAnotherName == subRhs.enableAnotherName
    }

    override func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool {
        cellModel is SuggestionParticipantCellModel
    }

    override func showExternalTag() -> Bool { userFlag == .external }

    override func relationTagUser() -> VCRelationTag.User? { participant.relationTagUser }

    override func relationTagUserID() -> String? { participant.user.id }
}

extension SuggestionParticipantCellModel: ParticipantIdConvertible {
    var participantId: ParticipantId {
        participant.participantId
    }
}
