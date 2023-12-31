//
//  UserId.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/9/7.
//

import Foundation

public protocol ParticipantIdConvertible {
    var participantId: ParticipantId { get }
}

public struct ParticipantId: Hashable {
    public let id: String
    public let type: ParticipantType
    public let deviceId: String
    public let bindInfo: BindInfo?

    public init(id: String, type: ParticipantType, deviceId: String = "0", bindInfo: BindInfo? = nil) {
        self.id = id
        self.type = type
        self.deviceId = deviceId
        self.bindInfo = bindInfo
    }
}

public extension ParticipantId {
    var larkUserId: String? {
        if type == .larkUser {
            return id
        } else if type == .pstnUser, let info = bindInfo, info.type == .lark {
            return info.id
        }
        return nil
    }

    var identifier: String {
        "\(id)_\(type.rawValue)_\(deviceId)"
    }

    var ringingIdentifier: String {
        "\(id)_\(type.rawValue)"
    }

    var pid: ByteviewUser {
        return ByteviewUser(id: id, type: type, deviceId: deviceId)
    }
}
