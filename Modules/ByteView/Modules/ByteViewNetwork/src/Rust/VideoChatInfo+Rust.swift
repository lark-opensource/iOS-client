//
//  VideoChatInfoMessages.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import ByteViewCommon
import ServerPB

typealias PBVideoChatInfo = Videoconference_V1_VideoChatInfo
typealias PBVideoChatSettings = Videoconference_V1_VideoChatSettings
typealias PBNotesPermission = Videoconference_V1_NotesPermission
typealias PBActionTime = Videoconference_V1_ActionTime
typealias PBRustH323Setting = Videoconference_V1_VideoChatH323Setting
typealias PBServerH323Setting = ServerPB_Videochat_VideoChatH323Setting
typealias PBBreakoutRoomInfo = Videoconference_V1_BreakoutRoomInfo
typealias PBSipSetting = Videoconference_V1_VideoChatSIPSetting
typealias PBSecuritySetting = Videoconference_V1_VideoChatSecuritySetting
typealias PBFeatureConfig = Videoconference_V1_FeatureConfig
typealias PBManageCapabilities = Videoconference_V1_VCManageCapabilities
typealias PBRTCInfo = Videoconference_V1_VCRTCInfo
typealias PBRTCProxy = Videoconference_V1_RTCProxy
typealias PBTMInfo = Videoconference_V1_RTMInfo
typealias PBLargeMeetingAutoManagement = Videoconference_V1_LargeMeetingAutoManagement
typealias PBBreakoutRoomSettings = Videoconference_V1_BreakoutRoomSetting
typealias PBPanelistPermission = Videoconference_V1_PanelistPermission
typealias PBAttendeePermission = Videoconference_V1_AttendeePermission
typealias PBWebinarSettings = Videoconference_V1_WebinarSettings
typealias PBWebinarAttendeePermission = Videoconference_V1_WebinarAttendeePermission
typealias PBWebinarRehearsalStatusType = Videoconference_V1_WebinarRehearsalStatusType
typealias PBShareScreenToRoomConfirmationInfo = Videoconference_V1_ShareScreenToRoomResponse.ConfirmationInfo
typealias PBVideoChatDisplayOrderInfo = Videoconference_V1_VideoChatDisplayOrderInfo
typealias PBWebinarStageInfo = Videoconference_V1_WebinarStageInfo

typealias PBIntelligentMeetingSetting = Videoconference_V1_IntelligentMeetingSetting
typealias PBFeatureStatus = Videoconference_V1_FeatureStatus

typealias ServerPBVideoChatInfo = ServerPB_Videochat_VideoChatInfo
typealias ServerPBVideoChatSettings = ServerPB_Videochat_VideoChatSettings
typealias ServerPBNotesPermission = ServerPB_Videochat_NotesPermission
typealias ServerPBActionTime = ServerPB_Videochat_ActionTime
typealias ServerPBRustH323Setting = ServerPB_Videochat_VideoChatH323Setting
typealias ServerPBBreakoutRoomInfo = ServerPB_Videochat_BreakoutRoomInfo
typealias ServerPBSipSetting = ServerPB_Videochat_VideoChatSIPSetting
typealias ServerPBSecuritySetting = ServerPB_Videochat_VideoChatSecuritySetting
typealias ServerPBFeatureConfig = ServerPB_Videochat_FeatureConfig
typealias ServerPBManageCapabilities = ServerPB_Videochat_VCManageCapabilities
typealias ServerPBRTCProxy = ServerPB_Videochat_RTCProxy
typealias ServerPBRTCInfo = ServerPB_Videochat_RTCInfo
typealias ServerPBTMInfo = ServerPB_Videochat_RTMInfo
typealias ServerPBSIPInviteH323Access = ServerPB_Videochat_GetSIPInviteInfoResponse.H323Access
typealias ServerPBLargeMeetingAutoManagement = ServerPB_Videochat_LargeMeetingAutoManagement
typealias ServerPBPanelistPermission = ServerPB_Videochat_PanelistPermission
typealias ServerPBAttendeePermission = ServerPB_Videochat_AttendeePermission
typealias ServerPBWebinarSettings = ServerPB_Videochat_WebinarSettings
typealias ServerPBWebinarAttendeePermission = ServerPB_Videochat_WebinarAttendeePermission
typealias ServerPBWebinarRehearsalStatusType = ServerPB_Videochat_WebinarRehearsalStatusType

typealias ServerPBIntelligentMeetingSetting = ServerPB_Videochat_IntelligentMeetingSetting
typealias ServerPBFeatureStatus = ServerPB_Videochat_FeatureStatus

