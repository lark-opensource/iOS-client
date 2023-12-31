//
//  SubtitleUser.swift
//  ByteViewCommon
//
//  Created by panzaofeng on 2022/4/20.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_SubtitleUserInfo
public struct SubtitleUser: Equatable {
    public var user: ByteviewUser

    public var info: PSTNInfo

    public init(user: ByteviewUser, info: PSTNInfo) {
        self.user = user
        self.info = info
    }
}

extension SubtitleUser: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        let bindInfo = BindInfo(id: info.bindId, type: info.bindType)
        return ParticipantId(id: user.id, type: user.type, deviceId: user.deviceId, bindInfo: bindInfo)
    }
}

extension SubtitleUser: CustomStringConvertible {
    public var description: String {
        String(indent: "SubtitleUser", "id: \(user.id)", "type: \(user.type)", "bindid: \(info.bindId)")
    }
}
