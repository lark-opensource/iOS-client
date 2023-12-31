//
//  MeetingSubtitleData.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_MeetingSubtitleData
public struct MeetingSubtitleData: Equatable {
    public init(meetingID: String, breakoutRoomId: String, subtitleType: SubtitleType,
                segID: Int64, sliceID: Int64, isSegFinal: Bool, timestamp: Int64,
                source: Subtitle, target: Subtitle, hasTarget: Bool,
                trackReceived: Bool, soundType: SoundType, event: SubtitleEvent?, batchID: Int64) {
        self.meetingID = meetingID
        self.breakoutRoomId = breakoutRoomId
        self.subtitleType = subtitleType
        self.segID = segID
        self.sliceID = sliceID
        self.isSegFinal = isSegFinal
        self.timestamp = timestamp
        self.source = source
        self.target = target
        self.hasTarget = hasTarget
        self.trackReceived = trackReceived
        self.soundType = soundType
        self.event = event
        self.batchID = batchID
    }

    public var meetingID: String

    //分组信息
    public var breakoutRoomId: String

    /// 字幕类型
    public var subtitleType: SubtitleType

    /// 字幕段编号，源字幕与翻译字幕为同一ID
    public var segID: Int64

    /// 字幕切片编号
    public var sliceID: Int64

    /// 字幕分段结束标识
    public var isSegFinal: Bool

    /// 字幕时间戳，精确到毫秒
    public var timestamp: Int64

    /// 源字幕
    public var source: Subtitle

    /// target is nil
    public var hasTarget: Bool

    /// 目标字幕
    public var target: Subtitle

    /// 是否上报字幕到达时间
    public var trackReceived: Bool

    /// 关键时间点时间
    public var event: SubtitleEvent?

    /// 字幕的声音类型
    public var soundType: SoundType

    /// 批次编号（仅用于按批次拉取转录信息，不参与其它交互）
    public var batchID: Int64

    public enum SubtitleType: Int, Hashable {
        case unknown // = 0
        case translation // = 1

        /// 保留
        case transcription // = 2
        case event // = 3
    }

    public enum SoundType: Int, Hashable {

        /// 正常语音
        case normal = 1

        /// 噪音
        case noise // = 2
    }

    public struct Subtitle: Equatable {
        public init(content: String, language: String, speaker: ByteviewUser, pstnInfo: PSTNInfo?, punctuation: Punctuation, annotations: [Annotation], trackArrival: Bool) {
            self.content = content
            self.language = language
            self.speaker = speaker
            self.pstnInfo = pstnInfo
            self.punctuation = punctuation
            self.annotations = annotations
            self.trackArrival = trackArrival
        }

        public var content: String

        public var language: String

        public var speaker: ByteviewUser

        public var pstnInfo: PSTNInfo?

        public var punctuation: Punctuation

        public var annotations: [Annotation]

        /// 是否上报字幕到达埋点
        public var trackArrival: Bool

        public struct Punctuation: Equatable {
            public init(wordEnds: [Int64]) {
                self.wordEnds = wordEnds
            }
            public var wordEnds: [Int64]
        }

        public struct Annotation: Equatable {
            public enum AType: Int {
                case unknown
                case translation
            }
            public struct Phrase: Equatable {
                public var language: String
                public var contents: [String]
            }
            public var type: AType
            public var start: Int32
            public var end: Int32
            public var translation: Phrase
        }

    }

    public struct SubtitleEvent: Equatable {
        public init(type: SubtitleEventType, user: ByteviewUser, followInfo: SubtitleEvent.FollowInfo?) {
            self.type = type
            self.user = user
            self.followInfo = followInfo
        }

        public var type: SubtitleEventType

        public var user: ByteviewUser

        public var followInfo: SubtitleEvent.FollowInfo?

        public enum SubtitleEventType: Int, Hashable {
            case unknown // = 0
            case turnSubtitleOn // = 1
            case startShareScreen // = 2
            case stopShareScreen // = 3
            case startFollow // = 4
            case stopFollow // = 5
        }

        public struct FollowInfo: Equatable {
            public init(docURL: String, docTitle: String) {
                self.docURL = docURL
                self.docTitle = docTitle
            }
            public var docURL: String
            public var docTitle: String
        }
    }
}

extension MeetingSubtitleData.Subtitle: CustomStringConvertible {

    public var description: String {
        String(
            indent: "MeetingSubtitleData.Subtitle",
            "language: \(language)",
            "speaker: \(speaker)"
        )
    }
}