extension VideoChatInfo: RustResponse {
    typealias ProtobufType = Videoconference_V1_VideoChatInfo
    init(pb: PBVideoChatInfo) {
        let meetingID = pb.id
        self.init(id: meetingID, type: pb.type.vcType, participants: pb.participants.map({ $0.vcType(meetingID: meetingID) }),
                  groupId: pb.groupID, info: pb.info,
                  inviterId: pb.inviterID, inviterType: pb.inviterType.vcType,
                  hostId: pb.hostID,
                  hostType: pb.hostType.vcType,
                  hostDeviceId: pb.hostDeviceID,
                  force: pb.force,
                  endReason: .init(rawValue: pb.endReason.rawValue) ?? .unknown,
                  actionTime: pb.hasActionTime ? pb.actionTime.vcType : nil, seqId: pb.seqID,
                  settings: pb.settings.vcType,
                  vendorType: .init(rawValue: pb.vendorType.rawValue) ?? .unknown,
                  startTime: pb.startTime,
                  meetNumber: pb.meetNumber,
                  msg: pb.hasMsg ? pb.msg.vcType : nil,
                  meetingSource: .init(rawValue: pb.meetingSource.rawValue) ?? .unknown, isVoiceCall: pb.isVoiceCall,
                  sponsor: pb.sponsor.vcType, tenantId: pb.tenantID, isLarkMeeting: pb.isLarkMeeting,
                  meetingOwner: pb.hasMeetingOwner ? pb.meetingOwner.vcType : nil, isExternalMeetingWhenRing: pb.isExternalMeetingWhenRing,
                  sid: pb.hasSid ? pb.sid : nil, breakoutRoomInfos: pb.breakoutRoomInfos.map({ $0.vcType }),
                  rtcInfo: pb.hasRtcInfo ? pb.rtcInfo.vcType : nil,
                  rtmInfo: pb.hasRtmInfo ? pb.rtmInfo.vcType : nil,
                  isCrossWithKa: pb.isCrossWithKa,
                  uniqueId: pb.uniqueID,
                  webinarAttendeeNum: Int(pb.webinarAttendeeNum),
                  relationTagWhenRing: pb.relationTagWhenRing.vcType,
                  e2EeJoinInfo: pb.settings.isE2EeMeeting && pb.hasE2EeJoinInfo ? pb.e2EeJoinInfo.vcType : nil,
                  ringtone: pb.ringtone
        )
    }

    init(serverPb: ServerPBVideoChatInfo) {
        let meetingID = serverPb.id
        self.init(id: meetingID, type: serverPb.type.vcType, participants: serverPb.participants.map({ $0.vcType(meetingID: meetingID) }),
                  groupId: serverPb.groupID, info: serverPb.info,
                  inviterId: serverPb.inviterID, inviterType: serverPb.inviterType.vcType,
                  hostId: serverPb.hostID,
                  hostType: serverPb.hostType.vcType,
                  hostDeviceId: serverPb.hostDeviceID,
                  force: serverPb.force,
                  endReason: .init(rawValue: serverPb.endReason.rawValue) ?? .unknown,
                  actionTime: serverPb.hasActionTime ? serverPb.actionTime.vcType : nil, seqId: serverPb.seqID,
                  settings: serverPb.settings.vcType,
                  vendorType: .init(rawValue: serverPb.vendorType.rawValue) ?? .unknown,
                  startTime: serverPb.startTime,
                  meetNumber: serverPb.meetNumber,
                  msg: serverPb.hasMsg ? serverPb.msg.vcType : nil,
                  meetingSource: .init(rawValue: serverPb.meetingSource.rawValue) ?? .unknown, isVoiceCall: serverPb.isVoiceCall,
                  sponsor: serverPb.sponsor.vcType, tenantId: serverPb.tenantID, isLarkMeeting: serverPb.isLarkMeeting,
                  meetingOwner: serverPb.hasMeetingOwner ? serverPb.meetingOwner.vcType : nil, isExternalMeetingWhenRing: serverPb.isExternalMeetingWhenRing,
                  sid: serverPb.hasPushSid ? serverPb.pushSid : nil, breakoutRoomInfos: serverPb.breakoutRoomInfos.map({ $0.vcType }),
                  rtcInfo: serverPb.hasRtcInfo ? serverPb.rtcInfo.vcType : nil,
                  rtmInfo: serverPb.hasRtmInfo ? serverPb.rtmInfo.vcType : nil,
                  isCrossWithKa: serverPb.isCrossWithKa,
                  uniqueId: serverPb.uniqueID,
                  webinarAttendeeNum: Int(serverPb.webinarAttendeeNum),
                  relationTagWhenRing: serverPb.relationTagWhenRing.vcType,
                  e2EeJoinInfo: serverPb.hasE2EeJoinInfo ? serverPb.e2EeJoinInfo.vcType : nil,
                  ringtone: serverPb.ringtone
        )
    }
}

