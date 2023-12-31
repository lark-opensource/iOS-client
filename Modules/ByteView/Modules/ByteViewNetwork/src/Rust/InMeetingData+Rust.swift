//
//  InMeetingData+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import RustPB

typealias PBInMeetingData = Videoconference_V1_InMeetingData
typealias PBMinutesStatusData = Videoconference_V1_MinutesStatusData
typealias PBCountDownInfo = Videoconference_V1_CountDownInfo
typealias PBTranscriptInfo = Videoconference_V1_TranscriptInfo

extension InMeetingData: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_InMeetingData
    init(pb: Videoconference_V1_InMeetingData) throws {
        guard let type = InMeetingDataType(rawValue: pb.type.rawValue) else {
            throw ProtobufCodableError(.notSupported, "unsupported type: \(pb.type)")
        }

        self.seqID = pb.seqID
        self.type = type
        self.meetingID = pb.meetingID
        self.settingsChangedData = pb.hasSettingsChangedData ? pb.settingsChangedData.vcType : nil
        self.hostTransferData = pb.hasHostTransferData ? pb.hostTransferData.vcType : nil
        self.muteAllData = pb.hasMuteAllData ? pb.muteAllData.vcType : nil
        self.recordingData = pb.hasRecordingData ? pb.recordingData.vcType : nil
        self.transcriptInfo = pb.hasTranscriptInfo ? pb.transcriptInfo.vcType : nil
        self.subtitleStatusData = pb.hasSubtitleStatusData ? pb.subtitleStatusData.vcType : nil
        self.liveData = pb.hasLiveData ? pb.liveData.vcType : nil
        self.meetingOwner = pb.hasMeetingOwner ? pb.meetingOwner.vcType : nil
        self.minutesStatusData = pb.hasMinutesStatusData ? pb.minutesStatusData.vcType : nil
        self.focusVideoData = pb.hasFocusVideoData ? pb.focusVideoData.vcType : nil
        self.countDownInfo = pb.hasCountDownInfo ? pb.countDownInfo.vcType : nil
        self.attendeeNum = pb.hasAttendeeNum ? pb.attendeeNum : nil
        self.unsafeLeaveParticipant = pb.hasUnsafeLeaveParticipant ? pb.unsafeLeaveParticipant.vcType(meetingID: self.meetingID) : nil
        self.participantsChangedData = pb.hasParticipantsChangedData ? pb.participantsChangedData.vcType(meetingID: pb.meetingID) : nil
        self.voteStatistic = pb.hasVoteStatistic ? pb.voteStatistic.vcType : nil
        self.videoChatDisplayOrderInfo = pb.hasVideoChatDisplayOrderInfo ? pb.videoChatDisplayOrderInfo.vcType : nil
        self.stageInfo = pb.hasStageInfo ? pb.stageInfo.vcType : nil
        self.notesPermission = pb.hasNotesPermission ? pb.notesPermission.vcType : nil
        self.intelligentMeetingSetting = pb.hasIntelligentMeetingSetting ? pb.intelligentMeetingSetting.vcType : nil
    }
}

extension PBInMeetingData.SettingsChangedData {
    var vcType: InMeetingData.SettingsChangedData {
        .init(meetingSettings: meetingSettings.vcType)
    }
}

extension PBInMeetingData.HostTransferredData {
    var vcType: InMeetingData.HostTransferredData {
        .init(hostID: hostID, hostType: hostType.vcType, hostDeviceID: hostDeviceID)
    }
}

extension PBInMeetingData.AllMicrophoneMutedData {
    var vcType: InMeetingData.AllMicrophoneMutedData {
        .init(isMuted: isMuted, operationUser: operationUser.vcType, breakoutRoomID: breakoutRoomID)
    }
}

