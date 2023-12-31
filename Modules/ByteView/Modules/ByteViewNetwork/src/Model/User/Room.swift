//
//  Room.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/9/7.
//

import Foundation
import ByteViewCommon

/// https://bytedance.feishu.cn/docs/doccndWGB1T3sEFuBUljXiHMOrb#
public struct Room: Equatable {
    public let id: String
    public let tenantId: String
    public var name: String
    public var avatarInfo: AvatarInfo
    /// floor_name-name
    public var primaryName: String
    /// building_name
    public var secondaryName: String
    /// building_name-floor_name-name
    public var fullName: String
    /// 是否未知用户
    public let isUnknown: Bool

    public var inMeetingName: String?

    public init(id: String, tenantId: String, name: String, avatarInfo: AvatarInfo,
                primaryName: String, secondaryName: String, fullName: String) {
        self.isUnknown = false
        self.id = id
        self.tenantId = tenantId
        self.name = name
        self.avatarInfo = avatarInfo
        self.primaryName = primaryName
        self.secondaryName = secondaryName
        self.fullName = fullName
    }

    public init(unknown id: String) {
        self.isUnknown = true
        self.id = id
        self.name = I18n.View_VM_Unknown
        self.fullName = I18n.View_VM_Unknown
        self.avatarInfo = .unknown
        self.tenantId = ""
        self.primaryName = ""
        self.secondaryName = ""
    }

    public var displayName: String {
        return inMeetingName ?? fullName
    }
}

extension Room: CustomStringConvertible {
    public var description: String {
        String(
            indent: "Room",
            "id: \(id)",
            "avatar: \(avatarInfo)",
            "tenantId: \(tenantId)",
            "isUnknown: \(isUnknown)",
            "hasName: \(!name.isEmpty)",
            "hasFullName: \(!fullName.isEmpty)",
            "hasPrimaryame: \(!primaryName.isEmpty)",
            "hasSecondaryName: \(!secondaryName.isEmpty)"
        )
    }
}
