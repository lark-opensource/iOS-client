//
//  SearchAPI.swift
//  LarkSDKInterface
//
//  Created by ChalrieSu on 2018/5/30.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import RustPB
import ServerPB
import EEAtomic
import LarkResource
import LarkContainer

public protocol SearchAPI {

    /// 上传搜索历史
    ///
    /// - Parameters:
    ///   - feedbacks: 搜索记录
    ///   - searchText: 搜索内容
    ///   - scene: 搜索场景
    ///   - searchSession: 客户端定义的一次搜索行为的ID
    ///   - imprID: 服务端response中的imporID
    /// - Returns: void
    func putSearch(feedbacks: [SearchFeedback],
                   searchText: String,
                   scene: SearchScene,
                   searchSession: String?,
                   imprID: String?) -> Observable<Void>

    // 搜索 V2 接口
    func universalSearch(
        query: String,
        scene: SearchSceneSection,
        begin: Int32,
        end: Int32,
        moreToken: Any?,
        filter: SearchFilterParam?,
        needSearchOuterTenant: Bool,
        authPermissions: [RustPB.Basic_V1_Auth_ActionType]
    ) -> Observable<SearchCallBack>

    func universalSearch(
        query: String,
        scene: SearchSceneSection,
        begin: Int32,
        end: Int32,
        moreToken: Any?,
        chatID: String?,
        needSearchOuterTenant: Bool,
        authPermissions: [RustPB.Basic_V1_Auth_ActionType]
    ) -> Observable<SearchCallBack>

    func universalSearch(
        query: String,
        scene: SearchSceneSection,
        moreToken: Any?,
        searchParam: UniversalSearchParam,
        authPermissions: [RustPB.Basic_V1_Auth_ActionType]
    ) -> Observable<SearchCallBack>

    // 无 query 大搜推荐 https://bytedance.feishu.cn/docx/ZxyJd6NbLo7yxvxnanFcusM5nuh
    func universalRecommendFeeds(request: ServerPB_Usearch_PullDocFeedCardsRequest) -> Observable<[SearchResultType]>

    func deleteAllSearchInfos() -> Observable<Search_V1_DeleteAllSearchInfosHistoryResponse>

    func getClosestChatters(begin: Int32, end: Int32) -> Observable<[ChatterMeta]>

    func pullClosestChats(begin: Int32, end: Int32) -> Observable<[ServerPB_Graph_ChatMeta]>

    /// 分词，例如："品质修复群" -> ["品质", "修复群"]
    func segmentText(text: String) -> Observable<RustPB.Search_V1_SegmentTextResponse>
    func fetchRecentForwardItems(includeGroupChat: Bool,
                                 includeP2PChat: Bool,
                                 includeThreadChat: Bool,
                                 includeOuterChat: Bool,
                                 includeSelf: Bool,
                                 includeMyAi: Bool,
                                 strategy: Basic_V1_SyncDataStrategy) -> Observable<[Feed_V1_GetRecentTransmitTargetsResponse.RecentTransmitTarget]>
}

// MARK: - UniversalRecommend

public struct UniversalRecommendSection {
    public let style: ServerPB_Search_urecommend_LayoutStyle
    public let title: String
    public let paginationToken: String
    public let enTitle: String
    public let results: [SearchResultType]
    public init(style: ServerPB_Search_urecommend_LayoutStyle,
                title: String,
                paginationToken: String,
                enTitle: String,
                results: [SearchResultType]) {
        self.style = style
        self.title = title
        self.paginationToken = paginationToken
        self.enTitle = enTitle
        self.results = results
    }
}

extension ServerPB_Usearch_UserMeta: SearchMetaChatterType {
    public var description_p: String { "" }
    public var descriptionFlag: Basic_V1_Chatter.Description.TypeEnum { .onDefault }
    public var timezone: Search_V1_TimeZone { .init() }
    public var withBotTag: String { "" }
    public var hasWorkStatus: Bool { false }
    public var workStatus: Basic_V1_WorkStatus { Basic_V1_WorkStatus() }
    public var deniedReason: [Int32: Basic_V1_Auth_DeniedReason] { [:] }
    public var deniedPermissions: [Basic_V1_Auth_ActionType] { [] }
    public var isCrypto: Bool { false }
    public var isRemind: Bool { true }
    public var p2PChatID: String { chatID }
    public var lastMessagePosition: Int32 { 0 }
    public var lastMessagePositionBadgeCount: Int32 { 0 }
    public var readPosition: Int32 { 0 }
    public var readPositionBadgeCount: Int32 { 0 }
    public var type: Basic_V1_Chatter.TypeEnum { .user }
    public var isInChat: Bool { extraFields.isInChat }
    public var enterpriseEmail: String { "" }
    public var customStatus: [Basic_V1_Chatter.ChatterCustomStatus] { [] }
    public var relationTag: RustPB.Search_V2_TagData { Search_V2_TagData() }
    public var isBlockedFromLocalSearch: Bool { false }
}

extension ServerPB_Usearch_BotMeta: SearchMetaChatterType {
    public var type: Basic_V1_Chatter.TypeEnum { .bot }
    public var isInChat: Bool { extraFields.isInChat }
    public var mailAddress: String { "" }
    public var enterpriseMailAddress: String { "" }
    public var description_p: String { "" }
    public var descriptionFlag: Basic_V1_Chatter.Description.TypeEnum { .onDefault }
    public var timezone: Search_V1_TimeZone { .init() }
    public var doNotDisturbEndTime: Int64 { 0 }
    public var hasWorkStatus: Bool { false }
    public var isRegistered: Bool { true }
    public var workStatus: Basic_V1_WorkStatus { .init() }
    public var deniedReason: [Int32: Basic_V1_Auth_DeniedReason] { [:] }
    public var deniedPermissions: [Basic_V1_Auth_ActionType] { [] }
    public var p2PChatID: String { chatID }
    public var lastMessagePositionBadgeCount: Int32 { 0 }
    public var lastMessagePosition: Int32 { 0 }
    public var readPosition: Int32 { 0 }
    public var readPositionBadgeCount: Int32 { 0 }
    public var isCrypto: Bool { false }
    public var isRemind: Bool { true }
    public var enterpriseEmail: String { "" }
    public var customStatus: [Basic_V1_Chatter.ChatterCustomStatus] { [] }
    public var relationTag: RustPB.Search_V2_TagData { Search_V2_TagData() }
    public var isBlockedFromLocalSearch: Bool { false }
}

