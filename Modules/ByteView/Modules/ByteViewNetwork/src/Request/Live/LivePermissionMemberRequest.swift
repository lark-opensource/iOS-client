//
//  LivePermissionMemberRequest.swift
//  ByteViewNetwork
//
//  Created by sihuahao on 2022/5/8.
//

import Foundation
import ServerPB
import RustPB

/// - LIVE_PERMISSION_MEMBER = 200044
/// - ServerPB_Videochat_live_GetLivePermissionMembersRequest
public struct LivePermissionMemberRequest {
    public static let command: NetworkCommand = .server(.getLivePermissionMembers)
    public typealias Response = LivePermissionMemberResponse

    public init(meetingId: String, liveId: String?) {
        self.meetingId = meetingId
        self.liveId = liveId
    }

    public var liveId: String?
    public var meetingId: String
}

/// ServerPB_Videochat_live_GetLivePermissionMembersResponse
public struct LivePermissionMemberResponse: Equatable {

    public var allowExternal: Bool?
    // 直播与开播者属于同一租户
    public var sameTenant: Bool?
    public var totalMembers: Int32?
    public var members: [LivePermissionMember]
    public var isAllResigned: Bool  // 全部已离职
    public var isOversea: Bool // 是否为海外

}

extension LivePermissionMemberRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_live_GetLivePermissionMembersRequest
    func toProtobuf() throws -> ServerPB_Videochat_live_GetLivePermissionMembersRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        return request
    }
}

extension LivePermissionMemberResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_live_GetLivePermissionMembersResponse
    init(pb: ServerPB_Videochat_live_GetLivePermissionMembersResponse) throws {
        self.allowExternal = pb.allowExternal
        self.sameTenant = pb.sameTenant
        self.totalMembers = pb.totalMembers
        self.isAllResigned = pb.isAllResigned
        self.isOversea = pb.isOversea
        var realMembers: [LivePermissionMember] = []
        for item in pb.members {
            switch item.memberType {
            case .memberTypeDepartment:
                realMembers.append(LivePermissionMember(memberId: item.memberID, memberType: .memberTypeDepartment, avatarUrl: item.avatarURL, isExternal: item.isExternal, isChatManager: item.isChatManager, isUserInChat: item.isUserInChat, userCount: item.userCount, memberName: LivePermissionMember.I18nString(zh_cn: item.memberName.zhCn, en_us: item.memberName.enUs, ja_jp: item.memberName.jaJp)))
            case .memberTypeChat:
                realMembers.append(LivePermissionMember(memberId: item.memberID, memberType: .memberTypeChat, avatarUrl: item.avatarURL, isExternal: item.isExternal, isChatManager: item.isChatManager, isUserInChat: item.isUserInChat, userCount: item.userCount, memberName: LivePermissionMember.I18nString(zh_cn: item.memberName.zhCn, en_us: item.memberName.enUs, ja_jp: item.memberName.jaJp)))
            case .memberTypeUser:
                realMembers.append(LivePermissionMember(memberId: item.memberID, memberType: .memberTypeUser, avatarUrl: item.avatarURL, isExternal: item.isExternal, isChatManager: item.isChatManager, isUserInChat: item.isUserInChat, userCount: item.userCount, memberName: LivePermissionMember.I18nString(zh_cn: item.memberName.zhCn, en_us: item.memberName.enUs, ja_jp: item.memberName.jaJp)))
            @unknown default:
                break
            }
        }
        self.members = realMembers
    }
}
