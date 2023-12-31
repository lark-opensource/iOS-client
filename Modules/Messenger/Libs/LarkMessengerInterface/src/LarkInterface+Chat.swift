//
//  LarkInterface+Chat.swift
//  LarkInterface
//
//  Created by linlin on 2018/5/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import LarkModel
import RxSwift
import RxCocoa
import RustPB
import EENavigator
import SuiteCodable
import Photos
import LarkSDKInterface
import LarkSegmentedView
import ServerPB
import LarkMessageBase
import UIKit
import EditTextView
import LarkRichTextCore
import LarkStorage
import LarkBaseKeyboard
import LarkOpenChat
import LarkChatOpenKeyboard
import LarkAIInfra

public enum ChatFromWhere: Codable, HasDefault {
    public static func `default`() -> ChatFromWhere {
        return .ignored
    }

    case feed
    case push // 在线\离线 banner
    case shortcut
    case search
    case card //卡片（加急、日历等）
    case profile // 通过名片页，选人组件，通讯录，群成员列表 等方式进入。
    case singleChatGroup // single chat group 单聊建群
    case thread
    case mygroup
    case mygroupCreated
    case mygroupJoined
    case ignored // 忽略的，不在意来自哪里
    case teamOpenChat // 团队下的公开群的内部（chat底部申请入群）
    case flag // 标记
    case vcMeeting // VC 会议入群
    case myAIChatMode // 应用唤起MyAI分会场
    case team(teamID: Int64)

    public var rawValue: String {
        switch self {
        case .feed:
            return "feed"
        case .push:
            return "push"
        case .shortcut:
            return "shortcut"
        case .search:
            return "search"
        case .card:
            return "card"
        case .profile:
            return "profile"
        case .singleChatGroup:
            return "singleChatGroup"
        case .thread:
            return "thread"
        case .mygroup:
            return "mygroup"
        case .mygroupCreated:
            return "contact_mygroup_created"
        case .mygroupJoined:
            return "contact_mygroup_joine"
        case .ignored:
            return "ignored"
        case .teamOpenChat:
            return "teamOpenChat"
        case .flag:
            return "flag"
        case .myAIChatMode:
            return "myAIChatMode"
        case .vcMeeting:
            return "vcMeeting"
        case .team(let teamID):
            return String(teamID)
        }
    }

    public init?(fromValue: String?, value: Any? = nil) {
        guard let fromValue = fromValue else { return nil }
        switch fromValue {
        case "feed":
            self = .feed
        case "push ":
            self = .push
        case "shortcut":
            self = .shortcut
        case "search":
            self = .search
        case "card":
            self = .card
        case "profile":
            self = .profile
        case "singleChatGroup":
            self = .singleChatGroup
        case "thread":
            self = .thread
        case "mygroup":
            self = .mygroup
        case "contact_mygroup_created":
            self = .mygroupCreated
        case "contact_mygroup_joine":
            self = .mygroupJoined
        case "ignored":
            self = .ignored
        case "teamOpenChat":
            self = .teamOpenChat
        case "flag":
            self = .flag
        case "vcMeeting":
            self = .vcMeeting
        case "myAIChatMode":
            self = .myAIChatMode
        case "team":
            guard let teamID = value as? Int64 else { return nil }
            self = .team(teamID: teamID)
        default:
            return nil
        }
    }

    public var sourceTypeForReciableTrace: Int {
        switch self {
        case .feed:
            return 1
        case .push:
            return 2
        case .shortcut:
            return 3
        case .search:
            return 5
        case .card:
            return 7
        case .profile:
            return 8
        case .singleChatGroup:
            return 9
        case .thread:
            return 10
        case .mygroup:
            return 11
        case .mygroupCreated:
            return 12
        case .mygroupJoined:
            return 13
        case .teamOpenChat:
            return 14
        case .flag:
            return 15
        case .team:
            return 16
        case .vcMeeting:
            return 17
        case .myAIChatMode:
            return 18
        case .ignored:
            return 0
        }
    }

    public static func == (lhs: ChatFromWhere, rhs: ChatFromWhere) -> Bool {
        switch (lhs, rhs) {
        case let (.team(teamID1), .team(teamID2)):
            if teamID1 == teamID2 {
                return true
            } else {
                return false
            }
        default:
            return lhs.rawValue == rhs.rawValue
        }
    }

    public static func != (lhs: ChatFromWhere, rhs: ChatFromWhere) -> Bool {
        return !(lhs == rhs)
    }
}

// 从什么渠道建群
public enum CreateGroupFromWhere: String {
    case unknown
    case plusMenu = "plus_menu" /// 加号建群
    case p2pConfig = "p2p_config" /// 单聊建群-设置中建群
    case internalToExternal = "internal_to_external" /// 从内部群创建外部群
    case forward = "forward" /// 转发分享时建群
    case mygroup = "mygroup" /// 我的群组里
}

////细化fromWhere的二级来源
public enum SpecificSourceFromWhere: Codable {
    case searchResultMessage   //pad 从搜索-消息跳转的消息详情页
}

// 键盘初始化状态
public struct KeyboardStartupState: Codable, HasDefault {
    public static func `default`() -> KeyboardStartupState {
        return KeyboardStartupState(type: .none)
    }

    public enum TypeEnum: String, Codable {
        case none        // 不做任何处理
        case inputView   // 如果存在草稿，聚焦在草稿
        case stickerSet  // 键盘聚焦在 stickerSet 上, info 字段代表 stickerSet id
    }

    public let type: TypeEnum
    // 存储初始化状态额外信息
    public let info: String

    public init(type: TypeEnum, info: String = "") {
        self.type = type
        self.info = info
    }

}

public protocol ChatViewControllerService: AnyObject {
    func backDismissAndCloseSceneItemTapped()
    func messagesBeenRendered()
}
public extension ChatViewControllerService {
    func backDismissAndCloseSceneItemTapped() {}
    func messagesBeenRendered() {}
}

@frozen
public enum ReadStatusType: String, Codable {
    case message
    case urgent
}