extension PBInMeetingData.ScreenSharedData {
    var vcType: ScreenSharedData {
        .init(isSharing: isSharing, participantID: participantID, participantType: participantType.vcType,
              participantDeviceID: participantDeviceID, width: width, height: height, shareScreenID: shareScreenID,
              isSketch: isSketch, canSketch: canSketch, version: version, accessibility: accessibility,
              isSmoothMode: isSmoothMode, isPortraitMode: isPortraitMode,
              sketchTransferMode: .init(rawValue: sketchTransferMode.rawValue) ?? .byData,
              sketchFitMode: .init(rawValue: sketchFitMode.rawValue) ?? .sketchCubicFitting,
              sharerTenantWatermarkOpen: extraInfo.sharerTenantWatermarkOpen,
              enableCursorShare: extraInfo.enableCursorShare,
              ccmInfo: hasCcmInfo ? ccmInfo.vcType : nil,
              isSharingPause: isSharingPause)
    }
}

extension PBInMeetingData.ScreenSharedData.CCMInfo {
    var vcType: CCMInfo {
        .init(status: status.vcType,
              url: url,
              token: token,
              type: type.vcType,
              title: title,
              memberID: memberID,
              isAllowFollowerOpenCcm: isAllowFollowerOpenCcm,
              extraInfo: extraInfo.vcType,
              rawURL: rawURL,
              strategies: strategies.map { $0.vcType },
              hasSharePermission_p: hasSharePermission_p,
              thumbnail: thumbnail.vcType)
    }
}

extension PBInMeetingData.ScreenSharedData.CCMInfoStatus {
    var vcType: CCMInfoStatus {
        .init(rawValue: rawValue) ?? .validating
    }
}

extension PBInMeetingData.LiveMeetingData {
    var vcType: InMeetingData.LiveMeetingData {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown, liveInfo: liveInfo.vcType, requester: requester.vcType)
    }
}

extension PBInMeetingData.LiveMeetingData.LiveInfo {
    var vcType: LiveInfo {
        .init(liveID: liveID, liveSessionID: liveSessionID, liveName: liveName, liveURL: liveURL, isLiving: isLiving,
              liveVote: hasLiveVote ? liveVote.vcType : nil,
              sid: sid, privilege: .init(rawValue: privilege.rawValue) ?? .unknown,
              defaultPrivilege: .init(rawValue: defaultPrivilege.rawValue) ?? .unknown,
              layoutStyle: .init(rawValue: layoutStyle.rawValue) ?? .unknown,
              defaultLayoutStyle: .init(rawValue: defaultLayoutStyle.rawValue) ?? .unknown,
              enableLiveComment: enableLiveComment, enablePlayback: enablePlayback, defaultEnableLiveComment: defaultEnableLiveComment, livePermissionMemberChanged: livePermissionMemberChanged)
    }
}

extension PBInMeetingData.LiveMeetingData.LiveVote {
    var vcType: LiveVote {
        .init(voteID: voteID, isVoting: isVoting, reason: .init(rawValue: reason.rawValue) ?? .unknown, sponsorID: sponsorID)
    }
}

extension PBInMeetingData.RecordMeetingData {
    var vcType: RecordMeetingData {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown, isRecording: isRecording, requester: requester.vcType,
              policyURL: policyURL, needUploadTimezone: needUploadTimezone,
              recordingStopV2: hasRecordingStopV2 ? recordingStopV2.vcType : nil,
              recordingStatus: recordingStatus.vcType)
    }
}

extension PBTranscriptInfo {
    var vcType: TranscriptInfo {
        return .init(type: .init(rawValue: type.rawValue) ?? .unknown, requester: requester.vcType,
              policyURL: policyURL,
              transcriptStopV2: hasTranscriptStop ? transcriptStop.vcType : nil,
              transcriptStatus: transcriptStatus.vcType)
    }
}

extension PBTranscriptInfo.TranscriptStatus {
    var vcType: TranscriptInfo.TranscriptStatus {
        switch self {
        case .transcriptUnknown: return .unknown
        case .transcriptNone: return .none
        case .transcriptInitializing: return .initializing
        case .transcriptIng: return .ing
        case .transcriptPause: return .pause
        @unknown default:
            return .unknown
        }
    }
}

