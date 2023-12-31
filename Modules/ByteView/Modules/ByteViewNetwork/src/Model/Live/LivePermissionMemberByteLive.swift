//   
//   LivePermissionMemberByteLive.swift
//   ByteViewNetwork
// 
//  Created by hubo on 2023/2/9.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//   


import Foundation
import ServerPB

public enum MemberSource: Int, Hashable {
    case unknow // = 0;
    case lark // = 1; // 飞书内配置的
    case console // = 2; // 企业直播控制台配置的
}

public struct LivePermissionMemberByteLive: Equatable {

    public init(larkMember: LivePermissionMember) {
        self.memberId = larkMember.memberId
        self.memberName = larkMember.memberName
        self.avatarUrl = larkMember.avatarUrl
        self.memberType = larkMember.memberType
        self.source = .lark
    }

    public var memberId: String
    // 名称
    public var memberName: LivePermissionMember.I18nString?
    // 用户/群组头像
    public var avatarUrl: String?

    public var memberType: LivePermissionMember.PermissionMemberType?

    public var source: MemberSource

    public func larkMember() -> LivePermissionMember {
        return LivePermissionMember(memberId: memberId, memberType: memberType, avatarUrl: avatarUrl ?? "", isExternal: nil, isChatManager: nil, isUserInChat: nil, userCount: 0, memberName: memberName)
    }
}

extension LivePermissionMemberByteLive: ProtobufEncodable, ProtobufDecodable {
    typealias ProtobufType = ServerPB_Videochat_live_LivePermissionMemberByteLive
    init(pb: ServerPB_Videochat_live_LivePermissionMemberByteLive) {
        self.memberId = pb.memberID
        switch pb.memberType {
        case .memberTypeDepartment:
            self.memberType = .memberTypeDepartment
        case .memberTypeChat:
            self.memberType = .memberTypeChat
        case .memberTypeUser:
            self.memberType = .memberTypeUser
        @unknown default:
            self.memberType = .memberTypeUnknown
        }
        self.avatarUrl = pb.avatarURL
        self.memberName = LivePermissionMember.I18nString(zh_cn: pb.memberName.zhCn, en_us: pb.memberName.enUs, ja_jp: pb.memberName.jaJp)
        self.source = MemberSource(rawValue: pb.source.rawValue) ?? .unknow
    }

    func toProtobuf() -> ServerPB_Videochat_live_LivePermissionMemberByteLive {
        var member = ProtobufType()
        member.memberID = memberId
        if let memberType = memberType {
            switch memberType {
            case .memberTypeDepartment:
                member.memberType = .memberTypeDepartment
            case .memberTypeChat:
                member.memberType = .memberTypeChat
            case .memberTypeUser:
                member.memberType = .memberTypeUser
            default:
                member.memberType = .memberTypeUnknown
            }
        }
        if let url = avatarUrl {
            member.avatarURL = url
        }
        if let memberName = memberName {
            member.memberName.zhCn = memberName.zh_cn ?? ""
            member.memberName.jaJp = memberName.ja_jp ?? ""
            member.memberName.enUs = memberName.en_us ?? ""
        }
        member.source = ServerPB_Videochat_live_MemberSource(rawValue: self.source.rawValue) ?? .unknown
        return member
    }
}
