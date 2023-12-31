//
//  ParticipantUserInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/9/7.
//

import Foundation
import ByteViewCommon

public struct ParticipantUserInfo: Equatable {
    public let id: String
    public var name: String
    public var originalName: String
    public var avatarInfo: AvatarInfo
    public var tenantId: String
    /// 是否未知用户
    public let isUnknown: Bool

    public var pid: ParticipantId?

    public let user: User?
    public let room: Room?
    public let guest: Guest?

    public static func user(_ user: User) -> ParticipantUserInfo {
        .init(id: user.id,
              name: user.displayName,
              originalName: user.name,
              avatarInfo: user.avatarInfo,
              tenantId: user.tenantId,
              isUnknown: user.isUnknown,
              user: user,
              room: nil,
              guest: nil)
    }

    public static func room(_ room: Room) -> ParticipantUserInfo {
        .init(id: room.id,
              name: room.displayName,
              originalName: room.fullName,
              avatarInfo: room.avatarInfo,
              tenantId: room.tenantId,
              isUnknown: room.isUnknown,
              user: nil,
              room: room,
              guest: nil)
    }

    public static func guest(_ guest: Guest) -> ParticipantUserInfo {
        .init(id: guest.id,
              name: guest.displayName,
              originalName: guest.originalName,
              avatarInfo: guest.avatarInfo,
              tenantId: "",
              isUnknown: guest.isUnknown,
              user: nil,
              room: nil,
              guest: guest)
    }
}

extension ParticipantUserInfo: CustomStringConvertible {
    public var description: String {
        String(
            indent: "UserInfo",
            "id: \(id)",
            "tenantId: \(tenantId)",
            "user: \(user)",
            "room: \(room)",
            "guest: \(guest)"
        )
    }
}
