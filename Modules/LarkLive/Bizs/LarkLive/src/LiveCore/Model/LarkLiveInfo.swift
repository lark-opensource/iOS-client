//
//  LarkLiveInfo.swift
//  LarkLive
//
//  Created by yangyao on 2021/11/2.
//

import Foundation

/// status
// 0 -> 未知
// 1 -> 开启
// 2 -> 暂停(没有使用)
// 3 -> 续播(没有使用)
// 4 -> 结束
// 5 -> 开播授权中
// 6 -> 未开始
// 7 -> 预览中
// 目前仅1是正常观看，7仅url里带上is_preview=1时可以正常观看，其余情况均不是开播状态

// permission
// 0 -> 没有权限
// 1 -> 正常权限(可观看，可互动)
// 2 -> 可观看，被禁言

enum LiveStatus: Int, Codable {
    case unknown = 0
    case start = 1
    case pause = 2
    case resume = 3
    case end = 4
    case null = 5
    case notStart = 6
    case hostLeft = 7
    case notExist = 8
}

enum PermissionStatus: Int, Codable {
    case unknown = -1
    case noPermission = 0
    case hasPermission = 1
    case commentBaned = 2
    case watchForbiden = 3
}

enum LiveCommentStatus: Int, Codable {
    case close = 0
    case normal = 1
    case inMeetingClosed = 2
}

public struct LarkLiveInfo: Codable {
    struct NTPTime: Codable {
        let receiveTime: Int
        let sendTime: Int
        
        enum CodingKeys: String, CodingKey {
            case receiveTime = "receive_time"
            case sendTime = "send_time"
        }
    }
    
    let platform: String?
    let liveShareUrl: String?
    
    var useCoBuilding: Bool = true
    var liveID: String? {
        return useCoBuilding ? liveId : realLiveId
    }
    var liveSessionID: String? {
        return useCoBuilding ? liveSessionId : liveId
    }
    
    private let liveId: String? //埋点使用， 非live id
    private let realLiveId: String? //直播用到的liveid
    private let liveSessionId: String?
    
    let conferenceId: String?
    let status: LiveStatus?
    let audienceNumber: Int?
    let startTime: Int?
    let meetingTopic: String?
    let ntpTime: NTPTime?
    let isInMeeting: Bool?
    let permissionStatus: PermissionStatus?
    let role: Int? //0 unknown 1 owner 2 guest 3 audience 4 host

    let liveCommentStatus: LiveCommentStatus?
    let liveSource: Int?
    let liveRange: Int?
    let posterUrl: String? //直播封面图
    let latestRedEnvelopeId: String?
    let isClapDisabled: Bool?
    let playbackId: String? // 有表示看播， 否则是直播
    let activityId: String?
    
    var useStreamRouter: Bool {
        activityId?.count != 0
    }

    var decoratePostUrl: String? //直播装修封面图
    
    enum CodingKeys: String, CodingKey {
        case platform = "platform"
        case liveShareUrl = "live_share_url"
        
        case liveId = "live_id"
        case realLiveId = "real_live_id"
        case liveSessionId = "live_session_id"
        
        case conferenceId = "conference_id"
        case status = "status"
        case audienceNumber = "audience_number"
        case startTime = "start_time"
        case meetingTopic = "meeting_topic"
        case ntpTime = "ntp_time"
        case isInMeeting = "is_in_meeting"
        case permissionStatus = "permission_status"
        case role = "role"
        case liveCommentStatus = "live_comment_status"
        case liveSource = "live_source"
        case liveRange = "live_range"
        case posterUrl = "poster_url"
        case latestRedEnvelopeId = "latest_red_envelope_id"
        case isClapDisabled = "is_clap_disabled"
        case playbackId = "playback_id"
        case activityId = "activity_id"
    }
    
    func isPlayback() -> Bool {
        return self.playbackId?.isEmpty == false
    }

    func isLive() -> Bool {
        return !isPlayback()
    }

    func isLiving() -> Bool {
        if isPlayback() { return false }
        return self.status == .start && permissionStatus != .noPermission
    }

    func hasPermission() -> Bool {
        if permissionStatus != .noPermission {
            return true
        }
        return false
    }
}
