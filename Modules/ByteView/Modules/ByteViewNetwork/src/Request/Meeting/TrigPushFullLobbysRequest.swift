//
//  TrigPushFullLobbysRequest.swift
//  ByteViewNetwork
//
//  Created by wulv on 2023/5/24.
//

import Foundation
import RustPB

/// 会触发推送全量等候参会人
/// - Videoconference_V1_TriggerPushFullVCLobbyParticipantsRequest
public struct TrigPushFullLobbysRequest {
    public static let command: NetworkCommand = .rust(.triggerPushFullVcLobbyParticipants)
    public init() {}
}

extension TrigPushFullLobbysRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_TriggerPushFullVCLobbyParticipantsRequest
    func toProtobuf() throws -> Videoconference_V1_TriggerPushFullVCLobbyParticipantsRequest {
        ProtobufType()
    }
}
