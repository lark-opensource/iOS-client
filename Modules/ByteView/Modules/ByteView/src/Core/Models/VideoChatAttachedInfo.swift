//
//  VideoChatAttachedInfo.swift
//  ByteView
//
//  Created by kiri on 2020/9/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

enum VideoChatAttachedInfo {
    case info(VideoChatInfo)
    case lobbyInfo(LobbyInfo)

    var meetingId: String {
        switch self {
        case .info(let videoChatInfo):
            return videoChatInfo.id
        case .lobbyInfo(let lobbyInfo):
            return lobbyInfo.meetingId
        }
    }

    var videoChatInfo: VideoChatInfo? {
        switch self {
        case .info(let info):
            return info
        default:
            return nil
        }
    }

    var lobbyInfo: LobbyInfo? {
        switch self {
        case .lobbyInfo(let info):
            return info
        default:
            return nil
        }
    }
}
