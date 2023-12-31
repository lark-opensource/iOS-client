//
//  RustPB+Identifier.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/6/5.
//

import Foundation
import ByteViewNetwork

extension VideoChatInMeetingInfo {

    var focusingUser: ByteviewUser? {
        guard let user = focusVideoData?.focusUser, !user.id.isEmpty else {
            return nil
        }
        return user
    }

}

extension LobbyInfo {
    var participantUser: ByteviewUser? {
        if let p = lobbyParticipant {
            return p.user
        }

        if let p = preLobbyParticipant {
            return p.user
        }
        return nil
    }
}
