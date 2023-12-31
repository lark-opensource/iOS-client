//
//  InterpreterParticipantCellModel.swift
//  ByteView
//
//  Created by wulv on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

// MARK: - 传译员CellModel父类
class InterpreterParticipantCellModel: BaseParticipantCellModel {
    /// 入会状态
    let joinState: ParticipantJoinStateLabel.State
    /// 设备标识(手机/pstn/web等)
    let deviceImgKey: ParticipantImgKey
    /// 主持人/联席主持人标签
    var roleConfig: ParticipantRoleConfig?
    /// 传译标签Key，用于拉取传译标签
    let interpretKey: String?
    /// 传译标签
    var interpret: String?
    /// 外部标签
    private(set) var userFlag: UserFlagType
    /// 申请发言
    let showMicHandsUp: Bool
    /// 申请开启摄像头
    let showCameraHandsUp: Bool
    /// 申请开启本地录制
    let showLocalRecordHandsUp: Bool

    let userType: ParticipantType

    init(avatarInfo: AvatarInfo,
         showRedDot: Bool,
         displayName: String,
         nameTail: String?,
         joinState: ParticipantJoinStateLabel.State,
         deviceImg: ParticipantImgKey,
         roleConfig: ParticipantRoleConfig?,
         interpretKey: String? = nil,
         userFlag: UserFlagType,
         showMicHandsUp: Bool,
         showCameraHandsUp: Bool,
         showLocalRecordHandsUp: Bool,
         userId: String,
         userType: ParticipantType,
         service: MeetingBasicService
    ) {
        self.joinState = joinState
        self.deviceImgKey = deviceImg
        self.roleConfig = roleConfig
        self.interpretKey = interpretKey
        self.userFlag = userFlag
        self.showMicHandsUp = showMicHandsUp
        self.showCameraHandsUp = showCameraHandsUp
        self.showLocalRecordHandsUp = showLocalRecordHandsUp
        self.userType = userType
        super.init(avatarInfo: avatarInfo, showRedDot: showRedDot, displayName: displayName, nameTail: nameTail, pID: userId, service: service)
    }

    override func showExternalTag() -> Bool { userFlag == .external }

    override func relationTagUser() -> VCRelationTag.User? {
        var relationUserType: VCRelationTag.User.TypeEnum
        switch userType {
        case .larkUser:
            relationUserType = .larkUser
        case .room:
            relationUserType = .room
        default:
            relationUserType = .unknown
        }
        let user = VCRelationTag.User(type: relationUserType, id: pID)
        return user
    }

    override func relationTagUserID() -> String? { pID }

    override func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        guard let subRhs = rhs as? InterpreterParticipantCellModel else { return false }
        return rhs.canEqual(self) && super.isEqual(rhs)
        && joinState == subRhs.joinState
        && deviceImgKey == subRhs.deviceImgKey
        && roleConfig == subRhs.roleConfig
        && interpretKey == subRhs.interpretKey
        && interpret == subRhs.interpret
        && userFlag == subRhs.userFlag
        && showMicHandsUp == subRhs.showMicHandsUp
        && showCameraHandsUp == subRhs.showCameraHandsUp
    }

    override func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool {
        cellModel is InterpreterParticipantCellModel
    }
}

// MARK: - 非会中CellModel子类
/// 未入会的传译员
class InterpreterIdleParticipantCellModel: InterpreterParticipantCellModel {
    /// 会前设置的传译员
    let idleInterpreter: SetInterpreter

    init(avatarInfo: AvatarInfo,
         showRedDot: Bool,
         displayName: String,
         nameTail: String?,
         joinState: ParticipantJoinStateLabel.State,
         deviceImg: ParticipantImgKey,
         roleConfig: ParticipantRoleConfig?,
         userFlag: UserFlagType,
         showMicHandsUp: Bool,
         showCameraHandsUp: Bool,
         showLocalRecordHandsUp: Bool,
         idleInterpreter: SetInterpreter,
         userType: ParticipantType,
         service: MeetingBasicService
    ) {
        self.idleInterpreter = idleInterpreter
        super.init(avatarInfo: avatarInfo, showRedDot: showRedDot, displayName: displayName, nameTail: nameTail, joinState: joinState, deviceImg: deviceImg, roleConfig: roleConfig, userFlag: userFlag, showMicHandsUp: showMicHandsUp, showCameraHandsUp: showCameraHandsUp, showLocalRecordHandsUp: showLocalRecordHandsUp, userId: idleInterpreter.user.id, userType: userType, service: service)
    }

    override func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        guard let subRhs = rhs as? InterpreterIdleParticipantCellModel else { return false }
        return rhs.canEqual(self) && super.isEqual(rhs)
        && idleInterpreter == subRhs.idleInterpreter
    }

    override func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool {
        cellModel is InterpreterIdleParticipantCellModel
    }
}

extension InterpreterIdleParticipantCellModel: ParticipantIdConvertible {
    var participantId: ParticipantId {
        idleInterpreter.user.participantId
    }
}

// MARK: - 会中CellModel子类
/// 会中参会人
class InterpreterInMeetParticipantCellModel: InterpreterParticipantCellModel {
    /// 参会人
    let participant: Participant

    init(avatarInfo: AvatarInfo,
         showRedDot: Bool,
         displayName: String,
         nameTail: String?,
         joinState: ParticipantJoinStateLabel.State,
         deviceImg: ParticipantImgKey,
         roleConfig: ParticipantRoleConfig?,
         interpretKey: String?,
         userFlag: UserFlagType,
         showMicHandsUp: Bool,
         showCameraHandsUp: Bool,
         showLocalRecordHandsUp: Bool,
         participant: Participant,
         service: MeetingBasicService
    ) {
        self.participant = participant
        super.init(avatarInfo: avatarInfo, showRedDot: showRedDot, displayName: displayName, nameTail: nameTail, joinState: joinState, deviceImg: deviceImg, roleConfig: roleConfig, interpretKey: interpretKey, userFlag: userFlag, showMicHandsUp: showMicHandsUp, showCameraHandsUp: showCameraHandsUp, showLocalRecordHandsUp: showLocalRecordHandsUp, userId: participant.user.id, userType: participant.type, service: service)
    }

    override func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        guard let subRhs = rhs as? InterpreterInMeetParticipantCellModel else { return false }
        return rhs.canEqual(self) && super.isEqual(rhs)
        && participant == subRhs.participant
    }

    override func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool {
        cellModel is InterpreterInMeetParticipantCellModel
    }
}

extension InterpreterInMeetParticipantCellModel: ParticipantIdConvertible {
    var participantId: ParticipantId {
        participant.participantId
    }
}

extension InterpreterInMeetParticipantCellModel: ParticipantInfoForSortType {
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