extension PBInMeetingData.RecordMeetingData.RecordingStatus {
    var vcType: RecordMeetingData.RecordingStatus {
        switch self {
        case .unknownStatus: return .unknown
        case .none: return .none
        case .meetingRecording: return .meetingRecording
        case .localRecording: return .localRecording
        case .multiRecording: return .multiRecording
        case .meetingRecordInitializing: return .meetingRecordInitializing
        @unknown default:
            return .unknown
        }
    }
}

extension PBInMeetingData.SubtitleStatusData {
    var vcType: SubtitleStatusData {
        .init(isSubtitleOn: isSubtitleOn, status: .init(rawValue: status.rawValue) ?? .unknown,
              globalSpokenLanguage: globalSpokenLanguage,
              langDetectInfo: langDetectInfo.vcType, firstOneOpenSubtitle: firstOneOpenSubtitle.vcType,
              monitor: .init(reuseAsrTask: monitor.reuseAsrTask), breakoutRoomId: breakoutRoomID)
    }
}

extension PBInMeetingData.SubtitleStatusData.LangDetectInfo {
    var vcType: SubtitleStatusData.LangDetectInfo {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown, language: language, languageKey: languageKey,
              detectedLanguage: detectedLanguage, detectedLanguageKey: detectedLanguageKey)
    }
}

extension PBMinutesStatusData {
    var vcType: MinutesStatusData {
        .init(status: .init(rawValue: status.rawValue) ?? .unknown, seq: seq)
    }
}

extension PBInMeetingData.FocusVideoData {
    var vcType: FocusVideoData {
        .init(focusUser: focusUser.vcType, version: version)
    }
}

extension PBCountDownInfo {
    var vcType: CountDownInfo {
        .init(lastAction: .init(rawValue: lastAction.rawValue) ?? .unknown, countDownEndTime: countDownEndTime, needPlayAudioEnd: needPlayAudioEnd, operator: `operator`.vcType, remindersInSeconds: remindersInSeconds.isEmpty ? nil : remindersInSeconds)
    }
}

extension PBInMeetingData.ParticipantsChangedData {
    func vcType(meetingID: String) -> InMeetingData.ParticipantsChangedData {
        .init(participants: participants.map({ $0.vcType(meetingID: meetingID) }), operationSource: .init(rawValue: operationSource.rawValue) ?? .unknownSource)
    }
}

extension PBWebinarStageInfo.DraggedLayoutInfo {
    var vcType: WebinarStageInfo.DraggedLayoutInfo {
        .init(guestAreaRatio: self.guestAreaRatio,
              guestItemRatio: self.guestItemRatio,
              guestLayoutColumn: self.guestLayoutColumn)
    }

}


extension PBWebinarStageInfo {
    var vcType: WebinarStageInfo {
        // aciton 字段废弃, 新版本使用 actionV2
        .init(actionV2: .init(rawValue: actionV2.rawValue) ?? .unkonwn,
              sharingPosition: .init(rawValue: sharingPosition.rawValue) ?? .shareUnknown,
              backgroundToken: self.hasBackgroundToken ? backgroundToken : nil,
              backgroundURL: self.hasBackgroundURL ? backgroundURL : nil,
              syncUser: self.hasSyncUser ? syncUser.vcType : nil,
              guests: guests.map(\.vcType),
              allowGuestsChangeView: self.allowGuestsChangeView,
              showFullVideoFrame: self.showFullVideoFrame,
              hideSharing: self.hideSharing,
              draggedLayoutInfo: self.hasDraggedLayoutInfo ? self.draggedLayoutInfo.vcType : nil,
              guestFloatingPos: .init(rawValue: self.guestFloatingPos.rawValue) ?? .floatingUnknown,
              version: self.hasVersion ? version : nil
        )
    }
}