extension PBVideoChatInfo {
    var vcType: VideoChatInfo {
        .init(pb: self)
    }
}

extension ServerPBVideoChatInfo {
    var vcType: VideoChatInfo {
        .init(serverPb: self)
    }
}

extension PBRTCInfo {
    var vcType: MeetingRtcInfo {
        .init(rtcAppId: hasRtcAppID ? (rtcAppID.isEmpty ? nil : rtcAppID) : nil)
    }
}

extension ServerPBRTCInfo {
    var vcType: MeetingRtcInfo {
        .init(rtcAppId: hasRtcAppID ? (rtcAppID.isEmpty ? nil : rtcAppID) : nil)
    }
}

extension PBTMInfo {
    var vcType: MeetingRTMInfo {
        .init(signature: signature, url: url, reqKey: reqKey, pushPublicKey: pushPublicKey, token: token, uid: uid)
    }
}

extension ServerPBTMInfo {
    var vcType: MeetingRTMInfo {
        .init(signature: signature, url: url, reqKey: reqKey, pushPublicKey: pushPublicKey, token: token, uid: uid)
    }
}

extension PBVideoChatInfo.TypeEnum {
    var vcType: MeetingType {
        switch self {
        case .meet:
            return .meet
        case .call:
            return .call
        @unknown default:
            return .unknown
        }
    }
}

extension ServerPBVideoChatInfo.TypeEnum {
    var vcType: MeetingType {
        switch self {
        case .meet:
            return .meet
        case .call:
            return .call
        @unknown default:
            return .unknown
        }
    }
}

extension PBVideoChatSettings.SubType {
    var vcType: MeetingSubType {
        switch self {
        case .chatRoom:
            return .chatRoom
        case .followShare:
            return .followShare
        case .screenShare:
            return .screenShare
        case .wiredScreenShare:
            return .wiredScreenShare
        case .enterprisePhoneCall:
            return .enterprisePhoneCall
        case .webinar:
            return .webinar
        @unknown default:
            return .default
        }
    }
}

extension ServerPBVideoChatSettings.SubType {
    var vcType: MeetingSubType {
        switch self {
        case .chatRoom:
            return .chatRoom
        case .followShare:
            return .followShare
        case .screenShare:
            return .screenShare
        case .wiredScreenShare:
            return .wiredScreenShare
        case .samePageMeeting:
            return .samePageMeeting
        case .enterprisePhoneCall:
            return .enterprisePhoneCall
        case .webinar:
            return .webinar
        @unknown default:
            return .default
        }
    }
}

extension PBActionTime {
    var vcType: MeetingActionTime {
        .init(invite: invite, accept: accept, push: push)
    }
}

extension ServerPBActionTime {
    var vcType: MeetingActionTime {
        .init(invite: invite, accept: accept, push: push)
    }
}

extension PBLargeMeetingAutoManagement {
    var vcType: VideoChatSettings.AutoManageInfo {
        .init(
            enabled: enabled,
            items: [
                .allowParticipantUnmute: .init(rawValue: allowPartiUnmute.rawValue) ?? .unknown,
                .onlyHostCanShare: .init(rawValue: onlyHostCanShare.rawValue) ?? .unknown,
                .onlyPresenterCanAnnotate: .init(rawValue: onlyPresenterCanAnnotate.rawValue) ?? .unknown
            ]
        )
    }
}

extension ServerPBLargeMeetingAutoManagement {
    var vcType: VideoChatSettings.AutoManageInfo {
        .init(
            enabled: enabled,
            items: [
                .allowParticipantUnmute: .init(rawValue: allowPartiUnmute.rawValue) ?? .unknown,
                .onlyHostCanShare: .init(rawValue: onlyHostCanShare.rawValue) ?? .unknown,
                .onlyPresenterCanAnnotate: .init(rawValue: onlyPresenterCanAnnotate.rawValue) ?? .unknown
            ]
        )
    }
}

extension PBBreakoutRoomSettings {
    var vcType: VideoChatSettings.BreakoutRoomSettings {
        .init(
            allowReturnToMainRoom: allowReturn,
            autoFinishEnabled: autoFinish,
            autoFinishTime: TimeInterval(finishTime),
            notifyHostBeforeFinish: notifyFinish,
            countdownEnabled: customCountdown,
            countdownDuration: TimeInterval(countdown)
        )
    }
}

