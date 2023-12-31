//
//  LarkInterface+Setting.swift
//  LarkMessengerInterface
//
//  Created by JackZhao on 2021/2/7.
//

import Foundation
import LarkModel

public enum EnterChatSettingSource: String {
    case chatTitle = "chat_title"
    case chatMoreMobile = "chat_more_mobile"
    case chatSwipeMobile = "chat_swipe_mobile"
}

public enum EnterChatSettingAction: String {
    case chatTitle = "group_name_mobile"
    case chatMoreMobile = "more_mobile"
    case chatSwipeMobile = "left_slide_mobile"
}

public enum GroupMemberClickEvent: String {
    case transferOwner = "transfer_owner"  // 转让群主
    case assignAdmin = "assign_admin"    //设为群管理员
    case deleteAdmin = "delete_admin"    //取消群管理员
    case deleteGroupMembers = "delete_group_members" //删除群成员
}

public enum MessengerMemberType: String {
    // 旧版参数, 防止数据统计受影响，暂时保留
    case member
    case admin

    // 新版参数
    case normalMember = "normal_member"
    case groupOwner = "group_owner"
    case groupAdmin = "group_admin"
    case bot = "bot"

    // 旧的埋点参数获取方法，防止数据统计受影响，暂时保留
    public static func getTypeWithIsAdmin(_ isAdmin: Bool) -> MessengerMemberType {
        if isAdmin { return .admin }
        return .member
    }

    // 新的埋点参数获取方法
    public static func getNewTypeWithIsAdmin(isOwner: Bool, isAdmin: Bool, isBot: Bool) -> MessengerMemberType {
        if isOwner { return .groupOwner }
        if isAdmin { return .groupAdmin }
        if isBot { return .bot }
        return .normalMember
    }
}

public enum MessengerChatMode: String {
    case `private`
    case `public`

    public static func getTypeWithIsPublic(_ isPublic: Bool) -> MessengerChatMode {
        if isPublic { return .public }
        return .private
    }
}

public enum MessengerChatType: String {
    case unknown = "unknown"
    case classic = "classic"
    case circle = "circle"
    case department = "department"
    case allStaff = "all_staff"
    case onCall = "on_call"
    case customerService = "customer_service"
    case meeting = "meeting"
    case `internal` = "internal"
    case p2p = "p2p"

    public static func getTypeWithChat(_ chat: Chat) -> MessengerChatType {
        if chat.type == .p2P { return .p2p }
        if chat.isOncall { return .onCall }
        if chat.isMeeting { return .meeting }
        if chat.isDepartment { return .department }
        if chat.chatMode == .threadV2 { return .circle }
        if chat.isCustomerService { return .customerService }
        if chat.isTenant { return .allStaff }
        if chat.chatMode == .default { return .classic }
        assertionFailure("unknown type")
        return .unknown
    }
}

public struct TrackerUtils {
    public static func getChatType(chat: Chat) -> String {
        if chat.type == .p2P { return "single" }
        if chat.type == .group { return "group" }
        if chat.chatMode == .threadV2 { return "circle" }
        assertionFailure("unknown type")
        return "unknown"
    }

    public static func getChatTypeDetail(chat: Chat, myUserId: String) -> String {
        if chat.type == .p2P {
            if chat.chatterId == myUserId {
                return "to_myself_single"
            } else if chat.isSingleBot {
                return "single_bot"
            }
            return "single_normal"
        }
        if chat.type == .group && chat.userCount == 1 { return "to_myself_group" }
        if chat.isOncall { return "on_call" }
        if chat.isMeeting { return "meeting" }
        if chat.isDepartment { return "department" }
        if chat.chatMode == .threadV2 { return "circle" }
        if chat.isCustomerService { return "customer_service" }
        if chat.isTenant { return "all_staff" }
        if chat.chatMode == .default { return "classic" }
        assertionFailure("unknown type")
        return "unknown"
    }
}
