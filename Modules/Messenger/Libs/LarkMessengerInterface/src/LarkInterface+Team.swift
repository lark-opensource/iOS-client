//
//  LarkInterface+Team.swift
//  LarkMessengerInterface
//
//  Created by JackZhao on 2021/7/5.
//

import UIKit
import RustPB
import LarkModel
import Foundation
import EENavigator
import LarkSDKInterface

// 创建团队
public struct CreateTeamBody: PlainBody {
    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(pattern)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(CreateTeamBody.pattern)") ?? .init(fileURLWithPath: "")
    }

    public static let pattern: String = "//client/im/team/createTeam"
    public let successCallback: ((Basic_V1_Team) -> Void)?

    public init(successCallback: ((Basic_V1_Team) -> Void)? = nil) {
        self.successCallback = successCallback
    }
}

// 创建群组
public struct TeamCreateGroupBody: CodableBody {
    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(pattern)/:teamId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(TeamCreateGroupBody.pattern)/\(teamId)") ?? .init(fileURLWithPath: "")
    }

    public static let pattern: String = "//client/im/team/createTeamGroup"
    public let teamId: Int64
    public let isAllowAddTeamPrivateChat: Bool
    public let chatId: String
    public let ownerId: Int64

    public init(teamId: Int64,
                chatId: String,
                ownerId: Int64,
                isAllowAddTeamPrivateChat: Bool) {
        self.teamId = teamId
        self.ownerId = ownerId
        self.chatId = chatId
        self.isAllowAddTeamPrivateChat = isAllowAddTeamPrivateChat
    }
}

// 添加团队成员
public struct TeamAddMemberBody: PlainBody {
    public static let pattern = "//client/im/team/member/addNew"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(pattern)/:teamId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(TeamAddMemberBody.pattern)/\(teamId)") ?? .init(fileURLWithPath: "")
    }

    public let teamId: Int64

    public let forceSelectedChatterIds: [String]

    public let title: String?
    public typealias CompletionHandler = () -> Void
    public let completionHandler: CompletionHandler?
    public let customLeftBarButtonItem: Bool

    public init(teamId: Int64,
                forceSelectedChatterIds: [Int64],
                title: String? = nil,
                completionHandler: CompletionHandler? = nil,
                customLeftBarButtonItem: Bool = false) {
        self.teamId = teamId
        self.forceSelectedChatterIds = forceSelectedChatterIds.map({ String($0) })
        self.title = title
        self.completionHandler = completionHandler
        self.customLeftBarButtonItem = customLeftBarButtonItem
    }
}

// 团队设置
public struct TeamSettingBody: PlainBody {
    public static let pattern: String = "//client/im/team/mainSetting"
    public let team: Team

    public init(team: Team) {
        self.team = team
    }
}

// 团队添加群组
public struct TeamBindGroupBody: PlainBody {
    public static let pattern: String = "//client/im/team/addGroup"
    public let teamId: Int64
    public let customLeftBarButtonItem: Bool
    public typealias CompletionHandler = (String?) -> Void
    public let completionHandler: TeamBindGroupBody.CompletionHandler?
    public init(teamId: Int64,
                completionHandler: TeamBindGroupBody.CompletionHandler? = nil,
                customLeftBarButtonItem: Bool = false) {
        self.teamId = teamId
        self.completionHandler = completionHandler
        self.customLeftBarButtonItem = customLeftBarButtonItem
    }
}

// 团队信息
public struct TeamInfoBody: PlainBody {
    public static let pattern: String = "//client/im/team/info"
    public var team: Team

    public init(team: Team) {
        self.team = team
    }
}

// 团队描述
public struct TeamDescriptionBody: PlainBody {
    public static let pattern: String = "//client/im/team/description"
    public var team: Team

    public init(team: Team) {
        self.team = team
    }
}

// 团队名称修改
public struct TeamNameConfigBody: PlainBody {
    public static let pattern: String = "//client/im/team/setting/nameConfig"
    public var team: Team
    public var hasAccess: Bool

    public init(team: Team,
                hasAccess: Bool) {
        self.team = team
        self.hasAccess = hasAccess
    }
}

// 设置公开群，系统消息的点击会用到
public struct TeamSetOpenGroupBody: PlainBody {
    public static let pattern: String = "//client/im/team/setOpenGroup"
    public var teamId: Int64
    public var chatId: Int64

    public init(teamId: Int64,
                chatId: Int64) {
        self.teamId = teamId
        self.chatId = chatId
    }
}

public enum TeamMemberMode: String, Codable {
    case normal
    case multiRemoveTeamMember // 多项移除
}

