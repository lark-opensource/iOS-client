//
//  VideoChatExtraInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import ByteViewCommon

typealias PBVideoChatExtraInfo = Videoconference_V1_VideoChatExtraInfo
typealias PBMeetingSubtitleData = Videoconference_V1_MeetingSubtitleData

extension PBVideoChatExtraInfo.RingingReceivedData {
    var vcType: VideoChatExtraInfo.RingingReceivedData {
        .init(meetingID: meetingID, participant: participant.vcType(meetingID: meetingID))
    }
}

extension PBMeetingSubtitleData {
    var vcType: MeetingSubtitleData {
        .init(meetingID: meetingID, breakoutRoomId: breakoutRoomID, subtitleType: .init(rawValue: subtitleType.rawValue) ?? .unknown,
              segID: segID, sliceID: sliceID, isSegFinal: isSegFinal, timestamp: absoluteTimestamp,
              source: source.vcType, target: target.vcType, hasTarget: hasTarget, trackReceived: trackReceived,
              soundType: .init(rawValue: soundType.rawValue) ?? .normal,
              event: hasEvent ? event.vcType : nil, batchID: 0)
    }
}

extension PBMeetingSubtitleData.Subtitle {
    var vcType: MeetingSubtitleData.Subtitle {
        .init(content: content, language: language, speaker: speaker.vcType, pstnInfo: pstnInfo.vcType, punctuation: hasPunctuation ? punctuation.vcType : .init(wordEnds: []), annotations: annotations.map { $0.vcType }, trackArrival: trackArrival)
    }
}

extension PBMeetingSubtitleData.Subtitle.Punctuation {
    var vcType: MeetingSubtitleData.Subtitle.Punctuation {
        .init(wordEnds: wordEnds)
    }
}

extension PBMeetingSubtitleData.Subtitle.Annotation {
    var vcType: MeetingSubtitleData.Subtitle.Annotation {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown, start: start, end: end, translation: phraseTranslation.vcType)
    }
}

extension PBMeetingSubtitleData.Subtitle.Annotation.Phrase {
    var vcType: MeetingSubtitleData.Subtitle.Annotation.Phrase {
        .init(language: language, contents: contents)
    }
}

extension PBMeetingSubtitleData.SubtitleEvent {
    var vcType: MeetingSubtitleData.SubtitleEvent {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown, user: user.vcType,
              followInfo: hasFollowInfo ? followInfo.vcType : nil)
    }
}

extension PBMeetingSubtitleData.SubtitleEvent.FollowInfo {
    var vcType: MeetingSubtitleData.SubtitleEvent.FollowInfo {
        .init(docURL: docURL, docTitle: docTitle)
    }
}

extension PBVideoChatExtraInfo.LiveExtraInfo {
    var vcType: VideoChatExtraInfo.LiveExtraInfo {
        .init(onlineUsersCount: onlineUsersCount)
    }
}

extension Videoconference_V1_TranscriptData {
    var vcType: MeetingSubtitleData {
        .init(meetingID: meetingID, breakoutRoomId: String(), subtitleType: subtitleType, segID: sentenceID, sliceID: 0, isSegFinal: true, timestamp: timestamp, source: source.vcType, target: target.vcType, hasTarget: hasTarget, trackReceived: true, soundType: .normal, event: hasEvent ? event.vcType : nil, batchID: batchID)
    }

    var subtitleType: MeetingSubtitleData.SubtitleType {
        if case .event = transcriptType {
            return .event
        }
        return .init(rawValue: transcriptType.rawValue) ?? .unknown
    }

}

extension Videoconference_V1_TranscriptData.Transcript {
    var vcType: MeetingSubtitleData.Subtitle {
        .init(content: content, language: language, speaker: speaker.vcType, pstnInfo: pstnInfo.vcType, punctuation: .init(wordEnds: []), annotations: [], trackArrival: true)
    }
}

extension Videoconference_V1_TranscriptData.TranscriptEvent {
    var vcType: MeetingSubtitleData.SubtitleEvent {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown, user: user.vcType, followInfo: hasFollowInfo ? followInfo.vcType : nil)
    }
}


extension Videoconference_V1_TranscriptData.TranscriptEvent.FollowInfo {
    var vcType: MeetingSubtitleData.SubtitleEvent.FollowInfo {
        .init(docURL: docURL, docTitle: docTitle)
    }
}