public struct BanningSettingBody: CodableBody {
    private static let prefix = "//client/chat/setting/banning"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(BanningSettingBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

public struct MailPermissionSettingBody: CodableBody {
    private static let prefix = "//client/chat/setting/mailPermission"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(MailPermissionSettingBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

public struct TransferGroupOwnerBody: Body {
    private static let prefix = "//client/chat/chatter/trancsfer"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(TransferGroupOwnerBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let isThread: Bool
    public let mode: TransferGroupOwnerMode
    public var lifeCycleCallback: ((TransferGroupOwnerLifeCycle) -> Void)?

    public init(chatId: String,
                mode: TransferGroupOwnerMode,
                isThread: Bool) {
        self.chatId = chatId
        self.mode = mode
        self.isThread = isThread
    }
}

public enum TransferGroupOwnerMode {
    case assign
    case leaveAndAssign
}

public enum TransferGroupOwnerLifeCycle {
    case before
    case success
    // error, newOwnerId
    case failure(Error, String)
}

public struct GroupChatterDetailBody: Body {
    private static let prefix = "//client/chat/chatter/detail"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupChatterDetailBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }
    public let isShowMulti: Bool
    public let isAccessToAddMember: Bool
    public let isAbleToSearch: Bool
    public let useLeanCell: Bool

    public let chatId: String

    public init(chatId: String,
                isShowMulti: Bool,
                isAccessToAddMember: Bool = false,
                isAbleToSearch: Bool = true,
                useLeanCell: Bool = false) {
        self.chatId = chatId
        self.isShowMulti = isShowMulti
        self.isAccessToAddMember = isAccessToAddMember
        self.isAbleToSearch = isAbleToSearch
        self.useLeanCell = useLeanCell
    }
}

public struct ReactionDetailBody: CodableBody {
    private static let prefix = "//client/chat/reaction/detail"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:messageId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ReactionDetailBody.prefix)/\(messageId)") ?? .init(fileURLWithPath: "")
    }

    public let messageId: String
    public let type: String

    public init(messageId: String, type: String) {
        self.messageId = messageId
        self.type = type
    }
}

public struct CustomServiceChatBody: CodablePlainBody {
    public static let pattern = "//client/chat/help"

    public var plainMessage: String = ""

    public init() {}
}

public struct OncallChatBody: CodablePlainBody {
    public static let pattern = "//client/helpdesk"

    public let id: String
    public let reportLocation: Bool
    public let extra: String
    public let faqId: String?

    public init(oncallId: String, reportLocation: Bool = false, extra: String = "", faqId: String? = nil) {
        self.id = oncallId
        self.reportLocation = reportLocation
        self.extra = extra
        self.faqId = faqId
    }
}

//使用chatterId跳转会话页面
public struct ChatControllerByChatterIdBody: CodablePlainBody, HasLocateMessageInfo {
    public static let pattern = "//client/chat/by/chatter"

    public var url: URL {
        if let position = position {
            return URL(string: "\(ChatControllerByChatterIdBody.pattern)#\(position)") ?? .init(fileURLWithPath: "")
        }
        return URL(string: ChatControllerByChatterIdBody.pattern) ?? .init(fileURLWithPath: "")
    }

    public let chatterId: String
    public let position: Int32?
    public let messageId: String?
    public var keyboardStartupState: KeyboardStartupState
    public var fromWhere: ChatFromWhere = .ignored
    public var showNormalBack: Bool = false
    public var isCrypto: Bool = false
    public let isPrivateMode: Bool
    public let createChatSource: CreateChatSource?
    //是否需要路由层做兜底报错，如果上层自己有报错处理或者不需要兜底提示，可以设置false
    public let needShowErrorAlert: Bool

    public init(
        chatterId: String,
        position: Int32? = nil,
        messageId: String? = nil,
        fromWhere: ChatFromWhere = .ignored,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState.default(),
        showNormalBack: Bool = false,
        isCrypto: Bool,
        createChatSource: CreateChatSource? = nil
    ) {
        self.init(chatterId: chatterId,
                  position: position,
                  messageId: messageId,
                  fromWhere: fromWhere,
                  keyboardStartupState: keyboardStartupState,
                  showNormalBack: showNormalBack,
                  isCrypto: isCrypto,
                  isPrivateMode: false,
                  needShowErrorAlert: true,
                  createChatSource: createChatSource)
    }

    public init(
        chatterId: String,
        position: Int32? = nil,
        messageId: String? = nil,
        fromWhere: ChatFromWhere = .ignored,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState.default(),
        showNormalBack: Bool = false,
        isCrypto: Bool,
        isPrivateMode: Bool,
        needShowErrorAlert: Bool,
        createChatSource: CreateChatSource? = nil
    ) {
        self.chatterId = chatterId
        self.position = position
        self.fromWhere = fromWhere
        self.keyboardStartupState = keyboardStartupState
        self.showNormalBack = showNormalBack
        self.isCrypto = isCrypto
        self.isPrivateMode = isPrivateMode
        self.messageId = messageId
        self.createChatSource = createChatSource
        self.needShowErrorAlert = needShowErrorAlert
    }
}

public protocol HasLocateMessageInfo {
    var messageId: String? { get }
}

//使用chatId跳转会话页面
public struct ChatControllerByIdBody: CodableBody, HasLocateMessageInfo {
    private static let prefix = "//client/chat"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId(\\d+)", type: .path)
    }

    public var _url: URL {
        if let position = position {
            return URL(string: "\(ChatControllerByIdBody.prefix)/\(chatId)#\(position)") ?? .init(fileURLWithPath: "")
        }
        return URL(string: "\(ChatControllerByIdBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let position: Int32?
    public let messageId: String?
    public var fromWhere: ChatFromWhere
    public var keyboardStartupState: KeyboardStartupState
    public var showNormalBack: Bool
    public var controllerService: ChatViewControllerService?

    private enum CodingKeys: String, CodingKey {
        case chatId
        case position
        case messageId
        case fromWhere
        case keyboardStartupState
        case showNormalBack
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(position, forKey: .position)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(fromWhere, forKey: .fromWhere)
        try container.encode(keyboardStartupState, forKey: .keyboardStartupState)
        try container.encode(showNormalBack, forKey: .showNormalBack)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.chatId = try container.decode(String.self, forKey: .chatId)
        self.position = try container.decodeIfPresent(Int32.self, forKey: .position)
        self.messageId = try container.decodeIfPresent(String.self, forKey: .messageId)
        self.fromWhere = try container.decode(ChatFromWhere.self, forKey: .fromWhere)
        self.keyboardStartupState = try container.decode(KeyboardStartupState.self, forKey: .keyboardStartupState)
        self.showNormalBack = try container.decode(Bool.self, forKey: .showNormalBack)
    }

    public init(
        chatId: String,
        position: Int32? = nil,
        messageId: String? = nil,
        fromWhere: ChatFromWhere = .ignored,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState.default(),
        showNormalBack: Bool = false
    ) {
        self.chatId = chatId
        self.position = position
        self.fromWhere = fromWhere
        self.showNormalBack = showNormalBack
        self.messageId = messageId
        self.keyboardStartupState = keyboardStartupState
    }
}

public enum ChatSyncStrategy: Int, Codable {
    case `default`, forceRemote
}

public enum ChatMessagePositionStrategy: Codable {
    case position(Int32), toLatestPositon
}

public struct ChatAddTabBody: PlainBody {
    public static let pattern = "//client/chat/addTab"
    public let chat: Chat
    public let completion: (RustPB.Im_V1_ChatTab) -> Void

    public init(chat: Chat, completion: @escaping (RustPB.Im_V1_ChatTab) -> Void) {
        self.chat = chat
        self.completion = completion
    }
}

public struct ChatAddPinBody: PlainBody {
    public static let pattern = "//client/chat/addPin"
    public let chat: Chat
    public let completion: (() -> Void)?

    public init(chat: Chat, completion: (() -> Void)?) {
        self.chat = chat
        self.completion = completion
    }
}

public struct ChatPinCardListBody: PlainBody {
    public static let pattern = "//client/chat/pinCardList"
    public let chat: Chat

    public init(chat: Chat) {
        self.chat = chat
    }
}

/// 会话内 Tabs 数据源
public protocol ChatTabsDataSourceService {
    var tabs: [RustPB.Im_V1_ChatTab] { get }
}

/// 群 Tab 引导服务
public protocol ChatTabsGuideService {
    /// chatId 可以出发引导的群 id
    func triggerGuide(_ chatId: String)
    var currentShowGuideChatIds: Set<String> { get }
}

/// 文档服务
public protocol ChatDocsService {
    func preloadDocs(_ url: String, from source: String)
}

/// 小程序一方容器服务
public protocol ChatWAContainerService {
    func  preloadWebAppIfNeed(appId: String)
}

//使用chatId及chatType、isCrypto等信息跳转会话页面（可支持进入会话后异步获取chat）
public struct ChatControllerByBasicInfoBody: Body, HasLocateMessageInfo {
    private static let prefix = "//client/chat/byIdAndInfo"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId(\\d+)/:aiChatModeId(\\d+)", type: .path)
    }

    public var _url: URL {
        var urlString = "\(ChatControllerByBasicInfoBody.prefix)/\(chatId)"
        if let myAIChatModeConfig = self.myAIChatModeConfig, myAIChatModeConfig.aiChatModeId > 0 {
            urlString += "/\(myAIChatModeConfig.aiChatModeId)"
        } else {
            urlString += "/0"
        }
        if let positionStrategy = self.positionStrategy, case .position(let position) = positionStrategy {
            urlString += "#\(position)"
        }
        return URL(string: urlString) ?? .init(fileURLWithPath: "")
    }
    public let chatId: String
    // 如果预期是跳转到最新的一条消息上，最好将chatSyncStrategy设为forceRemote，否则会基于localChat来跳转到本地的最新消息上
    public let positionStrategy: ChatMessagePositionStrategy?
    public let chatSyncStrategy: ChatSyncStrategy
    public let messageId: String?
    public var fromWhere: ChatFromWhere
    public var keyboardStartupState: KeyboardStartupState
    public var showNormalBack: Bool
    public let isCrypto: Bool
    /// 是不是和MyAI的主分会场
    public let isMyAI: Bool
    /// 如果是和MyAI的分会场，则传递一些业务方信息
    public let myAIChatModeConfig: MyAIChatModeConfig?
    public let chatMode: Chat.ChatMode
    public let extraInfo: [String: Any]

    public init(
        chatId: String,
        positionStrategy: ChatMessagePositionStrategy? = nil,
        chatSyncStrategy: ChatSyncStrategy = .default,
        messageId: String? = nil,
        fromWhere: ChatFromWhere = .ignored,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState.default(),
        showNormalBack: Bool = false,
        isCrypto: Bool,
        isMyAI: Bool,
        myAIChatModeConfig: MyAIChatModeConfig? = nil,
        chatMode: Chat.ChatMode,
        extraInfo: [String: Any] = [:]
    ) {
        self.chatId = chatId
        self.positionStrategy = positionStrategy
        self.chatSyncStrategy = chatSyncStrategy
        self.fromWhere = fromWhere
        self.showNormalBack = showNormalBack
        self.messageId = messageId
        self.keyboardStartupState = keyboardStartupState
        self.isCrypto = isCrypto
        self.isMyAI = isMyAI
        self.myAIChatModeConfig = myAIChatModeConfig
        self.chatMode = chatMode
        self.extraInfo = extraInfo
    }
}

public struct CreateGroupToChatInfo {
    public static let key = "createGroupToChatInfo"
    public enum CreateGroupWay: String {
        case new_group //首页加号新创建群
        case single_chat_to_group //单聊建群
        case create_external_group //内部群拉人创建出新的外部群
        case unKnown
    }
    public let way: CreateGroupWay
    public let syncMessage: Bool
    public let messageCount: Int
    public let memberCount: Int
    public let cost: Int64
    public init(way: CreateGroupWay, syncMessage: Bool, messageCount: Int, memberCount: Int, cost: Int64) {
        self.way = way
        self.syncMessage = syncMessage
        self.messageCount = messageCount
        self.memberCount = memberCount
        self.cost = cost
    }
}

//使用chat模型跳转会话
public struct ChatControllerByChatBody: Body, HasLocateMessageInfo {
    private static let prefix = "//client/chat/by/chat"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId(\\d+)", type: .path)
    }

    public var _url: URL {
        if let position = position {
            return URL(string: "\(ChatControllerByChatBody.prefix)/\(chat.id)#\(position)") ?? .init(fileURLWithPath: "")
        }
        return URL(string: "\(ChatControllerByChatBody.prefix)/\(chat.id)") ?? .init(fileURLWithPath: "")
    }

    public let chat: Chat
    public let position: Int32?
    public let messageId: String?
    public var fromWhere: ChatFromWhere = .ignored
    public var keyboardStartupState: KeyboardStartupState
    public var showNormalBack: Bool = false
    public let extraInfo: [String: Any] //携带一些额外信息，目前建群打点会使用，携带建群耗时及相关信息
    public var controllerService: ChatViewControllerService?
    public var specificSource: SpecificSourceFromWhere? //细化fromWhere的二级来源

    public init(
        chat: Chat,
        position: Int32? = nil,
        messageId: String? = nil,
        fromWhere: ChatFromWhere = .ignored,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState.default(),
        showNormalBack: Bool = false,
        extraInfo: [String: Any] = [:],
        specificSource: SpecificSourceFromWhere? = nil
    ) {
        self.chat = chat
        self.position = position
        self.fromWhere = fromWhere
        self.showNormalBack = showNormalBack
        self.messageId = messageId
        self.keyboardStartupState = keyboardStartupState
        self.extraInfo = extraInfo
        self.specificSource = specificSource
    }
}

// 预览群
public struct PreviewChatBody: PlainBody {
    public static let pattern = "//client/chat/preview"