extension PBVideoChatSettings {
    var vcType: VideoChatSettings {
        .init(topic: topic, isMicrophoneMuted: isMicrophoneMuted, isCameraMuted: isCameraMuted, subType: subType.vcType,
              maxParticipantNum: maxParticipantNum, maxVideochatDuration: maxVideochatDuration,
              planType: .init(rawValue: planType.rawValue) ?? .planFree,
              shouldEarlyJoin: shouldEarlyJoin, isLocked: isLocked, isMuteOnEntry: isMuteOnEntry, planTimeLimit: planTimeLimit,
              securitySetting: securitySetting.vcType,
              i18nDefaultTopic: .init(i18NKey: i18NDefaultTopic.i18NKey),
              lastSecuritySetting: hasLastSecuritySetting ? lastSecuritySetting.vcType : nil,
              featureConfig: hasFeatureConfig ? featureConfig.vcType : nil, allowPartiUnmute: allowPartiUnmute,
              sipSetting: hasSipSetting ? sipSetting.vcType : nil,
              isOwnerJoinedMeeting: isOwnerJoinedMeeting, onlyHostCanShare: onlyHostCanShare,
              manageCapabilities: manageCapabilities.vcType,
              onlyHostCanReplaceShare: onlyHostCanReplaceShare, maxSoftRtcNormalMode: maxSoftRtcNormalMode,
              rtcProxy: hasRtcProxy ? rtcProxy.vcType : nil,
              isMeetingOpenInterpretation: isMeetingOpenInterpretation,
              meetingSupportLanguages: meetingSupportLanguages.map({ $0.vcType }),
              isBoxSharing: isBoxSharing, onlyPresenterCanAnnotate: onlyPresenterCanAnnotate,
              countdownDuration: hasCountdownDuration ? countdownDuration : nil,
              isOpenBreakoutRoom: isOpenBreakoutRoom,
              h323Setting: hasH323Setting ? h323Setting.vcType : nil,
              isQuotaMeeting: isQuotaMeeting,
              isPartiChangeNameForbidden: isPartiChangeNameForbidden,
              isSupportNoHost: isSupportNoHost,
              autoManageInfo: hasLargeMeetingAutoManagement ? largeMeetingAutoManagement.vcType : nil,
              breakoutRoomSettings: hasBreakoutRoomSetting ? breakoutRoomSetting.vcType : nil,
              useImChat: useImChat,
              bindChatId: bindChatID, panelistPermission: panelistPermission.vcType,
              attendeePermission: attendeePermission.vcType,
              webinarSettings: hasWebinarSettings ? webinarSettings.vcType : nil,
              isE2EeMeeting: isE2EeMeeting,
              notePermission: notePermission.vcType,
              intelligentMeetingSetting: intelligentMeetingSetting.vcType)
    }
}

extension PBNotesPermission {
    var vcType: NotesPermission {
        .init(isOwnerOrganizer: isOwnerOrganizer,
              createPermission: .init(rawValue: createPermission.rawValue) ?? .unknown,
              editpermission: .init(rawValue: editPermission.rawValue) ?? .unknown)
    }
}

extension ServerPBVideoChatSettings {
    var vcType: VideoChatSettings {
        .init(topic: topic, isMicrophoneMuted: isMicrophoneMuted, isCameraMuted: isCameraMuted, subType: subType.vcType,
              maxParticipantNum: maxParticipantNum, maxVideochatDuration: maxVideochatDuration,
              planType: .init(rawValue: planType.rawValue) ?? .planFree,
              shouldEarlyJoin: shouldEarlyJoin, isLocked: isLocked, isMuteOnEntry: isMuteOnEntry, planTimeLimit: planTimeLimit,
              securitySetting: securitySetting.vcType,
              i18nDefaultTopic: .init(i18NKey: i18NDefaultTopic.i18NKey),
              lastSecuritySetting: hasLastSecuritySetting ? lastSecuritySetting.vcType : nil,
              featureConfig: hasFeatureConfig ? featureConfig.vcType : nil, allowPartiUnmute: allowPartiUnmute,
              sipSetting: hasSipSetting ? sipSetting.vcType : nil,
              isOwnerJoinedMeeting: isOwnerJoinedMeeting, onlyHostCanShare: onlyHostCanShare,
              manageCapabilities: manageCapabilities.vcType,
              onlyHostCanReplaceShare: onlyHostCanReplaceShare, maxSoftRtcNormalMode: maxSoftRtcNormalMode,
              rtcProxy: hasRtcProxy ? rtcProxy.vcType : nil,
              isMeetingOpenInterpretation: isMeetingOpenInterpretation,
              meetingSupportLanguages: meetingSupportLanguages.map({ $0.vcType }),
              isBoxSharing: isBoxSharing, onlyPresenterCanAnnotate: onlyPresenterCanAnnotate,
              countdownDuration: hasCountdownDuration ? countdownDuration : nil,
              isOpenBreakoutRoom: isOpenBreakoutRoom,
              h323Setting: hasH323Setting ? h323Setting.vcType : nil,
              isQuotaMeeting: isQuotaMeeting,
              isPartiChangeNameForbidden: isPartiChangeNameForbidden,
              isSupportNoHost: isSupportNoHost,
              autoManageInfo: hasLargeMeetingAutoManagement ? largeMeetingAutoManagement.vcType : nil,
              breakoutRoomSettings: nil,
              useImChat: false,
              bindChatId: "",
              panelistPermission: panelistPermission.vcType,
              attendeePermission: attendeePermission.vcType,
              webinarSettings: hasWebinarSettings ? webinarSettings.vcType : nil,
              isE2EeMeeting: isE2EeMeeting,
              notePermission: notePermission.vcType,
              intelligentMeetingSetting: intelligentMeetingSetting.vcType)
    }
}

