//
//  VChatPreviewedParticipant.swift
//
//
//  Created by yangyao on 2020/11/22.
//

import UIKit
import RustPB
import ByteViewNetwork
import ByteViewCommon

struct VChatPreviewedParticipant: ParticipantIdConvertible {

    let avatarInfo: AvatarInfo
    let userName: String
    let type: ParticipantType
    let id: String
    let deviceId: String

    init(id: String,
         deviceId: String,
         type: ParticipantType = .larkUser,
         userName: String,
         avatarInfo: AvatarInfo) {
        self.id = id
        self.deviceId = deviceId
        self.type = type
        self.userName = userName
        self.avatarInfo = avatarInfo
    }

    var participantId: ParticipantId {
        ParticipantId(id: id, type: type, deviceId: deviceId)
    }
}