public enum TeamMemberNavItemType: String, Codable {
    case noneItem       // 无选项
    case moreItem       // 更多选项
    case removeItem     // 移除选项
    case addItem        // 添加选项
}

public enum TeamMemberDataScene: String, Codable {
    case normal // 普通列表，包含chat和chatter
    case transferOwner // 只包含chatter（会把chat中的chatter也拆出来）
}

public typealias TeamMemberFliter = (_ member: Basic_V1_TeamMemberInfo) -> Bool

public typealias TeamSelectdMemberCallback = (_ chatterId: String,
                                              _ chatterName: String,
                                              _ from: UIViewController) -> Void
// 团队成员页面
public struct TeamMemberListBody: PlainBody {
    public static let pattern = "//client/messenger/team/member"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(pattern)/:teamId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(TeamMemberListBody.pattern)/\(teamId)") ?? .init(fileURLWithPath: "")
    }
    public let teamId: Int64
    public let mode: TeamMemberMode
    public let navItemType: TeamMemberNavItemType
    public let scene: TeamMemberDataScene
    public let selectdMemberCallback: TeamSelectdMemberCallback?
    public let isTransferTeam: Bool
    public init(teamId: Int64,
                mode: TeamMemberMode,
                navItemType: TeamMemberNavItemType,
                isTransferTeam: Bool,
                scene: TeamMemberDataScene,
                selectdMemberCallback: TeamSelectdMemberCallback? = nil) {
        self.teamId = teamId
        self.mode = mode
        self.navItemType = navItemType
        self.scene = scene
        self.selectdMemberCallback = selectdMemberCallback
        self.isTransferTeam = isTransferTeam
    }
}

public struct TeamEventBody: PlainBody {
    public static let pattern: String = "//client/im/team/teamEvent"
    public var teamID: Int64

    public init(teamID: Int64) {
        self.teamID = teamID
    }
}

/// 团队头像
public struct TeamCustomizeAvatarBody: PlainBody {
    public static var pattern: String = "//client/create/modify/avatar"

    public let name: String?
    public let avatarKey: String
    public let entityId: String
    public let avatarDrawStyle: AvatarDrawStyle
    public let imageData: Data?
    public let avatarMeta: RustPB.Basic_V1_AvatarMeta?
    public let defaultCenterIcon: UIImage
    public var savedCallback: ((UIImage, RustPB.Basic_V1_AvatarMeta, UIViewController, UIView) -> Void)?

    public init(avatarKey: String,
                entityId: String,
                name: String?,
                imageData: Data?,
                avatarDrawStyle: AvatarDrawStyle = .soild,
                avatarMeta: RustPB.Basic_V1_AvatarMeta?,
                defaultCenterIcon: UIImage) {
        self.name = name
        self.avatarDrawStyle = avatarDrawStyle
        self.avatarKey = avatarKey
        self.entityId = entityId
        self.imageData = imageData
        self.avatarMeta = avatarMeta
        self.defaultCenterIcon = defaultCenterIcon
    }
}

public struct EasilyJoinTeamBody: PlainBody {
    public static var pattern: String = "//client/create/modify/joinTeam"

    public let feedpreview: FeedPreview

    public init(feedpreview: FeedPreview) {
        self.feedpreview = feedpreview
    }
}

public struct BindItemInToTeamBody: PlainBody {
    public static let pattern = "//client/feed/team/addItem"

    public let feedPreview: FeedPreview

    public init(feedPreview: FeedPreview) {
        self.feedPreview = feedPreview
    }
}

public protocol TeamActionService {
    func joinTeamDialog(team: Basic_V1_Team, feedPreview: FeedPreview, on vc: UIViewController, isNewTeam: Bool, successCallBack: (() -> Void)?)

    func enableJoinTeam(feedPreview: FeedPreview) -> Bool
}

// 团队群组设置隐私权限
public struct TeamGroupPrivacyBody: PlainBody {
    public static let pattern: String = "//client/im/team/group/privacy"
    public let teamId: Int64
    public let chatId: String
    public let teamName: String
    public let isMessageVisible: Bool
    public let ownerAuthority: Bool
    public let isCrossTenant: Bool
    public let messageVisibility: Bool
    public let discoverable: Bool

    public init(teamId: Int64,
                chatId: String,
                teamName: String,
                isMessageVisible: Bool,
                ownerAuthority: Bool,
                isCrossTenant: Bool,
                discoverable: Bool,
                messageVisibility: Bool) {
        self.teamId = teamId
        self.chatId = chatId
        self.teamName = teamName
        self.isMessageVisible = isMessageVisible
        self.ownerAuthority = ownerAuthority
        self.isCrossTenant = isCrossTenant
        self.discoverable = discoverable
        self.messageVisibility = messageVisibility
    }
}