    public var messageId: String
    public var content: ShareGroupChatContent
    public var joinStatusCallback: (JoinGroupApplyBody.Status) -> Void
    public var joinStatus: JoinGroupApplyBody.Status

    public init(
        messageId: String,
        content: ShareGroupChatContent,
        joinStatus: JoinGroupApplyBody.Status = .unTap,
        joinStatusCallback: @escaping (JoinGroupApplyBody.Status) -> Void
    ) {
        self.messageId = messageId
        self.content = content
        self.joinStatus = joinStatus
        self.joinStatusCallback = joinStatusCallback
    }
}

// 预览群卡片
public struct PreviewChatCardWithChatBody: PlainBody {
    public static let pattern = "//client/chat/previewGroupCard"
    public let isFromSearch: Bool
    public let chat: Chat

    public init(chat: Chat,
                isFromSearch: Bool) {
        self.chat = chat
        self.isFromSearch = isFromSearch
    }
}

public struct ChatAnnouncementBody: CodablePlainBody {
    public static let pattern = "//client/chat/announcement"

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

/// 老版本群公告页面
public struct ChatOldAnnouncementBody: CodablePlainBody {
    public static let pattern = "//client/chat/oldAnnouncement"

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

/// 跳转到代码详情页面
public struct CodeDetailBody: PlainBody {
    public static let pattern = "//client/chat/codeDetail"

    public let property: Basic_V1_RichTextElement.CodeBlockV2Property

    public init(property: Basic_V1_RichTextElement.CodeBlockV2Property) {
        self.property = property
    }
}

public enum MessagePickerCancelReason {
    case cancelBtnClick
    case viewWillDisappear
}

// MARK: 获取MessagePickerController
public struct MessagePickerBody: PlainBody {
    public static var pattern: String = "//client/chat/message/picker"
    public let chatId: String
    public var cancel: ((MessagePickerCancelReason) -> Void)?
    public var finish: (([Message], [String: RustPB.Im_V1_CreateChatRequest.DocPermissions]) -> Void)?
    public var needDocAuth: Bool
    public init(chatId: String,
                needDocAuth: Bool = true) {
        self.chatId = chatId
        self.needDocAuth = needDocAuth
    }
}

public struct CreateGroupBody: PlainBody {
    public static var pattern: String = "//client/chat/create"

    public let createGroupBlock: ((_ chat: Chat?,
                                   _: UIViewController,
                                   _ cost: Int64,
                                   _ notFriendContacts: [AddExternalContactModel],
                                   _ pageLinkResult: Im_V1_CreateChatResponse.ChatPageLinkResult?) -> Void)?
    /// 显示'选择已有群聊'
    public let isShowGroup: Bool

    /// 是否能创建密聊，转发->创群不能创建密聊
    public let canCreateSecretChat: Bool
    /// 是否能创建话题群
    public var canCreateThread: Bool
    /// 是否能创建密盾聊
    public var canCreatePrivateChat: Bool
    /// 是否能查看和搜索外部联系人
    public var needSearchOuterTenant: Bool
    public let linkPageURL: String?
    /// 从什么渠道建群
    public let from: CreateGroupFromWhere
    /// 可传入确认按钮自定义文案(历史原因，广场场景，该文案要写死为“下一步”，逻辑要尽快下掉 @liluobin)
    public var createConfirmButtonTitle: String?
    /// 可传入title
    public var title: String?
    public init(createGroupBlock: ((_ chat: Chat?,
                                    _: UIViewController,
                                    _ cost: Int64,
                                    _ notFriendContacts: [AddExternalContactModel],
                                    _ pageLinkResult: Im_V1_CreateChatResponse.ChatPageLinkResult?) -> Void)?,
                isShowGroup: Bool = true,
                canCreateSecretChat: Bool = true,
                canCreateThread: Bool = true,
                canCreatePrivateChat: Bool = true,
                needSearchOuterTenant: Bool = true,
                linkPageURL: String? = nil,
                from: CreateGroupFromWhere = .unknown) {
        self.createGroupBlock = createGroupBlock
        self.isShowGroup = isShowGroup
        self.canCreateSecretChat = canCreateSecretChat
        self.canCreateThread = canCreateThread
        self.canCreatePrivateChat = canCreatePrivateChat
        self.needSearchOuterTenant = needSearchOuterTenant
        self.linkPageURL = linkPageURL
        self.from = from
    }

    public init(createGroupBlock: ((_ chat: Chat?,
                                    _: UIViewController,
                                    _ cost: Int64,
                                    _ notFriendContacts: [AddExternalContactModel],
                                    _ pageLinkResult: Im_V1_CreateChatResponse.ChatPageLinkResult?) -> Void)?,
                isShowGroup: Bool = true,
                canCreateSecretChat: Bool = true,
                canCreateThread: Bool = true,
                canCreatePrivateChat: Bool = true,
                needSearchOuterTenant: Bool = true,
                linkPageURL: String? = nil,
                from: CreateGroupFromWhere = .unknown,
                createConfirmButtonTitle: String? = nil,
                title: String? = nil) {
        self.init(createGroupBlock: createGroupBlock,
                  isShowGroup: isShowGroup,
                  canCreateSecretChat: canCreateSecretChat,
                  canCreateThread: canCreateThread,
                  canCreatePrivateChat: canCreatePrivateChat,
                  needSearchOuterTenant: needSearchOuterTenant,
                  linkPageURL: linkPageURL,
                  from: from)
        self.createConfirmButtonTitle = createConfirmButtonTitle
        self.title = title
    }
}

public struct MergeForwardDetailBody: Body {

    public enum ChatInfo {
        case chat(Chat)
        case chatId(String)
    }

    private static let prefix = "//client/chat/mergeForwardDetail"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:messageId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(MergeForwardDetailBody.prefix)/\(message.id)") ?? .init(fileURLWithPath: "")
    }

    public let message: Message
    public let chatInfo: ChatInfo
    public var chatId: String {
        switch chatInfo {
        case .chat(let chat): return chat.id
        case .chatId(let chatId): return chatId
        }
    }
    public var downloadFileScene: RustPB.Media_V1_DownloadFileScene?

    public init(message: Message,
                chatId: String,
                downloadFileScene: RustPB.Media_V1_DownloadFileScene?) {
        self.message = message
        self.chatInfo = .chatId(chatId)
        self.downloadFileScene = downloadFileScene
    }

    public init(message: Message,
                chat: Chat,
                downloadFileScene: RustPB.Media_V1_DownloadFileScene?) {
        self.message = message
        self.chatInfo = .chat(chat)
        self.downloadFileScene = downloadFileScene
    }

}

public struct MessageForwardContentPreviewBody: Body {

    public enum ChatInfo {
        case chat(Chat)
        case chatId(String)
    }

    private static let prefix = "//client/chat/messageForwardContentPreview"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:messageId", type: .path)
    }

