//
//  User+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

typealias PBChat = Basic_V1_Chat
typealias PBChatter = Basic_V1_Chatter
typealias PBStatusEffectiveInterval = Basic_V1_StatusEffectiveInterval
typealias PBRoom = Videoconference_V1_Room

extension PBChat {
    var vcType: Chat {
        .init(id: id, type: .init(rawValue: type.rawValue) ?? .unknown, name: name, avatarKey: avatarKey, chatterID: chatterID,
              tenantID: tenantID, isCrossTenant: isCrossTenant, desc: description_p, userCount: userCount, lastMessagePosition: lastMessagePosition)
    }
}

extension PBChatter {
    func toUser() -> User {
        let isRobot = (type == .bot)
        let ws: User.WorkStatus
        switch workStatus.status {
        case .onLeave:
            ws = .leave
        case .onMeeting:
            ws = .meeting
        @unknown default:
            ws = .default
        }

        return User(id: id, name: localizedName, displayName: localizedName, anotherName: nameWithAnotherName, alias: alias, avatarInfo: .remote(key: avatarKey, entityId: id),
                    workStatus: ws, isRobot: isRobot, tenantId: tenantID, customStatuses: status)
    }
}

extension PBRoom {
    var vcType: Room {
        Room(id: roomID, tenantId: tenantID, name: name, avatarInfo: .remote(key: avatarKey, entityId: roomID),
             primaryName: primaryNameParticipant, secondaryName: secondaryName, fullName: fullNameParticipant)
    }
}
