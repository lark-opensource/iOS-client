//
//  Room.swift
//  ByteView
//
//  Created by huangshun on 2019/8/27.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

typealias MaskAnimation = (images: [UIImage], duration: TimeInterval, repeatCount: Int)

struct SearchedRoom {
    let id: String
    let name: String
    let avatarInfo: AvatarInfo
    let status: SearchedUserStatus
    let title: String
    let subtitle: String
    let byteviewUser: ByteviewUser?
    // 会中信息
    let participant: Participant?
    let lobbyParticipant: LobbyParticipant?

    // sip地址
    let sipAddress: String?

    let relationTagWhenRing: CollaborationRelationTag?

    init(id: String,
         name: String,
         avatarInfo: AvatarInfo,
         byteviewUser: ByteviewUser? = nil,
         title: String,
         subtitle: String,
         status: SearchedUserStatus,
         participant: Participant? = nil,
         lobbyParticipant: LobbyParticipant? = nil,
         sipAddress: String? = nil,
         relationTagWhenRing: CollaborationRelationTag?) {
        self.id = id
        self.name = name
        self.avatarInfo = avatarInfo
        self.byteviewUser = byteviewUser
        self.status = status
        self.title = title
        self.subtitle = subtitle
        self.participant = participant
        self.lobbyParticipant = lobbyParticipant
        self.sipAddress = sipAddress
        self.relationTagWhenRing = relationTagWhenRing
    }
}

extension SearchedRoom {
    var isInVideo: Bool {
        switch status {
        case .idle, .inviting, .waiting:
            return false
        case .inMeeting, .busy, .ringing:
            return true
        }
    }

    var maskAnimation: MaskAnimation? {
        if isInVideo == true {
            let images = (1...3).map { UIImage(localNamed: "Videoing_\($0)")! }
            return (images, 1.5, 0)
        } else {
            return nil
        }
    }
}