    public var _url: URL {
        var chatId = ""
        switch chatInfo {
        case .chat(let chat):
            chatId = chat.id
        case .chatId(let chatIdentifier):
            chatId = chatIdentifier
        }
        return URL(string: "\(MessageForwardContentPreviewBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let messages: [Message]
    public let chatInfo: ChatInfo
    public var chatId: String {
        switch chatInfo {
        case .chat(let chat): return chat.id
        case .chatId(let chatId): return chatId
        }
    }
    public var title: String

    public init(messages: [Message],
                chatId: String,
                title: String) {
        self.messages = messages
        self.chatInfo = .chatId(chatId)
        self.title = title
    }

    public init(messages: [Message],
                chat: Chat,
                title: String) {
        self.messages = messages
        self.chatInfo = .chat(chat)
        self.title = title
    }
}

public struct ForwardChatMessagePreviewBody: PlainBody {

    public static var pattern = "//client/chat/forwardChatMessagePreview"

    public var chatId: String
    public var userId: String
    public var title: String
    public init(chatId: String,
                userId: String = "",
                title: String) {
        self.chatId = chatId
        self.userId = userId
        self.title = title
    }
}

public struct FavoriteMergeForwardDetailBody: PlainBody {
    public static var pattern: String = "//client/chat/favoriteMergeForwardDetail"

    public let message: Message
    public let chatId: String
    public let favoriteId: String
    public init(message: Message,
                chatId: String,
                favoriteId: String) {
        self.message = message
        self.chatId = chatId
        self.favoriteId = favoriteId
    }
}

public struct ReadStatusBody: CodablePlainBody {
    public static var pattern: String = "//client/chat/readStatus"

    public let type: ReadStatusType
    public let chatID: String
    public let messageID: String

    public init(chatID: String, messageID: String, type: ReadStatusType) {
        self.chatID = chatID
        self.messageID = messageID
        self.type = type
    }
}

public struct ThreadInfoBody: PlainBody {
    public static var pattern: String = "//client/thread/info"

    public let chat: Chat
    public let hideFeedSetting: Bool
    public let hasModifyAccess: Bool
    public let action: EnterChatSettingAction

    public init(
        chat: Chat,
        hasModifyAccess: Bool = true,
        hideFeedSetting: Bool = false,
        action: EnterChatSettingAction
    ) {
        self.chat = chat
        self.hasModifyAccess = hasModifyAccess
        self.hideFeedSetting = hideFeedSetting
        self.action = action
    }
}

/// 定制群头像
public struct CustomizeGroupAvatarBody: PlainBody {
    public static var pattern: String = "//client/chat/modify/avatar"

    public let chat: Chat
    public let avatarDrawStyle: AvatarDrawStyle

    public init(chat: Chat,
                avatarDrawStyle: AvatarDrawStyle = .transparent) {
        self.chat = chat
        self.avatarDrawStyle = avatarDrawStyle
    }
}

public enum AvatarDrawStyle {
    // 实心渲染
    case soild
    // 背景透明
    case transparent
}

public struct ChatInfoBody: PlainBody {
    public static var pattern: String = "//client/chat/info/main"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(pattern)/:chatId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ChatInfoBody.pattern)/\(chat.id)") ?? .init(fileURLWithPath: "")
    }

    public let chat: Chat
    public var type: P2PChatSettingBody.ChatSettingType
    public let action: EnterChatSettingAction

    public init(chat: Chat,
                action: EnterChatSettingAction,
                type: P2PChatSettingBody.ChatSettingType) {
        self.chat = chat
        self.type = type
        self.action = action
    }
}

// 群管理员body
public struct GroupAdminBody: PlainBody {
    public static var pattern = "//client/chat/admin"

    public static var patternConfig: PatternConfig {
    return PatternConfig(pattern: "\(pattern)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupAdminBody.pattern)/\(chat.id)") ?? .init(fileURLWithPath: "")
    }
    public let chat: Chat
    // 默认选中，而不能取消选择的人
    public var defaultUnableSelectedIds: [String]
    // 是否展示多选
    public let isShowMulti: Bool

    public init(chat: Chat,
                defaultUnableSelectedIds: [String] = [],
                isShowMulti: Bool = false) {
        self.chat = chat
        self.defaultUnableSelectedIds = defaultUnableSelectedIds
        self.isShowMulti = isShowMulti
    }
}

public struct RichTextContent {
    public var title: String
    public var richText: RustPB.Basic_V1_RichText
    public var lingoInfo: RustPB.Basic_V1_LingoOption?
    public var processProvider: [RustPB.Basic_V1_RichTextElement.Tag: RichTextOptionsType<NSAttributedString>] = [:]

    public init(title: String,
                richText: RustPB.Basic_V1_RichText,
                lingoInfo: RustPB.Basic_V1_LingoOption? = nil,
                processProvider: [RustPB.Basic_V1_RichTextElement.Tag: RichTextOptionsType<NSAttributedString>] = [:]) {
        self.title = title
        self.richText = richText
        self.lingoInfo = lingoInfo
        self.processProvider = processProvider
    }
}

public struct ComposePostItem {
    /// 为空 表示没有第一响应者
    public let firstResponderInfo: (NSRange, Bool)?
    // font bar的状态
    public let fontBarStatus: FontToolBarStatusItem

    public init(fontBarStatus: FontToolBarStatusItem,
                firstResponderInfo: (NSRange, Bool)?) {
        self.fontBarStatus = fontBarStatus
        self.firstResponderInfo = firstResponderInfo
    }
}

public struct ShowComposePostViewCallBacks {
    public var completeCallback: ((RichTextContent, Int64?) -> Void)?
    public var cancelCallback: ((ComposePostItem?) -> Void)?
    public var applyTranslationCallback: ((_ title: String?, _ content: RustPB.Basic_V1_RichText?) -> Void)?
    public var recallTranslationCallback: (() -> Void)?
    public var multiEditFinishCallback: (() -> Void)?
    public var patchScheduleMsgFinishCallback: (() -> Void)?
    public var selectMyAICallBack: (() -> Void)?
    public var setScheduleTipStatus: ((ScheduleMessageStatus) -> Void)?
    public var getScheduleMsgSendTime: (() -> Int64?)?
    public var getSendScheduleMsgIds: (() -> ([String], [String]))?

    public init(completeCallback: ((RichTextContent, Int64?) -> Void)? = nil,
                cancelCallback: ((ComposePostItem?) -> Void)? = nil,
                applyTranslationCallback: ((_ title: String?, _ content: RustPB.Basic_V1_RichText?) -> Void)? = nil,
                recallTranslationCallback: (() -> Void)? = nil,
                multiEditFinishCallback: (() -> Void)? = nil,
                patchScheduleMsgFinishCallback: (() -> Void)? = nil,
                selectMyAICallBack: (() -> Void)? = nil,
                setScheduleTipStatus: ((ScheduleMessageStatus) -> Void)? = nil,
                getScheduleMsgSendTime: (() -> Int64?)? = nil,
                getSendScheduleMsgIds: (() -> ([String], [String]))? = nil) {
        self.completeCallback = completeCallback
        self.cancelCallback = cancelCallback
        self.applyTranslationCallback = applyTranslationCallback
        self.recallTranslationCallback = recallTranslationCallback
        self.multiEditFinishCallback = multiEditFinishCallback
        self.selectMyAICallBack = selectMyAICallBack
        self.setScheduleTipStatus = setScheduleTipStatus
        self.getScheduleMsgSendTime = getScheduleMsgSendTime
        self.getSendScheduleMsgIds = getSendScheduleMsgIds
        self.patchScheduleMsgFinishCallback = patchScheduleMsgFinishCallback
    }
}

public struct ComposePostBody: PlainBody {
    public static var pattern: String = "//client/chat/post"

    public let chat: Chat
    public let dataService: KeyboardShareDataService
    public var defaultContent: String?
    public var reeditContent: RichTextContent?
    public var autoFillTitle: Bool = true
    public var callbacks: ShowComposePostViewCallBacks?
    public var placeholder: NSAttributedString?
    public var sendVideoEnable: Bool = false
    public var postItem: ComposePostItem?
    public var attachmentServer: PostAttachmentServer?
    public var userActualNameInfoDic: [String: String]?
    /// 业务上是否支持边写边译
    public var supportRealTimeTranslate: Bool = false
    /// 是否是msgThread的键盘
    public var isFromMsgThread: Bool = false
    /// 复制粘贴的安全token
    public let pasteBoardToken: String
    /// 翻译服务
    public var translateService: RealTimeTranslateService?
    public let chatFromWhere: ChatFromWhere
    public init(chat: Chat,
                pasteBoardToken: String,
                dataService: KeyboardShareDataService,
                chatFromWhere: ChatFromWhere = .ignored) {
        self.chat = chat
        self.pasteBoardToken = pasteBoardToken
        self.dataService = dataService
        self.chatFromWhere = chatFromWhere
    }
}

public struct ChatTranslationDetailBody: PlainBody {
    public static var pattern: String = "//client/chat/translationDetail"

    public let chat: Chat?
    public let title: String?
    public let content: Basic_V1_RichText?
    public let attributes: [NSAttributedString.Key: Any]
    public let imageAttachments: [String: (CustomTextAttachment, ImageTransformInfo, NSRange)]
    public let videoAttachments: [String: (CustomTextAttachment, VideoTransformInfo, NSRange)]
    public var useTranslationCallBack: (() -> Void)?
    public init(chat: Chat?,
                title: String?,
                content: Basic_V1_RichText?,
                attributes: [NSAttributedString.Key: Any],
                imageAttachments: [String: (CustomTextAttachment, ImageTransformInfo, NSRange)],
                videoAttachments: [String: (CustomTextAttachment, VideoTransformInfo, NSRange)],
                useTranslationCallBack: (() -> Void)?) {
        self.chat = chat
        self.title = title
        self.content = content
        self.attributes = attributes
        self.imageAttachments = imageAttachments
        self.videoAttachments = videoAttachments
        self.useTranslationCallBack = useTranslationCallBack
    }
}

public struct LanguagePickerBody: PlainBody {
    public static var pattern: String = "//client/chat/languagePicker"

    public let chatId: String
    public let currentTargetLanguage: String
    public var closeRealTimeTranslateCallBack: ((Chat) -> Void)?
    public var targetLanguageChangeCallBack: ((Chat) -> Void)?
    public let chatFromWhere: ChatFromWhere
    public init(chatId: String,
                currentTargetLanguage: String,
                chatFromWhere: ChatFromWhere = .ignored) {
        self.chatId = chatId
        self.currentTargetLanguage = currentTargetLanguage
        self.chatFromWhere = chatFromWhere
    }
}

public struct AtPickerBody: PlainBody {
    public struct SelectedItem {
        public var id: String
        public var name: String
        public var isOuter: Bool
        ///用户的真是姓名 发送消息时候使用
        ///安全需求，消息中不能流转备注名
        public var actualName: String
        public init(id: String, name: String, actualName: String, isOuter: Bool) {
            self.id = id
            self.name = name
            self.actualName = actualName
            self.isOuter = isOuter
        }
    }

