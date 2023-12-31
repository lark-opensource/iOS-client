//
//  AgendaInfo.swift
//  ByteViewNetwork
//
//  Created by liurundong.henry on 2023/5/11.
//

import Foundation

/// 会议议程
/// Videoconference_V1_AgendaInfo
public struct AgendaInfo: Equatable {

    public init(agendaID: String,
                relativeActivatedTime: Int64,
                duration: Int64,
                suiteVersion: Int64,
                status: Status,
                title: String,
                realEndTime: Int64) {
        self.agendaID = agendaID
        self.relativeActivatedTime = relativeActivatedTime
        self.duration = duration
        self.suiteVersion = suiteVersion
        self.status = status
        self.title = title
        self.realEndTime = realEndTime
    }

    /// 议程ID
    public var agendaID: String
    /// 议程开始相对会议开始的时间（秒）
    public var relativeActivatedTime: Int64
    /// 议程持续时长（秒）
    public var duration: Int64
    /// 低于该版本丢弃
    public var suiteVersion: Int64
    /// 议程状态
    public var status: Status
    /// 议程主题
    public var title: String
    /// 议程实际结束的时间，可能是开始下个议程的时刻或者会议结束时间
    public var realEndTime: Int64

    public enum Status: Int, Hashable {
        /// 未知/无效状态
        case unknown // = 0
        /// 开始
        case start // = 1
        /// 即将到时提醒
        case remind // = 2
        /// 已超时
        case timeout // = 3
        /// 议程已结束，可能是开始了下一个议程或者结束了会议
        case end // = 4

        var description: String {
            switch self {
            case .unknown: return "unknown"
            case .start: return "start"
            case .remind: return "remind"
            case .timeout: return "timeout"
            case .end: return "end"
            }
        }

        var debugDescription: String { description }
    }

}

extension AgendaInfo: CustomStringConvertible {

    public var description: String {
        String(indent: "AgendaInfo",
               "agendaID: \(agendaID)",
               "relativeActivatedTime: \(relativeActivatedTime)",
               "duration: \(duration)",
               "suiteVersion: \(suiteVersion)",
               "status: \(status.description)",
               "title.hash: \(title.hashValue)",
               "realEndTime: \(realEndTime)")
    }

}