extension ServerPBNotesPermission {
    var vcType: NotesPermission {
        .init(isOwnerOrganizer: isOwnerOrganizer,
              createPermission: .init(rawValue: createPermission.rawValue) ?? .unknown,
              editpermission: .init(rawValue: editPermission.rawValue) ?? .unknown)
    }
}

extension PBWebinarSettings {
   var vcType: WebinarSettings {
       .init(attendeePermission: attendeePermission.vcType,
             maxAttendeeNum: self.hasMaxAttendeeNum ? self.maxAttendeeNum : nil,
             rehearsalStatus: rehearsalStatus.vcType)
   }
}

extension ServerPBWebinarSettings {
    var vcType: WebinarSettings {
        .init(attendeePermission: attendeePermission.vcType,
              maxAttendeeNum: self.hasMaxAttendeeNum ? self.maxAttendeeNum : nil,
              rehearsalStatus: rehearsalStatus.vcType)
    }
}

extension PBWebinarAttendeePermission {
    var vcType: WebinarAttendeePermission {
        .init(allowIm: allowIm, allowChangeName: allowChangeName, allowHandsUp: allowHandsUp)
    }
}

extension ServerPBWebinarAttendeePermission {
    var vcType: WebinarAttendeePermission {
        .init(allowIm: allowIm, allowChangeName: allowChangeName, allowHandsUp: allowHandsUp)
    }
}

extension PBWebinarRehearsalStatusType {
    var vcType: WebinarRehearsalStatusType {
        .init(rawValue: rawValue) ?? .unknown
    }
}

extension ServerPBWebinarRehearsalStatusType {
    var vcType: WebinarRehearsalStatusType {
        .init(rawValue: rawValue) ?? .unknown
    }
}

extension PBSipSetting {
    var vcType: VideoChatSettings.SIPSetting {
        .init(domain: domain, ercDomainList: ercDomainList, isShowCrc: isShowCrc)
    }
}

extension ServerPBSipSetting {
    var vcType: VideoChatSettings.SIPSetting {
        .init(domain: domain, ercDomainList: ercDomainList, isShowCrc: isShowCrc)
    }
}

extension PBSecuritySetting {
    var vcType: VideoChatSettings.SecuritySetting {
        .init(securityLevel: .init(rawValue: securityLevel.rawValue) ?? .unknown,
              groupIds: groupIds, userIds: userIds, roomIds: roomIds,
              isOpenLobby: isOpenLobby,
              specialGroupType: specialGroupType.map({ .init(rawValue: $0.rawValue) ?? .unknown }))
    }
}

extension ServerPBSecuritySetting {
    var vcType: VideoChatSettings.SecuritySetting {
        .init(securityLevel: .init(rawValue: securityLevel.rawValue) ?? .unknown,
              groupIds: groupIds, userIds: userIds, roomIds: roomIds,
              isOpenLobby: isOpenLobby,
              specialGroupType: specialGroupType.map({ .init(rawValue: $0.rawValue) ?? .unknown }))
    }
}

extension PBFeatureConfig {
    var vcType: FeatureConfig {
        .init(liveEnable: liveEnable, recordEnable: recordEnable, localRecordEnable: localRecordEnable, hostControlEnable: hostControlEnable,
              pstn: pstn.vcType, shareMeeting: shareMeeting.vcType, sip: sip.vcType, magicShare: magicShare.vcType,
              relationChain: relationChain.vcType, interpretationEnable: interpretationEnable, chatHistoryEnabled: recordMessageEnable, recordCloseReason: recordCloseReason.vcType, voteConfig: voteConfig.vcType, whiteboardConfig: whiteboardConfig.vcType, transcriptConfig: transcriptConfig.vcType, myAIConfig: myAiConfig.vcType)
    }
}

extension PBFeatureConfig.RecordCloseReason {
    var vcType: FeatureConfig.RecordCloseReason {
        .init(rawValue: self.rawValue) ?? .unknown
    }
}

