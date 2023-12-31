//
//  RejectParticipantCellModel.swift
//  ByteView
//
//  Created by wulv on 2022/5/23.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

class RejectParticipantCellModel: BaseParticipantCellModel {
    /// 个人状态
    let customStatuses: [User.CustomStatus]
    /// 外部标签
    private(set) var userFlag: UserFlagType
    /// 会议室地点
    let room: String?
    /// 按钮样式
    let buttonStyle: ParticipantButton.Style
    /// 参会人
    let participant: Participant
    /// 是否允许快捷电话邀请
    var enableInvitePSTN: Bool

    init(avatarInfo: AvatarInfo,
         displayName: String,
         nameTail: String?,
         customStatuses: [User.CustomStatus],
         userFlag: UserFlagType,
         room: String?,
         buttonStyle: ParticipantButton.Style,
         participant: Participant,
         enableInvitePSTN: Bool,
         service: MeetingBasicService) {
        self.customStatuses = customStatuses
        self.userFlag = userFlag
        self.room = room
        self.buttonStyle = buttonStyle
        self.participant = participant
        self.enableInvitePSTN = enableInvitePSTN
        super.init(avatarInfo: avatarInfo, showRedDot: false, displayName: displayName, nameTail: nameTail, pID: participant.user.id, service: service)
    }

    override func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        guard let subRhs = rhs as? RejectParticipantCellModel else { return false }
        return canEqual(self) && super.isEqual(rhs)
        && customStatuses == subRhs.customStatuses
        && userFlag == subRhs.userFlag
        && room == subRhs.room
        && buttonStyle == subRhs.buttonStyle
        && participant == subRhs.participant
        && enableInvitePSTN == subRhs.enableInvitePSTN
    }

    override func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool {
        cellModel is RejectParticipantCellModel
    }

    override func showExternalTag() -> Bool { userFlag == .external }

    override func relationTagUser() -> VCRelationTag.User? { participant.relationTagUser }

    override func relationTagUserID() -> String? { participant.user.id }
}

extension RejectParticipantCellModel: ParticipantIdConvertible {
    var participantId: ParticipantId {
        participant.participantId
    }
}
