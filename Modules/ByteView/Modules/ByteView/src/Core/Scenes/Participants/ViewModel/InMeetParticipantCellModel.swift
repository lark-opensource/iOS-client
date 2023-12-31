//
//  InMeetParticipantCellModel.swift
//  ByteView
//
//  Created by wulv on 2022/1/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewCommon
import ByteViewNetwork

class InMeetParticipantCellModel: BaseParticipantCellModel {

    /// 高亮效果
    let selectionStyle: UITableViewCell.SelectionStyle
    /// 原始昵称（用于快捷电话邀请）
    var originalName: String?
    /// pstn标识(CallMe/快捷电话邀请)
    var showPstnIcon: Bool
    /// 设备标识(手机/web)
    var deviceImgKey: ParticipantImgKey
    /// 本地录制标识
    var showLocalRecordIcon: Bool
    /// 共享标识
    var showShareIcon: Bool
    /// 状态表情离开
    var showLeaveIcon: Bool
    /// 主持人/联席主持人标签配置
    var roleConfig: ParticipantRoleConfig?
    /// 传译标签Key，用于拉取传译标签
    let interpretKey: String?
    /// 传译标签
    var interpret: String?
    /// 外部标签
    private(set) var userFlag: UserFlagType
    /// 焦点视频
    var showFocus: Bool
    /// 申请发言
    let showMicHandsUp: Bool
    /// 申请开启摄像头
    let showCameraHandsUp: Bool
    /// 申请开启本地录制
    let showLocalRecordHandsUp: Bool
    /// 麦克风
    let micState: MicIconState
    /// 摄像头
    let cameraImgKey: ParticipantImgKey
    /// 状态表情举手
    let showStatusHandsUp: Bool
    /// 表情举手皮肤
    let handsUpEmojiKey: String?
    /// 参会人
    let participant: Participant
    /// room参会人人数文案
    let roomCountMessage: String?
    /// 接听系统电话标识
    let showSystemCallingStatus: Bool

    let volumeManager: VolumeManager

    init(selectionStyle: UITableViewCell.SelectionStyle,
         avatarInfo: AvatarInfo?,
         showRedDot: Bool,
         displayName: String?,
         originalName: String?,
         nameTail: String?,
         roomCountMessage: String?,
         showPstnIcon: Bool,
         deviceImg: ParticipantImgKey,
         showLocalRecordIcon: Bool,
         showShareIcon: Bool,
         showLeaveIcon: Bool,
         roleConfig: ParticipantRoleConfig?,
         interpretKey: String?,
         userFlag: UserFlagType,
         showFocus: Bool,
         showMicHandsUp: Bool,
         showCameraHandsUp: Bool,
         showLocalRecordHandsUp: Bool,
         micState: MicIconState,
         cameraImg: ParticipantImgKey,
         participant: Participant,
         volumeManager: VolumeManager,
         showStatusHandsUp: Bool,
         handsUpEmojiKey: String?,
         showSystemCallingStatus: Bool,
         service: MeetingBasicService
    ) {
        self.selectionStyle = selectionStyle
        self.originalName = originalName
        self.showPstnIcon = showPstnIcon
        self.deviceImgKey = deviceImg
        self.showLocalRecordIcon = showLocalRecordIcon
        self.showShareIcon = showShareIcon
        self.showLeaveIcon = showLeaveIcon
        self.roleConfig = roleConfig
        self.interpretKey = interpretKey
        self.userFlag = userFlag
        self.showFocus = showFocus
        self.showMicHandsUp = showMicHandsUp
        self.showCameraHandsUp = showCameraHandsUp
        self.showLocalRecordHandsUp = showLocalRecordHandsUp
        self.micState = micState
        self.cameraImgKey = cameraImg
        self.participant = participant
        self.roomCountMessage = roomCountMessage
        self.volumeManager = volumeManager
        self.showStatusHandsUp = showStatusHandsUp
        self.handsUpEmojiKey = handsUpEmojiKey
        self.showSystemCallingStatus = showSystemCallingStatus
        super.init(avatarInfo: avatarInfo, showRedDot: showRedDot, displayName: displayName, nameTail: nameTail, pID: participant.user.id, service: service)
    }

    override func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        guard let subRhs = rhs as? InMeetParticipantCellModel else { return false }
        return rhs.canEqual(self) && super.isEqual(rhs)
        && selectionStyle == subRhs.selectionStyle
        && originalName == subRhs.originalName
        && showPstnIcon == subRhs.showPstnIcon
        && deviceImgKey == subRhs.deviceImgKey
        && showLocalRecordIcon == subRhs.showLocalRecordIcon
        && showShareIcon == subRhs.showShareIcon
        && showLeaveIcon == subRhs.showLeaveIcon
        && roleConfig == subRhs.roleConfig
        && interpretKey == subRhs.interpretKey
        && interpret == subRhs.interpret
        && userFlag == subRhs.userFlag
        && showFocus == subRhs.showFocus
        && showMicHandsUp == subRhs.showMicHandsUp
        && showCameraHandsUp == subRhs.showCameraHandsUp
        && showLocalRecordHandsUp == subRhs.showLocalRecordHandsUp
        && micState == subRhs.micState
        && cameraImgKey == subRhs.cameraImgKey
        && participant == subRhs.participant
        && roomCountMessage == subRhs.roomCountMessage
        && showStatusHandsUp == subRhs.showStatusHandsUp
        && handsUpEmojiKey == subRhs.handsUpEmojiKey
        && showSystemCallingStatus == subRhs.showSystemCallingStatus
    }

    override func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool {
        cellModel is InMeetParticipantCellModel
    }

    override func showExternalTag() -> Bool { userFlag == .external }

    override func relationTagUser() -> VCRelationTag.User? { participant.relationTagUser }

    override func relationTagUserID() -> String? { participant.user.id }
}

extension InMeetParticipantCellModel: ParticipantIdConvertible {
    var participantId: ParticipantId {
        participant.participantId
    }
}

extension InMeetParticipantCellModel: ParticipantInfoForSortType {
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
        showFocus
    }

    var hasHandsUpEmoji: Bool {
        participant.settings.conditionEmojiInfo?.isHandsUp ?? false
    }

    var statusEmojiHandsUpTime: Int64 {
        participant.settings.conditionEmojiInfo?.handsUpTime ?? 0
    }

    var isExternal: Bool {
        userFlag == .external
    }

    var isSharer: Bool {
        showShareIcon
    }
}
