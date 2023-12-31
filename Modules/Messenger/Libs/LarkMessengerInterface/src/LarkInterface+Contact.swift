//
//  LarkInterface+Contact.swift
//  LarkContainer
//
//  Created by Sylar on 2018/4/15.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import EENavigator
import SuiteCodable
import LarkSnsShare
import LarkUIKit
import RxRelay
import LarkStorage
import RustPB
import LarkSDKInterface

public struct BlockStatusModel: Equatable {
    public var userId: String
    public var isHasBlock: Bool
    public var isHasBeBlock: Bool

    public init(userId: String = "",
                isHasBlock: Bool = false,
                isHasBeBlock: Bool = false) {
        self.userId = userId
        self.isHasBlock = isHasBlock
        self.isHasBeBlock = isHasBeBlock
    }
}

public struct UserRelationModel: Equatable {
    public var userId: String
    public var isFriend: Bool
    public var isOwner: Bool
    public var isHasApply: Bool
    public var isHasBlock: Bool
    public var isHasBeBlock: Bool
    public var isRecieveApply: Bool
    public var isCtrlAddContact: Bool
    public var beAppliedReason: String?
    // 是否是关联组织成员
    public var isAssociatedOrignazationMember: Bool

    public init(userId: String = "",
                isFriend: Bool = false,
                isOwner: Bool = false,
                isHasBlock: Bool = false,
                isHasBeBlock: Bool = false,
                isHasApply: Bool = false,
                isRecieveApply: Bool = false,
                isCtrlAddContact: Bool = false,
                isAssociatedOrignazationMember: Bool = false,
                beAppliedReason: String? = nil) {
        self.userId = userId
        self.isFriend = isFriend
        self.isOwner = isOwner
        self.isHasApply = isHasApply
        self.isHasBlock = isHasBlock
        self.isHasBeBlock = isHasBeBlock
        self.isRecieveApply = isRecieveApply
        self.isCtrlAddContact = isCtrlAddContact
        self.isAssociatedOrignazationMember = isAssociatedOrignazationMember
        self.beAppliedReason = beAppliedReason
    }

    public static func == (lhs: UserRelationModel, rhs: UserRelationModel) -> Bool {
        return lhs.isFriend == rhs.isFriend
            && lhs.isOwner == rhs.isOwner
            && lhs.isHasApply == rhs.isHasApply
            && lhs.isHasBlock == rhs.isHasBlock
            && lhs.isRecieveApply == rhs.isRecieveApply
            && lhs.isCtrlAddContact == rhs.isCtrlAddContact
            && lhs.beAppliedReason == rhs.beAppliedReason
    }
}

public struct ExternalBannerModel: Equatable {
    public var userRelationModel: UserRelationModel
    public var avatarKey: String?

    public init(userRelationModel: UserRelationModel = UserRelationModel(),
                avatarKey: String? = nil) {
        self.userRelationModel = userRelationModel
        self.avatarKey = avatarKey
    }

    public static func == (lhs: ExternalBannerModel, rhs: ExternalBannerModel) -> Bool {
        return lhs.userRelationModel == rhs.userRelationModel
            && lhs.avatarKey == rhs.avatarKey
    }
}

// 联系人控件服务
public protocol ContactControlService {
    // 获取是否展示unblock按钮
    func getIsShowUnBlock(chat: Chat) -> Bool?
    // 获取是否展示unblock按钮的序列
    func getIsShowUnBlockObservable(chat: Chat) -> Observable<Bool>?
    // 获取是否展示block/unblock状态下的视图变化
    func getIsShowBlockStatusControlChange(chat: Chat) -> Bool?
    // 获取banner模型的序列
    func getExternalBannerModelObservable(chat: Chat) -> Observable<ExternalBannerModel>?
    // 获取是否能打开红包页面
    func getCanOpenRedPacketPage(chat: Chat) -> Bool?
}

// 用户关系的服务
public protocol UserRelationService {
    // 获取/缓存外部联系人block关系的序列
    func getAndStashBlockStatusBehaviorRelay(chat: Chat) -> BehaviorRelay<BlockStatusModel>?
    // 移除外部联系人block关系的序列
    @discardableResult
    func removeBlockStatusBehaviorRelay(userId: String) -> Bool

    // 获取/缓存用户关系的序列
    func getAndStashUserRelationModelBehaviorRelay(chat: Chat) -> BehaviorRelay<UserRelationModel>?
    // 移除缓存用户关系的序列
    @discardableResult
    func removeUserRelationBehaviorRelay(userId: String) -> Bool
}

public struct DataOptions: OptionSet {
    public let rawValue: UInt
    public static let group = DataOptions(rawValue: 1 << 0)
    public static let robot = DataOptions(rawValue: 1 << 1)
    public static let onCall = DataOptions(rawValue: 1 << 2)
    public static let external = DataOptions(rawValue: 1 << 4)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

public struct ContactOptPickerModel {
    // 选中主动屏蔽的联系人的toast文案
    public var blockTip: String?
    // 选中被屏蔽的联系人的toast文案
    public var beBlockedTip: String?

    public init(blockTip: String? = nil,
                beBlockedTip: String? = nil) {
        self.blockTip = blockTip
        self.beBlockedTip = beBlockedTip
    }
}

public struct CreateGroupContext {
    public var name: String = ""
    public var desc: String = ""
    public var chatMode: Chat.ChatMode = .default
    public var isPublic: Bool = false
    public var isCrypto: Bool = false
    /// 密盾聊
    public var isPrivateMode: Bool = false
    public var isExternal: Bool = false
    public var count: Int = 0
    public var modeType: String = ""

    public init() {}
}

// MARK: - LarkContact Picker

public enum NewDepartmentViewControllerStyle: Equatable {
    /// callbackWithReset:目前即便单选模式下，数据源都是累加的，如果单选finish后选择界面不消失，后面再次单选操作，之前的数据也会存在数据源中，
    /// 所以提供callbackWithReset模式，单选每次finish后reset一下数据源。后面对接chatterpicker后，单选行为变为了只保留最近选择数据。无论清空还是保留最近数据感
    /// 觉都可以，单选可以理解为一种点击->消费的瞬时行为、每次select/finish都是独立的，只要保证数据不会出现多个，留不留都可以
    public enum SingleSelectStyle {
        case callback, defaultRoute, callbackWithReset
    }
    case single(style: SingleSelectStyle), multi, singleMultiChangeable
    public static func == (lhs: NewDepartmentViewControllerStyle, rhs: NewDepartmentViewControllerStyle) -> Bool {
        switch (lhs, rhs) {
        case (.multi, .multi),
             (.singleMultiChangeable, .singleMultiChangeable):
            return true
        case (.single(let lt), .single(let rt)):
            return lt == rt
        default: return false
        }
    }
}

public struct SelectChatterInfo: Equatable {
    public static func == (lhs: SelectChatterInfo, rhs: SelectChatterInfo) -> Bool {
        return lhs.ID == rhs.ID
    }

    public let ID: String
    public var name: String = ""
    /// 本地化后的真实姓名
    public var localizedRealName: String = ""
    public var avatarKey: String = ""
    public var isExternal: Bool = false
    public var deniedReason: RustPB.Basic_V1_Auth_DeniedReason?
    public var email: String = ""
    public var isInTeam: Bool?

    public var isBlocked: Bool {
        if let reason = self.deniedReason, reason == .beBlocked || reason == .blocked {
            return true
        }
        return false
    }

    public var isNotFriend: Bool {
        if let reason = self.deniedReason, reason == .noFriendship {
            return true
        }
        return false
    }

    public init(ID: String) {
        self.ID = ID
    }
}

public struct SelectChatInfo: Equatable {
    public static func == (lhs: SelectChatInfo, rhs: SelectChatInfo) -> Bool {
        return lhs.id == rhs.id
    }

    public let id: String
    public let name: String
    public let avatarKey: String
    public let chatUserCount: Int32
    public let chatDescription: String
    public var isInTeam: Bool?
    public var crossTenant: Bool?
    public init(id: String, name: String = "", avatarKey: String = "", chatUserCount: Int32 = 0, chatDescription: String = "") {
        self.init(id: id, name: name, avatarKey: avatarKey, chatUserCount: chatUserCount, chatDescription: chatDescription, crossTenant: nil)
    }

    public init(id: String, name: String = "", avatarKey: String = "", chatUserCount: Int32 = 0, chatDescription: String = "", crossTenant: Bool?) {
        self.id = id
        self.name = name
        self.avatarKey = avatarKey
        self.chatUserCount = chatUserCount
        self.chatDescription = chatDescription
        self.crossTenant = crossTenant
    }
}

public struct SelectDepartmentInfo: Equatable {
    public static func == (lhs: SelectDepartmentInfo, rhs: SelectDepartmentInfo) -> Bool {
        return lhs.id == rhs.id
    }
    public let id: String
    /// 可能为空，使用方可能需要检查一下
    public var name: String
    public init(id: String, name: String = "") {
        self.id = id
        self.name = name
    }
}

public struct SelectMailInfo: Equatable {
    public enum ContactType: Int {
        case unknown = 0
        case chatter
        case group
        case external
        case nameCard
        case sharedMailbox
        case mailGroup
        case noneType
    }

    public var displayName: String
    public var avatarKey: String
    public var email: String
    public var entityId: String
    public var type: ContactType

    public static func == (lhs: SelectMailInfo, rhs: SelectMailInfo) -> Bool {
        return lhs.email == rhs.email
    }

    public init(displayName: String, avatarKey: String, email: String, entityId: String, type: ContactType) {
        self.displayName = displayName
        self.avatarKey = avatarKey
        self.email = email
        self.entityId = entityId
        self.type = type
    }
}

public struct ContactPickerResult {
    public let chatterInfos: [SelectChatterInfo]
    public let botInfos: [SelectBotInfo]
    public let chatInfos: [SelectChatInfo]
    public let departments: [SelectDepartmentInfo]
    public let mails: [String]
    public let meetingGroupChatIds: [String]
    public let mailContacts: [SelectMailInfo]
    public let isRecommendSelected: Bool
    public let extra: Any?

