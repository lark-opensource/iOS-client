//
//  ByteviewHeartbeatStop.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 通知客户端心跳停止了
/// - PUSH_BYTEVIEW_HEARTBEAT_STOP = 2303
/// - Videoconference_V1_ByteviewHeartbeatStop
public struct ByteviewHeartbeatStop: Equatable {

    public var token: String

    public var serviceType: MeetingHeartbeatType

    public var reason: Reason

    public var offlineReason: Participant.OfflineReason?

    public enum Reason: Int, Hashable {
        case unknown // = 0
        case disconnect // = 1
        case invalid // = 2
    }
}

extension ByteviewHeartbeatStop: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_ByteviewHeartbeatStop
    init(pb: Videoconference_V1_ByteviewHeartbeatStop) throws {
        self.token = pb.token
        self.serviceType = .init(rawValue: pb.serviceType.rawValue) ?? .unknown
        self.reason = .init(rawValue: pb.reason.rawValue) ?? .unknown
        if pb.hasOfflineReason {
            self.offlineReason = .init(rawValue: Int(pb.offlineReason))
        }
    }
}

extension ByteviewHeartbeatStop.Reason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .disconnect:
            return "disconnect"
        case .invalid:
            return "invalid"
        }
    }
}
