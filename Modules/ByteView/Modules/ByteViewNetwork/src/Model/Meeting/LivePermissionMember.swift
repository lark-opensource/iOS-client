//
//  LivePermissionMember.swift
//  ByteViewNetwork
//
//  Created by sihuahao on 2022/5/6.
//

import Foundation
import ServerPB

public struct LivePermissionMember: Equatable {

    public init(memberId: String, memberType: PermissionMemberType?, avatarUrl: String?, isExternal: Bool?, isChatManager: Bool?, isUserInChat: Bool?, userCount: Int32?, memberName: I18nString?) {
        self.memberId = memberId
        self.memberType = memberType
        self.avatarUrl = avatarUrl
        self.isExternal = isExternal
        self.isChatManager = isChatManager
        self.isUserInChat = isUserInChat
        self.userCount = userCount
        self.memberName = memberName
    }

    public var memberId: String

    public var memberType: PermissionMemberType?
     // 用户/群组头像
    public var avatarUrl: String?
     // 用户/群组展示外部标志
    public var isExternal: Bool?
     // 是否群组管理员
    public var isChatManager: Bool?
     // 是否在群中
    public var isUserInChat: Bool?
     // 群组内人数
    public var userCount: Int32?
     // 多语言名称
    public var memberName: I18nString?

    public enum PermissionMemberType: Int, Hashable {
        case memberTypeUnknown //= 0
        case memberTypeUser //= 1
        case memberTypeChat //= 2
        case memberTypeDepartment //= 3
    }

    public struct I18nString: Equatable {

        public init(zh_cn: String?, en_us: String?, ja_jp: String?) {
            self.zh_cn = zh_cn
            self.en_us = en_us
            self.ja_jp = ja_jp
        }

        public var zh_cn: String?
        public var en_us: String?
        public var ja_jp: String?
    }
}

extension LivePermissionMember: ProtobufEncodable, ProtobufDecodable {
    typealias ProtobufType = ServerPB_Videochat_InMeetingData.LiveMeetingData.LivePermissionMember
    init(pb: ServerPB_Videochat_InMeetingData.LiveMeetingData.LivePermissionMember) throws {
        self.memberId = pb.memberID
        switch pb.memberType {
        case .memberTypeUnknown:
            self.memberType = .memberTypeUnknown
        case .memberTypeDepartment:
            self.memberType = .memberTypeDepartment
        case .memberTypeChat:
            self.memberType = .memberTypeChat
        case .memberTypeUser:
            self.memberType = .memberTypeUser
        @unknown default:
            throw ProtobufCodableError(.notSupported, "memberType: \(pb.memberType)")
        }
        self.avatarUrl = pb.avatarURL
        self.isExternal = pb.isExternal
        self.isChatManager = pb.isChatManager
        self.isUserInChat = pb.isUserInChat
        self.userCount = pb.userCount
        self.memberName = I18nString(zh_cn: pb.memberName.zhCn, en_us: pb.memberName.enUs, ja_jp: pb.memberName.jaJp)
    }

    func toProtobuf() -> ServerPB_Videochat_InMeetingData.LiveMeetingData.LivePermissionMember {
        var member = ProtobufType()
        member.memberID = memberId
        if let memberType = memberType {
            switch memberType {
            case .memberTypeUnknown:
                member.memberType = .memberTypeUnknown
            case .memberTypeDepartment:
                member.memberType = .memberTypeDepartment
            case .memberTypeChat:
                member.memberType = .memberTypeChat
            case .memberTypeUser:
                member.memberType = .memberTypeUser
            }
        }
        if let url = avatarUrl {
            member.avatarURL = url
        }
        if let isExternal = isExternal{
            member.isExternal = isExternal
        }
        if let isChatManager = isChatManager {
            member.isChatManager = isChatManager

        }
        if let isUserInChat = isUserInChat {
            member.isUserInChat = isUserInChat

        }
        if let memberName = memberName {
            member.memberName.zhCn = memberName.zh_cn ?? ""
            member.memberName.jaJp = memberName.ja_jp ?? ""
        }
        return member
    }
}
