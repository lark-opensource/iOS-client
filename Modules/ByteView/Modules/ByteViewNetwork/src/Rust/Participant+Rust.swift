//
//  ParticipantTransformer.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import ServerPB
import ByteViewCommon
import AVFoundation

typealias PBHostManageInterpretationSetting = Videoconference_V1_HostManageRequest.InterpretationSetting
typealias PBHostManageSetInterpreter = Videoconference_V1_HostManageRequest.SetInterpreter
typealias PBInterpretationSetting = Videoconference_V1_InterpretationSetting
typealias PBSetInterpreter = Videoconference_V1_SetInterpreter
typealias PBInterpreterSetting = Videoconference_V1_InterpreterSetting
typealias PBParticipant = Videoconference_V1_Participant
typealias PBByteviewUser = Videoconference_V1_ByteviewUser
typealias PBParticipantSettings = Videoconference_V1_ParticipantSettings
typealias PBParticipantType = Videoconference_V1_ParticipantType
typealias PBLanguageType = Videoconference_V1_LanguageType
typealias PBTenantTag = Videoconference_V1_TenantTag
typealias PBPSTNInfo = Videoconference_V1_PSTNInfo
typealias PBSubtitleUser = Videoconference_V1_GetParticipantListResponse.SubtitleUserInfo
typealias PBParticipantBreakoutRoomStatus = Videoconference_V1_Participant.BreakoutRoomStatus
typealias PBConditionEmojiInfo = Videoconference_V1_ConditionEmojiInfo
typealias PBWebinarAttendeeSettings = Videoconference_V1_WebinarAttendeeSettings
typealias PBLocalRecordSettings = Videoconference_V1_LocalRecordSettings

typealias ServerPBParticipant = ServerPB_Videochat_Participant
typealias ServerPBSetInterpreter = ServerPB_Videochat_common_SetInterpreter
typealias ServerPBInterpretationSetting = ServerPB_Videochat_common_InterpretationSetting
typealias ServerPBInterpreterSetting = ServerPB_Videochat_common_InterpreterSetting
typealias ServerPBByteviewUser = ServerPB_Videochat_common_ByteviewUser
typealias ServerPBParticipantSettings = ServerPB_Videochat_ParticipantSettings
typealias ServerPBParticipantType = ServerPB_Videochat_common_ParticipantType
typealias ServerPBLanguageType = ServerPB_Videochat_common_LanguageType
typealias ServerPBTenantTag = ServerPB_Videochat_TenantTag
typealias ServerPBPSTNInfo = ServerPB_Videochat_PSTNInfo
typealias ServerPBCallMeInfo = ServerPB_Videochat_Participant.CallMeInfo
typealias ServerPBParticipantBreakoutRoomStatus = ServerPB_Videochat_Participant.BreakoutRoomStatus
typealias ServerPBConditionEmojiInfo = ServerPB_Videochat_ConditionEmojiInfo
typealias ServerPBWebinarAttendeeSettings = ServerPB_Videochat_WebinarAttendeeSettings
typealias ServerPBLocalRecordSettings = ServerPB_Videochat_LocalRecordSettings

extension PBTenantTag {
    var vcType: TenantTag {
        .init(rawValue: rawValue) ?? .undefined
    }
}

extension ServerPBTenantTag {
    var vcType: TenantTag {
        .init(rawValue: rawValue) ?? .undefined
    }
}

extension PBPSTNInfo.BindType {
    var vcType: PSTNInfo.BindType {
        .init(rawValue: rawValue) ?? .unknown
    }
}

extension ServerPBPSTNInfo.BindType {
    var vcType: PSTNInfo.BindType {
        .init(rawValue: rawValue) ?? .unknown
    }
}

extension ServerPBCallMeInfo {
    var vcType: Participant.CallMeInfo {
        .init(status: .init(rawValue: status.rawValue) ?? .unknown,
              callmeIdleReason: .init(rawValue: callMeIdleReason.rawValue) ?? .unknown, callMeRtcJoinID: callMeRtcJoinID)
    }
}