    public var chatIds: [String] { chatInfos.map { $0.id } }
    public var departmentIds: [String] { departments.map { $0.id } }

    public init(
        chatterInfos: [SelectChatterInfo],
        botInfos: [SelectBotInfo],
        chatInfos: [SelectChatInfo],
        departments: [SelectDepartmentInfo],
        mails: [String],
        meetingGroupChatIds: [String],
        mailContacts: [SelectMailInfo],
        isRecommendSelected: Bool = false,
        extra: Any?
    ) {
        self.chatterInfos = chatterInfos
        self.botInfos = botInfos
        self.chatInfos = chatInfos
        self.departments = departments
        self.mails = mails
        self.meetingGroupChatIds = meetingGroupChatIds
        self.mailContacts = mailContacts
        self.isRecommendSelected = isRecommendSelected
        self.extra = extra
    }
}

public enum CalendarMemberActionStyle {
    case titleConfirmAction // 顶部显示「 确定（人数）」
    case footerShareAction  // 底部显示「 已选（人数）+ 分享 」
    case footerNextAction  // 底部显示「 已选（人数）+ 下一步 」
    case footerNextSkipAction // 底部显示「 已选（人数）+ 下一步 + 左上角跳过 」
}

public struct ContactSearchPickerBody: PlainBody {
    public static let pattern = "//client/contact/contactSearchPicker"

    public var featureConfig = PickerFeatureConfig()
    public var searchConfig = PickerSearchConfig(entities: [
        PickerConfig.ChatterEntityConfig(),
        PickerConfig.ChatEntityConfig()
    ])
    public var contactConfig = PickerContactViewConfig(entries: [
        PickerContactViewConfig.OwnedGroup(),
        PickerContactViewConfig.External(),
        PickerContactViewConfig.Organization()
    ])
    public weak var delegate: SearchPickerDelegate?

    public init() {}
}

public struct CalendarChatterPickerBody: PlainBody {
    public static let pattern = "//client/contact/calendarChatterPicker"

    public var title: String = ""
    public var searchPlaceholder: String?
    public var allowSelectNone: Bool = false
    public var forceSelectedChatterIds: [String] = []
    public var defaultSelectedChatterIds: [String] = []
    public var forceSelectedChatIds: [String] = []
    public var defaultSelectedChatIds: [String] = []
    public var forceSelectedMailContactIds: [String] = []
    public var defaultSelectedMailContactIds: [String] = []
    public var selectedCallback: ((UINavigationController, ContactPickerResult) -> Void)?
    public var cancelCallback: (() -> Void)?
    public var selectStyle: NewDepartmentViewControllerStyle = .multi
    public var needSearchOuterTenant: Bool = true
    public var needSearchMail: Bool = false
    public var enableEmailContact: Bool = false
    public var eventSearchMeetingGroup: Bool = false
    public var checkInvitePermission: Bool = false
    public var enableSearchingOuterTenant: Bool = false

    /// 是否支持选择群组和部门
    public var supportSelectGroup: Bool = true // 日历以前就可以选群，默认保持一致
    public var supportSelectOrganization: Bool = false

    // 联系人优化模型
    public var contactOptPickerModel = ContactOptPickerModel()

    public init() {}
}

public struct MailChatterPickerBody: PlainBody {
    public static let pattern = "//client/contact/mailChatterPicker"

    public var title: String = ""
    public var allowSelectNone: Bool = false
    public var forceSelectedEmails: [String] = []
    public var defaultSelectedEmails: [String] = []
    public var selectedCallback: ((UIViewController?, ContactPickerResult) -> Void)?
    public var cancelCallback: (() -> Void)?
    public var selectStyle: NewDepartmentViewControllerStyle = .multi
    public var maxSelectCount: Int = 500
    public var selectedCount: Int = 0
    public var mailAccount: Email_Client_V1_MailAccount?
    public var pickerDepartmentFG: Bool = false
    public init() {}
}

public struct MailGroupChatterPickerBody: PlainBody {
    public enum GroupRole {
        case member
        case manager
        case permission
    }

    public static let pattern = "//client/contact/MailGroupChatterPickerBody"

    public var title: String = ""
    public var allowSelectNone: Bool = false
    public var forceSelectedEmails: [String] = []
    public var defaultSelectedEmails: [String] = []
    public var selectedCallback: ((UIViewController?, ContactPickerResult) -> Void)?
    public var cancelCallback: (() -> Void)?
    public var selectStyle: NewDepartmentViewControllerStyle = .multi
    public var maxSelectCount: Int = 500
    public var groupId: Int
    public var groupRoleType: GroupRole
    public var accountID: String

    public init(groupId: Int, groupRoleType: GroupRole, accountID: String) {
        self.groupId = groupId
        self.groupRoleType = groupRoleType
        self.accountID = accountID
    }
}

public struct SelectChatterLimitInfo {
    public let max: Int
    public let warningTip: String
    public init(max: Int, warningTip: String) {
        self.max = max
        self.warningTip = warningTip
    }
}
public enum ChatterPickerSource {
    case addGroupMember // 群聊加人
    case p2p // 单聊加人
    case todo(TodoInfo)
    case other

    public final class TodoInfo {
        public var chatId: String?
        public var isAssignee: Bool
        public var isSelectAll: Bool
        public var isBatchAdd: Bool
        public var isDisableBatch: Bool
        public var onTapBatch: ((UIViewController) -> Void)?
        public var isShare: Bool

        public init(
            chatId: String?,
            isAssignee: Bool,
            isSelectAll: Bool = false,
            isBatchAdd: Bool = false,
            isDisableBatch: Bool = false,
            onTapBatch: ((UIViewController) -> Void)? = nil,
            isShare: Bool = false
        ) {
            self.chatId = chatId
            self.isAssignee = isAssignee
            self.isSelectAll = isSelectAll
            self.isBatchAdd = isBatchAdd
            self.isDisableBatch = isDisableBatch
            self.onTapBatch = onTapBatch
            self.isShare = isShare
        }
    }
}

public enum UserResignFilter: Int32 {
    /// 包含离职和未离职人员
    case all
    /// 仅包含离职人员
    case resigned
    /// 仅包含未离职人员
    case unresigned
}
public struct ChatterPickerBody: PlainBody {
    public static let pattern = "//client/contact/chatterPicker"

    public var showExternalContact: Bool?
    public var toolbarClass: AnyClass?
    /// needSearchOuterTenant会包含.external的section
    public var dataOptions: DataOptions = []
    public var title: String = ""
    public var supportCustomTitleView: Bool = false
    /// 是否可以展开数据源详情页
    public var supportUnfoldSelected: Bool = false
    /// 数据源为空是否可点击
    public var allowSelectNone: Bool = false
    /// 是否展示数据源个数
    public var allowDisplaySureNumber: Bool = true
    public var forceSelectedChatterIds: [String] = []
    public var forceSelectedChatId: String?
    public var defaultSelectedChatterIds: [String] = []
    public var selectedCallback: ((UIViewController?, ContactPickerResult) -> Void)?
    public var cancelCallback: (() -> Void)?
    public var selectStyle: NewDepartmentViewControllerStyle = .multi
    public var needSearchOuterTenant: Bool = true
    /// 是否过滤外部联系人
    public var filterOuterContact: Bool = false
    public var disabledSelectedChatterIds: [String] = []
    public var checkInvitePermission: Bool = false
    public var isCryptoModel: Bool = false
    /// 人员离职搜索情况
    public var userResignFilter: UserResignFilter?
    /// 是不是跨租户群
    public var isCrossTenantChat: Bool = false
    public var limitInfo: SelectChatterLimitInfo?
    /// 以C端用户的视角选择，如隐藏组织架构信息,只能看到外部联系人，目前只在单品内小B账号使用
    public var forceTreatAsCustomer: Bool = false
    /// 是否支持选择群组和部门
    public var supportSelectGroup: Bool = false
    public var supportSelectOrganization: Bool = false
    public var checkGroupPermissionForInvite: Bool = false
    public var checkOrganizationPermissionForInvite: Bool = false
    public var source: ChatterPickerSource = .other
    public var enableRelatedOrganizations: Bool = true
    /// 是否支持搜出机器人
    public var enableSearchBot: Bool = false
    /// 是否支持搜出MyAI
    public var enableMyAi: Bool = false
    /// 筛选器相关
    public var hasSearchFromFilterRecommend = false
    public var recommendList: [SearchResultType] = []
    public var targetPreview: Bool = true
    // 权限
    public var permissions: [RustPB.Basic_V1_Auth_ActionType]?

    public init() {}
}
/// 联系人picker选项的通用模型，后续picker在各种情况下的选项模型，都统一到这个协议上
public protocol PickerItemType {
    /// 用户id
    var id: String { get }
    /// 是否是外部用户
    var isCrossTenant: Bool { get }
    /// 是否是公开群组
    var isPublic: Bool { get }
    var isDepartment: Bool { get }
}

public protocol ChatterPickeSelectChatType {
    var selectedInfoId: String { get }
    var isCrossTenant: Bool { get }
    var isPublic: Bool { get }
    var isDepartment: Bool { get }
    var isMeeting: Bool { get }
    var isCrypto: Bool { get }
    var isPrivateMode: Bool { get }
}

/// 创建团队
/// 升级已有群组为团队
/// 添加团队成员
/// 绑定已有群组到团队
public struct TeamChatterPickerBody: PlainBody {
    public static let pattern = "//client/team/chatterPicker"