extension ServerPB_Usearch_MyAIMeta: SearchMetaChatterType {
    public var type: Basic_V1_Chatter.TypeEnum { .ai }
    public var withBotTag: String { "" }
    public var tenantID: String { "" }
    public var isRegistered: Bool { false }
    public var isInChat: Bool { false }
    public var mailAddress: String { "" }
    public var enterpriseEmail: String { "" }
    public var description_p: String { "" }
    public var descriptionFlag: Basic_V1_Chatter.Description.TypeEnum { .onDefault }
    public var timezone: RustPB.Search_V1_TimeZone { .init() }
    public var doNotDisturbEndTime: Int64 { 0 }
    public var hasWorkStatus: Bool { false }
    public var workStatus: Basic_V1_WorkStatus { .init() }
    public var deniedReason: [Int32: Basic_V1_Auth_DeniedReason] { [:] }
    public var deniedPermissions: [Basic_V1_Auth_ActionType] { [] }
    public var lastMessagePositionBadgeCount: Int32 { 0 }
    public var lastMessagePosition: Int32 { 0 }
    public var readPosition: Int32 { 0 }
    public var readPositionBadgeCount: Int32 { 0 }
    public var customStatus: [Basic_V1_Chatter.ChatterCustomStatus] { [] }
    public var relationTag: Search_V2_TagData { .init() }
    public var isCrypto: Bool { false }
    public var isRemind: Bool { true }
    public var isBlockedFromLocalSearch: Bool { false }
}

extension ServerPB_Usearch_GroupChatMeta: SearchMetaChatType {
    public var userCountTextMayBeInvisible: String {
        ""
    }
    public var type: Basic_V1_Chat.TypeEnum { .group }
    public var isOfficialOncall: Bool { false }
    public var tags: [Basic_V1_Tag] { [] }
    public var chatMode: Basic_V1_Chat.ChatMode {
        switch mode {
        case .default: return .default
        case .thread: return .thread
        case .threadV2: return .threadV2
        case .unknownChatMode: return .unknown
        }
    }
    public var userCountText: String { userCount > 0 ? "\(userCount)" : "" }
    public var isUserCountVisible: Bool { !self.userCountInvisible }
    public var userCountWithBackup: Int32 { userCount }
    public var lastMessagePositionBadgeCount: Int32 { 0 }
    public var lastMessagePosition: Int32 { 0 }
    public var readPosition: Int32 { 0 }
    public var readPositionBadgeCount: Int32 { 0 }
    public var isRemind: Bool { true }
    public var isShield: Bool { false }
    public var relationTag: RustPB.Search_V2_TagData { Search_V2_TagData() }
    public var description: String { description_p }
}

extension ServerPB_Usearch_MessageMeta: SearchMetaMessageType {
    public var contentType: Basic_V1_Message.TypeEnum {
        switch type {
        case .audio: return .audio
        case .calendar: return .calendar
        case .card: return .card
        case .cloudFile: return .file
        case .commercializedHongbao: return .commercializedHongbao
        case .email: return .email
        case .file: return .file
        case .folder: return .folder
        case .generalCalendar: return .generalCalendar
        case .hongbao: return .hongbao
        case .image: return .image
        case .location: return .location
        case .media: return .media
        case .mergeForward: return .mergeForward
        case .post: return .post
        case .shareCalendarEvent: return .shareCalendarEvent
        case .shareGroupChat: return .shareGroupChat
        case .shareUserCard: return .shareUserCard
        case .sticker: return .sticker
        case .system: return .system
        case .text: return .text
        case .todo: return .todo
        case .unknown: return .unknown
        case .videoChat: return .videoChat
        /// ServerPB have updated but not RustPB, Should fix ME ASAP！
        case .diagnose: return .unknown
        case .vote: return .vote
        @unknown default: return .unknown
        }
    }
    public var p2PChatterIDString: String {
        if isP2PChat { return chatID }
        return ""
    }
    public var fileMeta: Basic_V1_File { .init() }
    public var fromAvatarKey: String { "" }
    public var fromName: String { "" }
    public var docExtraInfosType: [Search_V2_MessageMeta.DocExtraInfo] {
        docExtraInfos.map { info in
            var newInfo = Search_V2_MessageMeta.DocExtraInfo()
            newInfo.name = info.name
            newInfo.url = info.url
            switch info.type {
            case .bitable: newInfo.type = .bitable
            case .doc: newInfo.type = .doc
            case .docx: newInfo.type = .docx
            case .file: newInfo.type = .file
            case .folder: newInfo.type = .file
            case .sheet: newInfo.type = .sheet
            case .slide: newInfo.type = .slide
            case .unknownDocType: newInfo.type = .unknown
            case .wiki: newInfo.type = .wiki
            case .mindnote: newInfo.type = .mindnote
            case .catalog: newInfo.type = .catalog
            case .slides: newInfo.type = .slides
            case .shortcut: newInfo.type = .unknown
            @unknown default:
                assertionFailure("Wrong doc type")
            }
            return newInfo
        }
    }
    public var threadMessageType: Basic_V1_Message.ThreadMessageType { threadMessageType }
    public var rootMessagePosition: Int32 { rootMessagePosition }
    public var isFileAccessAuth: Bool { false }
}

public extension ServerPB_Usearch_ResultMeta.OneOf_TypedMeta {
    public var avatarID: String? {
        switch self {
        case .threadMeta(let meta): return meta.id
        case .groupChatMeta(let meta): return meta.id
        case .userMeta(let meta): return meta.id
        case .cryptoP2PChatMeta(let meta): return meta.id
        case .botMeta(let meta): return meta.id
        case .oncallMeta(let meta): return meta.id
        case .appMeta(let meta): return meta.id
        @unknown default: return nil
        }
    }
}

public extension ServerPB_Entities_Icon {
    public func toV1Icon() -> Basic_V1_Icon {
        var icon = Basic_V1_Icon()
        let iconType: Basic_V1_Icon.TypeEnum
        switch type {
        case .image: iconType = .image
        case .unknownIconType, .emoji: iconType = .unknown
        @unknown default: iconType = .unknown
        }
        icon.type = iconType
        icon.value = key
        return icon
    }
}

// MARK: - Search
public struct UniversalSearchParam {
    public var externalID: String?

    public var needSearchOuterTenant: Bool = true
    public var doNotSearchResignedUser: Bool?
    public var inChatID: String?
    public var chatFilterMode: [ChatFilterMode]?
    /// calendar use, only true or nil, v2始终会带上这个标记
    public var includeMeetingGroup: Bool?

    /// 人群部门搜索的标记，只有V2支持，V1会降级到只有人
    public var includeChat = false
    public var includeDepartment = false
    public var includeUserGroup = false
    public var includeChatter = true
    public var includeBot = false
    public var includeThread = false
    public var includeMailContact = false
    /// 以群拉人标记，后端有对应的权限过滤
    public var includeChatForAddChatter = false
    /// 以部门拉人标记，后端有对应的权限过滤
    public var includeDepartmentForAddChatter = false
    /// 是否在搜索群的时候包含外部群
    public var includeOuterGroupForChat = false
    /// 是否在搜索单聊的时候包含密盾单聊
    public var includeShieldP2PChat = false
    /// 是否在搜索群的时候包含密盾群
    public var includeShieldGroup = false
    /// 是否筛选未聊天过的人和Bot
    public var excludeUntalkedChatterBot = false
    public var wikiNeedOwner = false
    /// 是否筛选外部联系人
    public var excludeOuterContact = false