    public typealias AtPickerSureCallBack = (_ selectItems: [SelectedItem]) -> Void

    public static var pattern: String = "//client/chat/at"

    public let chatID: String
    public var allowAtAll: Bool = true
    public var allowMyAI: Bool = false
    public var allowSideIndex: Bool = true
    public var completion: AtPickerSureCallBack?
    public var cancel: (() -> Void)?

    public init(chatID: String) {
        self.chatID = chatID
    }
}

public struct GroupChatterSelectBody: Body {
    private static let prefix = "//client/chat/chatter/select"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupChatterSelectBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    // 默认选中的列表
    public var defaultSelectedChatterIds: [String] = []
    // 默认选中，无法取消选中的列表
    public var defaultUnableCancelSelectedIds: [String] = []
    public var title: String?
    public var onSelected: ((_ selectedChattedIds: [Chatter]) -> Void)?
    public let showSelectedView: Bool
    public let chatId: String
    // $0: 最大选择人数, $1: 选择人数超过限制的文案
    public var maxSelectModel: (Int, String)?
    public var allowSelectNone: Bool
    public var isOwnerCanSelect: Bool

    public init(chatId: String,
                allowSelectNone: Bool,
                showSelectedView: Bool = true,
                isOwnerCanSelect: Bool = false) {
        self.chatId = chatId
        self.allowSelectNone = allowSelectNone
        self.showSelectedView = showSelectedView
        self.isOwnerCanSelect = isOwnerCanSelect
    }
}

// 添加管理员body
public struct GroupAddAdminBody: Body {
    private static let prefix = "//client/chat/chatter/addAdmin"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupAddAdminBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    // 默认选中，无法取消的列表
    public var defaultUnableCancelSelectedIds: [String]
    public let chatCount: Int32
    public let chatId: String
    public weak var controller: UIViewController?

    public init(chatId: String,
                chatCount: Int32,
                defaultUnableCancelSelectedIds: [String] = [],
                controller: UIViewController) {
        self.chatId = chatId
        self.chatCount = chatCount
        self.defaultUnableCancelSelectedIds = defaultUnableCancelSelectedIds
        self.controller = controller
    }
}

public struct ModifyGroupNameBody: Body {
    private static let prefix = "//client/chat/info/group/name"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ModifyGroupNameBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let title: String?
    public init(chatId: String, title: String? = nil) {
        self.chatId = chatId
        self.title = title
    }
}

public struct ModifyNicknameBody: Body {
    private static let prefix = "//client/chat/info/nickname"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ModifyNicknameBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let oldNickname: String
    public let title: String?
    public let saveNickName: (String) -> Void
    public let chat: Chat

    public init(chat: Chat, chatId: String, oldNickname: String, title: String? = nil, saveNickName: @escaping (String) -> Void) {
        self.chat = chat
        self.chatId = chatId
        self.oldNickname = oldNickname
        self.title = title
        self.saveNickName = saveNickName
    }
}

public struct ModifyGroupDescriptionBody: Body {
    private static let prefix = "//client/chat/info/group/description"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ModifyGroupDescriptionBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let title: String?

    public init(chatId: String, title: String? = nil) {
        self.chatId = chatId
        self.title = title
    }
}

/// 点击系统消息群名进群
public struct GroupCardSystemMessageJoinBody: CodableBody {
    private static let prefix = "//client/chat/group/join/systemmessage"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupCardSystemMessageJoinBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

/// group inof of recommend group
public struct RecommendGroupJoinBody: PlainBody {
    public static var pattern: String = "//client/chat/recommend/group/info"

    public let chatID: String

    public init(chatID: String) {
        self.chatID = chatID
    }
}

public struct GroupQRCodeBody: Body {
    private static let prefix = "//client/chat/info/group/qrcode"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupQRCodeBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

/// 通过团队群进入群卡片
public struct GroupCardTeamJoinBody: CodableBody {
    private static let prefix = "//client/chat/group/join/teamchannel"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupCardTeamJoinBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let teamId: Int64

    public init(chatId: String,
                teamId: Int64) {
        self.chatId = chatId
        self.teamId = teamId
    }
}

public struct GroupInfoBody: Body {
    private static let prefix = "//client/chat/info/group/info"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupInfoBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

public struct GroupSettingBody: Body {
    private static let prefix = "//client/chat/info/group/setting"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupSettingBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let scrollToBottom: Bool
    public let openSettingCellType: ChatSettingCellType?
    public let chatId: String

    public init(chatId: String, scrollToBottom: Bool = false, openSettingCellType: ChatSettingCellType? = nil) {
        self.chatId = chatId
        self.scrollToBottom = scrollToBottom
        self.openSettingCellType = openSettingCellType
    }
}

public struct P2PChatSettingBody: Body {
    public enum ChatSettingType: Int {
        case openappChat
        case ignore
    }

    private static let prefix = "//client/chat/p2p/setting"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(P2PChatSettingBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let type: ChatSettingType

    public init(chatId: String, type: ChatSettingType = .ignore) {
        self.chatId = chatId
        self.type = type
    }
}

public struct PinListBody: Body {
    private static let prefix = "//client/chat/pin/list"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(PinListBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let isThread: Bool

    public init(chatId: String, isThread: Bool = false) {
        self.isThread = isThread
        self.chatId = chatId
    }
}

public enum PinAlertFrom: Int {
    case inChat = 1
    case inChatPin = 2
}

public struct DeletePinAlertBody: Body {
    private static let prefix = "//client/chat/pin/delete_alert"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:messageId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(DeletePinAlertBody.prefix)/\(message.id)") ?? .init(fileURLWithPath: "")
    }

    public let chat: Chat
    // 用户点击的群分享卡片对应的chat模型
    public var shareChat: Chat?
    public let message: Message
    public let from: PinAlertFrom
    public weak var targetVC: UIViewController?
    public let chatFromWhere: ChatFromWhere
    public init(chat: Chat, message: Message, targetVC: UIViewController?, from: PinAlertFrom, chatFromWhere: ChatFromWhere = .ignored) {
        self.chat = chat
        self.message = message
        self.targetVC = targetVC
        self.from = from
        self.chatFromWhere = chatFromWhere
    }
}
public enum MessageDetailFromSource: String {
    case unknown = "none" // 未知位置上报none；
    case rootMsg = "root_msg" // 点击 根消息处「x条回复」展开详情页
    case postMsg = "post_msg" // 点击post消息进入详情页；
    case replyMsg = "reply_msg" // 点击「回复的消息」展开详情页；"

}

public struct MessageDetailBody: Body {

    private static let prefix = "//client/chat/messageDetail"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:messageId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(MessageDetailBody.prefix)/\(message.id)") ?? .init(fileURLWithPath: "")
    }

    public let chat: Chat
    public let message: Message
    public let source: MessageDetailFromSource
    public let chatFromWhere: ChatFromWhere

    public init(chat: Chat, message: Message, source: MessageDetailFromSource = .unknown, chatFromWhere: ChatFromWhere) {
        self.chat = chat
        self.message = message
        self.source = source
        self.chatFromWhere = chatFromWhere
    }
}

public struct FoldMessageDetailBody: Body {
    private static let prefix = "//client/chat/fold/message/detail"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:messageId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(FoldMessageDetailBody.prefix)/\(self.message.foldId)") ?? .init(fileURLWithPath: "")
    }

    public let chat: Chat
    public let message: Message
    public let richText: RustPB.Basic_V1_RichText
    public let atColor: AtColor

    public init(chat: Chat,
                message: Message,
                richText: RustPB.Basic_V1_RichText,
                atColor: AtColor = AtColor()) {
        self.chat = chat
        self.message = message
        self.richText = richText
        self.atColor = atColor
    }
}

public struct QuitGroupBody: PlainBody {
    public static var pattern: String = "//client/chat/info/quit"

    public let chatId: String
    public let isThread: Bool
    public var tips: String = ""

    public init(chatId: String, isThread: Bool) {
        self.chatId = chatId
        self.isThread = isThread
    }
}

// 群分享历史
public struct GroupShareHistoryBody: CodableBody {
    private static let prefix = "//client/chat/group/share/history"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupShareHistoryBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let title: String?
    public let isThreadGroup: Bool

    public init(chatId: String, title: String? = nil, isThreadGroup: Bool = false) {
        self.chatId = chatId
        self.title = title
        self.isThreadGroup = isThreadGroup
    }
}

// 进群申请
public struct ApprovalBody: CodableBody {
    private static let prefix = "//client/chat/group/approval"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ApprovalBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

// 配置群可被搜索
public struct GroupSearchAbleConfigBody: CodableBody {
    private static let prefix = "//client/chat/group/searchAble"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(GroupSearchAbleConfigBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

/// 当用户发起了三次手动翻译请求后需要弹出开启自动翻译引导
/// 出引导策略：AutoTranslateGuideInfo会存入UserDefaults中
/// 在手动点击翻译时open一次CheckAutoTranslateGuideBody
/// 把引导逻辑封装到CheckAutoTranslateGuideBody内部
public final class AutoTranslateGuideInfo: Decodable, Encodable {
    /// 开启自动翻译引导key，此外也作为AutoTranslateGuideInfo本地持久化的key
    public static let openAutoTranslateGuideKey = "all_auto_translation_setting"

    /// 手动翻译次数
    public var translateCount = 0

    enum CodingKeys: String, CodingKey {
        case translateCount = "translate_count"
    }

    public init() {}

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.translateCount, forKey: .translateCount)
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.translateCount = try values.decode(Int.self, forKey: .translateCount)
    }
}

/// 检查自动翻译引导
public struct CheckAutoTranslateGuideBody: PlainBody {
    public static var pattern: String = "//client/chat/guide/autotranslate"

