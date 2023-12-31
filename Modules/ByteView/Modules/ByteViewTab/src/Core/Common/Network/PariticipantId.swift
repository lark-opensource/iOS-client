//
//  PariticipantId.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/19.
//

import Foundation
import ByteViewNetwork

extension ParticipantAbbrInfo: ParticipantIdConvertible {
    var id: String {
        user.id
    }

    public var participantId: ParticipantId {
        ParticipantId(id: user.participantId.id, type: user.participantId.type, deviceId: user.participantId.deviceId,
                      bindInfo: BindInfo(id: bindID, type: bindType))
    }
}
