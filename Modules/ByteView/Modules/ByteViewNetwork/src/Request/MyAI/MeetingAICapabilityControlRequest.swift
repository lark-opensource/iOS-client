//
//  MeetingAICapabilityControlRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2023/12/7.
//

import Foundation
import ServerPB
import RustPB

public enum MeetingAICapabilityAction: Int, Codable {
    case unknow = 0
    case hostAccept = 1 // 主持人接受参会人开启AI会话请求
    case hostRefuse = 2 // 主持人拒绝参会人开启AI会话请求
    case participantRequestStart = 3 // 参会人请求开启AI会话
}

extension MeetingAICapabilityAction {
    var serverPbType: ServerPB_Videochat_MeetingAICapabilityAction {
        ServerPB_Videochat_MeetingAICapabilityAction(rawValue: rawValue) ?? .unknownAction
    }
}

extension ServerPB_Videochat_MeetingAICapabilityAction {
    var vcType: MeetingAICapabilityAction {
        MeetingAICapabilityAction(rawValue: rawValue) ?? .unknow
    }
}

extension Videoconference_V1_MeetingAICapabilityAction {
    var vcType: MeetingAICapabilityAction {
        MeetingAICapabilityAction(rawValue: rawValue) ?? .unknow
    }
}

public enum MeetingAICapability: Int, Codable {
    case unknow = 0
    case aiChat = 1
}

extension MeetingAICapability {
    var serverPbType: ServerPB_Videochat_MeetingAICapability {
        ServerPB_Videochat_MeetingAICapability(rawValue: rawValue) ?? .unknownCapability
    }
}

extension ServerPB_Videochat_MeetingAICapability {
    var vcType: MeetingAICapability {
        MeetingAICapability(rawValue: rawValue) ?? .unknow
    }
}

extension Videoconference_V1_MeetingAICapability {
    var vcType: MeetingAICapability {
        MeetingAICapability(rawValue: rawValue) ?? .unknow
    }
}

public struct AICapabilityPermData: Codable, Equatable {
    public let action: MeetingAICapabilityAction
    public let capability: MeetingAICapability // 请求打开的能力
    public let requester: ByteviewUser // 开启AI能力请求发起人

    public init(action: MeetingAICapabilityAction, capability: MeetingAICapability, requester: ByteviewUser) {
        self.action = action
        self.capability = capability
        self.requester = requester
    }

    init() {
        self.init(action: .unknow, capability: .unknow, requester: ByteviewUser(id: "", type: .unknown))
    }
}

extension AICapabilityPermData {
    var serverPbType: ServerPB_Videochat_AICapabilityPermData {
        var data = ServerPB_Videochat_AICapabilityPermData()
        data.action = action.serverPbType
        data.capability = capability.serverPbType
        data.requester = requester.serverPbType
        return data
    }
}

extension ServerPB_Videochat_AICapabilityPermData {
    var vcType: AICapabilityPermData {
        AICapabilityPermData(action: action.vcType, capability: capability.vcType, requester: requester.vcType)
    }
}

extension Videoconference_V1_AICapabilityPermData {
    var vcType: AICapabilityPermData {
        AICapabilityPermData(action: action.vcType, capability: capability.vcType, requester: requester.vcType)
    }
}

/// Command_MEETING_AI_CAPABILITY_CONTROL Command=89540
public struct MeetingAICapabilityControlRequest {
    public static let command: NetworkCommand = .server(.meetingAiCapabilityControl)
    public typealias Response = MeetingAICapabilityControlResponse

    public let meetingId: String
    public let permData: AICapabilityPermData // 请求打开ai能力相关操作数据

    public init(meetingId: String, permData: AICapabilityPermData) {
        self.meetingId = meetingId
        self.permData = permData
    }
}

extension MeetingAICapabilityControlRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_MeetingAICapabilityControlRequest

    func toProtobuf() throws -> ServerPB_Videochat_MeetingAICapabilityControlRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.aiCapabilityPermData = permData.serverPbType
        return request
    }
}

public struct MeetingAICapabilityControlResponse {
}

extension MeetingAICapabilityControlResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_MeetingAICapabilityControlResponse

    init(pb: ServerPB_Videochat_MeetingAICapabilityControlResponse) throws {
    }
}