    /// 搜索框 placeholder
    public var searchPlaceholder: String = ""
    /// 水槽 tips
    public var waterChannelHeaderTitle: String?
    /// 主标题
    public var title: String = ""
    /// 默认副标题
    public var subTitle: String = ""
    /// 是否使用 picker 提供的副标题
    public var usePickerTitleView: Bool = false
    /// 是否可以展开数据源详情页
    public var supportUnfoldSelected: Bool = false
    /// 是否支持选择群组和部门
    public var supportSelectGroup: Bool = true
    public var supportSelectOrganization: Bool = false
    public var supportSelectChatter: Bool = true
    public var source: ChatterPickerSource = .other
    public var forceSelectedChatterIds: [String] = []
    public var forceSelectedChatId: String?
    public var defaultSelectedResult: ContactPickerResult?
    public var selectedCallback: ((UIViewController?, ContactPickerResult) -> Void)?
    public var cancelCallback: (() -> Void)?
    public var selectStyle: NewDepartmentViewControllerStyle = .multi
    public var customLeftBarButtonItem: Bool = false
    public var hideRightNaviBarItem: Bool = false
    public var disabledSelectedChatterIds: [String] = []
    /// WIP: 配置Picker的搜索内容
    public var pickerContentConfigurations: [PickerContentConfigType] = []
    /// 是否可以搜到密盾聊
    public var includeShieldGroup: Bool = false

    /// 对于所选 Chat 鉴权
    public var checkChatDeniedReasonForDisabledPick: ((ChatterPickeSelectChatType) -> Bool)?
    public var checkChatDeniedReasonForWillSelected: ((ChatterPickeSelectChatType, UIViewController) -> Bool)?
    /// 对于所选 Chatter 鉴权
    public var checkChatterDeniedReasonForDisabledPick: ((_ isExternal: Bool) -> Bool)?
    public var checkChatterDeniedReasonForWillSelected: ((_ isExternal: Bool, UIViewController) -> Bool)?
    public var itemDisableBehavior: ((SearchOption) -> Bool)?
    public var itemDisableSelectedToastBehavior: ((SearchOption) -> String?)?
    public init() {}
}

public struct CreateGroupPickBody: PlainBody {
    public static let pattern = "//client/contact/create/group/pick"

    public var forceSelectedChatterIds: [String] = []
    public var selectCallback: ((CreateGroupContext?, CreateGroupResult, UIViewController) -> Void)?
    /// 显示'选择已有群聊'
    public var isShowGroup: Bool = true

    /// 是否能创建密聊
    public var canCreateSecretChat: Bool = true
    /// 是否能创建话题群
    public var canCreateThread: Bool = true
    /// 是否能创建密盾聊
    public var canCreatePrivateChat: Bool = true
    /// 是否能查看和搜索外部联系人
    public var needSearchOuterTenant: Bool = true
    /// 从什么渠道建群
    public var from: CreateGroupFromWhere = .unknown
    /// 可传入创建情况下，确认按钮自定义文案(历史原因，广场场景，该文案要写死为“下一步”，逻辑要尽快下掉 @liluobin)
    public var createConfirmButtonTitle: String?
    /// 可传入title
    public var title: String?
    /// 是否可目标预览
    public var targetPreview: Bool = false
    public init() {}
}

public enum CreateGroupResult {
    case department(String)
    case pickEntities(CreateGroupPickEntities)

    public struct CreateGroupPickEntities {
        public let chatters: [SelectChatterInfo]
        public let chats: [String]
        public let departments: [String]
        public init(chatters: [SelectChatterInfo],
                    chats: [String],
                    departments: [String]) {
            self.chatters = chatters
            self.chats = chats
            self.departments = departments
        }
    }
}

public struct ContactApplicationsBody: CodablePlainBody {
    public static let pattern = "//client/contact/applications"

    public init() {}
}

public enum PersonCardFromWhere: String, Codable, HasDefault {
    case none
    /// LarkSearch、添加朋友搜索界面
    case search
    /// 邀请朋友
    case invitation
    /// from chat
    case chat
    /// from thread
    case thread
    /// 机器人已被添加到群，支持删除
    case groupBotToRemove
    /// 机器人未被添加到群，支持添加
    case groupBotToAdd

    public static func `default`() -> PersonCardFromWhere {
        return .none
    }
}

public struct ProfileCardBody: PlainBody {
    public static let pattern = "//client/contact/profilecard"

    public let userProfile: UserProfile?
    public let fromWhere: PersonCardFromWhere

    public init(userProfile: UserProfile?, fromWhere: PersonCardFromWhere) {
        self.userProfile = userProfile
        self.fromWhere = fromWhere
    }
}

public struct NameCardProfileBody: PlainBody {
    public static let pattern = "//client/contact/namecardprofile"

    /// name card 跳转profile
    ///  name card 所属邮箱账号 id
    public let accountId: String
    /// 使用emial地址跳转
    public let email: String
    /// 使用namecardId跳转
    public let namecardId: String
    /// 可以附带用户姓名信息
    public let userName: String

    public let callback: ((Bool) -> Void)?

    public init(accountId: String, email: String = "", namecardId: String = "", userName: String = "", callback: ((Bool) -> Void)? = nil) {
        self.accountId = accountId
        self.email = email
        self.namecardId = namecardId
        self.userName = userName
        self.callback = callback
    }
}

public struct PersonCardLinkBody: CodableBody {
    private static let prefix = "//client/profile"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)")
    }

    public var _url: URL {
        if !uid.isEmpty {
            return URL(string: "\(PersonCardLinkBody.prefix)/\(uid)") ?? .init(fileURLWithPath: "")
        } else if !token.isEmpty {
            return URL(string: "\(PersonCardLinkBody.prefix)/\(token)") ?? .init(fileURLWithPath: "")
        } else {
            return URL(string: "\(PersonCardLinkBody.prefix)") ?? .init(fileURLWithPath: "")
        }
    }

    public let token: String
    public let uid: String
    public let chatId: String
    /// PRD: https://bytedance.feishu.cn/docs/doccnlCxYN5ro5JkqkLmywQQ958#
    /// PB：https://review.byted.org/c/ee/lark/rust-sdk/+/1449540/4/im-protobuf-sdk/client/im/v1/chats.proto
    /// 发送来源
    public let sender: String
    /// 来源名称
    public let sourceName: String
    /// 来源类型
    public let source: RustPB.Basic_V1_ContactSource

    public init(uid: String = "",
                token: String = "",
                chatId: String = "",
                sender: String = "",
                sourceName: String = "",
                source: RustPB.Basic_V1_ContactSource = .unknownSource) {
        self.uid = uid
        self.chatId = chatId
        self.sender = sender
        self.sourceName = sourceName
        self.source = source
        self.token = token
    }
}

public extension Notification.Name {
    // 取消屏蔽之后刷新屏蔽名单
    static let cancelBlockedSetting: Notification.Name = Notification.Name("cancelBlockedSetting")
}

public struct PersonCardBody: CodableBody {

    private static let prefix = "//client/contact/personcard"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatterId", type: .path)
    }

    public var _url: URL {
        if let url = URL(string: "\(PersonCardBody.prefix)/\(chatterId)") {
            return url
        }

        /// http://t.wtturl.cn/eUwhfQK/ fix
        /// We will soon update EENavigator to fix this crash totally. @lichen
        if let url = URL(string: "\(PersonCardBody.prefix)/\(chatterId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed))") {
            return url
        }

        /// 以上兜底仍然会崩溃，再来一个兜底，不过点击已经不可跳转了，此处为了避免客户端能窥
        return URL(string: PersonCardBody.prefix) ?? .init(fileURLWithPath: "")
    }

    public let chatterId: String
    public let chatId: String
    public let fromWhere: PersonCardFromWhere

    /// PRD: https://bytedance.feishu.cn/docs/doccnlCxYN5ro5JkqkLmywQQ958#
    /// PB：https://review.byted.org/c/ee/lark/rust-sdk/+/1449540/4/im-protobuf-sdk/client/im/v1/chats.proto
    /// 发送来源ID
    public let senderID: String
    /// 发送来源
    public let sender: String
    /// 来源ID
    public let sourceID: String
    /// 来源名称
    public let sourceName: String
    /// 来源类型
    public let source: RustPB.Basic_V1_ContactSource
    /// source子类型，透传。例如：source_type为doc，sub_type可能会有doc，表格，思维导图
    public let subSourceType: String
    /// extra parameters
    public let extraParams: [String: String]?

    //profile页打开后，需要立即调整到设置页
    public var needToPushSetInformationViewController = false

    public init(chatterId: String,
                chatId: String = "",
                fromWhere: PersonCardFromWhere = .none,
                senderID: String = "",
                sender: String = "",
                sourceID: String = "",
                sourceName: String = "",
                subSourceType: String = "",
                source: RustPB.Basic_V1_ContactSource = .unknownSource,
                extraParams: [String: String]? = nil
    ) {
        self.chatterId = chatterId
        self.chatId = chatId
        self.fromWhere = fromWhere
        self.senderID = senderID
        self.sender = sender
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.source = source
        self.subSourceType = subSourceType
        self.extraParams = extraParams
    }
}

public struct MyAIProfileBody: CodableBody {
    private static let prefix = "//client/contact/myai/profile"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)", type: .path)
    }

    public var _url: URL {
        return URL(string: Self.prefix) ?? URL(fileURLWithPath: "")
    }

    public init() {}
}

public struct MyAISettingBody: CodableBody {
    private static let prefix = "//client/contact/myai/setting"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)", type: .path)
    }

    public let myAiId: String
    public var avatarKey: String
    public var name: String

    public var _url: URL {
        return URL(string: Self.prefix) ?? URL(fileURLWithPath: "")
    }

    public init(myAiId: String,
                avatarKey: String,
                name: String) {
        self.myAiId = myAiId
        self.name = name
        self.avatarKey = avatarKey
    }
}

public struct MyAIOnboardingBody: Body {
    private static let prefix = "//client/contact/myai/onboarding"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)", type: .path)
    }
    public var onSuccess: ((_ chatID: Int64) -> Void)?
    public var onError: ((_ error: Error?) -> Void)?
    public var onCancel: (() -> Void)?

    public var _url: URL {
        return URL(string: Self.prefix) ?? URL(fileURLWithPath: "")
    }

    public init(onSuccess: ((_ chatID: Int64) -> Void)?,
                onError: ((_ error: Error?) -> Void)? = nil,
                onCancel: (() -> Void)? = nil) {
        self.onSuccess = onSuccess
        self.onError = onError
        self.onCancel = onCancel
    }
}

public struct MyAIToolsBody: PlainBody {