extension ServerPBFeatureConfig {
    var vcType: FeatureConfig {
        .init(liveEnable: liveEnable, recordEnable: recordEnable, localRecordEnable: localRecordEnable, hostControlEnable: hostControlEnable,
              pstn: pstn.vcType, shareMeeting: shareMeeting.vcType, sip: sip.vcType, magicShare: magicShare.vcType,
              relationChain: relationChain.vcType, interpretationEnable: interpretationEnable, chatHistoryEnabled: recordMessageEnable, recordCloseReason: recordCloseReason.vcType, voteConfig: voteConfig.vcType, whiteboardConfig: FeatureConfig.WhiteboardConfig(startWhiteboardEnable: true), transcriptConfig: FeatureConfig.TranscriptConfig(transcriptEnable: true), myAIConfig: .init(myAiEnable: true))
    }
}

extension ServerPBFeatureConfig.RecordCloseReason {
    var vcType: FeatureConfig.RecordCloseReason {
        .init(rawValue: self.rawValue) ?? .unknown
    }
}

extension PBFeatureConfig.Pstn {
    var vcType: FeatureConfig.Pstn {
        .init(outGoingCallEnable: outGoingCallEnable, incomingCallEnable: incomingCallEnable)
    }
}

extension ServerPBFeatureConfig.Pstn {
    var vcType: FeatureConfig.Pstn {
        .init(outGoingCallEnable: outGoingCallEnable, incomingCallEnable: incomingCallEnable)
    }
}

extension PBFeatureConfig.Sip {
    var vcType: FeatureConfig.Sip {
        .init(outGoingCallEnable: outGoingCallEnable, incomingCallEnable: incomingCallEnable)
    }
}

extension ServerPBFeatureConfig.Sip {
    var vcType: FeatureConfig.Sip {
        .init(outGoingCallEnable: outGoingCallEnable, incomingCallEnable: incomingCallEnable)
    }
}

extension PBFeatureConfig.ShareMeeting {
    var vcType: FeatureConfig.ShareMeeting {
        .init(inviteEnable: inviteEnable, copyMeetingLinkEnable: copyMeetingLinkEnable, shareCardEnable: shareCardEnable)
    }
}

extension ServerPBFeatureConfig.ShareMeeting {
    var vcType: FeatureConfig.ShareMeeting {
        .init(inviteEnable: inviteEnable, copyMeetingLinkEnable: copyMeetingLinkEnable, shareCardEnable: shareCardEnable)
    }
}

extension PBFeatureConfig.MagicShare {
    var vcType: FeatureConfig.MagicShare {
        .init(startCcmEnable: startCcmEnable, newCcmEnable: newCcmEnable)
    }
}

extension ServerPBFeatureConfig.MagicShare {
    var vcType: FeatureConfig.MagicShare {
        .init(startCcmEnable: startCcmEnable, newCcmEnable: newCcmEnable)
    }
}

extension PBFeatureConfig.RelationChain {
    var vcType: FeatureConfig.RelationChain {
        .init(browseUserProfileEnable: browseUserProfileEnable, enterGroupEnable: enterGroupEnable)
    }
}

extension ServerPBFeatureConfig.RelationChain {
    var vcType: FeatureConfig.RelationChain {
        .init(browseUserProfileEnable: browseUserProfileEnable, enterGroupEnable: enterGroupEnable)
    }
}

extension PBFeatureConfig.VoteConfig {
    var vcType: FeatureConfig.VoteConfig {
        .init(allowVote: allowVote, quotaIsOn: quotaIsOn)
    }
}

extension ServerPBFeatureConfig.VoteConfig {
    var vcType: FeatureConfig.VoteConfig {
        .init(allowVote: allowVote, quotaIsOn: quotaIsOn)
    }
}

extension PBFeatureConfig.WhiteboardConfig {
    var vcType: FeatureConfig.WhiteboardConfig {
        .init(startWhiteboardEnable: startWhiteboardEnable)
    }
}


extension PBManageCapabilities {
    var vcType: VideoChatSettings.ManageCapabilities {
        .init(vcLobby: vcLobby, forceMuteMicrophone: forceMuteMicrophone, sharePermission: sharePermission,
              forceGetSharePermission: forceGetSharePermission, onlyPresenterCanAnnotate: onlyPresenterCanAnnotate)
    }
}

extension ServerPBManageCapabilities {
    var vcType: VideoChatSettings.ManageCapabilities {
        .init(vcLobby: vcLobby, forceMuteMicrophone: forceMuteMicrophone, sharePermission: sharePermission,
              forceGetSharePermission: forceGetSharePermission, onlyPresenterCanAnnotate: onlyPresenterCanAnnotate)
    }
}