extension PBByteviewUser {
    var vcType: ByteviewUser {
        .init(id: userID, type: userType.vcType, deviceId: deviceID)
    }
}

extension ServerPBByteviewUser {
    var vcType: ByteviewUser {
        .init(id: userID, type: userType.vcType, deviceId: deviceID)
    }
}

extension PBSubtitleUser {
    var vcType: SubtitleUser {
        .init(user: user.vcType, info: pstnInfo.vcType)
    }
}

extension PBParticipantBreakoutRoomStatus {
    var vcType: Participant.BreakoutRoomStatus {
        .init(needHelp: needHelp, hostSetBreakoutRoomID: hostSetBreakoutroomID)
    }
}

extension ServerPBParticipantBreakoutRoomStatus {
    var vcType: Participant.BreakoutRoomStatus {
        .init(needHelp: needHelp, hostSetBreakoutRoomID: "") // TODO @maozhixiang.lip
    }
}

extension PBParticipant {

    func vcType(meetingID: String) -> Participant {
        .init(meetingId: meetingID, userId: id, type: type.vcType, deviceId: deviceID, interactiveId: interactiveID,
              status: .init(rawValue: status.rawValue) ?? .unknown, isHost: isHost,
              offlineReason: .init(rawValue: offlineReason.rawValue) ?? .unknown,
              deviceType: .init(rawValue: deviceType.rawValue) ?? .unknown,
              settings: settings.vcType, joinTime: joinTime, capabilities: capabilities.vcType,
              inviter: hasInviterID ? ByteviewUser(id: inviterID, type: inviterType.vcType, deviceId: inviterDeviceID) : nil,
              ongoingMeetingId: hasOngoingMeetingID ? ongoingMeetingID : nil,
              ongoingMeetingInteractiveId: hasOngoingMeetingInteractiveID ? ongoingMeetingInteractiveID : nil,
              role: .init(rawValue: role.rawValue) ?? .unknown,
              pstnInfo: hasPstnInfo ? pstnInfo.vcType : nil,
              meetingRole: .init(rawValue: participantRoleSettings.meetingRole.rawValue) ?? .participant,
              isMeetingOwner: participantRoleSettings.isMeetingOwner,
              micHandsUpTime: handsUpTime, cameraHandsUpTime: cameraHandsUpTime, sortName: sortName, isLarkGuest: isLarkGuest, tenantId: userTenantID,
              tenantTag: tenantTag.vcType,
              seqId: seqID, globalSeqId: globalSeqID, rtcJoinId: rtcJoinID, breakoutRoomId: breakoutRoomID, callMeInfo: callMeInfo.vcType,
              offlineReasonDetails: offlineReasonDetails.map({ .init(rawValue: $0.rawValue) ?? .unknown }),
              leaveTime: leaveTime, breakoutRoomStatus: breakoutRoomStatus.vcType, sortID: hasSortID ? sortID : nil, refuseReplyTime: refuseReplyTime,
              replaceOtherDevice: replaceOtherDevice)
    }
}

extension ServerPBParticipant {

