//
//  VideoChatNoticeUpdate.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 推送对VideoChatNotice的更新动作
/// - PUSH_VIDEO_CHAT_NOTICE_UPDATE = 2350
/// - Videoconference_V1_VideoChatNoticeUpdate
public struct VideoChatNoticeUpdate: Equatable {

    public var meetingID: String

    /// 标识原有消息类型
    public var type: VideoChatNotice.TypeEnum

    public var action: Action

    /// 要dismiss的key 对应I18nKeyInfo的new key
    public var key: String

    /// 服务端推送的sid，打点用
    public var pushSid: String

    public enum Action: Int, Hashable {
        case unknown // = 0
        case dismiss // = 1
    }
}

extension VideoChatNoticeUpdate: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VideoChatNoticeUpdate
    init(pb: Videoconference_V1_VideoChatNoticeUpdate) {
        self.meetingID = pb.meetingID
        self.type = .init(rawValue: pb.type.rawValue) ?? .unknown
        self.key = pb.key
        self.pushSid = pb.pushSid
        if pb.hasAction, let action = Self.Action(rawValue: pb.action.rawValue) {
            self.action = action
        } else {
            self.action = .unknown
        }
    }
}

extension VideoChatNoticeUpdate: CustomStringConvertible {
    public var description: String {
        String(indent: "VideoChatNoticeUpdate",
               "meetingId: \(meetingID)",
               "type: \(type)",
               "key: \(key)",
               "pushSid: \(pushSid)",
               "action: \(action)"
        )
    }
}