    // 加在 commonFilter 中
    public var chatID: String?

    /// 优先级最高的外部群组配置
    public var incluedOuterChat: Bool?
    /// 是否包含密聊/密聊群聊
    public var includeCrypto: Bool?
}

extension UniversalSearchParam {
    public static var `default`: UniversalSearchParam {
        return UniversalSearchParam()
    }
}

/// NOTE: refactor to adopt v1, v2. hide old API's SearchCallBack
/// 以后还是要往SearchSource和Response上靠
// 属性都先留着，以后再看情况精简
// TODO: 没有as的话，应该可以直接用struct，没必要protocol多态
public protocol SearchCallBack {
    var searchScene: SearchSceneSection { get }
    var hasMore: Bool { get }
    var moreToken: Any? { get }
    var isRemote: Bool { get }
    var imprID: String? { get }
    var results: [SearchResultType] { get set } // 可能做filter，暂时不new类型
    var extra: String? { get }
    var contextID: String? { get }
    //section类型时所有的result都是spotlight结果
    //common类型有loadMore情况，但是loadMore不改动第一次设置的contextID，具体哪个result是spotlight与contextID强相关
    var isSpotlight: Bool { get }
}

/// 搜索结果类型，会透传给UI Cell消费使用
public protocol SearchItem {
    /// 唯一标识，用于排重 TODO: 排重实现
    var identifier: String? { get }
}

/// 高级语法搜索结果
public protocol SearchAdvancedSyntaxItem {
    var id: String { get }
}

public enum PickerSearchSelectType: String {
    case group, cryptoGroup, member, thread, doc, wiki, bot, department, emailMember, generalFilter, userGroup, myAi
    case unknown
    public var description: String {
        switch self {
        case .cryptoGroup: return "crypto_group"
        case .emailMember: return "email_member"
        case .userGroup: return "user_group"
        case .myAi: return "my_ai"
        default: return rawValue
        }
    }
}

@frozen
public struct OptionIdentifier: Hashable, Option {
    public var optionIdentifier: OptionIdentifier { return self }

    public var type: String
    public var id: String
    public var chatId: String
    public var name: String
    public var isThread: Bool
    public var isCrypto: Bool
    public var emailId: String?
    public var description: String
    public var avatarImageURLStr: String
    public init(type: String,
                id: String,
                chatId: String = "",
                name: String = "",
                description: String = "",
                avatarImageURLStr: String = "",
                isThread: Bool = false,
                isCrypto: Bool = false,
                emailId: String? = nil) {
        self.type = type
        self.id = id
        self.chatId = chatId
        self.name = name
        self.description = description
        self.avatarImageURLStr = avatarImageURLStr
        self.isThread = isThread
        self.isCrypto = isCrypto
        self.emailId = emailId
    }

    // known types for option
    public enum Types: String, RawRepresentable {
        case unknown, chatter, myAi, chat, bot, thread
        case mailContact // id is unqiue email string
        case department
        case fromFilterRecommend
        case generalFilter
        case userGroup, userGroupAssign, newUserGroup
        case mailUser
    }
    public static func chatter(id: String,
                               name: String = "") -> Self {
        .init(type: "chatter", id: id, name: name)
    }
    public static func chat(id: String,
                            chatId: String = "",
                            name: String = "",
                            isThread: Bool = false,
                            isCrypto: Bool = false) -> Self {
        .init(type: "chat", id: id, chatId: chatId, name: name, isThread: isThread, isCrypto: isCrypto)
    }
    public static func department(id: String) -> Self { .init(type: "department", id: id) }
    public static func mailContact(id: String, emailId: String? = nil) -> Self { .init(type: "mailContact", id: id, emailId: emailId) }
    public static func fromFilterRecommend(id: String) -> Self { .init(type: "fromFilterRecommend", id: id) }
    public static func filter(id: String) -> Self { .init(type: "generalFilter", id: id)}

    public static func == (lhs: OptionIdentifier, rhs: OptionIdentifier) -> Bool {
        return lhs.type == rhs.type && lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(id)
    }
}

public protocol Option {
    var optionIdentifier: OptionIdentifier { get }
}

public protocol PickerSelectionTrackable: Option {
    var selectType: PickerSearchSelectType { get }
}

extension PickerItem: Option {
    public var optionIdentifier: OptionIdentifier {
        switch meta {
        case .chatter(let meta):
            return OptionIdentifier(type: "chatter", id: self.id, name: meta.localizedRealName ?? "")
        case .wiki(let meta):
            return OptionIdentifier(type: "wiki", id: self.id, name: meta.title ?? "")
        case .doc(let meta):
            return OptionIdentifier(type: "doc", id: self.id, name: meta.title ?? "")
        case .wikiSpace(let meta):
            // 目前搜索出来的是workspace, 还不能使用wikiSpace的type
            return OptionIdentifier(type: "workspace", id: self.id, name: meta.title ?? "")
        case .mailUser(let meta):
            return OptionIdentifier(type: "mailUser", id: meta.id, name: meta.title ?? "", description: meta.summary ?? "", avatarImageURLStr: meta.imageURL ?? "", emailId: meta.mailAddress)
        default:
            return OptionIdentifier(type: "unknown", id: self.id)
        }
    }
}

extension SearchResultType {
    public var optionIdentifier: OptionIdentifier {
        switch meta {
        // mailContact id 需要是邮箱 @刘特枫
        // 通过mailUser实体类型搜出的邮箱相关的结果都是开放搜索
        case .mailContact(let meta):
            return OptionIdentifier(type: type.rawValue, id: meta.email)
        case .chat(let chat):
            return OptionIdentifier(type: type.rawValue, id: chat.id, chatId: chat.id, name: title.string,
                                    isThread: chat.chatMode == .threadV2 || chat.chatMode == .thread,
                                    isCrypto: chat.isCrypto, emailId: chat.enterpriseEmail)
        case .shieldP2PChat(let chat):
            return OptionIdentifier(type: type.rawValue, id: chat.id, chatId: chat.id, name: title.string)
        case .chatter(let chatter):
            return OptionIdentifier(type: type.rawValue, id: id, name: title.string, emailId: chatter.enterpriseEmail)
        case .slash(let slashMeta):
            if bid.elementsEqual("lark"),
               (entityType.elementsEqual("mail-contact") || entityType.elementsEqual("mail-group") ||
                entityType.elementsEqual("name-card") || entityType.elementsEqual("mail_shared_account")) {
                return OptionIdentifier(type: OptionIdentifier.Types.mailUser.rawValue, id: summary.string, name: title.string, description: summary.string, avatarImageURLStr: slashMeta.imageURL)
            } else {
                return OptionIdentifier(type: type.rawValue, id: id)
            }
        default:
            return OptionIdentifier(type: type.rawValue, id: id)
        }
    }
    // PickerSelectionTrackable
    public var selectType: PickerSearchSelectType {
        switch type {
        case .chat: return .group
        case .cryptoP2PChat: return .cryptoGroup
        case .shieldP2PChat: return .cryptoGroup
        case .chatter, .external: return .member
        case .department: return .department
        case .thread: return .thread
        case .bot: return .bot
        case .mailContact: return .emailMember
        case .wiki: return .wiki
        case .doc: return .doc
        case .userGroup, .userGroupAssign, .newUserGroup: return .userGroup
        default: return .unknown
        }
    }
    public var identifier: String? { "\(self.type.rawValue):\(self.id)" }