    func vcType(meetingID: String) -> Participant {
        .init(meetingId: meetingID, userId: id, type: type.vcType, deviceId: deviceID, interactiveId: interactiveID,
              status: .init(rawValue: status.rawValue) ?? .unknown, isHost: isHost,
              offlineReason: .init(rawValue: offlineReason.rawValue) ?? .unknown,
              deviceType: .init(rawValue: deviceType.rawValue) ?? .unknown,
              settings: settings.vcType, joinTime: joinTime, capabilities: capabilities.vcType,
              inviter: hasInviterID ? ByteviewUser(id: inviterID, type: inviterType.vcType, deviceId: inviterDeviceID) : nil,
              ongoingMeetingId: hasOngoingMeetingID ? ongoingMeetingID : nil,
              ongoingMeetingInteractiveId: hasOngoingMeetingInteractiveID ? ongoingMeetingInteractiveID : nil,
              role: .init(rawValue: role.rawValue) ?? .unknown,
              pstnInfo: hasPstnInfo ? pstnInfo.vcType : nil,
              meetingRole: .init(rawValue: participantRoleSettings.meetingRole.rawValue) ?? .participant,
              isMeetingOwner: participantRoleSettings.isMeetingOwner,
              micHandsUpTime: handsUpTime, cameraHandsUpTime: cameraHandsUpTime, sortName: "", isLarkGuest: isLarkGuest, tenantId: userTenantID,
              tenantTag: tenantTag.vcType,
              seqId: seqID, globalSeqId: globalSeqID, rtcJoinId: rtcJoinID, breakoutRoomId: breakoutRoomID, callMeInfo: callMeInfo.vcType,
              offlineReasonDetails: offlineReasonDetails.map({ .init(rawValue: $0.rawValue) ?? .unknown }),
              leaveTime: leaveTime, breakoutRoomStatus: breakoutRoomStatus.vcType, sortID: hasSortID ? sortID : nil, refuseReplyTime: refuseReplyTime,
              replaceOtherDevice: false)
    }
}

extension PBPSTNInfo {
    var vcType: PSTNInfo {
        PSTNInfo(participantType: participantType.vcType, mainAddress: mainAddress, subAddress: subAddress, displayName: displayName,
                 bindId: bindID, bindType: .init(rawValue: bindType.rawValue) ?? .unknown, pstnSubType: .init(rawValue: pstnSubType.rawValue) ?? .unknownSubtype)
    }
}

extension ServerPBPSTNInfo {
    var vcType: PSTNInfo {
        PSTNInfo(participantType: participantType.vcType, mainAddress: displayName, subAddress: mainAddress, displayName: subAddress,
                 bindId: bindID, bindType: .init(rawValue: bindType.rawValue) ?? .unknown, pstnSubType: .init(rawValue: pstnSubType.rawValue) ?? .unknownSubtype)
    }
}

extension PBParticipant.VideoChatCapabilities {
    var vcType: Participant.VideoChatCapabilities {
        .init(follow: follow, followPresenter: followPresenter, followProduceStrategyIds: followProduceStrategyIds,
              becomeInterpreter: becomeInterpreter, canBeHost: canBeHost, canBeCoHost: canBeCoHost)
    }
}

extension ServerPBParticipant.VideoChatCapabilities {
    var vcType: Participant.VideoChatCapabilities {
        .init(follow: follow, followPresenter: followPresenter, followProduceStrategyIds: followProduceStrategyIds,
              becomeInterpreter: becomeInterpreter, canBeHost: canBeHost, canBeCoHost: canBeCoHost)
    }
}

extension PBParticipant.CallMeInfo {
    var vcType: Participant.CallMeInfo {
        .init(status: .init(rawValue: status.rawValue) ?? .unknown,
              callmeIdleReason: .init(rawValue: callMeIdleReason.rawValue) ?? .unknown, callMeRtcJoinID: callMeRtcJoinID)
    }
}