extension PBRTCProxy {
    var vcType: RTCProxy {
        .init(status: status, proxyType: .init(rawValue: proxyType.rawValue) ?? .unknown,
              proxyIp: proxyIp, proxyPort: proxyPort, userName: userName, passport: passport)
    }
}

extension ServerPBRTCProxy {
    var vcType: RTCProxy {
        .init(status: status, proxyType: .init(rawValue: proxyType.rawValue) ?? .unknown,
              proxyIp: proxyIp, proxyPort: proxyPort, userName: userName, passport: passport)
    }
}

extension RTCProxy {
    var pbType: PBRTCProxy {
        var pb = PBRTCProxy()
        pb.status = status
        pb.proxyType = .init(rawValue: proxyType.rawValue) ?? .unknown
        pb.proxyIp = proxyIp
        pb.proxyPort = proxyPort
        pb.userName = userName
        pb.passport = passport
        return pb
    }

    var serverPbType: ServerPBRTCProxy {
        var pb = ServerPBRTCProxy()
        pb.status = status
        pb.proxyType = .init(rawValue: proxyType.rawValue) ?? .unknown
        pb.proxyIp = proxyIp
        pb.proxyPort = proxyPort
        pb.userName = userName
        pb.passport = passport
        return pb
    }
}

extension PBRustH323Setting {
    var vcType: H323Setting {
        .init(h323AccessList: h323AccessList.map({ H323Setting.H323Access(ip: $0.ip, country: $0.country) }), ercDomainList: ercDomainList, isShowCrc: isShowCrc)
    }
}

extension PBBreakoutRoomInfo {
    var vcType: BreakoutRoomInfo {
        .init(breakoutRoomId: breakoutRoomID, topic: topic, startTime: startTime, channelId: channelID,
              status: .init(rawValue: status.rawValue) ?? .unknown,
              recordingStatus: .init(rawValue: recordingStatus.rawValue) ?? .unknown,
              countDownFromStartTime: countDownFromStartTime,
              finishFromStartTime: finishFromStartTime,
              sortId: sortID,
              closeReason: .init(rawValue: closeReason.rawValue) ?? .unknown)
    }
}

extension ServerPBBreakoutRoomInfo {
    var vcType: BreakoutRoomInfo {
        .init(breakoutRoomId: breakoutRoomID, topic: topic, startTime: startTime, channelId: channelID,
              status: .init(rawValue: status.rawValue) ?? .unknown,
              recordingStatus: .init(rawValue: recordingStatus.rawValue) ?? .unknown,
              countDownFromStartTime: countDownFromStartTime,
              finishFromStartTime: finishFromStartTime,
              sortId: sortID,
              closeReason: .unknown) // TODO @mzx
    }
}

extension PBServerH323Setting {
    var vcType: H323Setting {
        .init(h323AccessList: h323AccessList.map({ H323Setting.H323Access(ip: $0.ip, country: $0.country) }), ercDomainList: ercDomainList, isShowCrc: isShowCrc)
    }
}

extension ServerPBSIPInviteH323Access {
    var vcType: GetSIPInviteInfoResponse.H323Access {
        .init(ip: ip, country: country)
    }
}

extension PBPanelistPermission {
    var vcType: PanelistPermission {
        .init(allowSendMessage: allowSendMessage,
              allowSendReaction: allowSendReaction,
              allowRequestRecord: allowRequestRecord,
              allowVirtualAvatar: allowVirtualAvatar,
              allowVirtualBackground: allowVirtualBackground,
              messageButtonStatus: PanelistPermission.MessageButtonStatus(rawValue: messageButtonStatus.rawValue) ?? .default)
    }
}

extension ServerPBPanelistPermission {
    var vcType: PanelistPermission {
        .init(allowSendMessage: allowSendMessage,
              allowSendReaction: allowSendReaction,
              allowRequestRecord: allowRequestRecord,
              allowVirtualAvatar: allowVirtualAvatar,
              allowVirtualBackground: allowVirtualBackground,
              messageButtonStatus: .default)
    }
}

extension PBAttendeePermission {
    var vcType: AttendeePermission {
        .init(allowSendMessage: allowSendMessage, allowSendReaction: allowSendReaction)
    }
}

extension ServerPBAttendeePermission {
    var vcType: AttendeePermission {
        .init(allowSendMessage: allowSendMessage, allowSendReaction: allowSendReaction)
    }
}

extension PBShareScreenToRoomConfirmationInfo {
    var vcType: ShareScreenToRoomResponse.ConfirmationInfo {
        .init(needConfirm: needConfirm,
              roomInfo: .init(roomID: roomInfo.roomID,
                              tanentID: roomInfo.tanentID,
                              fullName: roomInfo.fullName))
    }
}