    public var backupImage: UIImage? { type.backupImage }
    public var title: NSAttributedString { title(by: "") }
    public var extra: NSAttributedString { extra(by: "") }

    public var hasThread: Bool {
        switch meta {
        case .message(let messageMeta):
            let isRootMessage = messageMeta.threadMessageType == .threadRootMessage
            let isReplyMessage = messageMeta.threadMessageType == .threadReplyMessage
            return isRootMessage || isReplyMessage
        default: return false
        }
    }
}

/// 端上需要用到的SearchResult模型抽象，兼容V1, V2的模型
public protocol SearchResultType: SearchHistoryModel, SearchItem, PickerSelectionTrackable {
    var id: String { get }
    var type: Search.Types { get }

    // 通用的属性字段
    var contextID: String? { get }
    var avatarID: String? { get }
    var avatarKey: String { get }
    // 如果做日夜间模式，颜色需要改变
    func title(by tag: String) -> NSAttributedString
    var title: NSAttributedString { get }
    var summary: NSAttributedString { get }
    var extra: NSAttributedString { get }
    /// v1根据场景拼接不同的attributedString
    func extra(by tag: String) -> NSAttributedString

    var meta: Search.Meta? { get }

    var card: Search.Card? { get }
    // 一些特定类型特有的字段, 原来v1是放到result里的, 先也放到result里实现

    // 兼容v1在result上，v2在meta上的字段
    var icon: Basic_V1_Icon? { get }
    // var iconURL: String { get }
    var imageURL: String { get }

    // 其他一些很多meta都有的，但不是那么通用的属性，也放这里进行分发
    /// 对应后端标记的通用tag. 很多属性都有
    var tags: [Basic_V1_Tag] { get }

    /// 平台化的实体归属标识
    var bid: String { get }

    var entityType: String { get }

    var isSpotlight: Bool { get set }

    var extraInfos: [Search_V2_ExtraInfoBlock] { get }

    //默认使用空格连接
    var extraInfoSeparator: String { get }
}

/// Search NameSpace
public enum Search {
    /// all known search types, it's a open string wwrapper, so can extend external types
    public struct Types: Hashable, Equatable, RawRepresentable {
        /// known types, 尽量和Option的type定义的值一致
        /// 值定义主要参考新的v2 type
        public static var unknown: Types { Types("unknown") }
        public static var chatter: Types { Types("chatter") }
        public static var cryptoP2PChat: Types { Types("cryptoP2PChat") }
        public static var shieldP2PChat: Types { Types("shieldP2PChat") }
        public static var bot: Types { Types("bot") }
        public static var chat: Types { Types("chat") }
        public static var thread: Types { Types("thread") }
        public static var message: Types { Types("message") }
        public static var openApp: Types { Types("openApp") }
        public static var oncall: Types { Types("oncall") }
        public static var link: Types { Types("link") }
        public static var doc: Types { Types("doc") }
        public static var wiki: Types { Types("wiki") }
        public static var workspace: Types { Types("workspace") }
        public static var email: Types { Types("email") }
        public static var mailContact: Types { Types("mailContact") }

        public static var QACard: Types { Types("QACard") }
        public static var ServiceCard: Types { Types("ServiceCard") }
        public static var department: Types { Types("department") }
        public static var slashCommand: Types { Types("slashCommand") }
        public static var section: Types { Types("section") }
        public static var resource: Types { Types("resource") }
        public static var pano: Types { Types("pano") }
        public static var box: Types { Types("box") }
        public static var external: Types { Types("external") }
        public static var customization: Types { Types("customization") }
        public static var openSearchJumpMore: Types { Types("openSearchJumpMore") }
        public static var userGroup: Types { Types("userGroup") }
        public static var userGroupAssign: Types { Types("userGroupAssign") }
        public static var calendarEvent: Types { Types("calendarEvent") }
        public static var newUserGroup: Types { Types("newUserGroup") }
        public static var facility: Types { Types("facility") }

        public init?(rawValue: String) {
            self.rawValue = rawValue
        }
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        public let rawValue: String
        //todo: wangxiaohua customization要适配下
        public init(_ value: Search_V2_SearchEntityType) {
            switch value {
            case .unknown: self = Types("unknown")
            case .user: self = .chatter
            case .myAi: self = .chatter
            case .cryptoP2PChat: self = .cryptoP2PChat
            case .shieldP2PChat: self = .shieldP2PChat
            case .bot: self = .bot
            case .groupChat: self = .chat
            case .thread: self = .thread
            case .message: self = .message
            case .doc: self = .doc
            case .wiki: self = .wiki
            case .wikiSpace: self = .workspace
            case .app: self = .openApp
            case .oncall: self = .oncall
            case .qaCard: self = .QACard
            case .url: self = .link
            case .department: self = .department
            case .pano: self = .pano
            case .slashCommand: self = .slashCommand
            case .section: self = .section
            case .resource: self = .resource
            case .customization: self = .customization
            case .mailContact: self = .mailContact
            case .userGroup: self = .userGroup
            case .userGroupAssign: self = .userGroupAssign
            case .calendarEvent: self = .calendarEvent
            case .email: self = .email
            case .newUserGroup: self = .newUserGroup
            case .facility: self = .facility
            case .max, .chameleon, .banner, .messageFile:
                // FIXME: use unknown default setting to fix warning
                fallthrough
            @unknown default:
                assertionFailure("unsupported")
                self = Types(String(describing: value))
            }
        }

        public init(_ value: ServerPB_Usearch_SearchEntityType) {
            switch value {
            case .unknown: self = Types("unknown")
            case .user: self = .chatter
            case .passage: self = .chatter
            case .myAi: self = .chatter
            case .cryptoP2PChat: self = .cryptoP2PChat
            case .bot: self = .bot
            case .groupChat: self = .chat
            case .thread: self = .thread
            case .message: self = .message
            case .doc: self = .doc
            case .wiki: self = .wiki
            case .app: self = .openApp
            case .oncall: self = .oncall
            case .qaCard: self = .QACard
            case .url: self = .link
            case .department: self = .department
            case .pano: self = .pano
            case .slashCommand: self = .slashCommand
            case .section: self = .section
            case .resource: self = .resource
            case .customization: self = .customization
            case .mailContact: self = .mailContact
            case .userGroup: self = .userGroup
            case .userGroupAssign: self = .userGroupAssign
            case .calendarEvent: self = .calendarEvent
            case .email: self = .email
            case .facility: self = .facility
            case .chameleon,
                    .banner, .wikiSpace, .phoenix,
                    .shieldP2PChat, .messageFile, .mailUser:
                // FIXME: use unknown default setting to fix warning
                fallthrough
            @unknown default:
                assertionFailure("unsupported")
                self = Types(String(describing: value))
            }
        }

