//
//  UpdateLobbyParticipantRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// UPDATE_VC_LOBBY_PARTICIPANT
/// - ServerPB_Videochat_lobby_UpdateVCLobbyParticipantRequest
public struct UpdateLobbyParticipantRequest {
    public static let command: NetworkCommand = .server(.updateVcLobbyParticipant)

    public init(meetingId: String) {
        self.meetingId = meetingId
    }

    public var meetingId: String

    /// 麦克风开/关
    public var isMicrophoneMuted: Bool?

    /// 摄像头开/关
    public var isCameraMuted: Bool?
}

extension UpdateLobbyParticipantRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_lobby_UpdateVCLobbyParticipantRequest
    func toProtobuf() throws -> ServerPB_Videochat_lobby_UpdateVCLobbyParticipantRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        if let mic = isMicrophoneMuted {
            request.isMicrophoneMuted = mic
        }
        if let camera = isCameraMuted {
            request.isCameraMuted = camera
        }
        return request
    }
}