    /// 是否是译文->原文
    public let messageToOrigin: Bool
    /// 当前会话自动翻译开关
    public let chatIsAutoTranslate: Bool
    /// 消息主语言
    public let messageLanguage: String

    public init(messageToOrigin: Bool,
                chatIsAutoTranslate: Bool,
                messageLanguage: String) {
        self.messageToOrigin = messageToOrigin
        self.chatIsAutoTranslate = chatIsAutoTranslate
        self.messageLanguage = messageLanguage
    }
}

public struct ChatTranslateSettingBody: Body {
    private static let prefix = "//client/chat/setting/translate"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(Self.prefix)/\(chat.id)") ?? .init(fileURLWithPath: "")
    }

    public let chat: Chat

    public var pushChat: Observable<Chat>

    public init(chat: Chat,
                pushChat: Observable<Chat>) {
        self.chat = chat
        self.pushChat = pushChat
    }
}

// 进群申请
public struct JoinGroupApplyBody: PlainBody {
    public enum Way {
        // 群分享：我通过群分享消息（messageId）的joinToken入群
        case viaShare(joinToken: String, messageId: String, isTimeExpired: Bool)
        // 邀请：
        // 1. 群加人：我（inviterId）邀请其他人（chatterIds）入群
        // 2. ThreadDetail里at群外的人，我第一次进对应的群时，需要验证
        // jumpChat：群加人不需要跳chat
        case viaInvitation(inviterId: String?, inviterIsAdminOrOwner: Bool, isFriendChatterIds: [String], chatIds: [String], departmentIds: [String], jumpChat: Bool)
        // 群二维码：我通过别人（inviterId）分享的群二维码入群
        case viaQrCode(inviterId: String, token: String)
        // 搜索：我通过搜索加入到搜索到的群中
        case viaSearch
        // 联系人模块 -> 组织架构 -> 部门群入口
        /// jumpChat：进入部门群需要从feed跳转
        case viaDepartmentStructure(jumpChat: Bool)

        /// @群外的人点击系统消息邀请被@的人入群
        case viaMentionInvitation(inviterId: String, chatterIDs: [String])

        /// share topic. 分享话题
        case viaShareTopic

        /// enter topic group without jump. useAddMembersToTopicGroup: use addTopicGroup interface. isDefaultFavorite: true subcribe topic group
        case viaTopicGroup(useAddMembersToTopicGroup: Bool, isDefaultFavorite: Bool)

        // ChatLink：我通过别人（inviterId）分享的群Link入群
        case viaLink(inviterId: String, token: String)
        // 通过[群在指定团队里可公开]渠道入群
        case viaTeamOpenChat(teamId: Int64)
        // 通过[群在指定团队里可私密可发现]渠道入群
        case viaTeamChat(teamId: Int64)
        // 通过会议日程页进群
        case viaCalendar(eventID: String)
        // 通过关联页面加群
        case viaLinkPageURL(url: String)
    }

    public enum Status {
        // 正常未点击状态
        case unTap
        // 已经在群内
        case hadJoined
        // 等待验证
        case waitAccept
        // 群已经解散
        case groupDisband
        // 分享过期
        case expired
        // 群人数已满
        case numberLimit
        // 分享被停用
        case ban
        // 跨租户内部群不支持外部加入
        case contactAdmin
        // 无权限
        case noPermission
        // 分享的人已经退出该群
        case sharerQuit
        //  非认证租户
        case nonCertifiedTenantRefuse
        // 兼容字段，通用失败
        case fail

        // 兼容老代码，目前看没有什么用
        case cancel    // 入群申请中点击取消
    }

    public static let pattern = "//client/chat/group/join/apply"

    public var chatId: String
    public var way: Way
    public var callback: ((Status) -> Void)?
    /// true: show loading HUD when fetch data. true时开启请求时的HUD显示。
    public var showLoadingHUD: Bool
    public let extraInfo: [AnyHashable: Any]?
    public init(
        chatId: String,
        way: Way,
        showLoadingHUD: Bool = true,
        callback: ((Status) -> Void)? = nil
    ) {
        self.init(chatId: chatId, way: way, showLoadingHUD: showLoadingHUD, extraInfo: nil, callback: callback)
    }

    public init(
        chatId: String,
        way: Way,
        showLoadingHUD: Bool = true,
        extraInfo: [AnyHashable: Any]?,
        callback: ((Status) -> Void)? = nil
    ) {
        self.showLoadingHUD = showLoadingHUD
        self.chatId = chatId
        self.way = way
        self.callback = callback
        self.extraInfo = extraInfo
    }
}

public enum AddMemberSource: String, Codable {
    case sectionAdd = "section_add_mobile"
    case listMore = "list_more_mobile"
}

// 添加群成员
public struct AddGroupMemberBody: CodableBody {
    private static let prefix = "//client/chat/setting/member/addnew"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(AddGroupMemberBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let source: AddMemberSource?

    public init(chatId: String, source: AddMemberSource? = nil) {
        self.chatId = chatId
        self.source = source
    }
}

/// call to enter group members join and leave history page
/// 群成员进退群历史页面
public struct AutomaticallyAddGroupBody: PlainBody {
    public static var pattern: String = "//client/chat/setting/member/automaticallyAddGroup"

    public let chatId: String
    public let rules: [ServerPB_Entities_ChatRefDynamicRule]