        public func convertToRustSearchEntityType() -> Search_V2_SearchEntityType {
            var entityType: Search_V2_SearchEntityType = .unknown
            switch self {
            case .unknown: entityType = .unknown
            case .chatter: entityType = .user
            case .cryptoP2PChat: entityType = .cryptoP2PChat
            case .shieldP2PChat: entityType = .shieldP2PChat
            case .bot: entityType = .bot
            case .chat: entityType = .groupChat
            case .thread: entityType = .thread
            case .message: entityType = .message
            case .doc: entityType = .doc
            case .wiki: entityType = .wiki
            case .workspace: entityType = .wikiSpace
            case .openApp: entityType = .app
            case .oncall: entityType = .oncall
            case .QACard: entityType = .qaCard
            case .link: entityType = .url
            case .department: entityType = .department
            case .pano: entityType = .pano
            case .slashCommand: entityType = .slashCommand
            case .section: entityType = .section
            case .resource: entityType = .resource
            case .customization: entityType = .customization
            case .mailContact: entityType = .mailContact
            case .userGroup: entityType = .userGroup
            case .userGroupAssign: entityType = .userGroupAssign
            case .calendarEvent: entityType = .calendarEvent
            case .email: entityType = .email
            case .newUserGroup: entityType = .newUserGroup
            default:
                break
            }
            return entityType
        }

        public var backupImage: UIImage? {
            switch self {
            case .department: return ResourceManager.get(key: "LarkSearchCore.department_avatar", type: "image")
            default: return nil
            }
        }
    }

    /// 端上依赖到的Meta相关接口抽象, 兼容v1 v2
    public enum Meta {
        // 先搬运v1的接口定义，保持兼容，v2适配相同的protocol
        case chatter(SearchMetaChatterType)
        case chat(SearchMetaChatType)
        case message(SearchMetaMessageType)
        case doc(SearchMetaDocType)
        case userGroup(Search_V2_UserGroupMeta)
        case userGroupAssign(Search_V2_UserGroupMeta)
        case newUserGroup(Search_V2_UserGroupMeta)
        case email(SearchMetaEmailType)
        case box(Search_V1_SearchBoxMeta)
        case oncall(SearchMetaOncallType)
        case cryptoP2PChat(SearchMetaCryptoP2PChatType)
        case shieldP2PChat(Search_V2_ShieldP2PChatMeta)
        case thread(SearchMetaThreadType)
        case openApp(Search_V2_AppMeta)
        case link(SearchMetaLinkType)
        case external(Search_V1_SearchExternalMeta)
        case wiki(SearchMetaWikiType)
        case workspace(Search_V2_WikiSpaceMeta)
        case calendar(SearchCalendarMeta)
        case mail(SearchMetaMailType)
        case department(SearchMetaDepartmentType)
        case slash(SearchMetaSlashType)
        case qaCard(Search_V2_QaCardMeta)
        case customization(Search_V2_CustomizationMeta)
        case mailContact(Search_V2_MailContactMeta)
        case section(SearchSectionMeta)
        case resource(Search_Resource_ResourceMeta)
        case messageFile(Search_V2_MessageFileMeta)
        case facility(Search_V2_FacilityMeta)
    }

    public struct Card {
        public var id: String
        public var renderContent: String
        public var templateName: String

        public init(id: String, renderContent: String, templateName: String) {
            self.id = id
            self.renderContent = renderContent
            self.templateName = templateName
        }
    }
}

// V1 V2 协议接口抽象
// Section Meta

public protocol SearchSectionHeader {
    var title: String { get }
    var avatarKey: String { get }
    var avatarURL: String { get }
    var titleModifiers: [Search_Sections_V1_Modifier] { get }
}

public enum SearchSectionAction: String {
    case main = "QUICK_JUMP"
    case message = "MESSAGE"
    case doc = "DOC"
    case wiki = "WIKI"
    case oncall = "ONCALL"
    case topic = "TOPIC"
    case thread = "THREAD"
    case app = "APP"
    case mail = "MAIL"
    case contacts = "CONTACTS"
    case group = "CHAT"
    case calendar = "CALENDAR"
    case pano = "PANO"
    case openSearch = "OPEN_SEARCH"
    case slashCommand = "SLASH_COMMAND"
}

public protocol SearchSectionFooter {
    var avatarKey: String { get }
    var text: String { get }
    var action: Search_Sections_V1_Action { get }
}

public protocol SearchSectionMeta {
    var id: String { get }
    var headerInfo: SearchSectionHeader { get }
    var footerInfo: SearchSectionFooter { get }
    var results: [SearchResultType] { get }
    var extras: String { get }
}

public protocol CommonChatterMetaType {
    var id: String { get }
    var type: Chatter.TypeEnum { get }
    var isCrypto: Bool { get }
    var withBotTag: String { get }
    var isRegistered: Bool { get }
    var hasWorkStatus: Bool { get }
    var workStatus: WorkStatus { get }
    var doNotDisturbEndTime: Int64 { get }
    var tenantID: String { get }
    var description_p: String { get }
    var descriptionFlag: Chatter.Description.TypeEnum { get }

    var isRemind: Bool { get }
    var readPosition: Int32 { get }
    var readPositionBadgeCount: Int32 { get }
    var lastMessagePosition: Int32 { get }
    var lastMessagePositionBadgeCount: Int32 { get }
}