extension PBParticipantSettings {
    var vcType: ParticipantSettings {
        .init(isMicrophoneMuted: isMicrophoneMuted, isCameraMuted: isCameraMuted,
              microphoneStatus: .init(rawValue: microphoneStatus.rawValue) ?? .unknown,
              cameraStatus: .init(rawValue: cameraStatus.rawValue) ?? .unknown,
              playEnterExitChimes: hasPlayEnterExitChimes ? playEnterExitChimes : nil,
              followingStatus: followingStatus,
              isTranslationOn: hasIsTranslationOn ? isTranslationOn : nil,
              subtitleLanguage: subtitleLanguage, spokenLanguage: spokenLanguage, nickname: nickname,
              enableSubtitleRecord: enableSubtitleRecord, appliedSpokenLanguage: appliedSpokenLanguage,
              handsStatus: .init(rawValue: handsStatus.rawValue) ?? .unknown,
              rtcMode: .init(rawValue: rtcMode.rawValue) ?? .unknown,
              interpreterSetting: hasInterpreterSetting ? interpreterSetting.vcType : nil,
              inMeetingName: inMeetingName,
              audioMode: .init(rawValue: audioMode.rawValue) ?? .unknown,
              targetToJoinTogether: syncRoom.hasTargetToJoinTogether ? syncRoom.targetToJoinTogether.vcType : nil,
              roomPeopleCnt: roomExtraInfo.peopleCntChanged ? roomExtraInfo.roomPeopleCnt : nil, conditionEmojiInfo: hasConditionEmojiInfo ? conditionEmojiInfo.vcType : nil,
              mobileCallingStatus: .init(rawValue: mobileCallingStatus.rawValue) ?? .unknown,
              cameraHandsStatus: .init(rawValue: cameraHandsStatus.rawValue) ?? .unknown,
              attendeeSettings: hasAttendeeSettings ? attendeeSettings.vcType : nil,
              isBindScreenCastRoom: hasBindScreenCastRoom ? bindScreenCastRoom : false,
              localRecordSettings: hasLocalRecordSettings ? localRecordSettings.vcType : nil,
              refuseReply: hasRefuseReply ? refuseReply : nil, transcriptLanguage: transcriptLanguage)
    }
}

extension PBLocalRecordSettings {
    var vcType: LocalRecordSettings {
        return .init(
            localRecordHandsStatus: .init(rawValue: localRecordHandsStatus.rawValue) ?? .unknown,
            isLocalRecording: isLocalRecording,
            hasLocalRecordAuthority: hasLocalRecordAuthority_p,
            localRecordHandsUpTime: localRecordHandsUpTime
        )
    }
}

extension PBWebinarAttendeeSettings {
    var vcType: WebinarAttendeeSettings {
        .init(unmuteOffer: hasUnmuteOffer ? self.unmuteOffer : nil,
              becomeParticipantOffer: hasBecomeParticipantOffer ? self.becomeParticipantOffer : nil)
    }
}

extension ServerPBWebinarAttendeeSettings {
    var vcType: WebinarAttendeeSettings {
        .init(unmuteOffer: hasUnmuteOffer ? self.unmuteOffer : nil,
              becomeParticipantOffer: hasBecomeParticipantOffer ? self.becomeParticipantOffer : nil)
    }
}

extension ServerPBParticipantSettings {
    var vcType: ParticipantSettings {
        return .init(isMicrophoneMuted: isMicrophoneMuted, isCameraMuted: isCameraMuted,
              microphoneStatus: .init(rawValue: microphoneStatus.rawValue) ?? .unknown,
              cameraStatus: .init(rawValue: cameraStatus.rawValue) ?? .unknown,
              playEnterExitChimes: hasPlayEnterExitChimes ? playEnterExitChimes : nil,
              followingStatus: followingStatus,
              isTranslationOn: hasIsTranslationOn ? isTranslationOn : nil,
              subtitleLanguage: subtitleLanguage, spokenLanguage: spokenLanguage, nickname: nickname,
              enableSubtitleRecord: enableSubtitleRecord, appliedSpokenLanguage: appliedSpokenLanguage,
              handsStatus: .init(rawValue: handsStatus.rawValue) ?? .unknown,
              rtcMode: .init(rawValue: rtcMode.rawValue) ?? .unknown,
              interpreterSetting: hasInterpreterSetting ? interpreterSetting.vcType : nil,
              inMeetingName: inMeetingName,
              audioMode: .init(rawValue: audioMode.rawValue) ?? .unknown,
              targetToJoinTogether: syncRoom.hasTargetToJoinTogether ? syncRoom.targetToJoinTogether.vcType : nil,
                     roomPeopleCnt: roomExtraInfo.peopleCntChanged ? roomExtraInfo.roomPeopleCnt : nil,
                     conditionEmojiInfo: hasConditionEmojiInfo ? conditionEmojiInfo.vcType : nil,
                     mobileCallingStatus: .init(rawValue: mobileCallingStatus.rawValue) ?? .unknown,
                     cameraHandsStatus: .init(rawValue: cameraHandsStatus.rawValue) ?? .unknown,
                     attendeeSettings: hasAttendeeSettings ? attendeeSettings.vcType : nil,
                     isBindScreenCastRoom: hasBindScreenCastRoom ? bindScreenCastRoom : false,
                     localRecordSettings: hasLocalRecordSettings ? localRecordSettings.vcType : nil,
                     refuseReply: hasRefuseReply ? refuseReply : nil, transcriptLanguage: transcriptLanguage)
    }
}