    public typealias SelectToolsSureCallBack = (_ selectItems: [MyAIToolInfo]) -> Void

    public static var pattern: String = "//client/myai_extensions/select"
    public static var applinkPattern: String = "/client/myai_extensions/select"

    /// 已选toolIds
    public var selectedToolIds: [String]
    public var chat: Chat
    /// 场景，默认为IM
    public var scenario: String
    public var completionHandle: SelectToolsSureCallBack?
    public var closeHandler: (() -> Void)?
    /// 最大选择，nil 使用选择组件内部限制，0不限制 其他数字表示具体限制
    public var maxSelectCount: Int?
    public var aiChatModeId: Int64
    public var extra: [AnyHashable: Any]
    public var myAIPageService: MyAIPageService?

    public init(chat: Chat,
                scenario: String,
                selectedToolIds: [String] = [],
                completionHandle: SelectToolsSureCallBack? = nil,
                closeHandler: (() -> Void)? = nil,
                maxSelectCount: Int? = nil,
                aiChatModeId: Int64 = 0,
                myAIPageService: MyAIPageService? = nil,
                extra: [AnyHashable: Any] = [:] ) {
        self.chat = chat
        self.selectedToolIds = selectedToolIds
        self.scenario = scenario
        self.completionHandle = completionHandle
        self.closeHandler = closeHandler
        self.maxSelectCount = maxSelectCount
        self.aiChatModeId = aiChatModeId
        self.myAIPageService = myAIPageService
        self.extra = extra
    }
}

public struct MyAIToolsDetailBody: PlainBody {
    public static var pattern: String = "//client/MyAITools/detail"

    public let toolItem: MyAIToolInfo
    public let isSingleSelect: Bool
    public let chat: Chat
    public var myAIPageService: MyAIPageService?
    public let extra: [AnyHashable: Any]
    public let addToolHandler: ((MyAIToolInfo) -> Void)?

    public init(toolItem: MyAIToolInfo,
                isSingleSelect: Bool,
                chat: Chat,
                myAIPageService: MyAIPageService? = nil,
                extra: [AnyHashable: Any] = [:],
                addToolHandler: ((MyAIToolInfo) -> Void)? = nil) {
        self.toolItem = toolItem
        self.isSingleSelect = isSingleSelect
        self.chat = chat
        self.myAIPageService = myAIPageService
        self.extra = extra
        self.addToolHandler = addToolHandler
    }
}

public struct MyAIToolsSelectedBody: PlainBody {
    public static var pattern: String = "//client/MyAITools/selected"

    public var toolItems: [MyAIToolInfo]
    public var toolIds: [String]
    public var chat: Chat
    public var aiChatModeId: Int64
    public var myAIPageService: MyAIPageService?
    public let extra: [AnyHashable: Any]
    public var startNewTopicHandler: (() -> Void)?

    public init(toolItems: [MyAIToolInfo] = [],
                toolIds: [String] = [],
                chat: Chat,
                aiChatModeId: Int64 = 0,
                myAIPageService: MyAIPageService? = nil,
                extra: [AnyHashable: Any] = [:],
                startNewTopicHandler: (() -> Void)? = nil) {
        self.toolItems = toolItems
        self.toolIds = toolIds
        self.chat = chat
        self.aiChatModeId = aiChatModeId
        self.myAIPageService = myAIPageService
        self.extra = extra
        self.startNewTopicHandler = startNewTopicHandler
    }
}

public struct AddFriendBody: CodablePlainBody {
    public static let pattern = "//client/contact/add_friend"
    public static let applinkPattern = "/client/contact/add_friend"

    public let token: String

    /// PRD: https://bytedance.feishu.cn/docs/doccnlCxYN5ro5JkqkLmywQQ958#
    /// PB：https://review.byted.org/c/ee/lark/rust-sdk/+/1449540/4/im-protobuf-sdk/client/im/v1/chats.proto
    /// 发送来源
    public let sender: String
    /// 来源名称
    public let sourceName: String
    /// 来源类型
    public let source: RustPB.Basic_V1_ContactSource

    public init(token: String,
                sender: String = "",
                sourceName: String = "",
                source: RustPB.Basic_V1_ContactSource = .link) {
        self.token = token
        self.sender = sender
        self.sourceName = sourceName
        self.source = source
    }
}

public struct ApplyFriendSource {
    /// PRD: https://bytedance.feishu.cn/docs/doccnlCxYN5ro5JkqkLmywQQ958#
    /// PB：https://review.byted.org/c/ee/lark/rust-sdk/+/1449540/4/im-protobuf-sdk/client/im/v1/chats.proto
    /// 发送来源
    public var sender: String = ""
    /// 来源名称
    public var sourceName: String = ""
    /// 来源类型
    public var source: RustPB.Basic_V1_ContactSource = .unknownSource

    public init() {}
}

public struct MedalVCBody: CodablePlainBody {
    public static let pattern = "//client/profile/medal"
    public static let applinkPattern = "/client/profile/medal"

    public let userID: String

    public init(userID: String) {
        self.userID = userID
    }
}

public enum AddContactBusinessType: String {
    //拉群
    case groupConfirm = "group_confirm"
    //加急
    case buzzConfirm = "buzz_confirm"
    //单聊发送红包时confirm添加好友
    case hongBaoConfirm = "hongbao_confirm"
    //会话中邀约VC
    case chatVCConfirm = "chat_vc_confirm"
    //视频会议中邀约VC
    case vcOnGoingConfirm = "vc_ongoing_confirm"
    //日程中邀约参与人
    case eventConfirm = "event_confirm"
    //IM Banner中添加好友
    case bannerConfirm = "banner_confirm"
    //Onboarding中添加好友
    case onboardingConfirm = "onboarding_confirm"
    //在profile中点击添加好友
    case profileAdd = "profile_add"
    //单聊分享名片
    case shareConfirm = "share_confirm"
}

/// 添加好友使用 好友申请收口支持 token 和 user_id 两种维度的添加方式，二选一即可
public struct AddContactRelationBody: PlainBody {

    public static let pattern = "//client/contact/AddContactRelation"

    public var token: String?

    /// 这里如果chatId 可以获取到 尽量传入，一些特殊场景下添加好友需要使用
    public var chatId: String?

    public var userId: String?

    /// 来源信息
    public let source: Source
    /// 默认备注名
    public let userName: String
    /// 添加好友成功之后回调
    public let addContactBlock: ((_ userId: String?) -> Void)?

    /// 来自哪个业务 埋点需要
    public let businessType: AddContactBusinessType?

    /// 是否认证
    public let isAuth: Bool?
    /// 是否有认证
    public let hasAuth: Bool?
    // dissMiss添加好友页面后执行的任务
    public var dissmissBlock: (() -> Void)?

    public init(userId: String?,
                chatId: String?,
                token: String?,
                source: Source,
                addContactBlock: ((_ userId: String?) -> Void)?,
                userName: String,
                isAuth: Bool? = nil,
                hasAuth: Bool? = nil,
                businessType: AddContactBusinessType?) {
        self.userId = userId
        self.chatId = chatId
        self.token = token
        self.source = source
        self.isAuth = isAuth
        self.hasAuth = hasAuth
        self.addContactBlock = addContactBlock
        self.userName = userName
        self.businessType = businessType
    }

    public init(userId: String?,
                chatId: String?,
                token: String?,
                source: Source,
                addContactBlock: ((_ userId: String?) -> Void)?,
                userName: String,
                isAuth: Bool? = nil,
                hasAuth: Bool? = nil,
                businessType: AddContactBusinessType?,
                dissmissBlock: (() -> Void)? = nil) {
        self.userId = userId
        self.chatId = chatId
        self.token = token
        self.source = source
        self.isAuth = isAuth
        self.hasAuth = hasAuth
        self.addContactBlock = addContactBlock
        self.userName = userName
        self.businessType = businessType
        self.dissmissBlock = dissmissBlock
    }
}

/// 申请联系人沟通权限
public struct ApplyCommunicationPermissionBody: PlainBody {
    public enum FromType {
        case profile    // Profile页面
    }

    public static let pattern = "//client/communication_permission/apply"
    public static let applinkPattern = "/client/communication_permission/apply"

    /// PRD: https://bytedance.feishu.cn/docx/PJqbdTa8Ropls5xeQtschkZsnQe
    /// 来源来源名称
    public let type: FromType
    /// 来源类型
    public var dismissCallBack: ((Bool) -> Void)?
    public let userId: String

    public init(userId: String,
                type: FromType = .profile,
                dismissCallBack: ((Bool) -> Void)? = nil) {
        self.userId = userId
        self.type = type
        self.dismissCallBack = dismissCallBack
    }
}

/// 创建部门群
public struct CreateDepartmentGroupBody: PlainBody {
    public static var pattern: String = "//client/department_group/create"

    public let departmentId: String
    public let successCallBack: ((Chat) -> Void)?

    public init(departmentId: String, successCallBack: ((Chat) -> Void)?) {
        self.departmentId = departmentId
        self.successCallBack = successCallBack
    }
}

// 创群&聊天记录
public struct CreateGroupWithRecordBody: PlainBody {
    public enum FromType {
        case p2P    // 单聊建群
        case group  // 群聊添加外部成员
    }

    public static var pattern: String = "//client/group/create"

    public let type: FromType
    public let chatId: String
    public let selectedChatterIds: [String]
    public let selectedChatIds: [String]
    public let selectedDepartmentIds: [String]
    public weak var pickerController: UIViewController?
    public let syncMessage: Bool

    public init(p2pChatId: String) {
        self.type = .p2P
        self.chatId = p2pChatId
        self.selectedChatterIds = []
        self.selectedChatIds = []
        self.selectedDepartmentIds = []
        self.pickerController = nil
        self.syncMessage = false
    }

    public init(
        groupChatId: String,
        selectedChatterIds: [String],
        selectedChatIds: [String],
        selectedDepartmentIds: [String],
        pickerController: UIViewController,
        syncMessage: Bool) {
        self.type = .group
        self.chatId = groupChatId
        self.selectedChatterIds = selectedChatterIds
        self.selectedChatIds = selectedChatIds
        self.selectedDepartmentIds = selectedDepartmentIds
        self.pickerController = pickerController
        self.syncMessage = syncMessage
    }
}