/// 抽象端上使用到的Meta接口，隔离v1, v2变化影响
public protocol SearchMetaChatterType: CommonChatterMetaType {
    var id: String { get }
    var type: Basic_V1_Chatter.TypeEnum { get }
    var isInChat: Bool { get }
    var mailAddress: String { get }
    /// 企业邮箱
    var enterpriseEmail: String { get }
    var description_p: String { get }
    var descriptionFlag: Basic_V1_Chatter.Description.TypeEnum { get }
    var timezone: Search_V1_TimeZone { get }
    var withBotTag: String { get }
    var doNotDisturbEndTime: Int64 { get }
    var hasWorkStatus: Bool { get }
    var workStatus: Basic_V1_WorkStatus { get }
    var tenantID: String { get }
    var isRegistered: Bool { get }
    var deniedReason: [Int32: Basic_V1_Auth_DeniedReason] { get }
    var deniedPermissions: [Basic_V1_Auth_ActionType] { get }
    var p2PChatID: String { get }
    var lastMessagePositionBadgeCount: Int32 { get }
    var lastMessagePosition: Int32 { get }
    var readPosition: Int32 { get }
    var readPositionBadgeCount: Int32 { get }
    var customStatus: [Basic_V1_Chatter.ChatterCustomStatus] { get }
    var relationTag: Search_V2_TagData { get }
    var isBlockedFromLocalSearch: Bool { get }
}
public protocol SearchMetaChatType {
    var id: String { get }
    var type: RustPB.Basic_V1_Chat.TypeEnum { get }
    var isCrypto: Bool { get }
    var isShield: Bool { get }
    var isOfficialOncall: Bool { get }
    var tags: [Basic_V1_Tag] { get }
    var oncallID: String { get }
    var isCrossWithKa: Bool { get }
    var isCrossTenant: Bool { get }
    var isPublicV2: Bool { get }
    var isDepartment: Bool { get }
    var isTenant: Bool { get }
    var isMeeting: Bool { get }
    var chatMode: Basic_V1_Chat.ChatMode { get }
    var userCountText: String { get }
    var userCountTextMayBeInvisible: String { get }
    var isUserCountVisible: Bool { get }
    var userCountWithBackup: Int32 { get }
    var lastMessagePositionBadgeCount: Int32 { get }
    var lastMessagePosition: Int32 { get }
    var readPosition: Int32 { get }
    var readPositionBadgeCount: Int32 { get }
    var isMember: Bool { get }
    var isRemind: Bool { get }
    var enabledEmail: Bool { get }
    /// 企业邮箱
    var enterpriseEmail: String { get }
    var relationTag: Search_V2_TagData { get }
    var description: String { get }
}
public protocol SearchMetaMessageType {
    var id: String { get }
    var fromID: String { get }
    var contentType: Basic_V1_Message.TypeEnum { get }
    var chatID: String { get }
    var position: Int32 { get }
    var threadID: String { get }
    var threadPosition: Int32 { get }
    var isP2PChat: Bool { get }
    var p2PChatterIDString: String { get }
    var fileMeta: RustPB.Basic_V1_File { get }
    var hasFileMeta: Bool { get }
    var fromAvatarKey: String { get }
    var updateTime: Int64 { get }
    var createTime: Int64 { get }
    var fromName: String { get }
    var docExtraInfosType: [Search_V2_MessageMeta.DocExtraInfo] { get }
    var threadMessageType: RustPB.Basic_V1_Message.ThreadMessageType { get }
    var rootMessagePosition: Int32 { get }
    var isFileAccessAuth: Bool { get }
}
public protocol SearchMetaDocType {
    var id: String { get }
    var url: String { get }
    var type: RustPB.Basic_V1_Doc.TypeEnum { get }
    var wikiInfo: [RustPB.Search_V1_WikiInfo] { get }
    var isCrossTenant: Bool { get }
    var updateTime: Int64 { get }
    var ownerName: String { get }
    var ownerID: String { get }
    var isShareFolder: Bool { get }
    var iconInfo: String { get }

    // 群内跳转相关
    var chatID: String { get }
    var threadID: String { get }
    var threadPosition: Int32 { get }
    var position: Int32 { get }
    var relationTag: Search_V2_TagData { get }
}
public protocol SearchMetaEmailType {}
public protocol SearchMetaOncallType {
    var id: String { get }
    var chatID: String { get }
    var isOfficialOncall: Bool { get }
    var tagsV1: [Basic_V1_Tag] { get }
    var crossTagInfo: String { get }
    var hasCrossTagInfo: Bool { get }
    var faqTitle: String { get }
}
public protocol SearchMetaSlashType {
    var slashCommand: Search_V2_SlashCommandMeta.SlashCommandType { get }
    var hasSlashCommandType: Bool { get }
    var appLink: String { get }
    var hasAppLink: Bool { get }
    var description_p: String { get }
    var hasDescription_p: Bool { get }
    var tags: [Search_V2_SlashCommandMeta.SlashCommandTag] { get }
    var extra: String { get }
    var hasExtra: Bool { get }
    var imageURL: String { get }
}
public protocol SearchMetaCryptoP2PChatType: CommonChatterMetaType {
    var id: String { get }
    var customStatus: [Basic_V1_Chatter.ChatterCustomStatus] { get }
    var relationTag: Search_V2_TagData { get }
}
public protocol SearchMetaThreadType {
    var id: String { get }
    var channel: Basic_V1_Channel { get }
}
public protocol SearchMetaLinkType {
    var id: String { get }
    var chatID: String { get }
    var position: Int32 { get }
    var threadID: String { get }
    var threadPosition: Int32 { get }
    var originalURL: String { get }
    var fromName: String { get }
    var createTime: Int64 { get }
}
public protocol SearchMetaWikiType: SearchMetaDocType {
    var docMetaType: SearchMetaDocType { get }
}
public typealias SearchMetaDepartmentType = Search_V2_DepartmentMeta
public typealias SearchMetaMailType = Search_V1_SearchMailMeta

public typealias SearchScene = RustPB.Search_V1_Scene.TypeEnum

public typealias SearchHistoryType = RustPB.Search_V1_EntityType

public typealias SearchFeedback = RustPB.Search_V1_SearchFeedbackRequest.Feedback

// Integation Search
public typealias SearchChatterMeta = RustPB.Search_V1_SearchChatterMeta

public typealias SearchCryptoP2PChatMeta = RustPB.Search_V1_SearchCryptoP2PChatMeta

public typealias SearchChatMeta = RustPB.Search_V1_SearchChatMeta

public typealias SearchMessageMeta = RustPB.Search_V1_SearchMessageMeta

public typealias SearchDocMeta = RustPB.Search_V1_SearchDocMeta

public typealias SearchBoxMeta = RustPB.Search_V1_SearchBoxMeta

public typealias SearchOncallMeta = RustPB.Search_V1_SearchOncallMeta

public typealias SearchThreadMeta = RustPB.Search_V1_SearchThreadMeta

public typealias SearchOpenAppMeta = RustPB.Search_V1_SearchOpenAppMeta

public typealias SearchLinkMeta = RustPB.Search_V1_SearchLinkMeta

public typealias SearchWikiMeta = RustPB.Search_V1_SearchWikiMeta

public typealias SearchMailMeta = RustPB.Search_V1_SearchMailMeta

public typealias SearchExternalMeta = RustPB.Search_V1_SearchExternalMeta

public typealias ChatFilterParam = RustPB.Search_V1_ChatFilterParam

public typealias MessageFilterType = SearchHistoryMessageSubSource.TypeEnum

public typealias MessageAttachmentFilterType = RustPB.Basic_V1_Message.MessageAttachmentType

public typealias ChatFilterMode = Search_V1_ChatFilterParam.ChatMode

public typealias SearchActionType = RustPB.Basic_V1_Auth_ActionType

public typealias SearchDeniedReason = RustPB.Basic_V1_Auth_DeniedReason

public enum ChatFilterType {
    case unknowntab // = 0

    /// 私有群
    case `private` // = 1

    /// 外部群
    case outer // = 2

    /// 已加入的公共群
    case publicJoin // = 3

