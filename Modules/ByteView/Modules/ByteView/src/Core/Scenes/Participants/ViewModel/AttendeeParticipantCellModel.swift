//
//  AttendeeParticipantCellModel.swift
//  ByteView
//
//  Created by wulv on 2022/9/26.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

class AttendeeParticipantCellModel: BaseParticipantCellModel {

    /// 高亮效果
    let selectionStyle: UITableViewCell.SelectionStyle
    /// 原始昵称（用于快捷电话邀请）
    var originalName: String?
    /// pstn标识(CallMe/快捷电话邀请)
    var showPstnIcon: Bool
    /// 设备标识(手机/web)
    var deviceImgKey: ParticipantImgKey
    /// 传译标签Key，用于拉取传译标签
    let interpretKey: String?
    /// 传译标签
    var interpret: String?
    /// 外部标签
    let userFlag: UserFlagType
    /// 申请发言
    let showHandsUp: Bool
    /// 状态表情举手
    let showStatusHandsUp: Bool
    /// 表情举手皮肤
    let handsUpEmojiKey: String?
    /// 状态表情离开
    var showLeaveIcon: Bool
    /// 麦克风
    let micState: MicIconState
    /// 参会人
    let participant: Participant

    let volumeManager: VolumeManager

    init(selectionStyle: UITableViewCell.SelectionStyle,
         avatarInfo: AvatarInfo?,
         showRedDot: Bool,
         displayName: String?,
         originalName: String?,
         nameTail: String?,
         showPstnIcon: Bool,
         deviceImg: ParticipantImgKey,
         interpretKey: String?,
         userFlag: UserFlagType,
         showHandsUp: Bool,
         showLeaveIcon: Bool,
         showStatusHandsUp: Bool,
         handsUpEmojiKey: String?,
         micState: MicIconState,
         participant: Participant,
         volumeManager: VolumeManager,
         service: MeetingBasicService
    ) {
        self.selectionStyle = selectionStyle
        self.originalName = originalName
        self.showPstnIcon = showPstnIcon
        self.deviceImgKey = deviceImg
        self.showLeaveIcon = showLeaveIcon
        self.interpretKey = interpretKey
        self.userFlag = userFlag
        self.showHandsUp = showHandsUp
        self.showStatusHandsUp = showStatusHandsUp
        self.handsUpEmojiKey = handsUpEmojiKey
        self.micState = micState
        self.participant = participant
        self.volumeManager = volumeManager
        super.init(avatarInfo: avatarInfo, showRedDot: showRedDot, displayName: displayName, nameTail: nameTail, pID: participant.user.id, service: service)
    }

    override func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        guard let subRhs = rhs as? AttendeeParticipantCellModel else { return false }
        return rhs.canEqual(self) && super.isEqual(rhs)
        && selectionStyle == subRhs.selectionStyle
        && originalName == subRhs.originalName
        && showPstnIcon == subRhs.showPstnIcon
        && deviceImgKey == subRhs.deviceImgKey
        && showLeaveIcon == subRhs.showLeaveIcon
        && interpretKey == subRhs.interpretKey
        && interpret == subRhs.interpret
        && userFlag == subRhs.userFlag
        && showHandsUp == subRhs.showHandsUp
        && showStatusHandsUp == subRhs.showStatusHandsUp
        && handsUpEmojiKey == subRhs.handsUpEmojiKey
        && micState == subRhs.micState
        && participant == subRhs.participant
    }

    override func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool {
        cellModel is AttendeeParticipantCellModel
    }

    override func showExternalTag() -> Bool { userFlag == .external }

    override func relationTagUser() -> VCRelationTag.User? { participant.relationTagUser }

    override func relationTagUserID() -> String? { participant.user.id }
}

extension AttendeeParticipantCellModel: ParticipantIdConvertible {
    var participantId: ParticipantId {
        participant.participantId
    }
}

extension AttendeeParticipantCellModel: WebinarAttendeeSortType {
    var sortId: Int64 {
        participant.sortID ?? 0
    }
}