// 面对面建群
public struct CreateGroupWithFaceToFaceBody: PlainBody {
    public enum FromType {
        case createGroup    // 发起群聊页面
        case externalContact // 添加外部联系人页面
    }

    public static var pattern: String = "//client/nearby/create"
    public let type: FromType

    public init(type: FromType) {
        self.type = type
    }
}

public enum InviteStorage {
    public static let invitationAccessKey = KVKey("member_invite_permission", default: false)
    public static let inviteAdministratorAccessKey = KVKey("member_invite_is_admin", default: false)
    public static let isAdministratorKey = KVKey("is_administrator", default: false)
}

/// 成员邀请相关页面的来源
public enum MemberInviteSourceScenes {
    case upgrade                      // 升级团队
    case newGuide                     // 新用户引导
    case updateBot                    // bot 引导个人使用转为团队使用
    case updateDialog                 // 弹框提示个人使用转为团队使用
    case invitePeopleUnion            // 邀请伙伴分流页
    case inviteMemberBanner           // 邀请成员 banner
    case contact                      // 联系人右上角
    case department                   // 组织架构右上角
    case sidecar                      // 首页侧边栏
    case urlLink                      // 外链跳转过来的
    case feedBanner                   // Feed升级团队引导
    case feedMenu                     // Feed右上角Menu
    case customizedSource(source: String)  // 自定义的动态场景(由外部传入)
    case larkGuide                    // Lark的引导流程
    case unknown                      // 未知场景

    public func toString() -> String {
        switch self {
        case .upgrade: return "upgrade"
        case .newGuide: return "new_guide"
        case .updateBot: return "update_bot"
        case .updateDialog: return "update_dialog"
        case .invitePeopleUnion: return "invite_people_union"
        case .inviteMemberBanner: return "invite_member_banner"
        case .contact: return "contact"
        case .department: return "department"
        case .sidecar: return "invite_sidecar_entry"
        case .urlLink: return "url_link"
        case .unknown: return "unknown"
        case .feedBanner: return "upgrade_team_banner"
        case .feedMenu: return "feed_menu"
        case .customizedSource(let source): return source
        case .larkGuide: return "lark_guide"
        }
    }

    public static func transform(_ source: String) -> MemberInviteSourceScenes {
        switch source {
        case "upgrade": return .upgrade
        case "new_guide": return .newGuide
        case "update_bot": return .updateBot
        case "update_dialog": return .updateDialog
        case "invite_people_union": return .invitePeopleUnion
        case "invite_member_banner": return .inviteMemberBanner
        case "contact": return .contact
        case "invite_sidecar_entry": return .sidecar
        case "department": return .department
        case "feed_menu": return .feedMenu
        case "url_link": return .urlLink
        case "unknown": return .unknown
        case "upgrade_team_banner": return .feedBanner
        case "lark_guide": return .larkGuide
        default: return .customizedSource(source: source)
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.toString() == rhs.toString()
    }
}

/// 统一邀请分流页面
public struct UnifiedInvitationBody: CodablePlainBody {
    public static let pattern = "//client/invite/unified"
    public static let applinkPattern = "/client/invite/unified"
    public var _url: URL {
        return URL(string: UnifiedInvitationBody.pattern) ?? .init(fileURLWithPath: "")
    }

    public init() {}
}

/// 智能决策统一邀请分流页面的路由(统一邀请or添加朋友)
public struct SmartUnifiedInvitationBody: CodablePlainBody {
    public static let pattern = "//client/invite/unifiedSmart"
    public static let applinkPattern = "/client/invite/unifiedSmart"
    public var _url: URL {
        return URL(string: UnifiedInvitationBody.pattern) ?? .init(fileURLWithPath: "")
    }

    public init() {}
}

/// 智能决策成员邀请目标页面的路由
public struct SmartMemberInviteBody: CodablePlainBody {
    public static let pattern = "//client/invite/memberSmart"
    public static let applinkPattern = "/client/invite/memberSmart"
    public var _url: URL {
        return URL(string: SmartMemberInviteBody.pattern) ?? .init(fileURLWithPath: "")
            .append(parameters: ["from": sourceScenes.toString(),
                                 "departments": departments.joined(separator: ",")])
    }

    public var sourceScenes: MemberInviteSourceScenes
    public let departments: [String]

    public init(sourceScenes: MemberInviteSourceScenes, departments: [String] = []) {
        self.sourceScenes = sourceScenes
        self.departments = departments
    }

    private enum _CodingKeys: String, CodingKey {
        case fromScenes
        case departments
    }

    public func encode(to encoder: Encoder) throws {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        if let source = try? container.decode(String.self, forKey: .fromScenes) {
            self.sourceScenes = MemberInviteSourceScenes.transform(source)
        } else {
            self.sourceScenes = .unknown
        }
        if let departmentsQuery = try? container.decode(String.self, forKey: .departments) {
            self.departments = departmentsQuery.components(separatedBy: ",")
        } else {
            self.departments = []
        }
    }
}

/// 国内成员邀请分流页
public struct MemberInviteSplitBody: CodablePlainBody {
    public static let pattern = "//client/invite/member/channel"
    public static let applinkPattern = "/client/invite/member/channel"

    public var _url: URL {
        return URL(string: MemberInviteSplitBody.pattern) ?? .init(fileURLWithPath: "")
            .append(parameters: ["from": sourceScenes.toString(),
                                 "departments": departments.joined(separator: ",")])
    }

    public let sourceScenes: MemberInviteSourceScenes
    public let departments: [String]
    // 在引导流程中，需要额外定制右上角按钮的行为和标题，其他场景可不传
    public var rightButtonTitle: String?
    public var rightButtonClickHandler: (() -> Void)?

    public init(sourceScenes: MemberInviteSourceScenes, departments: [String] = []) {
        self.sourceScenes = sourceScenes
        self.departments = departments
    }

    private enum _CodingKeys: String, CodingKey {
        case fromScenes
        case departments
    }

    public func encode(to encoder: Encoder) throws {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        if let source = try? container.decode(String.self, forKey: .fromScenes) {
            self.sourceScenes = MemberInviteSourceScenes.transform(source)
        } else {
            self.sourceScenes = .unknown
        }
        if let departmentsQuery = try? container.decode(String.self, forKey: .departments) {
            self.departments = departmentsQuery.components(separatedBy: ",")
        } else {
            self.departments = []
        }
    }
}

/// 海外成员邀请分流页
public struct MemberInviteLarkSplitBody: CodablePlainBody {
    public static let pattern = "//client/invite/member/channelLark"
    public static let applinkPattern = "/client/invite/member/channelLark"

    public var _url: URL {
        return URL(string: MemberInviteLarkSplitBody.pattern) ?? .init(fileURLWithPath: "")
            .append(parameters: ["from": sourceScenes.toString(),
                                 "departments": departments.joined(separator: ",")])
    }

    public let sourceScenes: MemberInviteSourceScenes
    public let departments: [String]
    // 在引导流程中，需要额外定制右上角按钮的行为和标题，其他场景可不传
    public var rightButtonTitle: String?
    public var rightButtonClickHandler: (() -> Void)?

    public init(sourceScenes: MemberInviteSourceScenes, departments: [String] = []) {
        self.sourceScenes = sourceScenes
        self.departments = departments
    }

    private enum _CodingKeys: String, CodingKey {
        case fromScenes
        case departments
    }

    public func encode(to encoder: Encoder) throws {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        if let source = try? container.decode(String.self, forKey: .fromScenes) {
            self.sourceScenes = MemberInviteSourceScenes.transform(source)
        } else {
            self.sourceScenes = .unknown
        }
        if let departmentsQuery = try? container.decode(String.self, forKey: .departments) {
            self.departments = departmentsQuery.components(separatedBy: ",")
        } else {
            self.departments = []
        }
    }
}

/// 企业成员定向邀请页面
public enum MemberInviteNeedShowType: Int {
    case email
    case phone
    case all
}

public struct MemberDirectedInviteBody: CodablePlainBody {
    public static let pattern = "//client/invite/member"
    public static let applinkPattern = "/client/invite/member"

    public var _url: URL {
        return URL(string: MemberDirectedInviteBody.pattern) ?? .init(fileURLWithPath: "")
            .append(parameters: ["from": sourceScenes.toString(),
                                 "is_from_invite_split_page": String(isFromInviteSplitPage),
                                 "departments": departments.joined(separator: ",")])
    }

    private enum _CodingKeys: String, CodingKey {
        case fromScenes
        case departments
    }

    public let sourceScenes: MemberInviteSourceScenes
    public let isFromInviteSplitPage: Bool
    public let departments: [String]
    public let needShowType: MemberInviteNeedShowType
    // 在引导流程中，需要额外定制右上角按钮的行为和标题，其他场景可不传
    public var rightButtonTitle: String?
    public var rightButtonClickHandler: (() -> Void)?

    public init(sourceScenes: MemberInviteSourceScenes,
                isFromInviteSplitPage: Bool,
                departments: [String],
                needShowType: MemberInviteNeedShowType? = .all) {
        self.sourceScenes = sourceScenes
        self.isFromInviteSplitPage = isFromInviteSplitPage
        self.departments = departments
        self.needShowType = needShowType ?? .all
    }

    public func encode(to encoder: Encoder) throws {}

    public init(from decoder: Decoder) throws {
        self.isFromInviteSplitPage = false
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        if let source = try? container.decode(String.self, forKey: .fromScenes) {
            self.sourceScenes = MemberInviteSourceScenes.transform(source)
        } else {
            self.sourceScenes = .unknown
        }
        if let departmentsQuery = try? container.decode(String.self, forKey: .departments) {
            self.departments = departmentsQuery.components(separatedBy: ",")
        } else {
            self.departments = []
        }
        self.needShowType = .all
    }
}

/// 企业成员非定向邀请页面
public typealias MemberNoDirectionalDisplayPriority = MemberNoDirectionalBody.DisplayPriority
public struct MemberNoDirectionalBody: CodablePlainBody {
    public static let pattern = "//client/invite/member/share"
    public static let applinkPattern = "/client/invite/member/share"

