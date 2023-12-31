//
//  FullLobbyParticipants.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

public protocol FullLobbyParticipantsPushObserver: AnyObject {
    func didReceiveFullLobbyParticipants(meetingId: String, participants: [LobbyParticipant])
}

/// 全量等候室参会人
/// - PUSH_FULL_VC_LOBBY_PARTICIPANTS = 89325
/// - Videoconference_V1_FullVCLobbyParticipants
public struct FullLobbyParticipants {

    public var meetingID: String

    public var lobbyParticipants: [LobbyParticipant]
}

extension FullLobbyParticipants: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_FullVCLobbyParticipants
    init(pb: Videoconference_V1_FullVCLobbyParticipants) {
        self.meetingID = pb.meetingID
        self.lobbyParticipants = pb.lobbyParticipants.map({ $0.vcType })
    }
}

extension FullLobbyParticipants: CustomStringConvertible {
    public var description: String {
        let count = lobbyParticipants.count
        return String(indent: "FullLobbyParticipants",
                      "meetingId: \(meetingID)",
                      "participants: \(count > 10 ? "count=\(count)" : "\(lobbyParticipants)")")
    }
}
