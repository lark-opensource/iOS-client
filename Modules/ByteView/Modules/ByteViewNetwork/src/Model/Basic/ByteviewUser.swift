//
//  ByteviewUser.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_ByteviewUser
public struct ByteviewUser: Hashable, Codable {
    public var id: String

    public var type: ParticipantType

    public var deviceId: String

    public init(id: String, type: ParticipantType, deviceId: String = "0") {
        self.id = id
        self.type = type
        self.deviceId = deviceId
    }

    public static func == (lhs: ByteviewUser, rhs: ByteviewUser) -> Bool {
        if lhs.deviceIdIsEmpty && rhs.deviceIdIsEmpty {
            return lhs.id == rhs.id && lhs.type == rhs.type
        }
        return lhs.id == rhs.id && lhs.type == rhs.type && lhs.deviceId == rhs.deviceId
    }
}

public extension ByteviewUser {
    var isSipOrRoom: Bool {
        self.type == .sipUser || self.type == .room
    }

    var deviceIdIsEmpty: Bool {
        self.deviceId.isEmpty || self.deviceId == "0"
    }
}

extension ByteviewUser: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        ParticipantId(id: id, type: type, deviceId: deviceId)
    }
}

extension ByteviewUser: CustomStringConvertible {
    public var description: String {
        String(indent: "ByteviewUser", "id: \(id)", "type: \(type)", "deviceId: \(deviceId)")
    }
}