    public var _url: URL {
        return URL(string: MemberNoDirectionalBody.pattern) ?? .init(fileURLWithPath: "")
            .append(parameters: ["from": sourceScenes.toString(),
                                 "type": displayPriority.rawValue,
                                 "departments": departments.joined(separator: ",")])
    }

    public enum DisplayPriority: String, Codable {
        case qrCode = "qr_code"
        case inviteLink = "link"

        public static func transform(_ type: String) -> DisplayPriority {
            return DisplayPriority(rawValue: type) ?? .qrCode
        }
    }

    public let sourceScenes: MemberInviteSourceScenes
    public let displayPriority: DisplayPriority
    public let departments: [String]

    public init(displayPriority: DisplayPriority,
                sourceScenes: MemberInviteSourceScenes,
                departments: [String]) {
        self.displayPriority = displayPriority
        self.sourceScenes = sourceScenes
        self.departments = departments
    }

    private enum _CodingKeys: String, CodingKey {
        case displayPriority
        case fromScenes
        case departments
    }

    public func encode(to encoder: Encoder) throws {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        if let source = try? container.decode(String.self, forKey: .fromScenes) {
            self.sourceScenes = MemberInviteSourceScenes.transform(source)
        } else {
            self.sourceScenes = .unknown
        }
        if let priority = try? container.decode(String.self, forKey: .displayPriority) {
            self.displayPriority = DisplayPriority(rawValue: priority) ?? .qrCode
        } else {
            self.displayPriority = .qrCode
        }
        if let departmentsQuery = try? container.decode(String.self, forKey: .departments) {
            self.departments = departmentsQuery.components(separatedBy: ",")
        } else {
            self.departments = []
        }
    }
}

/// 团队码邀请页
public struct TeamCodeInviteBody: CodablePlainBody {
    public static let pattern = "//client/invite/member/teamcode"
    public static let applinkPattern = "/client/invite/member/teamcode"

    private enum _CodingKeys: String, CodingKey {
        case fromScenes
        case departments
    }

    public var _url: URL {
        return URL(string: TeamCodeInviteBody.pattern) ?? .init(fileURLWithPath: "")
            .append(parameters: ["from": sourceScenes.toString(),
                                 "departments": departments.joined(separator: ",")])
    }
    public let sourceScenes: MemberInviteSourceScenes
    public let departments: [String]

    public init(sourceScenes: MemberInviteSourceScenes, departments: [String]) {
        self.sourceScenes = sourceScenes
        self.departments = departments
    }

    public func encode(to encoder: Encoder) throws {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        if let source = try? container.decode(String.self, forKey: .fromScenes) {
            self.sourceScenes = MemberInviteSourceScenes.transform(source)
        } else {
            self.sourceScenes = .unknown
        }
        if let departmentsQuery = try? container.decode(String.self, forKey: .departments) {
            self.departments = departmentsQuery.components(separatedBy: ",")
        } else {
            self.departments = []
        }
    }
}

/// 成员邀请引导页
public enum MemberInviteGuideType: String {
    case ldr     ///  LDR
    case qrcode  /// 二维码方式
    case link    /// 链接
    case split   /// lark 下用这种，分享链接、或者发送邮件、导通讯录
}

public struct MemberInviteGuideBody: PlainBody {
    public static let pattern = "//client/invite/member/guide"
    public var _url: URL {
        return URL(string: MemberInviteGuideBody.pattern) ?? .init(fileURLWithPath: "")
    }

    public let inviteType: MemberInviteGuideType

    public init(inviteType: MemberInviteGuideType? = .qrcode) {
        self.inviteType = inviteType ?? .qrcode
    }
}

public enum ExternalInviteSourceEntrance: Hashable, Codable {
    enum CodingKeys: String, CodingKey {
        case fromScenes = "from_scenes"
    }

    public func encode(to encoder: Encoder) throws {}

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let source = try? container.decode(String.self, forKey: .fromScenes) {
            self = ExternalInviteSourceEntrance.transform(source)
        } else {
            self = .unknown
        }
    }

    case feedMenu
    case contact
    case contactExternal
    case contactNew
    case profile
    case edit_profile
    case onboarding
    case customizedSource(source: String)
    case unknown

    public var rawValue: String {
        switch self {
        case .feedMenu: return "feed_menu"
        case .contact: return "contact"
        case .contactExternal: return "contact_external"
        case .contactNew: return "contact_new"
        case .profile: return "profile"
        case .edit_profile: return "edit_profile"
        case .onboarding: return "onboarding"
        case .customizedSource(let source): return source
        case .unknown: return "unknown"
        }
    }