    /// 未加入的公共群
    case publicAbsent // = 4

    public init() {
        self = .unknowntab
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .unknowntab
        case 1: self = .private
        case 2: self = .outer
        case 3: self = .publicJoin
        case 4: self = .publicAbsent
        default: return nil
        }
    }

    public static var allCases: [ChatFilterType] {
        return [.unknowntab, .private, .outer, .publicJoin, .publicAbsent]
    }

}

public struct SearchCalendarMeta {
    public var eventKey: String
    public var calendarId: String
    public var originalTime: Int64
    public var startTime: Int64
    public var endTime: Int64
    public var isLarkEvent: Bool // lark or google event
    public var timeDisplay: String

    public init(
        eventKey: String,
        calendarId: String,
        originalTime: Int64,
        startTime: Int64,
        endTime: Int64,
        isLarkEvent: Bool,
        timeDisplay: String
    ) {
        self.eventKey = eventKey
        self.calendarId = calendarId
        self.originalTime = originalTime
        self.startTime = startTime
        self.endTime = endTime
        self.isLarkEvent = isLarkEvent
        self.timeDisplay = timeDisplay
    }
}

public typealias SearchOpenAppAbility = RustPB.Search_V1_SearchOpenAppMeta.OpenAppAbility

public typealias SearchOpenAppBotAbility = RustPB.Search_V1_SearchOpenAppMeta.BotAbility

public typealias SearchResult = RustPB.Search_V1_SearchResult

public typealias SearchFilterParam = RustPB.Search_V1_IntegrationSearchRequest.FilterParam

public typealias CalendarSearchFilterParam = RustPB.Search_V1_CalendarFilterParam

public typealias SearchHistoryInfo = ServerPB_Usearch_QueryHistoryInfo

public typealias SearchHistoryInfoSource = ServerPB_Searches_SearchTabName

public typealias SearchHistoryMainSubSource = RustPB.Search_V1_SearchHistoryInfo.MainSubSource

public typealias SearchHistoryMessageSubSource = RustPB.Search_V1_SearchHistoryInfo.MessageSubSource

public typealias SearchQueryState = RustPB.Search_V1_IntegrationSearchRequest.QueryState

public typealias ExternalSearch = RustPB.Basic_V1_ExternalSearch

public typealias ChatterMeta = RustPB.Tool_V1_ChatterMeta

public typealias Modifier = RustPB.Search_V1_Modifier

public enum SearchMeta {
    case chatter(SearchChatterMeta)
    case chat(SearchChatMeta)
    case message(SearchMessageMeta)
    case doc(SearchDocMeta)
    case email(SearchMessageMeta)
    case box(SearchBoxMeta)
    case oncall(SearchOncallMeta)
    case cryptoP2PChat(SearchCryptoP2PChatMeta)
    case shieldP2PChat(Search_V2_ShieldP2PChatMeta)
    case thread(SearchThreadMeta)
    case openApp(Search_V2_AppMeta)
    case link(SearchLinkMeta)
    case external(Search_V1_SearchExternalMeta)
    case wiki(SearchWikiMeta)
    case workspace(Search_V2_WikiSpaceMeta)
    case calendar(SearchCalendarMeta)
    case mail(SearchMailMeta)
    case department(Search_V2_DepartmentMeta)
    case slash(Search_Slash_V1_SlashCommandMeta)
    case qaCard(Search_V2_QaCardMeta)
    case customization(Search_V2_CustomizationMeta)
    case mailContact(Search_V2_MailContactMeta)
}

public extension SearchMeta {
    var avatarID: String {
        switch self {
        case .chat(let chat): return chat.id
        case .thread(let thread): return thread.channel.id
        case .chatter(let chatter): return chatter.id
        case .oncall(let oncall): return oncall.id
        case .cryptoP2PChat(let chat): return chat.chatterID
        case .shieldP2PChat(let chat): return chat.chatterID
        default: return ""
        }
    }
}

public extension SearchResult {

    static func attributedText(
        attributedString: NSAttributedString,
        withHitTerms terms: [String],
        highlightColor: UIColor
    ) -> NSAttributedString {
        let text = attributedString.string
        let muAttributedString = NSMutableAttributedString(attributedString: attributedString)
        terms.forEach { (term) in
            var searchRange = NSRange(location: 0, length: text.count)
            let maxSearchTime = 10
            var searchTime = 0
            while searchRange.location < text.count, searchTime < maxSearchTime {
                searchTime += 1
                let foundRange = (text as NSString).range(of: term, options: [.caseInsensitive], range: searchRange)
                if foundRange.location != NSNotFound {
                    muAttributedString.addAttribute(.foregroundColor,
                                                    value: highlightColor,
                                                    range: foundRange)
                    searchRange.location = foundRange.location + foundRange.length
                    searchRange.length = text.count - searchRange.location
                } else {
                    break
                }
            }
        }
        let attString = NSAttributedString(attributedString: muAttributedString)
        return attString
    }

}

// Integation Search end

public extension SearchFeedback {
    static func feedBackWith(model: SearchHistoryModel, offset: Int32) -> SearchFeedback {
        var feedBack = SearchFeedback()
        feedBack.entityID = model.id
        feedBack.offset = offset
        feedBack.type = model.historyType
        return feedBack
    }
}

public protocol SearchHistoryModel {
    var id: String { get }
    var historyType: SearchHistoryType { get }
}

extension Chat: SearchHistoryModel {
    public var imageURL: String {
        return self.avatar.urls.first ?? ""
    }

    public var imageKey: String {
        return self.avatarKey
    }

    public var historyType: SearchHistoryType {
        return .chat
    }
}

extension Chatter: SearchHistoryModel {
    public var imageURL: String {
        return self.avatar.origin.urls.first ?? ""
    }

    public var imageKey: String {
        return self.avatarKey
    }

    public var historyType: SearchHistoryType {
        return .chatter
    }
}

public struct SelectBotInfo: Equatable {
    public static func == (lhs: SelectBotInfo, rhs: SelectBotInfo) -> Bool {
        return lhs.id == rhs.id
    }
    public let id: String
    /// 可能为空，使用方可能需要检查一下
    public let name: String
    public let avatarKey: String
    public init(id: String, avatarKey: String, name: String = "") {
        self.id = id
        self.avatarKey = avatarKey
        self.name = name
    }
}

public enum SearchChatterPickerItem: Equatable {
    public struct GeneralFilterOption {
        public var name: String, id: String
        public init(name: String, id: String) {
            self.name = name
            self.id = id
        }
    }
    case chatter(Chatter)
    case chatterMeta(ChatterMeta)
    case bot(SelectBotInfo)
    case searchResultType(SearchResultType)
    case filter(GeneralFilterOption)

    public var chatterID: String {
        switch self {
        case .chatter(let chatter):
            return chatter.id
        case .chatterMeta(let chatterMeta):
            return chatterMeta.id
        case .bot(let bot):
            return bot.id
        case .searchResultType(let result):
            return result.id
        case let .filter(option):
            return option.id
        }
    }

