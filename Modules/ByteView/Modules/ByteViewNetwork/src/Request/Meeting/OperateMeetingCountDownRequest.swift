//
//  OperateMeetingCountDownRequest.swift
//  ByteViewNetwork
//
//  Created by wulv on 2022/4/24.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// commandID: OPERATE_MEETING_COUNT_DOWN = 89313
/// - ServerPB_Videochat_OperateMeetingCountDownRequest
public struct OperateMeetingCountDownRequest {
    public static let command: NetworkCommand = .server(.operateMeetingCountDown)

    public init(meetingID: String, action: CountDownAction, playEndAudio: Bool? = nil,
                duration: Int64? = nil, remindersInSeconds: [Int64]? = nil) {
        self.meetingID = meetingID
        self.action = action
        self.playEndAudio = playEndAudio
        self.duration = duration
        self.remindersInSeconds = remindersInSeconds
    }

    /// 倒计时操作类型
    public var action: CountDownAction
    /// 倒计时操作会议ID
    public var meetingID: String
    /// 倒计时结束时是否需要播放音频
    public var playEndAudio: Bool?
    /// 倒计时操作时长（prolong/start）毫秒
    public var duration: Int64?
    /// 倒计时提醒 相对倒计结束时间戳前x秒
    public var remindersInSeconds: [Int64]?

    public enum CountDownAction: Int, Hashable {
        case unknown // = 0
        /// 设置 or 重设
        case set // = 1
        /// 提前结束
        case endInAdvance // = 2
        /// 关闭倒计时界面
        case close // = 3
        /// 延长
        case prolong // = 4
    }
}

extension OperateMeetingCountDownRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_OperateMeetingCountDownRequest

    func toProtobuf() throws -> ServerPB_Videochat_OperateMeetingCountDownRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.action = .init(rawValue: action.rawValue) ?? .unknown
        if let playEndAudio = playEndAudio {
            request.playEndAudio = playEndAudio
        }
        if let duration = duration {
            request.duration = duration
        }
        if let remindersInSeconds = remindersInSeconds {
            request.remindersInSeconds = remindersInSeconds
        }
        return request
    }
}
