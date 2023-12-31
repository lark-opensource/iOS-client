//
//  InvitedParticipantCellModel.swift
//  ByteView
//
//  Created by wulv on 2022/1/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

class InvitedParticipantCellModel: BaseParticipantCellModel {
    /// 头像涟漪
    let playRipple: Bool
    /// 设备标识(快捷电话邀请)
    let deviceImgKey: ParticipantImgKey
    /// 呼叫反馈
    let inviteFeedback: String?
    /// 拒绝回复
    let refuseReply: String?
    /// 外部标签
    private(set) var userFlag: UserFlagType
    /// 会议室地点
    let room: String?
    ///「转为电话呼叫」按钮
    let convertPSTNStyle: ParticipantButton.Style
    /// 「取消」按钮
    let cancelStyle: ParticipantButton.Style
    /// 参会人
    let participant: Participant
    /// 是否是快捷电话邀请
    let isConveniencePSTN: Bool
    /// 是否有别名FG
    let enableAnotherName: Bool

    var hasRefuseReply: Bool {
        guard let refuseReply = refuseReply else {
            return false
        }
        return !refuseReply.isEmpty
    }

    init(avatarInfo: AvatarInfo?,
         displayName: String?,
         nameTail: String?,
         playRipple: Bool,
         deviceImg: ParticipantImgKey,
         inviteFeedback: String?,
         refuseReply: String?,
         userFlag: UserFlagType,
         room: String?,
         convertPSTNStyle: ParticipantButton.Style,
         cancelStyle: ParticipantButton.Style,
         participant: Participant,
         isConveniencePSTN: Bool,
         enableAnotherName: Bool,
         service: MeetingBasicService
    ) {
        self.playRipple = playRipple
        self.deviceImgKey = deviceImg
        self.inviteFeedback = inviteFeedback
        self.refuseReply = refuseReply
        self.userFlag = userFlag
        self.room = room
        self.convertPSTNStyle = convertPSTNStyle
        self.cancelStyle = cancelStyle
        self.participant = participant
        self.isConveniencePSTN = isConveniencePSTN
        self.enableAnotherName = enableAnotherName
        super.init(avatarInfo: avatarInfo, showRedDot: false, displayName: displayName, nameTail: nameTail, pID: participant.user.id, service: service)
    }

    override func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        guard let subRhs = rhs as? InvitedParticipantCellModel else { return false }
        return rhs.canEqual(self) && super.isEqual(rhs)
        && playRipple == subRhs.playRipple
        && deviceImgKey == subRhs.deviceImgKey
        && inviteFeedback == subRhs.inviteFeedback
        && userFlag == subRhs.userFlag
        && room == subRhs.room
        && convertPSTNStyle == subRhs.convertPSTNStyle
        && cancelStyle == subRhs.cancelStyle
        && participant == subRhs.participant
        && isConveniencePSTN == subRhs.isConveniencePSTN
        && enableAnotherName == subRhs.enableAnotherName
        && refuseReply == subRhs.refuseReply
    }

    override func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool {
        cellModel is InvitedParticipantCellModel
    }

    override func showExternalTag() -> Bool { userFlag == .external }

    override func relationTagUser() -> VCRelationTag.User? { participant.relationTagUser }

    override func relationTagUserID() -> String? { participant.user.id }
}

extension InvitedParticipantCellModel: ParticipantIdConvertible {
    var participantId: ParticipantId {
        participant.participantId
    }
}

extension InvitedParticipantCellModel: ParticipantInfoForSortType {
    var isHost: Bool {
        participant.isHost
    }

    var deviceID: String {
        participant.deviceId
    }

    var isMicHandsUp: Bool {
        participant.isMicHandsUp
    }

    var isCameraHandsUp: Bool {
        participant.isCameraHandsUp
    }

    var isLocalRecordHandsUp: Bool {
        participant.isLocalRecordHandsUp
    }

    var joinTime: Int64 {
        participant.joinTime
    }

    var sortName: String {
        participant.sortName
    }

    var user: ByteviewUser {
        participant.user
    }

    var isCoHost: Bool {
        participant.isCoHost
    }

    var isRing: Bool {
        participant.isRing
    }

    var micHandsUpTime: Int64 {
        participant.micHandsUpTime
    }

    var cameraHandsUpTime: Int64 {
        participant.cameraHandsUpTime
    }

    var localRecordHandsUpTime: Int64 {
        participant.settings.localRecordSettings?.localRecordHandsUpTime ?? 0
    }

    var isInterpreter: Bool {
        participant.isInterpreter
    }

    var interpreterConfirmTime: Int64 {
        participant.settings.interpreterSetting?.confirmInterpretationTime ?? 0
    }

    var isMicrophoneOn: Bool {
        !participant.settings.isMicrophoneMutedOrUnavailable
    }

    var isFocusing: Bool {
        false
    }

    var hasHandsUpEmoji: Bool {
        participant.settings.conditionEmojiInfo?.isHandsUp ?? false
    }

    var statusEmojiHandsUpTime: Int64 {
        participant.settings.conditionEmojiInfo?.handsUpTime ?? 0
    }

    var isExternal: Bool {
        false
    }

    var isSharer: Bool {
        false
    }
}

extension InvitedParticipantCellModel: WebinarAttendeeSortType {
    var sortId: Int64 {
        participant.sortID ?? 0
    }
}
