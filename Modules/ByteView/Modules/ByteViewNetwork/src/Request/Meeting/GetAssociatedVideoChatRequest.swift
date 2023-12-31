//
//  GetAssociatedVideoChatResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - GET_ASSOCIATED_VC = 2335
/// - ServerPB_Videochat_GetAssociatedVideoChatRequest
public struct GetAssociatedVideoChatRequest {
    public static let command: NetworkCommand = .server(.getAssociatedVc)
    public typealias Response = GetAssociatedVideoChatResponse

    public init(id: String, idType: VideoChatIdType, needTopic: Bool, sourceDetails: SourceDetails? = nil, calendarInstanceIdentifier: CalendarInstanceIdentifier? = nil) {
        self.id = id
        self.idType = idType
        self.needTopic = needTopic
        self.sourceDetails = sourceDetails
        if let calendarInstance = calendarInstanceIdentifier {
            self.extraInfo = .init(uniqueIDInfo: .init(calendarInstanceIdentifier: calendarInstance))
        }
    }

    public var id: String

    public var idType: VideoChatIdType

    /// 是否需要获取topic
    public var needTopic: Bool

    public var sourceDetails: SourceDetails?

    public var extraInfo: ExtraInfo?

    public struct SourceDetails {
        /// 入会来源
        public var sourceType: SourceType

        /// source_type为CARD时需要赋值，对应视频会议卡片消息的ID
        public var messageID: String

        /// source_type为CHAT时需要赋值，对应会话ID。source_type为CARD时需要赋值，对应视频会议卡片消息存在的会话id
        public var chatID: String

        public init(sourceType: SourceType, messageID: String?, chatID: String?) {
            self.sourceType = sourceType
            self.chatID = chatID ?? ""
            self.messageID = messageID ?? ""
        }

        public enum SourceType: Int {
            case unknownSource // = 0

            /// 通过视频会议卡片入会
            case card // = 1

            /// 通过群组右上角绿色图标入会
            case chat // = 2

            /// 通过独立tab入会
            case tab // = 3

            /// 通过日程会议开始通知入会
            case calendarNotice // = 4

            /// 通过会中等候室入会
            case lobby // = 5

            /// 通过会前等候室入会
            case preLobby // = 6
        }
    }

    public struct ExtraInfo {

        public var uniqueIDInfo: UniqueIDInfo

        public struct UniqueIDInfo {
            public var calendarInstanceIdentifier: CalendarInstanceIdentifier
        }
    }
}

/// ServerPB_Videochat_GetAssociatedVideoChatResponse
public struct GetAssociatedVideoChatResponse {
    /// 绑定群聊组的VideoChat信息
    public var videoChatInfo: VideoChatInfo?

    /// 根据request中是否获取topic和idType来获取对应的会议名称，若为meetingID的类型，则忽略topic
    public var topic: String

    /// 面试会议对应的自己的角色是面试官或者候选人
    public var interviewRole: Participant.Role
}

extension GetAssociatedVideoChatRequest.SourceDetails {
    func toProtobuf() -> ServerPB_Videochat_GetAssociatedVideoChatRequest.SourceDetails {
        var result = ServerPB_Videochat_GetAssociatedVideoChatRequest.SourceDetails()
        result.sourceType = .init(rawValue: sourceType.rawValue) ?? .unknownSource
        result.chatID = chatID
        result.messageID = messageID
        return result
    }
}

extension GetAssociatedVideoChatRequest.ExtraInfo {
    func toProtobuf() -> ServerPB_Videochat_GetAssociatedVideoChatRequest.ExtraInfo {
        var extraInfo = ServerPB_Videochat_GetAssociatedVideoChatRequest.ExtraInfo()
        extraInfo.uniqueIDInfo = uniqueIDInfo.toProtobuf()
        return extraInfo
    }
}

extension GetAssociatedVideoChatRequest.ExtraInfo.UniqueIDInfo {
    func toProtobuf() -> ServerPB_Videochat_GetAssociatedVideoChatRequest.ExtraInfo.UniqueIDInfo {
        var info = ServerPB_Videochat_GetAssociatedVideoChatRequest.ExtraInfo.UniqueIDInfo()
        info.calendarInstanceIdentifier = calendarInstanceIdentifier.serverPBType
        return info
    }
}

extension GetAssociatedVideoChatRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetAssociatedVideoChatRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetAssociatedVideoChatRequest {
        var request = ProtobufType()
        request.id = id
        request.idType = .init(rawValue: idType.rawValue) ?? .unknownIDType
        request.isNeedTopic = needTopic
        if let sourceDetails = sourceDetails {
            request.sourceDetails = sourceDetails.toProtobuf()
        }
        if let extraInfo = extraInfo {
            request.extraInfo = extraInfo.toProtobuf()
        }
        return request
    }
}

extension GetAssociatedVideoChatResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetAssociatedVideoChatResponse
    init(pb: ServerPB_Videochat_GetAssociatedVideoChatResponse) throws {
        self.topic = pb.topic
        self.interviewRole = .init(rawValue: pb.interviewRole.rawValue) ?? .unknown
        self.videoChatInfo = pb.videoChatInfo.first?.vcType
    }
}