extension ServerPBLocalRecordSettings {
    var vcType: LocalRecordSettings {
        return .init(
            localRecordHandsStatus: .init(rawValue: localRecordHandsStatus.rawValue) ?? .unknown,
            isLocalRecording: isLocalRecording,
            hasLocalRecordAuthority: hasLocalRecordAuthority_p,
            localRecordHandsUpTime: localRecordHandsUpTime
        )
    }
}

extension PBConditionEmojiInfo {
    var vcType: ParticipantSettings.ConditionEmojiInfo {
        return .init(isStepUp: isStepUp, isHandsUp: isHandsUp, handsUpTime: handsUpTime, handsUpEmojiKey: handsUpEmojiKey)
    }
}

extension ServerPBConditionEmojiInfo {
    var vcType: ParticipantSettings.ConditionEmojiInfo {
        return .init(isStepUp: isStepUp, isHandsUp: isHandsUp, handsUpTime: handsUpTime, handsUpEmojiKey: handsUpEmojiKey)
    }
}
extension PBSetInterpreter {
    var vcType: SetInterpreter {
        .init(user: user.vcType, interpreterSetting: hasInterpreterSetting ? interpreterSetting.vcType : nil, isDeleteInterpreter: isDeleteInterpreter)
    }
}

extension PBHostManageSetInterpreter {
    var vcType: SetInterpreter {
        .init(user: user.vcType, interpreterSetting: hasInterpreterSetting ? interpreterSetting.vcType : nil, isDeleteInterpreter: isDeleteInterpreter)
    }
}

extension PBInterpreterSetting {
    var vcType: InterpreterSetting {
        .init(firstLanguage: firstLanguage.vcType, secondLanguage: secondLanguage.vcType,
              confirmStatus: hasConfirmStatus ? (.init(rawValue: confirmStatus.rawValue) ?? .reserve) : nil,
              interpretingLanguage: interpretingLanguage.vcType,
              confirmInterpretationTime: confirmInterpretationTime, interpreterSetTime: interpreterSetTime)
    }
}

extension PBInterpretationSetting {
    var vcType: InterpretationSetting {
        .init(isOpenInterpretation: isOpenInterpretation, interpreterSettings: interpreterSettings.map { $0.vcType })
    }
}

extension PBHostManageInterpretationSetting {
    var vcType: InterpretationSetting {
        .init(isOpenInterpretation: isOpenInterpretation, interpreterSettings: interpreterSettings.map { $0.vcType })
    }
}

extension ServerPBSetInterpreter {
    var vcType: SetInterpreter {
        .init(user: user.vcType, interpreterSetting: hasInterpreterSetting ? interpreterSetting.vcType : nil, isDeleteInterpreter: isDeleteInterpreter)
    }
}

extension ServerPBInterpreterSetting {
    var vcType: InterpreterSetting {
        .init(firstLanguage: firstLanguage.vcType, secondLanguage: secondLanguage.vcType,
              confirmStatus: hasConfirmStatus ? (.init(rawValue: confirmStatus.rawValue) ?? .reserve) : nil,
              interpretingLanguage: interpretingLanguage.vcType,
              confirmInterpretationTime: confirmInterpretationTime, interpreterSetTime: interpreterSetTime)
    }
}

