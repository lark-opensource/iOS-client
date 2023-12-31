//
//  PickerChatMeta.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/3/28.
//

import Foundation
import RustPB

public struct PickerChatMeta: PickerItemMetaType {
    public var id: String
    
    public var name: String?
    public var namePinyin: String?
    public var avatarKey: String?
    public var ownerId: String?
    /// unknown `default` thread threadV2
    public var type: RustPB.Basic_V1_Chat.TypeEnum
    public var mode: RustPB.Basic_V1_Chat.ChatMode = .default
    public var userCount: Int32?
    public var tags: [RustPB.Basic_V1_Tag]?
    public var desc: String?
    /// 部分群组带企业邮箱
    public var enterpriseMailAddress: String?

    public var lastMessageId: String?
    public var lastMessageTime: Int64?

    public var isDepartment: Bool?
    public var isOuter: Bool?
    public var isCrypto: Bool?

    public var isPublic: Bool?
    public var isMeeting: Bool?
    public var isKa: Bool?
    public var isShield: Bool?
    public var isInTeam: Bool?

    public init(id: String, name: String? = nil, namePinyin: String? = nil,
                avatarKey: String? = nil, ownerId: String? = nil,
                type: Basic_V1_Chat.TypeEnum, mode: Basic_V1_Chat.ChatMode = .default,
                userCount: Int32? = nil, tags: [Basic_V1_Tag]? = nil,
                desc: String? = nil, enterpriseMailAddress: String? = nil,
                lastMessageId: String? = nil, lastMessageTime: Int64? = nil,
                isDepartment: Bool? = nil, isOuter: Bool? = nil,
                isCrypto: Bool? = nil, isPublic: Bool? = nil, isMeeting: Bool? = nil,
                isKa: Bool? = nil, isShield: Bool? = nil, isInTeam: Bool? = nil) {
        self.id = id
        self.name = name
        self.namePinyin = namePinyin
        self.avatarKey = avatarKey
        self.ownerId = ownerId
        self.type = type
        self.mode = mode
        self.userCount = userCount
        self.tags = tags
        self.desc = desc
        self.enterpriseMailAddress = enterpriseMailAddress
        self.lastMessageId = lastMessageId
        self.lastMessageTime = lastMessageTime
        self.isDepartment = isDepartment
        self.isOuter = isOuter
        self.isCrypto = isCrypto
        self.isPublic = isPublic
        self.isMeeting = isMeeting
        self.isKa = isKa
        self.isShield = isShield
        self.isInTeam = isInTeam
    }
}