    public init(chatId: String, rules: [ServerPB_Entities_ChatRefDynamicRule]) {
        self.chatId = chatId
        self.rules = rules
    }
}

/// call to enter group members join and leave history page
/// 群成员进退群历史页面
public struct JoinAndLeaveBody: CodableBody {
    private static let prefix = "//client/chat/setting/member/joinandleave"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(JoinAndLeaveBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

/// 翻译效果
public struct TranslateEffectBody: PlainBody {
    public static let pattern = "//client/chat/translateEffect"

    public let chat: Chat
    public let message: Message

    public init(chat: Chat, message: Message) {
        self.chat = chat
        self.message = message
    }
}

/// 聊天背景
public struct ChatThemeBody: PlainBody {
    public enum Scene {
        case personal
        case group
    }
    public static let pattern = "//client/chat/chatTheme"

    public let chatId: String
    public let title: String
    public let scene: Scene

    public init(chatId: String,
                title: String,
                scene: Scene) {
        self.chatId = chatId
        self.title = title
        self.scene = scene
    }
}

public enum ChatBgImageStyle {
    case unknown
    case defalut
    case color(UIColor)
    case image(UIImage)
    case key(String, String)
}

/// 聊天背景预览
public struct ChatThemePreviewBody: PlainBody {
    public static let pattern = "//client/chat/chatThemePreview"

    public let title: String
    public let style: ChatBgImageStyle
    public let chatId: String
    public let theme: ServerPB_Entities_ChatTheme
    public let scope: Im_V2_ChatThemeType
    public let hasPersonalTheme: Bool
    // 重设个人背景
    public let isResetPernalTheme: Bool
    // 再次设置当前背景
    public let isResetCurrentTheme: Bool
    public var confirmHandler: (() -> Void)?
    public let cancelHandler: (() -> Void)?

    public init(style: ChatBgImageStyle,
                title: String,
                chatId: String,
                theme: ServerPB_Entities_ChatTheme,
                scope: Im_V2_ChatThemeType,
                hasPersonalTheme: Bool,
                isResetPernalTheme: Bool,
                isResetCurrentTheme: Bool,
                confirmHandler: (() -> Void)? = nil,
                cancelHandler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.chatId = chatId
        self.theme = theme
        self.scope = scope
        self.hasPersonalTheme = hasPersonalTheme
        self.isResetPernalTheme = isResetPernalTheme
        self.isResetCurrentTheme = isResetCurrentTheme
        self.confirmHandler = confirmHandler
        self.cancelHandler = cancelHandler
    }
}

public struct ChatTheme: PushMessage {
    public var chatId: String
    public var style: ChatBgImageStyle
    public var scene: ChatThemeScene

    public init(chatId: String, style: ChatBgImageStyle, scene: ChatThemeScene) {
        self.chatId = chatId
        self.style = style
        self.scene = scene
    }
}

/// 申请群成员上限
public struct GroupApplyForLimitBody: CodableBody {
    public static var appLinkPattern: String {
        return "/client/group/apply_member_limit/open"
    }

    private static let prefix = "//client/group/apply_member_limit/open"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }
    public var _url: URL {
        return URL(string: "\(Self.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String

    public init(chatId: String) {
        self.chatId = chatId
    }
}

// 电话查询限制
public struct PhoneQueryLimitBody: PlainBody {
    public static let pattern = "//client/mine/phone_query_limit"

    public let queryQuota: ServerPB_Users_CheckUserPhoneNumberResponse
    public let chatterId: String
    public let chatId: String
    public let deniedAlertDisplayName: String

    public init(queryQuota: ServerPB_Users_CheckUserPhoneNumberResponse, chatterId: String, chatId: String, deniedAlertDisplayName: String) {
        self.queryQuota = queryQuota
        self.chatterId = chatterId
        self.chatId = chatId
        self.deniedAlertDisplayName = deniedAlertDisplayName
    }
}

public protocol MultiEditService {
    func multiEditMessage(messageId: Int64, chatId: String, type: Basic_V1_Message.TypeEnum,
                          richText: Basic_V1_RichText, title: String?, lingoInfo: Basic_V1_LingoOption) -> Observable<RustPB.Basic_V1_RichText>
    func reloadEditEffectiveTimeConfig()
}
public protocol PostMessageErrorAlertService {
    func showResendAlertFor(error: Error?,
                            message: Message,
                            fromVC: UIViewController)
    func showResendAlertForThread(error: Error?,
                            message: ThreadMessage,
                            fromVC: UIViewController)
}
public struct DocChangePermissionBody: Body {
    private static let prefix = "//client/doc/permission/change"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:messageId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(DocChangePermissionBody.prefix)/\(docPermission.messageID)") ?? .init(fileURLWithPath: "")
    }

    public let docPermission: RustPB.Basic_V1_DocPermission
    public let chat: Chat
    public let sourceView: UIView?

    public init(docPermission: RustPB.Basic_V1_DocPermission, chat: Chat, sourceView: UIView?) {
        self.docPermission = docPermission
        self.chat = chat
        self.sourceView = sourceView
    }
}

public enum AddMemeberWay {
    case viaInvite
    case viaQrCode
    case viaLink
    case viaShare
}

public protocol WithdrawAddGroupMemberService {
    func withdrawMembers(chatId: String,
                         isThread: Bool,
                         entity: WithdrawEntity,
                         messageId: String,
                         messageCreateTime: TimeInterval,
                         way: AddMemeberWay,
                         from: NavigatorFrom,
                         sourveView: UIView?)
}

// 需要撤回的人/群/部门
public struct WithdrawEntity {
    public let chatterIds: [String]
    public let chatterNames: [String: String]
    public let chatIds: [String]
    public let chatNames: [String: String]
    public let departmentIds: [String]
    public let departmentNames: [String: String]
    public init(chatterIds: [String],
                chatterNames: [String: String],
                chatIds: [String],
                chatNames: [String: String],
                departmentIds: [String],
                departmentNames: [String: String]) {
        self.chatterIds = chatterIds
        self.chatterNames = chatterNames
        self.chatIds = chatIds
        self.chatNames = chatNames
        self.departmentIds = departmentIds
        self.departmentNames = departmentNames
    }
}

public enum ChannelType {
    case unknow
    case chat
    case psersion
}

public struct CallByChannelBody: PlainBody {
    public static var pattern: String = "//client/chat/action/choice_channel"

    public let chatterId: String
    public let chatId: String?
    public let displayName: String
    public let inCryptoChannel: Bool
    public var sender: UIControl?
    // code_next_line tag CryptChat
    public var isCrossTenant: Bool
    public var channelType: ChannelType
    public var isShowVideo: Bool
    public var accessInfo: Chatter.AccessInfo
    public var fromWhere: String?
    public var chatterName: String
    public var chatterAvatarKey: String
    /// 目前Person和单聊会用到此Body，单聊会传chat用于埋点
    public var chat: Chat?
    /// 点击item, 是phone则为true
    public var clickBlock: ((Bool) -> Void)?

    public init(chatterId: String,
                chatId: String?,
                displayName: String,
                // code_next_line tag CryptChat
                inCryptoChannel: Bool,
                sender: UIControl?,
                isCrossTenant: Bool = false,
                channelType: ChannelType = .unknow,
                isShowVideo: Bool,
                accessInfo: Chatter.AccessInfo,
                fromWhere: String? = nil,
                chatterName: String = "",
                chatterAvatarKey: String = "",
                chat: Chat? = nil,
                clickBlock: ((Bool) -> Void)? = nil) {
        self.chatterId = chatterId
        self.chatId = chatId
        self.displayName = displayName
        // code_next_line tag CryptChat
        self.inCryptoChannel = inCryptoChannel
        self.sender = sender
        self.isCrossTenant = isCrossTenant
        self.channelType = channelType
        self.isShowVideo = isShowVideo
        self.accessInfo = accessInfo
        self.fromWhere = fromWhere
        self.chatterName = chatterName
        self.chatterAvatarKey = chatterAvatarKey
        self.chat = chat
        self.clickBlock = clickBlock
    }
}

extension CallByChannelBody: CustomStringConvertible {
    public var description: String {
        var desc = "CallByChannelBody(chatterId: \(chatterId), chatId: \(String(describing: chatId)), inCryptoChannel: \(inCryptoChannel)"
        desc.append(", isCrossTenant: \(isCrossTenant), channelType: \(channelType), isShowVideo: \(isShowVideo))")
        return desc
    }
}

public struct GroupFreeBusyBody: PlainBody {
    public static var pattern: String = "//client/chat/calendar/groupFreeBusy"

    public let chatId: String
    public let selectedChatterIds: [String]
    public let selectCallBack: ([String]) -> Void

    public init(chatId: String,
                selectedChatterIds: [String],
                selectCallBack: @escaping ([String]) -> Void) {
        self.chatId = chatId
        self.selectedChatterIds = selectedChatterIds
        self.selectCallBack = selectCallBack
    }
}

/// 自动翻译引导
public struct AutoTranslateGuideBody: PlainBody {
    public static var pattern: String = "//client/chat/autoTranslateGuide"

    public init() {}
}

// 群分享 -> 分享群二维码
public protocol ShareGroupQRCodeController: JXSegmentedListContainerViewListDelegate {}

// 群分享 -> 分享群链接
public protocol ShareGroupLinkController: JXSegmentedListContainerViewListDelegate {}

// 外部群加人
public struct ExternalGroupAddMemberBody: CodableBody {
    private static let prefix = "//client/chat/setting/member/addGroupMember"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ExternalGroupAddMemberBody.prefix)/\(chatId)") ?? .init(fileURLWithPath: "")
    }

    public let chatId: String
    public let source: AddMemberSource?

    public init(chatId: String, source: AddMemberSource? = nil) {
        self.chatId = chatId
        self.source = source
    }
}

public protocol TodoChatSmartReplyProtocol {
    func showTodoChatSmartReply(icon: UIImage, title: String, onClick: @escaping (() -> Void))
}

public struct GroupModeViewBody: PlainBody {
    public static var pattern: String = "//client/contact/groupmode"

    public let modeType: ModelType
    public let ability: CreateAbility
    public let hasSelectedExternalChatter: Bool
    public let hasSelectedChatOrDepartment: Bool
    public let completion: CompletionFunc

    public init(modeType: ModelType,
                ability: CreateAbility,
                hasSelectedExternalChatter: Bool,
                hasSelectedChatOrDepartment: Bool,
                completion: @escaping CompletionFunc) {
        self.modeType = modeType
        self.ability = ability
        self.hasSelectedExternalChatter = hasSelectedExternalChatter
        self.hasSelectedChatOrDepartment = hasSelectedChatOrDepartment
        self.completion = completion
    }
}

/// 能够创建哪些类型的会话
public struct CreateAbility: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// 不能创建任何类型的群，写出CreateAbility(rawValue: 0)会有警告
    public static let none = CreateAbility([])
    /// 能创建密聊群
    public static let secret = CreateAbility(rawValue: 1)
    /// 能创建话题群
    public static let thread = CreateAbility(rawValue: 1 << 1)
    /// 能创建密盾群
    public static let privateChat = CreateAbility(rawValue: 1 << 2)
}

public typealias CompletionFunc = (ModelType) -> Void

public enum ModelType {
    case chat
    case thread
    case secret
    case privateChat
}

public enum TopNoticeMenuType {
    case cancelTopMessage
    case topMessage
}
/// 聊天消息置顶
public protocol ChatTopNoticeService {
    func createTopNoticeBannerWith(topNotice: ChatTopNotice,
                                           chatPush: BehaviorRelay<Chat>,
                                           fromVC: UIViewController?,
                                           closeHander: (() -> Void)?) -> UIView?

    func topNoticeActionMenu(_ message: Message,
                              chat: Chat,
                              currentTopNotice: ChatTopNotice?) -> TopNoticeMenuType?

    func topNoticeActionMenu(_ message: Message,
                                    chat: Chat,
                                    currentTopNotice: ChatTopNotice?,
                                    currentUserId: String) -> TopNoticeMenuType?

    func isSupportTopNoticeChat(_ chat: Chat) -> Bool

    func canTopNotice(chat: Chat) -> Bool

