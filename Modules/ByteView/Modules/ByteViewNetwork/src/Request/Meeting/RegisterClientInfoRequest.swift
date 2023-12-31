//
//  RegisterClientInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 启动时上报客户端信息 & 恢复状态
/// - REGISTER_CLIENT_INFO = 2204
/// - Videoconference_V1_RegisterClientInfoRequest
///
/// 在客户端CALLING状态下，也可以用于拉取最新的服务端状态，用于解决长连不稳定的情况
/// 
/// 会议内容通过VideoChatInfo异步推送，没有会议则不进行推送，如果设置了sync_response为true，则直接返回不再推送
/// - zoom会议时，始终会下发服务端最新的会议状态
/// - 自研1v1会议时
///    - 如果status是IDLE，且服务端处于CALLING和ON_THE_CALL时则不会下发，并且会重置服务端的状态（结束会议）
///    - 如果是其他status，则会正常下发服务端会议状态
public struct RegisterClientInfoRequest {
    public static let command: NetworkCommand = .rust(.registerClientInfo)
    public typealias Response = RegisterClientInfoResponse

    public init(sourceType: SourceType, status: Participant.Status?, meetingIds: [String]) {
        self.sourceType = sourceType
        self.status = status
        self.meetingIds = meetingIds
    }

    public var sourceType: SourceType

    /// 上报客户端自己的状态，没有时表示IDLE
    public var status: Participant.Status?

    /// 用于支持PC端多个ringing的双通道
    public var meetingIds: [String]

    public enum SourceType: Int, Hashable {
        case unknown // = 0

        /// 长连断开注册
        case longConnectionLoss // = 1

        /// crash后重启注册
        case crashedStartup // = 2

        /// 被杀后重启注册
        case killedStartup // = 3

        /// 双通道
        case dualChannelPoll // = 4
    }
}

/// Videoconference_V1_RegisterClientInfoResponse
public struct RegisterClientInfoResponse {
    public init(status: StatusCode, info: VideoChatInfo?, infos: [VideoChatInfo], prompts: [VideoChatPrompt]) {
        self.status = status
        self.info = info
        self.infos = infos
        self.prompts = prompts
    }

    public var status: StatusCode

    /// 如果是参数sync_response = true，则直接返回会议信息，不走推送
    public var info: VideoChatInfo?

    /// 废弃info字段，使用infos字段，即可能存在返回多个VideoChatInfo对象
    public var infos: [VideoChatInfo]

    /// 日程视频会议的入会提醒信息
    public var prompts: [VideoChatPrompt]

    public enum StatusCode: Int, Equatable {
        case unknown // = 0

        /// 当前设备还在当前会议中
        case active // = 1

        /// 当前设备已经离开会议, 当前会议还存在
        case inactive // = 2

        /// 当前会议已结束
        case meetingEnd // = 3

        /// 其他设备在当前会议或其他会议中
        case otherDevActive // = 4
    }
}

extension RegisterClientInfoRequest.SourceType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .longConnectionLoss:
            return "longConnectionLoss"
        case .crashedStartup:
            return "crashedStartup"
        case .killedStartup:
            return "killedStartup"
        case .dualChannelPoll:
            return "dualChannelPoll"
        }
    }
}

extension RegisterClientInfoResponse: CustomStringConvertible {
    public var description: String {
        String(
            indent: "RegisterClientInfoResponse",
            "info: \(info)",
            "status: \(status)",
            "infos: \(infos)",
            "prompts: \(prompts)"
        )
    }
}

extension RegisterClientInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_RegisterClientInfoRequest
    func toProtobuf() throws -> Videoconference_V1_RegisterClientInfoRequest {
        var request = ProtobufType()
        request.meetingIds = self.meetingIds
        if let status = status {
            request.status = .init(rawValue: status.rawValue) ?? .unknown
        }
        request.sourceType = .init(rawValue: sourceType.rawValue) ?? .unknown
        request.syncResponse = true // 默认都同步返回
        return request
    }
}

extension RegisterClientInfoResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_RegisterClientInfoResponse
    init(pb: Videoconference_V1_RegisterClientInfoResponse) throws {
        self.status = .init(rawValue: pb.status.rawValue) ?? .unknown
        self.info = pb.hasInfo ? pb.info.vcType : nil
        self.infos = pb.infos.map({ VideoChatInfo(pb: $0) })
        self.prompts = pb.prompts.map({ VideoChatPrompt(pb: $0) })
    }
}