extension ServerPBInterpretationSetting {
    var vcType: InterpretationSetting {
        .init(isOpenInterpretation: isOpenInterpretation, interpreterSettings: interpreterSettings.map { $0.vcType })
    }
}

extension PBLanguageType {
    var vcType: InterpreterSetting.LanguageType {
        .init(languageType: languageType, despI18NKey: despI18NKey, iconStr: iconStr)
    }
}

extension ServerPBLanguageType {
    var vcType: InterpreterSetting.LanguageType {
        .init(languageType: languageType, despI18NKey: despI18NKey, iconStr: iconStr)
    }
}

extension PBParticipant.DeviceType {
    var vcType: Participant.DeviceType {
        Participant.DeviceType(rawValue: rawValue) ?? .unknown
    }
}

extension PBParticipantType {
    var vcType: ParticipantType {
        ParticipantType(rawValue: rawValue)
    }
}

extension ServerPBParticipantType {
    var vcType: ParticipantType {
        ParticipantType(rawValue: rawValue)
    }
}

extension ParticipantType {
    var pbType: PBParticipantType {
        PBParticipantType(rawValue: rawValue) ?? .unknow
    }

    var serverPbType: ServerPBParticipantType {
        ServerPBParticipantType(rawValue: rawValue) ?? .unknow
    }
}

extension InterpreterSetting.LanguageType {
    var pbType: PBLanguageType {
        var lang = PBLanguageType()
        lang.languageType = languageType
        lang.despI18NKey = despI18NKey
        lang.iconStr = iconStr
        return lang
    }

    var serverPbType: ServerPBLanguageType {
        var lang = ServerPBLanguageType()
        lang.languageType = languageType
        lang.despI18NKey = despI18NKey
        lang.iconStr = iconStr
        return lang
    }
}

extension ByteviewUser {
    var pbType: PBByteviewUser {
        var user = PBByteviewUser()
        user.userID = id
        user.userType = type.pbType
        user.deviceID = deviceId
        return user
    }

    var serverPbType: ServerPBByteviewUser {
        var user = ServerPBByteviewUser()
        user.userID = id
        user.userType = type.serverPbType
        user.deviceID = deviceId
        return user
    }
}

extension PSTNInfo {
    var pbType: PBPSTNInfo {
        var info = PBPSTNInfo()
        info.mainAddress = mainAddress
        info.participantType = participantType.pbType
        if !subAddress.isEmpty {
            info.subAddress = subAddress
        }
        if !displayName.isEmpty {
            info.displayName = displayName
        }
        if !bindId.isEmpty, bindType != .unknown {
            info.bindID = bindId
            info.bindType = PBPSTNInfo.BindType(rawValue: bindType.rawValue) ?? .unknown
        }
        if pstnSubType != .unknownSubtype {
            info.pstnSubType = PBPSTNInfo.PSTNSubType(rawValue: pstnSubType.rawValue) ?? .unknownSubtype
        }
        return info
    }

    var serverPbType: ServerPBPSTNInfo {
        var info = ServerPBPSTNInfo()
        info.mainAddress = mainAddress
        info.participantType = participantType.serverPbType
        if !subAddress.isEmpty {
            info.subAddress = subAddress
        }
        if !displayName.isEmpty {
            info.displayName = displayName
        }
        if !bindId.isEmpty, bindType != .unknown {
            info.bindID = bindId
            info.bindType = ServerPBPSTNInfo.BindType(rawValue: bindType.rawValue) ?? .unknown
        }
        return info
    }
}

extension Videoconference_V1_GetTranscriptParticipantListResponse.TranscriptUserInfo {
    var vcType: SubtitleUser {
        .init(user: user.vcType, info: pstnInfo.vcType)
    }
}
