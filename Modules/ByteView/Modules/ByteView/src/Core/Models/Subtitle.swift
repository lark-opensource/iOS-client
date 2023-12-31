//
//  SubtitleDefines.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/8/8.
//

import Foundation
import RxSwift
import ByteViewCommon
import ByteViewNetwork

enum AsrSubtitleStatus: Equatable {
    case unknown
    case opening // 开启中
    case openSuccessed(isRecover: Bool, isAllMuted: Bool = false)
    case openFailed
    case exception // 服务端实时字幕功能出现不可恢复的异常
    case recoverableException //服务端实时字幕功能出现可恢复的异常
    case recoverSuccess // 字幕异常恢复成功
    case translation(Subtitle) //翻译字幕中
    case discontinuous // 翻译字幕不连续
    case closed
    case langDetected // 语种识别
    case firstOpen
}

//  字幕数据结构
struct Subtitle: Equatable {
    static func == (lhs: Subtitle, rhs: Subtitle) -> Bool {
        lhs.name == rhs.name && lhs.avatarInfo == rhs.avatarInfo && lhs.data == rhs.data
    }

    typealias Language = PullVideoChatConfigResponse.SubtitleLanguage

    let name: String?
    let avatarInfo: AvatarInfo

    let data: MeetingSubtitleData

    var segID: Int {
        return Int(data.segID)
    }

    var participantId: ParticipantId {
        return data.participantId
    }

    var sliceID: Int {
        return Int(data.sliceID)
    }

    var sourceContent: String {
        return data.source.content
    }

    var hasTranslation: Bool {
        return data.hasTarget
    }

    var translatedContent: String {
        return data.target.content
    }

    var speakerIdentifier: String {
        return data.target.speaker.identifier
    }

    var isSegFinal: Bool {
        return data.isSegFinal
    }

    var uniqueIdentifier: String {
        return "\(speakerIdentifier)_\(segID)_\(sliceID)"
    }

    var groupID: String {
        return "\(speakerIdentifier)_\(segID)"
    }

    var timestamp: Int {
        return Int(data.timestamp)
    }

    var isNoise: Bool {
         return data.soundType == .noise
    }

    var wordEnds: [Int64] {
        return data.target.punctuation.wordEnds
    }

    var annotations: [MeetingSubtitleData.Subtitle.Annotation] {
        return data.target.annotations
    }

    var trackArrival: Bool {
        return data.target.trackArrival
    }

    var batchID: Int64 {
        data.batchID
    }

    private(set) weak var meeting: InMeetMeeting?

    init(data: MeetingSubtitleData, meeting: InMeetMeeting?, name: String? = nil, avatarInfo: AvatarInfo? = nil) {
        self.data = data
        self.meeting = meeting
        self.name = name
        self.avatarInfo = avatarInfo ?? .asset(AvatarResources.unknown)
    }
}

extension Subtitle: CustomStringConvertible {
    var description: String {
        return "uniqueIdentifier:\(uniqueIdentifier),translatedContent:\(translatedContent)"
    }
}

extension SubtitleStatus {
    var asrSubtitleStatus: AsrSubtitleStatus {
        switch self {
        case .openFailed:
            return .openFailed
        case .openSuccess:
            return .openSuccessed(isRecover: false, isAllMuted: false)
        case .exception:
            return .exception
        case .recoverableException:
            return .recoverableException
        case .recoverSuccess:
            return .recoverSuccess
        case .langDetected:
            return .langDetected
        case .firstOpen:
            return .firstOpen
        default: // 仅“开启字幕时选择口说语言”用到，按照unknown处理
            return .unknown
        }
    }
}

extension Subtitle {

    static func makeSubtitles(from datas: [MeetingSubtitleData], meeting: InMeetMeeting) -> Single<[Subtitle]> {
        if datas.isEmpty { return .just([]) }
        let meetingId = meeting.meetingId
        let participantService = meeting.httpClient.participantService
        return Single<[Subtitle]>.create { [weak meeting] (ob) -> Disposable in
            let pids = datas.map { $0.participantId }
            participantService.participantInfo(pids: pids, meetingId: meetingId) { aps in
                let subtitles = zip(aps, datas).map { (ap, data) -> Subtitle in
                    Subtitle(data: data, meeting: meeting, name: ap.name, avatarInfo: ap.avatarInfo)
                }
                ob(.success(subtitles))
            }
            return Disposables.create()
        }
    }
}
