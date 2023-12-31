//
//  BasicInfo.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation

public enum ReviewStatus: Int, Codable, ModelEnum {
    public static var fallbackValue: ReviewStatus = .unknown

    case normal // - 0-(审核通过的正常状态，按照status字段正常展示即可)
    case autoReviewFailed // - 1-(机审或自动触发的人审失败 review failed)
    case complainFailed // - 2-(申诉人审失败 展示本次申诉失败)
    case manualReviewing // - 3-(人审中，页面展示申诉中，列表页展示under review)
    case reserve1
    case reserve2
    case reserve3
    case reserve4
    case reserve5
    case unknown = -999
}

public enum SummaryStatus: Int, Codable, ModelEnum {
    public static var fallbackValue: SummaryStatus = .unknown
    case normal // - 0-(审核通过的正常状态，按照status字段正常展示即可)
    case generating = 1
    case unknown = -999
}

public enum ObjectType: Int, Codable, ModelEnum {
    public static var fallbackValue: ObjectType = .unknown

    case normal = 0 // 视频会议结构化
    case upload = 1 // 导入
    case says = 2 // Says
    case demo = 3 // 演示Demo
    case ccm = 4
    case recording = 5
    case live = 6
    case reserve1
    case reserve2
    case reserve3
    case reserve4
    case reserve5
    case unknown = -999
}

public enum ObjectStatus: Int, Codable, ModelEnum {
    public static var fallbackValue: ObjectStatus = .unknown

    case deleted = -2     // 删除中
    case trash = -1       // 回收站
    case recording = 0    // 录制中
    case waitASR = 1      // 转录中
    case complete = 2     // 转录完成
    case failed = 3       //  转录失败
    case transcoding = 4  // 转码中
    case uploading = 5    // ccm上传中
    case waitDiarization = 11     // 上传完 等待说话人分离
    case pending = 12             // asr转录之前quata不够用
    case pendingLowPriority = 13  // asr优先级低
    case fileCorrupted = 31  // 文件损坏

    // 40 41 合并成40，代表录音中
    case audioRecording = 40  // 录音中
    case audioRecordPause = 41  // 录音暂停

    // 42 43 44 合并成42，代表上传中
    case audioRecordUploading = 42  // 录音完成（分片上传中）
    case audioRecordUploadingForced = 43  // 录音完成（分片上传中）
    case audioRecordCompleteUpload = 44  // 录音上传完成

    case cutting = 50 //妙记片段剪辑

    case reserve1
    case reserve2
    case reserve3
    case reserve4
    case reserve5
    case unknown = -999

    public func minutesIsProcessing() -> Bool {
        return (self == .recording ||
                self == .transcoding ||
                self == .cutting ||
                self == .uploading ||
                self == .waitDiarization ||
                self == .pending ||
                self == .pendingLowPriority)
    }

    public func minutesIsNeedBashStatus() -> Bool {
        return (self == .recording ||
                self == .waitASR ||
                self == .transcoding ||
                self == .uploading ||
                self == .waitDiarization ||
                self == .pending ||
                self == .pendingLowPriority ||
                self == .audioRecording ||
                self == .audioRecordUploading)
    }
}

public enum MediaType: String, Codable, ModelEnum {
    public static var fallbackValue: MediaType = .unknown

    case video
    case audio
    case text
    case unknown = ""
}

public struct SpriteInfo: Codable {
    public let imgWidth: Int
    public let imgHeight: Int
    public let xLen: Int
    public let yLen: Int
    public let interval: Int
    public let fext: String
    public let imgUrls: [String]
    public let isFull: Bool?

    private enum CodingKeys: String, CodingKey {
        case imgWidth = "img_x_size"
        case imgHeight = "img_y_size"
        case xLen = "img_x_len"
        case yLen = "img_y_len"
        case interval = "interval"
        case fext = "fext"
        case imgUrls = "img_urls"
        case isFull = "is_full"
    }
}

public struct BasicInfo: Codable {
    public var showExternalTag: Bool
    public let objectToken: String
    public let meetingID: String
    public var topic: String
    public let startTime: Int
    public let stopTime: Int
    public let duration: Int
    public let mediaType: MediaType
    public let ownerID: String
    public let canModify: Bool
    public let objectStatus: ObjectStatus
    public let objectVersion: Int
    public let objectType: ObjectType
    public let reviewStatus: ReviewStatus
    public let videoURLStr: String
    public let HLSVideoUrlStr: String?
    public let videoCover: String
    public let subtitleLanguages: [Language]
    public let isOwner: Bool?
    public let ownerInfo: OwnerInfo?
    public let clipInfo: ClipInfo?
    public let isRecordingDevice: Bool?
    public let audioURLStr: String
    public let hasStatistics: Bool?
    public let canComment: Bool
    public let canEditSpeaker: Bool?
    public let longMeetingNoContentTips: Bool?
    public let showReportIcon: Bool?
    public let isAiAnalystSummary: Bool?

    public let summaryStatus: NewSummaryStatus?
    public let agendaStatus: NewSummaryStatus?
    public let speakerAiStatus: NewSummaryStatus?

    public var videoURL: URL? {
        if let hls = HLSVideoUrlStr, hls.isEmpty == false {
            return URL(string: hls)
        } else if videoURLStr.isEmpty == false {
            return URL(string: videoURLStr)
        } else {
            return nil
        }
    }
    
    // 通过播放器音视频分离，不需要单独的音频url
    public var podcastURL: URL? {
        return videoURL
    }
    
    public var spriteInfo: SpriteInfo

    public let supportAsr: Bool?

    public var schedulerType: MinutesSchedulerType
    public var schedulerDeltaExecuteTime: Int?
    public var isRisk: Bool?
    public let displayTag: DisplayTag?
    
    public var isInCCMfg: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case showExternalTag = "show_external_tag"
        case objectToken = "object_token"
        case meetingID = "meeting_id"
        case topic = "topic"
        case startTime = "start_time"
        case stopTime = "stop_time"
        case duration = "duration"
        case mediaType = "media_type"
        case ownerID = "owner_id"
        case canModify = "can_modify"
        case objectStatus = "object_status"
        case objectVersion = "object_version"
        case objectType = "object_type"
        case reviewStatus = "review_status"
        case videoURLStr = "video_url"
        case HLSVideoUrlStr = "hls_video_url"
        case videoCover = "video_cover"
        case subtitleLanguages = "subtitle_languages"
        case isOwner = "is_owner"
        case ownerInfo = "owner_info"
        case clipInfo = "clip_info"
        case isRecordingDevice = "is_recording_device"
        case audioURLStr = "audio_url"
        case hasStatistics = "has_statistics"
        case canComment = "can_comment"
        case canEditSpeaker = "can_edit_speaker"
        case spriteInfo = "sprite_info"
        case supportAsr = "support_asr"
        case schedulerType = "scheduler_type"
        case schedulerDeltaExecuteTime = "scheduler_execute_delta_time"
        case isRisk = "is_risk"
        case displayTag = "display_tag"
        case isInCCMfg = "is_in_ccm_fg"
        case longMeetingNoContentTips = "long_meeting_no_content_tips"
        case showReportIcon = "show_report_icon"
        case isAiAnalystSummary = "is_ai_analyst_summary"
        case summaryStatus = "summary_status"
        case agendaStatus = "agenda_status"
        case speakerAiStatus = "speaker_ai_status"
    }
}
