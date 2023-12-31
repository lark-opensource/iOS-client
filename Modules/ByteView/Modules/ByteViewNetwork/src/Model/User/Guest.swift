//
//  Guest.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/9/7.
//

import Foundation
import ByteViewCommon

/// 标记一些非体系内的账号
/// - case neoGuestUser = 5
/// - case pstnUser = 6
/// - case sipUser = 7
/// - case xiaofei = 10
public struct Guest: Equatable {
    public let id: String
    public let type: ParticipantType
    public var name: String
    public var fullName: String
    public var avatarInfo: AvatarInfo
    public var nickname: String = ""

    /// 是否未知用户
    public let isUnknown: Bool

    public var inMeetingName: String?

    public init(id: String, type: ParticipantType, name: String, fullName: String, avatarKey: String) {
        self.isUnknown = false
        self.id = id
        self.type = type
        self.name = name
        self.fullName = fullName
        if avatarKey.isEmpty {
            switch type {
            case .pstnUser:
                self.avatarInfo = .pstn
            case .sipUser:
                self.avatarInfo = .sip
            default:
                self.avatarInfo = .unknown
            }
        } else {
            self.avatarInfo = .remote(key: avatarKey, entityId: id)
        }
    }

    public init(unknown id: String) {
        self.isUnknown = true
        self.id = id
        self.name = I18n.View_VM_Unknown
        self.fullName = I18n.View_VM_Unknown
        self.type = .unknown
        self.avatarInfo = .unknown
    }

    public var originalName: String {
        if !nickname.isEmpty {
            return nickname
        } else if !name.isEmpty {
            return name
        } else if !fullName.isEmpty {
            return fullName
        } else {
            return ""
        }
    }

    public var displayName: String {
        if let inMeetingName = inMeetingName, !inMeetingName.isEmpty {
            return inMeetingName
        } else {
            return originalName
        }
    }
}

extension Guest: CustomStringConvertible {
    public var description: String {
        String(
            indent: "Guest",
            "id: \(id)",
            "type: \(type)",
            "avatar: \(avatarInfo)",
            "isUnknown: \(isUnknown)",
            "hasName: \(!name.isEmpty)",
            "hasFullName: \(!fullName.isEmpty)",
            "hsNickname: \(!nickname.isEmpty)"
        )
    }
}