    func getTopNoticeMessageSummerize(_ message: Message, customAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString

    func closeOrRemoveTopNotice(_ topNotice: ChatTopNotice,
                                chat: Chat,
                                fromVC: UIViewController?,
                                trackerInfo: (Message?, Bool),
                                closeHander: (() -> Void)?)
}

/// 用户置顶/取消置顶相关操作
public protocol TopNoticeUserActionService {
    /// 置顶信息&chatID
    var updatePublishSubject: PublishSubject<(ChatTopNotice, Int64)> { get }
    func patchChatTopNoticeWithChatID(_ chatId: Int64,
                                      type: RustPB.Im_V1_PatchChatTopNoticeRequest.ActionType,
                                      senderId: Int64?,
                                      messageId: Int64?) -> Observable<RustPB.Im_V1_PatchChatTopNoticeResponse>
}

/// 群公告相关 CCM&端上交互使用
public enum GetGroupAnnouncementInfoResult {
   /// richText: 富文本
   /// title: 标题
   /// chat: 当前会话
   case success(chatId: String, richText: RustPB.Basic_V1_RichText, title: String)
   /// Error: 错误信息 String: 给用户的展示信息
   case fail(Error?, String)
}
/// 用于获取信息的闭包
public typealias GetGroupAnnouncementInfoClosure = (GetGroupAnnouncementInfoResult) -> Void

public struct SendAlertSheetUIConfig {
    public weak var fromController: UIViewController?
    public weak var actionView: UIView?
    public init(fromController: UIViewController, actionView: UIView?) {
        self.fromController = fromController
        self.actionView = actionView
    }
}
public protocol GroupAnnouncementService {
    /// CCM 调用端上触发，端上弹出弹窗
    /// - Parameters:
    ///   - chatId: 群聊 id
    ///   - uiConfig: alertSheet展示需要的UI
    ///   - extra: 额外信息
    ///   - getInfoHandler: 获取信息的处理闭包
    ///   - completion: IM完成处理，回到CCM处理比如(Pop) isCancel 点击 取消按钮/遮罩
    func showSendAlertSheetIfNeed(chatId: String,
                                  uiConfig: SendAlertSheetUIConfig,
                                  extra: [String: Any]?,
                                  getInfoHandler: @escaping ( @escaping GetGroupAnnouncementInfoClosure) -> Void,
                                  completion: ((_ isCancel: Bool) -> Void)?)
}

/// 保证在主线程回调
public protocol RealTimeTranslateDataDelegate: AnyObject {
    func beginTranslateTitle()
    func beginTranslateConent()
    func onUpdateTitleTranslation(_ text: String)
    func onUpdateContentTranslationPreview(_ previewtext: String, completeData: RustPB.Basic_V1_RichText?)
    func onRecallEnableChanged(_ enable: Bool)
}

public final class RealTimeTranslateData {
    public var chatID: String
    /// 这里不要干扰原有的生命周期
    public weak var contentTextView: LarkEditTextView?
    public weak var titleTextView: LarkEditTextView?
    public weak var delegate: RealTimeTranslateDataDelegate?
    public init(chatID: String,
                titleTextView: LarkEditTextView?,
                contentTextView: LarkEditTextView?,
                delegate: RealTimeTranslateDataDelegate?) {
        self.chatID = chatID
        self.titleTextView = titleTextView
        self.contentTextView = contentTextView
        self.delegate = delegate
    }
}
/// 输入框边写边译相关的逻辑
public protocol RealTimeTranslateService {
    func bindToTranslateData(_ data: RealTimeTranslateData)
    func unbindToTranslateData()
    func updateSessionID()
    func refreshTranslateContent()
    func getCurrentTranslateOriginData() -> (String?, RustPB.Basic_V1_RichText?)
    func getLastOriginData() -> (String?, NSAttributedString?)
    func clearTranslationData()
    func clearOriginAndTranslationData()
    func updateTargetLanguage(_ languageKey: String)
    func getRecallEnable() -> Bool
}
/// ReplyInThread的配置协议
public protocol ReplyInThreadConfigService {
    func canCreateThreadForChat(_ chat: Chat) -> Bool
    func canForwardThread(message: Message) -> Bool
    func canReplyInThread(message: Message) -> Bool
}

/// 消息聚合的+1动画配置协议
public protocol FoldApproveDataService {
    var dataUsable: Bool { get }
    var filePath: IsoPath? { get }
    func configData(exclude: Bool)
}

public protocol ScheduleSendService {
    // 定时发送fg
    var scheduleSendEnable: Bool { get }
    // 在编辑状态打开时间选择器
    func showDatePickerInEdit(currentSelectDate: Date,
                              chatName: String,
                              from: UIViewController,
                              isShowSendNow: Bool,
                              sendNowCallback: @escaping () -> Void,
                              confirmTask: @escaping (Date) -> Void)
    // 打开时间选择器
    func showDatePicker(currentInitDate: Date,
                        currentSelectDate: Date,
                        from: UIViewController,
                        confirmTask: @escaping (Int64) -> Void)

    func showAlertWhenSchuduleExitButtonTap(from: UIViewController,
                                            chatID: Int64,
                                            closeTask: @escaping () -> Void,
                                            continueTask: @escaping () -> Void)
    //swiftlint:disable all
    func patchScheduleMessage(chatID: Int64,
                              messageId: String,
                              messageType: Basic_V1_Message.TypeEnum?,
                              itemType: Basic_V1_ScheduleMessageItem.ItemType,
                              cid: String,
                              content: QuasiContent,
                              scheduleTime: Int64?,
                              isSendImmediately: Bool,
                              needSuspend: Bool,
                              callback: @escaping (Result<PatchScheduleMessageResponse, Error>) -> Void)
    //swiftlint:enable all

    func showAlertWhenSchuduleCloseButtonTap(from: UIViewController,
                                             chatID: Int64,
                                             itemId: String,
                                             itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType,
                                             cancelTask: @escaping () -> Void,
                                             closeTask: @escaping () -> Void,
                                             continueTask: @escaping () -> Void)

    // 显示“发送失败”的弹窗
    func showFailAlert(from: UIViewController,
                       message: Message,
                       itemType: Basic_V1_ScheduleMessageItem.ItemType,
                       title: String,
                       chat: Chat,
                       pasteboardToken: String)

    // 检查当前时区对应的时间是否能展示引导
    func checkTimezoneCanShowGuide(timezone: String) -> Bool

    func showAlertWhenContentNil(from: UIViewController,
                                 chatID: Int64,
                                 itemId: String,
                                 itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType,
                                 deleteConfirmTask: @escaping () -> Void,
                                 deleteSuccessTask: @escaping () -> Void)
}

public struct TapableTextModel {
    public var range: NSRange
    public var handler: () -> Void

    public init(range: NSRange,
                handler: @escaping () -> Void) {
        self.range = range
        self.handler = handler
    }
}

public struct ChatScheduleTipModel {
    public var normalDesc: NSAttributedString
    public var normalInlineCheckDesc: NSAttributedString?

    public var disableDesc: NSAttributedString
    public var disableInlineCheckDesc: NSAttributedString?
    public var normalTextLinkRange: [String: TapableTextModel]
    public var disableTextLinkRange: [String: TapableTextModel]

    public var iconColor: UIColor
    public var status: ScheduleMessageStatus

    public init(normalDesc: NSAttributedString,
                normalInlineCheckDesc: NSAttributedString? = nil,
                disableDesc: NSAttributedString,
                disableInlineCheckDesc: NSAttributedString? = nil,
                iconColor: UIColor,
                status: ScheduleMessageStatus,
                normalTextLinkRange: [String: TapableTextModel],
                disableTextLinkRange: [String: TapableTextModel]) {
        self.normalDesc = normalDesc
        self.disableDesc = disableDesc
        self.status = status
        self.iconColor = iconColor
        self.normalTextLinkRange = normalTextLinkRange
        self.disableTextLinkRange = disableTextLinkRange
        self.normalInlineCheckDesc = normalInlineCheckDesc
        self.disableInlineCheckDesc = disableInlineCheckDesc
    }
}

// 定时消息发送所有状态
public enum ScheduleMessageStatus: String {
    case sendSuccess
    case delete
    // 创建完成，待发送
    case createSuccess
    case creating
    case updating

    // failed
    case quasiFailed
    case updateFailed
    case sendFailed

    // 兼容字段
    case unknown

    public var isFailed: Bool {
        return self == .quasiFailed || self == .updateFailed || self == .sendFailed
    }
}

public protocol MergeForwardContentService {
    func getMergeForwardTitleFromContent(_ content: MergeForwardContent?) -> String
    func getPosterNameFromMessage(_ message: Message?, _ chatType: Chat.TypeEnum?) -> String
}

public protocol AfterFirstScreenMessagesRenderDelegate: AnyObject {
    func afterMessagesRender()
}

public protocol MultiEditCountdownService {
    func startMultiEditTimer(messageCreateTime: TimeInterval,
                             effectiveTime: TimeInterval,
                             onNeedToShowTip: (() -> Void)?,
                             onNeedToBeDisable: (() -> Void)?)
    func stopMultiEditTimer()
}

/// 支持的粘贴能力
public enum KeyboardSupportPasteType {
    case imageAndVideo /// 图片视频
    case emoji         /// emoji
    case fontStyle     /// BISU
    case code          /// 代码块
}

public protocol SyncToChatOptionViewService {
    var showSyncToCheckBox: Bool { get set }
    var isKeyboardFold: Bool { get set }
    var forwardToChat: Bool { get }
    func updateText(chat: Chat, showFromChat: Bool)
    func getView(isInComposeView: Bool, chat: Chat?) -> UIView?
    func messageWillSend(chat: Chat)
}

public protocol KeyboardShareDataService: AnyObject {
    var countdownService: MultiEditCountdownService { get }
    var keyboardStatusManager: KeyboardStatusManager { get }
    var myAIInlineService: IMMyAIInlineService? { get set }
    var isMyAIChatMode: Bool { get set }
    var supportDraft: Bool { get set }
    var supportPartReply: Bool { get set }
    var unsupportPasteTypes: [KeyboardSupportPasteType] { get set }
    var forwardToChatSerivce: SyncToChatOptionViewService { get set }
}