extension PBVideoChatDisplayOrderInfo {
    var vcType: VideoChatDisplayOrderInfo {
        .init(action: .init(rawValue: action.rawValue) ?? .videoChatOrderUnknown,
              orderList: orderList.map { $0.vcType },
              shareStreamInsertPosition: shareStreamInsertPosition == -1 ? 1 : shareStreamInsertPosition,
              versionID: versionID,
              indexBegin: indexBegin,
              hostSyncSeqID: hostSyncSeqID,
              hasMore_p: hasMore_p)
    }
}

extension PBFeatureConfig.TranscriptConfig {
    var vcType: FeatureConfig.TranscriptConfig {
        .init(transcriptEnable: transcriptEnable)
    }
}

extension PBFeatureConfig.MyAIConfig {
    var vcType: FeatureConfig.MyAIConfig {
        .init(myAiEnable: myAiEnable)
    }
}

/// Videoconference_V1_IntelligentMeetingSetting
/// ServerPB_Videochat_IntelligentMeetingSetting
public struct IntelligentMeetingSetting: Codable, Equatable {
    /// 在妙记中生成智能会议纪要
    public var generateMeetingSummaryInMinutes: FeatureStatus
    /// 在纪要文档中生成智能会议纪要
    public var generateMeetingSummaryInDocs: FeatureStatus
    /// 在会议中使用 AI 对话
    public var chatWithAiInMeeting: FeatureStatus
    /// 兼容老版本，默认值false表示会中AI依赖录制
    public var isAINotDependRecording: Bool
    /// 参会人请求打开ai能力
    public var permData: AICapabilityPermData
}

extension IntelligentMeetingSetting {
    var pbType: PBIntelligentMeetingSetting {
        var setting = PBIntelligentMeetingSetting()
        setting.generateMeetingSummaryInMinutes = .init(rawValue: generateMeetingSummaryInMinutes.rawValue) ?? .unknown
        setting.generateMeetingSummaryInDocs = .init(rawValue: generateMeetingSummaryInDocs.rawValue) ?? .unknown
        setting.chatWithAiInMeeting = .init(rawValue: chatWithAiInMeeting.rawValue) ?? .unknown
        return setting
    }
    var serverPbType: ServerPB_Videochat_IntelligentMeetingSetting {
        var setting = ServerPB_Videochat_IntelligentMeetingSetting()
        setting.generateMeetingSummaryInMinutes = .init(rawValue: generateMeetingSummaryInMinutes.rawValue) ?? .unknown
        setting.generateMeetingSummaryInDocs = .init(rawValue: generateMeetingSummaryInDocs.rawValue) ?? .unknown
        setting.chatWithAiInMeeting = .init(rawValue: chatWithAiInMeeting.rawValue) ?? .unknown
        return setting
    }
}

extension PBIntelligentMeetingSetting {
    var vcType: IntelligentMeetingSetting {
        .init(generateMeetingSummaryInMinutes: .init(rawValue: generateMeetingSummaryInMinutes.rawValue) ?? .featureStatusUnknown,
              generateMeetingSummaryInDocs: .init(rawValue: generateMeetingSummaryInDocs.rawValue) ?? .featureStatusUnknown,
              chatWithAiInMeeting: .init(rawValue: chatWithAiInMeeting.rawValue) ?? .featureStatusUnknown, isAINotDependRecording: isAiNotDependRecording, permData: aiCapabilityPermData.vcType)
    }
}

public enum FeatureStatus: Int, Codable {
    case featureStatusUnknown = 0
    case featureStatusDisabled
    case featureStatusOn
    case featureStatusOff

    public var isValid: Bool {
        switch self {
        case .featureStatusOn, .featureStatusOff: return true
        default: return false
        }
    }

    public var isOn: Bool {
        switch self {
        case .featureStatusOn: return true
        default: return false
        }
    }

    public var isOff: Bool {
        switch self {
        case .featureStatusOff: return true
        default: return false
        }
    }

    public var isOffOrInvalid: Bool {
        switch self {
        case .featureStatusOn: return false
        default: return true
        }
    }
}

extension ServerPBIntelligentMeetingSetting {
    var vcType: IntelligentMeetingSetting {
        .init(generateMeetingSummaryInMinutes: .init(rawValue: generateMeetingSummaryInMinutes.rawValue) ?? .featureStatusUnknown,
              generateMeetingSummaryInDocs: .init(rawValue: generateMeetingSummaryInDocs.rawValue) ?? .featureStatusUnknown,
              chatWithAiInMeeting: .init(rawValue: chatWithAiInMeeting.rawValue) ?? .featureStatusUnknown, isAINotDependRecording: isAiNotDependRecording, permData: aiCapabilityPermData.vcType)
    }
}
