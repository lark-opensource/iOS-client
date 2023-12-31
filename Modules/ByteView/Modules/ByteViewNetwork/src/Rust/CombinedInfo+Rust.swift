//
//  CombinedInfo+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import RustPB

typealias PBVideoChatInMeetingInfo = Videoconference_V1_VideoChatInMeetingInfo

extension PBVideoChatInMeetingInfo {
    func toVcType() -> VideoChatInMeetingInfo {
        return VideoChatInMeetingInfo.init(
            id: id,
            vcType: vcType.vcType,
            isRecording: isRecording,
            hasRecorded: hasRecorded_p,
            shouldPullSuggested: shouldPullSuggested,
            meetingURL: meetingURL,
            isSubtitleOn: hasIsSubtitleOn ? isSubtitleOn : nil,
            version: version,
            meetingSettings: meetingSettings.vcType,
            followInfo: hasFollowInfo ? followInfo.vcType : nil,
            shareScreen: hasShareScreenInMeetingInfo ? shareScreenInMeetingInfo.vcType : nil,
            whiteboardInfo: hasWhiteboardInfo ? whiteboardInfo.vcType : nil,
            videoChatDisplayOrderInfo: hasVideoChatDisplayOrderInfo ? videoChatDisplayOrderInfo.vcType : nil,
            liveInfo: hasLiveInfo ? liveInfo.vcType : nil,
            recordingData: hasRecordingData ? recordingData.vcType : nil,
            transcriptInfo: hasTranscriptInfo ? transcriptInfo.vcType: nil,
            breakoutRoomInfos: breakoutRoomInfos.map({ $0.vcType }),
            minutesStatusData: hasMinutesStatusData ? minutesStatusData.vcType : nil,
            focusVideoData: hasFocusVideoData ? focusVideoData.vcType : nil,
            countDownInfo: hasCountDownInfo ? countDownInfo.vcType : nil,
            interpretationSetting: hasInterpretationSetting ? interpretationSetting.vcType : nil,
            notesInfo: hasNotesInfo ? notesInfo.vcType : nil,
            voteList: voteList.map { $0.vcType },
            stageInfo: hasStageInfo ? stageInfo.vcType : nil
        )
    }
}