    public static func transform(_ source: String) -> ExternalInviteSourceEntrance {
        switch source {
        case "feed_menu": return .feedMenu
        case "contact": return .contact
        case "contact_external": return .contactExternal
        case "contact_new": return .contactNew
        case "profile": return .profile
        case "edit_profile": return .edit_profile
        case "onboarding": return .onboarding
        default: return .customizedSource(source: source)
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

/// 外部联系人邀请动态路由
public struct ExternalContactDynamicBody: CodablePlainBody {
    public static let pattern = "//client/invite/external"
    public static let applinkPattern = "/client/invite/external"

    public var _url: URL {
        return URL(string: ExternalContactDynamicBody.pattern) ?? .init(fileURLWithPath: "")
            .append(parameters: ["from_scenes": fromEntrance.rawValue, "scenes": scenes.rawValue])
    }

    public let scenes: ExternalContactsInvitationScenes
    public let fromEntrance: ExternalInviteSourceEntrance

    public init(scenes: ExternalContactsInvitationScenes, fromEntrance: ExternalInviteSourceEntrance) {
        self.scenes = scenes
        self.fromEntrance = fromEntrance
    }
}

/// 外部联系人非定向邀请页
public typealias ExternalContactsInvitationScenes = ExternalContactsInvitationControllerBody.Scenes
public struct ExternalContactsInvitationControllerBody: CodablePlainBody {
    public static let pattern = "//client/invite/external/display"
    public static let applinkPattern = "/client/invite/external/display"

    public var _url: URL {
        return URL(string: ExternalContactsInvitationControllerBody.pattern) ?? .init(fileURLWithPath: "")
            .append(parameters: ["from_scenes": fromEntrance.rawValue, "scenes": scenes.rawValue])
    }

    @frozen
    public enum Scenes: String, Codable {
        case externalInvite = "contact_external"
        case myQRCode = "my_qrcode"

        public static func transform(_ scenes: String) -> Scenes {
            return Scenes(rawValue: scenes) ?? .externalInvite
        }
    }

    public let scenes: Scenes
    public let fromEntrance: ExternalInviteSourceEntrance

    public init(scenes: Scenes, fromEntrance: ExternalInviteSourceEntrance) {
        self.scenes = scenes
        self.fromEntrance = fromEntrance
    }
}

/// 外部联系人邀请分流页
public struct ExternalContactSplitBody: CodablePlainBody {
    public static let pattern = "//client/invite/external/split"
    public static let applinkPattern = "/client/invite/external/split"

    public let fromEntrance: ExternalInviteSourceEntrance

    public init(fromEntrance: ExternalInviteSourceEntrance) {
        self.fromEntrance = fromEntrance
    }
}

/// 外部联系人搜索页面(定向)
public struct ContactsSearchBody: CodablePlainBody {
    public static let pattern = "//client/invite/external/search"
    public static let applinkPattern = "/client/invite/external/search"

    public var _url: URL {
        return URL(string: ContactsSearchBody.pattern) ?? .init(fileURLWithPath: "")
            .append(parameters: ["invite_msg": inviteMsg])
    }

    public let inviteMsg: String
    public let uniqueId: String
    public let fromEntrance: ExternalInviteSourceEntrance

    public init(inviteMsg: String,
                uniqueId: String,
                fromEntrance: ExternalInviteSourceEntrance) {
        self.inviteMsg = inviteMsg
        self.uniqueId = uniqueId
        self.fromEntrance = fromEntrance
    }
}

public struct AssociationInviteQRPageBody: CodablePlainBody {
    public static let pattern = "//client/invite/b2b/qrpage"
    public static let applinkPattern = "/client/invite/qrpage"

    public let source: AssociationInviteSource

    public let contactType: AssociationContactType

    public init(source: AssociationInviteSource, contactType: AssociationContactType) {
        self.source = source
        self.contactType = contactType
    }
}

public enum AssociationInviteSource: String, Codable {
    // 从通讯录进入
    case contact = "contact"
    // 从 List 进入
    case list = "list"
    // 外链
    case urlLink = "url_link"
}

public enum AssociationContactType: Int, Codable {
    case external = 0
    case `internal` = 1

    public init(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .external
        case 1:
            self = .internal
        default:
            self = .external
        }
    }
}

public struct AssociationInviteBody: CodablePlainBody {
    public static let pattern = "//client/invite/b2b"
    public static let applinkPattern = "/client/invite/b2b"

    public let source: AssociationInviteSource

    public let contactType: AssociationContactType

    public init(source: AssociationInviteSource, contactType: AssociationContactType) {
        self.source = source
        self.contactType = contactType
    }
}

public protocol ProfileCache {
    func set(object: UserProfile, forKey: String)
    func object(forKey: String) -> UserProfile?
}

public struct OnCallViewControllerBody: CodablePlainBody {
    public static let pattern = "//client/contact/oncall"

    public let showSearch: Bool

    public init(showSearch: Bool = true) {
        self.showSearch = showSearch
    }
}

public struct RobotViewControllerBody: CodablePlainBody {
    public static let pattern = "//client/contact/robot"

    public init() {}
}

public struct GroupsViewControllerBody: PlainBody {
    public static let pattern = "//client/contact/groups"

    public let title: String?
    // 右上角的 New Group 按钮是否隐藏，默认不隐藏
    public let newGroupBtnHidden: Bool
    // 点选任意一个群组会话的自定义处理回调，如果不传，默认打开该会话
    public let chooseGroupHandler: ((UIViewController, Chat, ChatFromWhere) -> Void)?
    // 点击返回 or 关闭按钮的回调
    public let dismissHandler: (() -> Void)?

    public init(
        title: String? = nil,
        newGroupBtnHidden: Bool = false,
        chooseGroupHandler: ((UIViewController, Chat, ChatFromWhere) -> Void)? = nil,
        dismissHandler: (() -> Void)? = nil
    ) {
        self.title = title
        self.newGroupBtnHidden = newGroupBtnHidden
        self.chooseGroupHandler = chooseGroupHandler
        self.dismissHandler = dismissHandler
    }
}

public struct SetAliasViewControllerBody: PlainBody {
    public static let pattern = "//client/contact/alias"

    public let currentAlias: String
    public let setBlock: ((_ alias: String) -> Void)?

    public init(currentAlias: String, setBlock: ((_ alias: String) -> Void)?) {
        self.currentAlias = currentAlias
        self.setBlock = setBlock
    }
}

public struct SetInformationViewControllerBody: PlainBody {
    public static let pattern = "//client/contact/setInfo"

    public struct AliasAndMemoInfo {
        public var name: String = ""
        public var alias: String = ""
        public var memoDescription: Contact_V2_GetUserProfileResponse.MemoDescription?
        public var memoText: String = ""
        public var memoImage: UIImage?
        public var updateAliasCallback: (() -> Void)?

        public init(name: String = "",
             alias: String = "",
             memoDescription: Contact_V2_GetUserProfileResponse.MemoDescription? = nil,
             memoText: String = "",
             memoImage: UIImage? = nil,
             updateAliasCallback: (() -> Void)? = nil) {
            self.name = name
            self.alias = alias
            self.memoDescription = memoDescription
            self.memoText = memoText
            self.memoImage = memoImage
            self.updateAliasCallback = updateAliasCallback
        }
    }

    public enum ShareInfo {
        case no
        case yes(ShareEnable)
        public enum ShareEnable {
            case denied(desc: String)
            case enable
        }
    }

    public let isBlocked: Bool
    public let isSameTenant: Bool
    public let setNumebrEnable: Bool
    public let isCanReport: Bool
    public let isMe: Bool
    public let isFriend: Bool
    public let userId: String
    public let contactToken: String
    public let dismissCallback: (() -> Void)?
    public let shareInfo: ShareInfo
    public let isSpecialFocus: Bool
    public let aliasAndMemoInfo: AliasAndMemoInfo
    public let isFromPrivacy: Bool
    public let isResigned: Bool
    public let isShowBlockMenu: Bool
    public var showAddBtn: Bool = false
    public var pushToAddContactHandler: (() -> Void)?

    public init(isBlocked: Bool,
                isSameTenant: Bool,
                setNumebrEnable: Bool,
                isCanReport: Bool,
                isMe: Bool,
                isFriend: Bool,
                userId: String,
                contactToken: String,
                shareInfo: ShareInfo,
                isSpecialFocus: Bool,
                aliasAndMemoInfo: AliasAndMemoInfo,
                isFromPrivacy: Bool = false,
                isResigned: Bool = false,
                isShowBlockMenu: Bool = false,
                dismissCallback: (() -> Void)? = nil) {

        self.isBlocked = isBlocked
        self.isSameTenant = isSameTenant
        self.setNumebrEnable = setNumebrEnable
        self.isCanReport = isCanReport
        self.isMe = isMe
        self.isFriend = isFriend
        self.userId = userId
        self.contactToken = contactToken
        self.dismissCallback = dismissCallback
        self.shareInfo = shareInfo
        self.isSpecialFocus = isSpecialFocus
        self.aliasAndMemoInfo = aliasAndMemoInfo
        self.isFromPrivacy = isFromPrivacy
        self.isResigned = isResigned
        self.isShowBlockMenu = isShowBlockMenu
    }
}

public struct AddContactViewControllerBody: CodablePlainBody {
    public static let pattern = "//client/contact/add/friend"

    public init() {}
}

public struct OpenTelBody: CodablePlainBody {
    public static var pattern: String = "//client/telephone"
    public var source: ChatMeetingSource

    public let number: String

    public init(number: String,
                source: ChatMeetingSource = .meetingLinkJoin) {
        self.number = number
        self.source = source
    }
}

public enum ChatMeetingSource: String, Codable {
    case meetingLinkJoin                // 通过IM中会议ID引导入会
}

public enum InviteSendType: Int {
    case phone
    case email
}

public enum SourceScene {
    case deviceContacts
    case search
}

public let LKFriendStatusChangeNotification = "LKFriendStatusChangeNotification"
public let LKProfileUserInfoUpdateNotification = "LKProfileUserInfoUpdateNotification"
public let LKProfileHideAddOnProfileKey = "hideAddOnProfile"
public let LKProfileIsDoubleFriend = "isDoubleFriend"

// 邀请外部联系人
public struct ExternalInviteSendControllerBody: PlainBody {
    public static var pattern: String = "//client/invite/external/send"

    public let type: InviteSendType
    public let content: String
    public let countryCode: String
    public let inviteMsg: String
    public let uniqueId: String
    public let source: SourceScene
    public let sendCompletionHandler: () -> Void

    public init(source: SourceScene,
                type: InviteSendType,
                content: String,
                countryCode: String,
                inviteMsg: String,
                uniqueId: String,
                sendCompletionHandler: @escaping () -> Void) {
        self.source = source
        self.type = type
        self.content = content
        self.countryCode = countryCode
        self.inviteMsg = inviteMsg
        self.uniqueId = uniqueId
        self.sendCompletionHandler = sendCompletionHandler
    }
}

// 邀请外部联系人的引导页
public struct ExternalInviteGuideBody: PlainBody {
    public static let pattern: String = "//client/invite/external/guide"
    public static let applinkPattern = "/client/invite/external/guide"

    public let fromEntrance: ExternalInviteSourceEntrance
    public let closeHandler: (() -> Void)?

    public init(fromEntrance: ExternalInviteSourceEntrance, closeHandler: (() -> Void)? = nil) {
        self.fromEntrance = fromEntrance
        self.closeHandler = closeHandler
    }
}

public enum ShowNameStyle {
    case nameAndAlias
    case justAlias
}

public enum DepartmentsAdministratorStatus {
    case unknown
    case isAdmin
    case notAdmin
}

public typealias SubDepartmentItem = (tenantId: String?, department: Basic_V1_Department, isShowMemberCount: Bool)

/// 部门列表
public struct DepartmentBody: PlainBody {
    public static var pattern: String = "//client/contact/department"

    public let department: RustPB.Basic_V1_Department
    public let departmentPath: [RustPB.Basic_V1_Department]
    public let showNameStyle: ShowNameStyle
    /// 是否显示部门群入口
    public let showContactsTeamGroup: Bool
    public let isPublic: Bool
    // 是否来自联系人tab首页
    public let isFromContactTab: Bool
    // 是否来自更多部门
    public let subDepartmentsItems: [SubDepartmentItem]
    // 是否是成员与部门的管理员
    public let departmentsAdministratorStatus: DepartmentsAdministratorStatus

    public init(department: RustPB.Basic_V1_Department,
                departmentPath: [RustPB.Basic_V1_Department],
                showNameStyle: ShowNameStyle,
                showContactsTeamGroup: Bool,
                isPublic: Bool = false,
                isFromContactTab: Bool = false,
                subDepartmentsItems: [SubDepartmentItem] = [],
                departmentsAdministratorStatus: DepartmentsAdministratorStatus = .unknown
    ) {
        self.department = department
        self.departmentPath = departmentPath
        self.showNameStyle = showNameStyle
        self.showContactsTeamGroup = showContactsTeamGroup
        self.isPublic = isPublic
        self.isFromContactTab = isFromContactTab
        self.subDepartmentsItems = subDepartmentsItems
        self.departmentsAdministratorStatus = departmentsAdministratorStatus
    }
}

/// 关联组织
public struct CollaborationDepartmentBody: PlainBody {
  public static var pattern: String = "//client/contact/collaboration_department"

  public let tenantId: String?
  public let department: RustPB.Basic_V1_Department
  public let departmentPath: [RustPB.Basic_V1_Department]
  public let showNameStyle: ShowNameStyle
  /// 是否显示部门群入口
  public let showContactsTeamGroup: Bool
  public let isPublic: Bool
  // 是否来自联系人tab首页
  public let isFromContactTab: Bool
  public let associationContactType: AssociationContactType?

  public init(
        tenantId: String?,
        department: RustPB.Basic_V1_Department,
        departmentPath: [RustPB.Basic_V1_Department],
        showNameStyle: ShowNameStyle,
        showContactsTeamGroup: Bool,
        isPublic: Bool = false,
        isFromContactTab: Bool = false,
        associationContactType: AssociationContactType?
  ) {
    self.tenantId = tenantId
    self.department = department
    self.departmentPath = departmentPath
    self.showNameStyle = showNameStyle
    self.showContactsTeamGroup = showContactsTeamGroup
    self.isPublic = isPublic
    self.isFromContactTab = isFromContactTab
    self.associationContactType = associationContactType
  }
}

// 外部联系人列表
public struct ExternalContactsBody: PlainBody {
    public static var pattern: String = "//client/contact/external"

    public init() {}
}

// 星标联系人列表
public struct SpecialFocusListBody: PlainBody {
    public static var pattern: String = "//client/contact/specialFocusList"

    public init() {}
}

// 邀请人
public struct InvitationBody: PlainBody {
    public static var pattern: String = "//client/contact/invitation"

    public let content: String
    public init(content: String) {
        self.content = content
    }
}

// 活动规则
public struct PromotionRuleBody: PlainBody {
    public static var pattern: String = "//client/contact/promotionRule"

    public init() {}
}

// 分享推荐链接
public struct LinkInvitationBody: PlainBody {
    public static var pattern: String = "//client/contact/linkInvitation"

    public init() {}
}

// 选择区号
public struct SelectCountryNumberBody: PlainBody {
    public static var pattern: String = "//client/contact/selectCountryNumber"

    public let hotDatasource: [LarkSDKInterface.MobileCode]
    public let allDatasource: [LarkSDKInterface.MobileCode]
    public let selectAction: ((_ number: String) -> Void)?

    public init(hotDatasource: [LarkSDKInterface.MobileCode],
                allDatasource: [LarkSDKInterface.MobileCode],
                selectAction: ((_ number: String) -> Void)?) {
        self.hotDatasource = hotDatasource
        self.allDatasource = allDatasource
        self.selectAction = selectAction
    }
}

public struct UnregisterTeamBody: PlainBody {
    public static var pattern: String = "//client/account_setting/out_team_release"

    public let url: URL
    public let hideShowMore: Bool

    public init(url: URL, hideShowMore: Bool) {
        self.url = url
        self.hideShowMore = hideShowMore
    }
}

public typealias ContactPickFinishCallBack = () -> Void

public struct ContactPickListBody: PlainBody {
    public static let pattern = "//client/contact/contactPickList"

    public let title: String?
    public let skipText: String?
    public let confirmText: String?
    // 默认该页面是present，隐藏关闭按钮，如果是push则显示返回按钮
    public let isShowBehaviorPush: Bool?
    public let pickFinishCallBack: ContactPickFinishCallBack

    public init(title: String? = nil,
         skipText: String? = nil,
         confirmText: String? = nil,
         isShowBehaviorPush: Bool? = false,
         pickFinishCallBack: @escaping ContactPickFinishCallBack) {
        self.title = title
        self.skipText = skipText
        self.confirmText = confirmText
        self.isShowBehaviorPush = isShowBehaviorPush
        self.pickFinishCallBack = pickFinishCallBack
    }
}

// 权限申请场景
public enum AddContactApplicationSource {
    case urgent
    case videoCall
    case calendar
    case groupAddMember
    case createGroup
    case voiceCall
    case phoneCall
    case secretVoiceCall
    case profileCall
}

// 外部联系人添加好友的联系人model
public struct AddExternalContactModel {
    public let ID: String
    public let name: String
    public let avatarKey: String

    public init(
        ID: String,
        name: String,
        avatarKey: String
    ) {
        self.ID = ID
        self.name = name
        self.avatarKey = avatarKey
    }
}

public struct MSendContactApplicationDependecy {
    public let sender: String?
    public let senderId: String?
    public let source: RustPB.Basic_V1_ContactSource?
    public let sourceName: String?
    public let subSourceType: String?

    public init(sender: String? = nil,
                senderId: String? = nil,
                source: RustPB.Basic_V1_ContactSource? = nil,
                sourceName: String? = nil,
                subSourceType: String? = nil) {
        self.sender = sender
        self.senderId = senderId
        self.source = source
        self.sourceName = sourceName
        self.subSourceType = subSourceType
    }
}

// 外部联系人多选添加好友弹窗
// PRD：https://bytedance.feishu.cn/docs/doccnzbIUblfwciYEuWU95t0C5Q
// 接入文档：https://bytedance.feishu.cn/docs/doccnfPyPmSXRSYZTILUiC72Tmb#
public struct MAddContactApplicationAlertBody: PlainBody {
    public static var pattern: String = "//client/contact/applyCollaborationAlert"

    public let contacts: [AddExternalContactModel]

    public let title: String?
    public let text: String?
    public let sureButtonTitle: String?
    public let showConfirmApplyCheckBox: Bool
    public let cancelCallBack: (() -> Void)?
    public let sureCallBack: ((_ inputText: String, _ isSucceeded: Bool) -> Void)?
    public let source: AddContactApplicationSource?
    public let dependecy: MSendContactApplicationDependecy
    /// 来自哪个业务 埋点需要
    public let businessType: AddContactBusinessType?

    public init(
        contacts: [AddExternalContactModel],
        title: String? = nil,
        text: String? = nil,
        sureButtonTitle: String? = nil,
        showConfirmApplyCheckBox: Bool = false,
        source: AddContactApplicationSource? = nil,
        dependecy: MSendContactApplicationDependecy,
        businessType: AddContactBusinessType? = nil,
        cancelCallBack: (() -> Void)? = nil,
        sureCallBack: ((_ inputText: String, _ isSucceeded: Bool) -> Void)? = nil
    ) {
        self.contacts = contacts
        self.title = title
        self.text = text
        self.sureButtonTitle = sureButtonTitle
        self.showConfirmApplyCheckBox = showConfirmApplyCheckBox
        self.source = source
        self.dependecy = dependecy
        self.businessType = businessType
        self.cancelCallBack = cancelCallBack
        self.sureCallBack = sureCallBack
    }
}

/// 外部联系人添加好友弹窗
public struct AddContactApplicationAlertBody: PlainBody {
    public static var pattern: String = "//client/contact/addContactApplicationAlert"

    public let userId: String
    public let chatId: String?
    public let source: Source
    public let token: String?
    public let displayName: String
    public let title: String?
    public let content: String?
    public let cancelCallBack: (() -> Void)?
    public let addContactBlock: ((_ userId: String?) -> Void)?
    // dissMiss添加好友页面后执行的任务
    public var dissmissBlock: (() -> Void)?
    public weak var targetVC: NavigatorFrom?
    /// 来自哪个业务 埋点需要
    public let businessType: AddContactBusinessType?

    public init(userId: String,
                chatId: String? = nil,
                source: Source,
                token: String? = nil,
                displayName: String,
                title: String? = nil,
                content: String? = nil,
                targetVC: NavigatorFrom? = nil,
                businessType: AddContactBusinessType? = nil,
                cancelCallBack: (() -> Void)? = nil,
                addContactBlock: ((_ userId: String?) -> Void)? = nil) {
        self.userId = userId
        self.chatId = chatId
        self.token = token
        self.title = title
        self.content = content
        self.source = source
        self.displayName = displayName
        self.targetVC = targetVC
        self.businessType = businessType
        self.cancelCallBack = cancelCallBack
        self.addContactBlock = addContactBlock
    }

    public init(userId: String,
                chatId: String? = nil,
                source: Source,
                token: String? = nil,
                displayName: String,
                title: String? = nil,
                content: String? = nil,
                targetVC: UIViewController? = nil,
                businessType: AddContactBusinessType? = nil,
                cancelCallBack: (() -> Void)? = nil,
                addContactBlock: ((_ userId: String?) -> Void)? = nil,
                dissmissBlock: (() -> Void)? = nil) {
        self.userId = userId
        self.chatId = chatId
        self.token = token
        self.title = title
        self.content = content
        self.source = source
        self.displayName = displayName
        self.targetVC = targetVC
        self.businessType = businessType
        self.cancelCallBack = cancelCallBack
        self.addContactBlock = addContactBlock
        self.dissmissBlock = dissmissBlock
    }
}

public struct VCChatterPickerBody: PlainBody {
    public static let pattern = "//client/vc/chatterPicker"
    /// resultView 底部栏
    public var toolbarClass: AnyClass?
    /// needSearchOuterTenant会包含.external的section
    public var dataOptions: DataOptions = []
    public var title: String = ""
    // 自定义列表头部view
    public var customHeaderView: UIView?
    /// 是否显示Title副标题（已选部门、群组、人员情况）
    public var supportCustomTitleView: Bool = false
    /// 是否可以展开数据源详情页
    public var supportUnfoldSelected: Bool = false
    /// 数据源为空是否可点击
    public var allowSelectNone: Bool = false
    /// 是否展示数据源个数
    public var allowDisplaySureNumber: Bool = true
    public var forceSelectedChatterIds: [String] = []
    public var forceSelectedChatId: String?
    public var defaultSelectedChatterIds: [String] = []
    /// 默认选中项
    public var defaultSelectedResult: ContactPickerResult?
    public var selectedCallback: ((UIViewController?, ContactPickerResult) -> Void)?
    public var cancelCallback: (() -> Void)?
    public var selectStyle: NewDepartmentViewControllerStyle = .multi
    public var needSearchOuterTenant: Bool = true
    public var includeOuterChat: Bool = false
    public var disabledSelectedChatterIds: [String] = []
    public var checkInvitePermission: Bool = false
    public var isCryptoModel: Bool = false
    /// 是不是跨租户群
    public var isCrossTenantChat: Bool = false
    public var limitInfo: SelectChatterLimitInfo?
    /// 以C端用户的视角选择，如隐藏组织架构信息,只能看到外部联系人，目前只在单品内小B账号使用
    public var forceTreatAsCustomer: Bool = false
    /// 是否展示家校组织架构
    public var showEduStructure: Bool = false
    /// 是否支持选择群组和部门
    public var supportSelectGroup: Bool = false
    public var supportSelectOrganization: Bool = false
    public var checkGroupPermissionForInvite: Bool = false
    public var checkOrganizationPermissionForInvite: Bool = false
    public var source: ChatterPickerSource = .other
    public var enableRelatedOrganizations: Bool = true
    /// 是否支持搜出机器人
    public var enableSearchBot: Bool = false
    /// 支持搜索外部群组
    public var includeOuterGroupForChat: Bool = false
    /// 对于所选 Chat 鉴权
    public var checkChatDeniedReasonForDisabledPick: ((ChatterPickeSelectChatType) -> Bool)?
    public var checkChatDeniedReasonForWillSelected: ((ChatterPickeSelectChatType, UIViewController) -> Bool)?
    /// 对于所选 Chatter 鉴权
    public var checkChatterDeniedReasonForDisabledPick: ((_ isExternal: Bool) -> Bool)?
    public var checkChatterDeniedReasonForWillSelected: ((_ isExternal: Bool, UIViewController) -> Bool)?
    /// 我的群组联系人可选配置
    public var myGroupContactCanSelect: ((PickerItemType) -> Bool)?
    public var myGroupContactDisableReason: ((PickerItemType) -> String?)?
    /// 外部群组联系人可选配置
    public var externalContactCanSelect: ((PickerItemType) -> Bool)?
    public var externalContactDisableReason: ((PickerItemType) -> String?)?
    public init() {}
}