    public var name: String {
        switch self {
        case .chatter(let chatter):
            return chatter.name
        case .chatterMeta(let chatterMeta):
            return chatterMeta.name
        case .bot(let bot):
            return bot.name
        case .searchResultType(let result):
            return result.title.string
        case let .filter(option):
            return option.name
        }
    }

    public static func == (lhs: SearchChatterPickerItem, rhs: SearchChatterPickerItem) -> Bool {
        return lhs.chatterID == rhs.chatterID
    }

    public var avatarKey: String {
        switch self {
        case .chatter(let chatter):
            return chatter.avatarKey
        case .chatterMeta(let chatterMeta):
            return chatterMeta.avatarKey
        case .bot(let bot):
            return bot.avatarKey
        case .searchResultType(let result):
            return result.avatarKey
        case let .filter(option):
            return "" // filter 暂时没有头像
        }
    }

    public var id: String {
        return self.chatterID
    }
}

public struct SearchSetting {
    public let modifiers: [RustPB.Search_V1_Modifier]
    public init(modifiers: [RustPB.Search_V1_Modifier]) {
        self.modifiers = modifiers
    }
}

public enum DocFormatType: CaseIterable, Equatable {
    case all, doc, sheet, slide, slides, mindNote, bitale, file
}

public enum DocContentType: CaseIterable, Equatable {
    case fullContent, onlyComment, onlyTitle
}

public extension DocContentType {
    var pbType: Search_V1_DocFilterParam.DocSearchType {
        switch self {
        case .fullContent: return .fullText
        case .onlyComment: return .matchComment
        case .onlyTitle: return .title
        }
    }
}

public enum ThreadFilterType: CaseIterable, Equatable {
    case all, `public`, `private`
}

public extension ThreadFilterType {
    var chatTypes: [ChatFilterType] {
        switch self {
        case .private:
            return [.private]
        case .public:
            return [.publicJoin, .publicAbsent]
        default:
            return []
        }
    }
}

public extension Array where Element == ServerPB_Searches_ChatFilterParam.ChatType {
    var threadFilterType: ThreadFilterType {
        guard !self.isEmpty else { return .all }
        if self == [.private] {
            return .private
        }
        if !self.contains(.private) && !self.contains(.outer) {
            return .public
        }
        return .all
    }
}

public extension Array where Element == ChatFilterParam.ChatType {
    var threadFilterType: ThreadFilterType {
        guard !self.isEmpty else { return .all }
        if self == [.private] {
            return .private
        }
        if !self.contains(.private) && !self.contains(.outer) {
            return .public
        }
        return .all
    }
}

// 真正的用于展示不同搜索板块的scene，因为有一些板块在rust的scene是通用的，如小组/群组，都是searchChats 和 searchChatsInAdvanceScene, 话题/消息，都是searchMessages
public enum SearchSceneSection: Hashable {
    // 传入rustScene中的searchChats、searchMessages、searchChatsInAdvanceScene时
    // 大搜会根据fg判断是否要切分成小组和群组、话题和会话
    // 不切分或其他不走大搜相关流程的则默认搜全部
    case rustScene(SearchScene)
    // 大搜单搜话题消息
    case searchTopicOnly
    // 高级搜索单搜话题消息
    case searchTopicInAdvanceOnly
    // 单搜普通消息
    case searchMessageOnly
    // 大搜单搜普通会话
    case searchChatOnly
    // 大搜单搜小组会话
    case searchThreadOnly
    // 高级搜索搜小组会话
    case searchThreadInAdvanceOnly
    // 高级搜索搜普通会话
    case searchChatInAdvanceOnly
    // 员工服务卡片，包括精准QA和模糊卡片
    case searchServiceCard
    // 会话内搜索图片
    case searchResourceInChat
    // Block 卡片
    case searchBlock
    // SEARCH_DOC_COLLABORATOR
    case searchDocCollaborator
    // SEARCH_PLATFORM_FILTER_SCENE
    case searchPlatformFilter(String)
    // SPOTLIGHT
    case spotlight
    //SPOTLIGHT_CHAT
    case spotlightChat
    //SPOTLIGHT_CHATTER
    case spotlightChatter
    //SPOTLIGHT_App
    case spotlightApp
    /// im发送云文档
    case searchDocAndWiki
    ///  搜索人和群
    case searchUserAndGroupChat
}

public extension SearchSceneSection {
    var remoteRustScene: SearchScene {
        switch self {
        case .rustScene(let scene):
            return scene
        case .searchChatOnly, .searchThreadOnly:
            return .searchChats
        case .searchMessageOnly, .searchTopicInAdvanceOnly:
            return .searchMessages
        case .searchTopicOnly:
            return .searchThreadScene
        case .searchChatInAdvanceOnly, .searchThreadInAdvanceOnly:
            return .searchChatsInAdvanceScene
        case .searchServiceCard, .searchBlock:
            return .unknown
        case .searchResourceInChat, .searchDocCollaborator, .searchPlatformFilter:
            return .unknown
        case .spotlight, .spotlightChat, .spotlightChatter, .spotlightApp:
            return .unknown
        case .searchDocAndWiki, .searchUserAndGroupChat:
            return .unknown
        }
    }

    var localRustScene: SearchScene {
        switch self {
        case .searchTopicOnly:
            return .searchMessages
        case .searchChatInAdvanceOnly, .searchThreadInAdvanceOnly:
            return .searchChats
        case .rustScene(let scene):
            switch scene {
            case .searchChatsInAdvanceScene:
                return .searchChats
            @unknown default:
                return scene
            }
        default:
            return remoteRustScene
        }
    }

    var chatFilterModes: [ChatFilterMode]? {
        switch self {
        case .searchChatOnly, .searchChatInAdvanceOnly, .searchMessageOnly:
            return [.normal]
        case .searchThreadOnly, .searchThreadInAdvanceOnly, .searchTopicOnly, .searchTopicInAdvanceOnly:
            return [.thread]
        default:
            return nil
        }
    }

    //日程 邮箱 PANO不处理
    var searchActionTabName: Search_Common_SearchTabName {
        switch self {
        case .rustScene(.smartSearch):
            return .smartSearchTab
        //消息类型下会，切换消息类型，会切换rust的搜索场景
        case .rustScene(.searchMessages), .rustScene(.searchLinkScene), .rustScene(.searchFileScene):
            return .messageTab
        case .rustScene(.searchDoc):
            return .docsTab
        case .rustScene(.searchOpenAppScene):
            return .appTab
        case .rustScene(.searchChatters):
            return .chatterTab
        case .rustScene(.searchChatsInAdvanceScene):
            return .chatTab
        case .rustScene(.searchOncallScene):
            return .helpdeskTab
        case .rustScene(.searchOpenSearchScene):
            return .openSearchTab
        default:
            return .unknownTab
        }
    }
}
