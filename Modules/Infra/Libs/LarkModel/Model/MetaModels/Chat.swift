//
//  Chat.swift
//  Model
//
//  Created by qihongye on 2018/3/13.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//
import UIKit
import Foundation
import RustPB
import LKCommonsLogging
import LarkLocalizations
import ServerPB

public typealias ChatTopNotice = RustPB.Im_V1_ChatTopNotice

public enum RestrictedModeSettingType {
    case forward
    case copy
    case download
    case screenshot
}

// 保密模式消息删除时间状态
public enum RestrictedModeMessageBurnTime: Equatable {
    public static let minutes_1: Int64 = 60
    public static let hours_1: Int64 = 60 * RestrictedModeMessageBurnTime.minutes_1
    public static let day_1: Int64 = 24 * RestrictedModeMessageBurnTime.hours_1
    public static let week_1: Int64 = 7 * RestrictedModeMessageBurnTime.day_1
    public static let month_1: Int64 = 30 * RestrictedModeMessageBurnTime.day_1

    case close
    case time(Int64)
}

public final class Chat: ModelProtocol, AtomicExtra {
    public static let logger = Logger.log(Chat.self, category: "Chat")

    public typealias PBModel = RustPB.Basic_V1_Chat

    public typealias TypeEnum = RustPB.Basic_V1_Chat.TypeEnum
    public typealias Role = RustPB.Basic_V1_Chat.Role
    public typealias Announcement = RustPB.Basic_V1_Chat.Announcement
    public typealias ChatMode = RustPB.Basic_V1_Chat.ChatMode

    public typealias AddMemberPermission = RustPB.Basic_V1_Chat.AddMemberPermission
    public typealias AnonymousSetting = RustPB.Basic_V1_Chat.AnonymousSetting
    /// chat的横幅设置，用于当消息不可见的时候，在顶部给用户一个提示
    public typealias BannerSetting = RustPB.Basic_V1_BannerSetting

    public typealias MessageVisibilitySetting = RustPB.Basic_V1_Chat.MessageVisibilitySetting
    public typealias MessagePosition = RustPB.Basic_V1_Chat.MessagePosition
    public typealias AtAllPermission = RustPB.Basic_V1_Chat.AtAllPermission
    public typealias SystemMessageVisible = RustPB.Basic_V1_Chat.SystemMessageVisible
    public typealias ShareCardPermission = RustPB.Basic_V1_Chat.ShareCardPermission
    public typealias AddMemberApply = RustPB.Basic_V1_Chat.AddMemberApply
    public typealias PostType = RustPB.Basic_V1_Chat.PostType // 群发言权限类型
    public typealias MailPermissionType = RustPB.Basic_V1_ChatMailSetting.SendPermission
    public typealias ChatMailSetting = RustPB.Basic_V1_ChatMailSetting
    public typealias CreateP2PChatSource = RustPB.Im_V1_CreateP2PChatSource
    public typealias Tag = RustPB.Basic_V1_Tag
    public typealias CreateUrgentSetting = RustPB.Basic_V1_Chat.CreateUrgentSetting.Enum
    public typealias CreateVideoConferenceSetting = RustPB.Basic_V1_Chat.CreateVideoConferenceSetting.Enum
    public typealias PinPermissionSetting = RustPB.Basic_V1_Chat.PinPermissionSetting.Enum
    public typealias ChatPinPermissionSetting = RustPB.Basic_V1_Chat.ChatPinPermissionSetting.Enum
    public typealias TopNoticePermissionSetting = RustPB.Basic_V1_Chat.TopNoticePermissionSetting.Enum
    public typealias ChatTabPermissionSetting = RustPB.Basic_V1_Chat.ChatTabPermissionSetting.Enum
    public typealias TeamChatType = RustPB.Basic_V1_TeamChatType
    public typealias ChatterExtraStatesType = RustPB.Basic_V1_ChatterExtraStateType
    /// 标签
    public typealias FeedLabelTag = RustPB.Basic_V1_FeedTag
    public typealias TypingTranslateSetting = RustPB.Basic_V1_Chat.TypingTranslateSetting
    // 信息防泄漏设置
    public typealias RestrictedModeSetting = RustPB.Basic_V1_Chat.RestrictedModeSetting
    public typealias DefDisplaySetting = RustPB.Basic_V1_Chat.DefDisplaySetting.Enum
    // 隐藏群人数设置
    public typealias UserCountVisibleSetting = RustPB.Basic_V1_Chat.UserCountVisibleSetting.Enum

    // 固有字段
    public var id: String
    public var type: TypeEnum
    public var name: String
    public var namePinyin: String
    public var lastMessageId: String
    // 最后一条消息Position
    public var lastMessagePosition: Int32
    public var updateTime: TimeInterval
    public var createTime: TimeInterval
    public var chatterId: String
    public var description: String
    public var avatar: Image
    public var avatarKey: String
    public let miniAvatarKey: String
    private var _ownerId: String = ""
    public var ownerId: String {
        get {
            return self.type == .p2P ? "" : self._ownerId
        }
        set {
            self._ownerId = newValue
        }
    }
    public var p2POwnerId: String {
        return self.type == .p2P ? self._ownerId : ""
    }
    public var chatterCount: Int32
    public var userCount: Int32
    public var isDepartment: Bool
    public var isPublic: Bool
    public var isArchived: Bool
    public var isDeleted: Bool
    public var isRemind: Bool
    public var role: Role
    public var isCustomerService: Bool
    public var isCustomIcon: Bool
    public var textDraftId: String
    public var postDraftId: String
    public var isShortCut: Bool
    public var announcement: Announcement
    public var offEditGroupChatInfo: Bool
    public var tenantId: String
    public var isDissolved: Bool
    public var isFrozen: Bool /// 群是否被冻结
    public var messagePosition: MessagePosition.Enum
    public var addMemberPermission: AddMemberPermission.Enum
    public var atAllPermission: AtAllPermission.Enum
    public var messageVisibilitySetting: MessageVisibilitySetting.Enum
    public var joinMessageVisible: SystemMessageVisible.Enum
    public var quitMessageVisible: SystemMessageVisible.Enum
    public var shareCardPermission: ShareCardPermission.Enum
    public var addMemberApply: AddMemberApply.Enum
    public var putChatterApplyCount: Int32
    public var anonymousTotalQuota: Int64
    public var showBanner: Bool
    public var lastVisibleMessageId: String
    // 密聊场景使用，会话当前密聊焚毁时间, 普通聊天使用restrictedModeSetting.onTimeDelMsgSetting.aliveTime
    public var burnLife: Int32
    public var isCrypto: Bool
    /// 是不是我和MyAI的单聊
    public var isP2PAi: Bool
    public var isMeeting: Bool
    public var chatable: Bool
    public var muteable: Bool
    public var isTenant: Bool // 是否是全员群
    public var isCrossTenant: Bool
    public var isCrossWithKa: Bool // 是否跨 Unit
    public var isInBox: Bool
    public var isDelayed: Bool
    public var isFlaged: Bool
    public var isMuteAtAll: Bool
    /// 是不是官网服务台
    public var isOfficialOncall: Bool
    public var isOfflineOncall: Bool
    public var oncallId: String

    /// 最远的有效消息。在密聊中不同设备 firstMessagePostion 不一样。这个字段会用来判断上部加载更多逻辑。
    private var _firstMessagePostion: Int32

    /// chat顶部的banner提示
    public var bannerSetting: BannerSetting?

    public var firstMessagePostion: Int32 {
        set {
            _firstMessagePostion = newValue
        }

        get {
            guard let bannerSetting = self.bannerSetting else {
                return _firstMessagePostion
            }
            if self.chatMode == .threadV2 {
                return max(bannerSetting.chatThreadPosition, _firstMessagePostion)
            } else {
                return max(bannerSetting.chatMessagePosition, _firstMessagePostion)
            }
        }
    }

    public var needShowTopBanner: Bool {
        guard let setting = bannerSetting else { return false }
        if self.chatMode == .threadV2 {
            return firstMessagePostion == setting.chatThreadPosition && setting.chatThreadPosition >= 0
        } else {
            return firstMessagePostion == setting.chatMessagePosition && setting.chatMessagePosition >= 0
        }
    }

    /// 顶部提示信息
    public var topBannerTip: String? {
        guard let bannerSetting = self.bannerSetting else {
            return nil
        }
        let language = LanguageManager.currentLanguage.localeIdentifier.lowercased()
        guard let tip = bannerSetting.i18NNames[language] else {
            let enUSKey = "en_us"
            return bannerSetting.i18NNames[enUSKey]
        }
        return tip
    }

    public var lastVisibleMessagePosition: Int32 // 最后一条可见消息位置
    public var readPosition: Int32 // 读到消息的位置
    public var readPositionBadgeCount: Int32 // 读到的消息前面有几条计算badge的消息
    public var lastMessagePositionBadgeCount: Int32 // 最后一条消息前面有几条计算badge的消息
    public var isAutoTranslate: Bool
    public var typingTranslateSetting: TypingTranslateSetting
    public var isAllowPost: Bool // 群发言权限：是否允许发言
    public var postType: PostType // 群发言权限：当前群发言权限类型
    public var hasWaterMark: Bool // 群是否带有水印
    public var lastDraftId: String // 最后一次编辑的 draft id
    public var editMessageDraftId: String //二次编辑的 draft id
    public var lastReadPosition: Int32
    public var lastReadOffset: CGFloat
    public var mailSetting: ChatMailSetting?

    /// thread字段
    public var chatMode: ChatMode
    public var lastThreadPositionBadgeCount: Int32
    public var readThreadPosition: Int32
    public var readThreadPositionBadgeCount: Int32
    public var lastVisibleThreadPosition: Int32
    public var lastVisibleThreadId: String
    public var lastThreadId: String
    public var lastThreadPosition: Int32
    /// 我参与的话题，已读时间戳
    public var myThreadsReadTimestamp: Int64
    /// 我参与的话题，最新时间戳
    public var myThreadsLastTimestamp: Int64
    /// 我参与的话题，有多少个话题有未读的回复
    public var myThreadsUnreadCount: Int32
    public var topNoticePermissionSetting: RustPB.Basic_V1_Chat.TopNoticePermissionSetting.Enum
    public let chatTabPermissionSetting: ChatTabPermissionSetting
    public var adminPostSetting: RustPB.Basic_V1_Chat.AdminPostSetting.Enum

    /// 群成员列表可以按照首字母排序
    public var canBeSortedAlphabetically: Bool

    /// 服务端下发的chat侧边栏sidebars，展示在本地sidebars前面
    public var sidebarButtons: [RustPB.Basic_V1_SideBarButton]

    /// Chat 可选信息，用于非通用数据的场景
    /// pushChat不会更新这个数据，设计单独的chatOptionInfo push接口提供更新。
    /// 现在只在ThreadChat中使用，并且未接入chatOptionInfo push接口，只有MGetChatsResponse中有返回ChatOptionInfo数据。
    public var chatOptionInfo: Basic_V1_ChatOptionInfo?

    typealias ExtraModel = ChatExtra
    struct ChatExtra {
        var owner: Chatter?
        var chatter: Chatter?
    }
    var atomicExtra = SafeAtomic(value: ExtraModel())

    public var chatter: Chatter? {
        get {
            return atomicExtra.value.chatter
        }
        set {
            atomicExtra.value.chatter = newValue
            if newValue?.id ?? self.chatterId != self.chatterId {
                assertionFailure("chatter.id should equal to self.chatterId!")
            }
        }
    }

    public var owner: Chatter? {
        get {
            return atomicExtra.value.owner
        }
        set {
            atomicExtra.value.owner = newValue
        }
    }

    // sdk收敛的标签枚举数组
    public var tags: [Tag]
    // 是否是群管理员
    public var isGroupAdmin: Bool
    // 匿名id
    public var anonymousId: String

    // Team 相关
    public struct TeamEntity {
        public let teams: [Int64: Basic_V1_Team]
        public let teamsChatType: [Int64: TeamChatType]
        public let teamChatInfos: [Basic_V1_ChatTeamInfo]
        public let boundTeamsInfo: [Basic_V1_ChatTeamInfo]
    }

    public var teamEntity: TeamEntity
    public var isAssociatedTeam: Bool {
        !self.teamEntity.boundTeamsInfo.isEmpty
    }

    public let hasVcChatPermission: Bool
    // 是否是临时入会用户，用户实际未入群
    public var isInMeetingTemporary: Bool {
        return self.role != .member && self.hasVcChatPermission
    }
    // 是否是密盾聊
    public var isPrivateMode: Bool
    // 是否是超大群
    public var isSuper: Bool
    // 加急权限
    public var createUrgentSetting: CreateUrgentSetting?
    // 视频会议权限
    public var createVideoConferenceSetting: CreateVideoConferenceSetting?
    // pin权限
    public var pinPermissionSetting: PinPermissionSetting?
    // 普通群内谁可以管理置顶，话题群内 谁可以管理置顶和pin
    public let chatPinPermissionSetting: ChatPinPermissionSetting
    // chatter的其他业务状态
    // 保存一些会话级别、人纬度的信息，即同一个群中不同群成员的状态信息是不同的
    public var chatterExtraStates: [ChatterExtraStatesType: Int32]

    /// 挂在chat上的标签
    public var feedLabels: [FeedLabelTag]

    // 信息防泄漏设置
    public var restrictedModeSetting: RestrictedModeSetting
    // 进群默认展示群菜单 or 键盘
    public let defDisplaySetting: DefDisplaySetting
    public var scheduleMessageDraftID: String = ""

    public let displayMode: RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum
    public var displayInThreadMode: Bool {
        switch self.displayMode {
        case.thread:
            return true
        default:
            return false
        }
    }
    public var tagData: RustPB.Basic_V1_TagData?
    // 主题
    public var theme: ServerPB_Entities_ChatTheme?

    public var restrictedBurnTime: RestrictedModeMessageBurnTime {
        if self.restrictedModeSetting.onTimeDelMsgSetting.status {
            return RestrictedModeMessageBurnTime.time(self.restrictedModeSetting.onTimeDelMsgSetting.aliveTime)
        }
        return .close
    }

    public var inRestrictedModeWhiteList: Bool

    public let isUserCountVisible: Bool // 群成员数量是否可见
    public let userCountVisibleSetting: UserCountVisibleSetting

    public var isOcicCustomerService: Bool //新的飞书客服

    public init(
        id: String,
        type: TypeEnum,
        name: String,
        namePinyin: String,
        lastMessageId: String,
        lastMessagePosition: Int32,
        updateTime: TimeInterval,
        createTime: TimeInterval,
        chatterId: String,
        description: String,
        avatar: Image,
        avatarKey: String,
        miniAvatarKey: String,
        ownerId: String,
        chatterCount: Int32,
        userCount: Int32,
        isDepartment: Bool,
        isPublic: Bool,
        isArchived: Bool,
        isDeleted: Bool,
        isRemind: Bool,
        role: Role,
        hasVcChatPermission: Bool,
        isCustomerService: Bool,
        isCustomIcon: Bool,
        textDraftId: String,
        postDraftId: String,
        isShortCut: Bool,
        announcement: Announcement,
        offEditGroupChatInfo: Bool,
        tenantId: String,
        isDissolved: Bool,
        isFrozen: Bool,
        messagePosition: MessagePosition.Enum,
        addMemberPermission: AddMemberPermission.Enum,
        atAllPermission: AtAllPermission.Enum,
        messageVisibilitySetting: MessageVisibilitySetting.Enum,
        joinMessageVisible: SystemMessageVisible.Enum,
        quitMessageVisible: SystemMessageVisible.Enum,
        shareCardPermission: ShareCardPermission.Enum,
        addMemberApply: AddMemberApply.Enum,
        putChatterApplyCount: Int32,
        anonymousTotalQuota: Int64,
        showBanner: Bool,
        lastVisibleMessageId: String,
        burnLife: Int32,
        isCrypto: Bool,
        isP2PAi: Bool,
        isMeeting: Bool,
        chatable: Bool,
        muteable: Bool,
        isTenant: Bool,
        isCrossTenant: Bool,
        isCrossWithKa: Bool,
        isInBox: Bool,
        isDelayed: Bool,
        isFlaged: Bool,
        isMuteAtAll: Bool,
        firstMessagePostion: Int32,
        bannerSetting: BannerSetting?,
        isOfficialOncall: Bool,
        isOfflineOncall: Bool,
        oncallId: String,
        lastVisibleMessagePosition: Int32,
        readPosition: Int32,
        readPositionBadgeCount: Int32,
        lastMessagePositionBadgeCount: Int32,
        isAutoTranslate: Bool,
        typingTranslateSetting: TypingTranslateSetting,
        chatMode: ChatMode,
        lastThreadPositionBadgeCount: Int32,
        readThreadPosition: Int32,
        readThreadPositionBadgeCount: Int32,
        lastVisibleThreadPosition: Int32,
        lastVisibleThreadId: String,
        lastThreadId: String,
        lastThreadPosition: Int32,
        myThreadsReadTimestamp: Int64,
        myThreadsLastTimestamp: Int64,
        myThreadsUnreadCount: Int32,
        sidebarButtons: [RustPB.Basic_V1_SideBarButton],
        isAllowPost: Bool,
        postType: PostType,
        hasWaterMark: Bool,
        lastDraftId: String,
        editMessageDraftId: String,
        lastReadPosition: Int32,
        lastReadOffset: CGFloat,
        topNoticePermissionSetting: RustPB.Basic_V1_Chat.TopNoticePermissionSetting.Enum,
        chatTabPermissionSetting: ChatTabPermissionSetting,
        tags: [Tag] = [],
        isGroupAdmin: Bool = false,
        anonymousId: String = "",
        isSuper: Bool = false,
        isPrivateMode: Bool,
        teams: TeamEntity,
        createUrgentSetting: CreateUrgentSetting? = nil,
        createVideoConferenceSetting: CreateVideoConferenceSetting? = nil,
        pinPermissionSetting: PinPermissionSetting? = nil,
        chatPinPermissionSetting: ChatPinPermissionSetting,
        chatterExtraStates: [ChatterExtraStatesType: Int32],
        feedLabels: [FeedLabelTag],
        restrictedModeSetting: RestrictedModeSetting,
        scheduleMessageDraftID: String = "",
        displayMode: RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum,
        defDisplaySetting: DefDisplaySetting,
        adminPostSetting: RustPB.Basic_V1_Chat.AdminPostSetting.Enum,
        tagData: RustPB.Basic_V1_TagData? = nil,
        canBeSortedAlphabetically: Bool = false,
        inRestrictedModeWhiteList: Bool = false,
        isUserCountVisible: Bool,
        userCountVisibleSetting: UserCountVisibleSetting,
        isOcicCustomerService: Bool = false
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.namePinyin = namePinyin
        self.lastMessageId = lastMessageId
        self.updateTime = updateTime
        self.createTime = createTime
        self.chatterId = chatterId
        self.description = description
        self.avatar = avatar
        self.avatarKey = avatarKey
        self.miniAvatarKey = miniAvatarKey
        self.chatterCount = chatterCount
        self.userCount = userCount
        self.isDepartment = isDepartment
        self.isPublic = isPublic
        self.isArchived = isArchived
        self.isDeleted = isDeleted
        self.isRemind = isRemind
        self.role = role
        self.hasVcChatPermission = hasVcChatPermission
        self.isCustomerService = isCustomerService
        self.isCustomIcon = isCustomIcon
        self.textDraftId = textDraftId
        self.postDraftId = postDraftId
        self.isShortCut = isShortCut
        self.announcement = announcement
        self.offEditGroupChatInfo = offEditGroupChatInfo
        self.tenantId = tenantId
        self.lastMessagePosition = lastMessagePosition
        self.isDissolved = isDissolved
        self.isFrozen = isFrozen
        self.messagePosition = messagePosition
        self.addMemberPermission = addMemberPermission
        self.atAllPermission = atAllPermission
        self.messageVisibilitySetting = messageVisibilitySetting
        self.joinMessageVisible = joinMessageVisible
        self.quitMessageVisible = quitMessageVisible
        self.shareCardPermission = shareCardPermission
        self.addMemberApply = addMemberApply
        self.putChatterApplyCount = putChatterApplyCount
        self.anonymousTotalQuota = anonymousTotalQuota
        self.showBanner = showBanner
        self.lastVisibleMessageId = lastVisibleMessageId
        self.burnLife = burnLife
        self.isCrypto = isCrypto
        self.isP2PAi = isP2PAi
        self.isMeeting = isMeeting
        self.chatable = chatable
        self.muteable = muteable
        self.isTenant = isTenant
        self.isCrossTenant = isCrossTenant
        self.isCrossWithKa = isCrossWithKa
        self.isInBox = isInBox
        self.isDelayed = isDelayed
        self.isFlaged = isFlaged
        self.isMuteAtAll = isMuteAtAll
        self._firstMessagePostion = firstMessagePostion
        self.bannerSetting = bannerSetting
        self.isOfficialOncall = isOfficialOncall
        self.isOfflineOncall = isOfflineOncall
        self.oncallId = oncallId
        self.lastVisibleMessagePosition = lastVisibleMessagePosition
        self.readPosition = readPosition
        self.readPositionBadgeCount = readPositionBadgeCount
        self.lastMessagePositionBadgeCount = lastMessagePositionBadgeCount
        self.isAutoTranslate = isAutoTranslate
        self.typingTranslateSetting = typingTranslateSetting
        self.chatMode = chatMode
        self.lastThreadPositionBadgeCount = lastThreadPositionBadgeCount
        self.readThreadPosition = readThreadPosition
        self.readThreadPositionBadgeCount = readThreadPositionBadgeCount
        self.lastVisibleThreadPosition = lastVisibleThreadPosition
        self.lastVisibleThreadId = lastVisibleThreadId
        self.lastThreadId = lastThreadId
        self.lastThreadPosition = lastThreadPosition
        self.myThreadsReadTimestamp = myThreadsReadTimestamp
        self.myThreadsLastTimestamp = myThreadsLastTimestamp
        self.myThreadsUnreadCount = myThreadsUnreadCount
        self.sidebarButtons = sidebarButtons
        self.isAllowPost = isAllowPost
        self.postType = postType
        self.hasWaterMark = hasWaterMark
        self.lastDraftId = lastDraftId
        self.editMessageDraftId = editMessageDraftId
        self.lastReadPosition = lastReadPosition
        self.lastReadOffset = lastReadOffset
        self.topNoticePermissionSetting = topNoticePermissionSetting
        self.chatTabPermissionSetting = chatTabPermissionSetting
        self.tags = tags
        self.isGroupAdmin = isGroupAdmin
        self.anonymousId = anonymousId
        self.isSuper = isSuper
        self.isPrivateMode = isPrivateMode
        self.teamEntity = teams
        self.chatterExtraStates = chatterExtraStates
        self.feedLabels = feedLabels
        self.restrictedModeSetting = restrictedModeSetting
        self.displayMode = displayMode
        self.defDisplaySetting = defDisplaySetting
        self.createUrgentSetting = createUrgentSetting
        self.createVideoConferenceSetting = createVideoConferenceSetting
        self.pinPermissionSetting = pinPermissionSetting
        self.chatPinPermissionSetting = chatPinPermissionSetting
        self.scheduleMessageDraftID = scheduleMessageDraftID
        self.tagData = tagData
        self.adminPostSetting = adminPostSetting
        self.canBeSortedAlphabetically = canBeSortedAlphabetically
        self.inRestrictedModeWhiteList = inRestrictedModeWhiteList
        self.isUserCountVisible = isUserCountVisible
        self.userCountVisibleSetting = userCountVisibleSetting
        self.isOcicCustomerService = isOcicCustomerService
        self.ownerId = ownerId
    }

    public static func transform(pb: PBModel) -> Chat {
        return Chat(id: pb.id,
                    type: pb.type,
                    name: pb.name,
                    namePinyin: pb.namePinyin,
                    lastMessageId: pb.lastMessageID,
                    lastMessagePosition: pb.lastMessagePosition,
                    updateTime: TimeInterval(pb.updateTime),
                    createTime: TimeInterval(pb.createTime),
                    chatterId: pb.chatterID,
                    description: pb.description_p,
                    avatar: pb.avatar,
                    avatarKey: pb.avatarKey,
                    miniAvatarKey: pb.miniAvatarKey,
                    ownerId: pb.ownerID,
                    chatterCount: pb.chatterCount,
                    userCount: pb.userCount,
                    isDepartment: pb.isDepartment,
                    isPublic: pb.isPublicV2,
                    isArchived: pb.isArchived,
                    isDeleted: pb.isDeleted,
                    isRemind: pb.isRemind,
                    role: pb.role,
                    hasVcChatPermission: pb.hasVcChatPermission_p,
                    isCustomerService: pb.isCustomerService,
                    isCustomIcon: pb.isCustomIcon,
                    textDraftId: pb.textDraftID,
                    postDraftId: pb.postDraftID,
                    isShortCut: pb.isShortcut,
                    announcement: pb.announcement,
                    offEditGroupChatInfo: pb.offEditGroupChatInfo,
                    tenantId: pb.tenantID,
                    isDissolved: pb.isDissolved,
                    isFrozen: pb.isFrozen,
                    messagePosition: pb.messagePosition,
                    addMemberPermission: pb.addMemberPermission,
                    atAllPermission: pb.atAllPermission,
                    messageVisibilitySetting: pb.messageVisibilitySetting,
                    joinMessageVisible: pb.joinMessageVisible,
                    quitMessageVisible: pb.quitMessageVisible,
                    shareCardPermission: pb.shareCardPermission,
                    addMemberApply: pb.addMemberApply,
                    putChatterApplyCount: pb.putChatterApplyCount,
                    anonymousTotalQuota: pb.anonymousTotalQuota,
                    showBanner: pb.showBanner,
                    lastVisibleMessageId: pb.lastVisibleMessageID,
                    burnLife: pb.burnLife,
                    isCrypto: pb.isCrypto,
                    isP2PAi: pb.isP2PAi,
                    isMeeting: pb.isMeeting,
                    chatable: pb.chatable,
                    muteable: pb.muteable,
                    isTenant: pb.isTenant,
                    isCrossTenant: pb.isCrossTenant,
                    isCrossWithKa: pb.isCrossWithKa,
                    isInBox: pb.isInBox,
                    isDelayed: pb.isDelayed,
                    isFlaged: pb.isFlag,
                    isMuteAtAll: pb.isMuteAtAll,
                    firstMessagePostion: pb.firstMessagePosition,
                    bannerSetting: pb.hasBannerSetting ? pb.bannerSetting : nil,
                    isOfficialOncall: pb.isOfficialOncall,
                    isOfflineOncall: pb.isOfflineOncall,
                    oncallId: pb.oncallID,
                    lastVisibleMessagePosition: pb.lastVisibleMessagePosition,
                    readPosition: pb.readPosition,
                    readPositionBadgeCount: pb.readPositionBadgeCount,
                    lastMessagePositionBadgeCount: pb.lastMessagePositionBadgeCount,
                    isAutoTranslate: pb.isAutoTranslate,
                    typingTranslateSetting: pb.typingTranslateSetting,
                    chatMode: pb.chatMode,
                    lastThreadPositionBadgeCount: pb.lastThreadPositionBadgeCount,
                    readThreadPosition: pb.readThreadPosition,
                    readThreadPositionBadgeCount: pb.readThreadPositionBadgeCount,
                    lastVisibleThreadPosition: pb.lastVisibleThreadPosition,
                    lastVisibleThreadId: pb.lastVisibleThreadID,
                    lastThreadId: pb.lastThreadID,
                    lastThreadPosition: pb.lastThreadPosition,
                    myThreadsReadTimestamp: pb.myThreadsReadTimestamp,
                    myThreadsLastTimestamp: pb.myThreadsLastTimestamp,
                    myThreadsUnreadCount: pb.myThreadsUnreadCount,
                    sidebarButtons: pb.sidebarButtons,
                    isAllowPost: pb.allowPost,
                    postType: pb.postType,
                    hasWaterMark: pb.hasWaterMark_p,
                    lastDraftId: pb.lastDraftID,
                    editMessageDraftId: pb.editMessageDraftID,
                    lastReadPosition: pb.lastReadPosition,
                    lastReadOffset: CGFloat(pb.lastReadOffset),
                    topNoticePermissionSetting: pb.topNoticePermissionSetting,
                    chatTabPermissionSetting: pb.chatTabPermissionSetting,
                    tags: pb.tags,
                    isGroupAdmin: pb.isAdmin,
                    anonymousId: pb.anonymousID,
                    isSuper: pb.isSuper,
                    isPrivateMode: pb.isPrivateMode,
                    teams: TeamEntity(teams: pb.joinedTeams,
                                 teamsChatType: Dictionary.init(pb.boundTeamInfos.compactMap { return ($0.teamID, $0.teamChatType) }) { $1 },
                                 teamChatInfos: pb.joinedTeamInfos.sorted(by: { $0.orderWeight < $1.orderWeight }), boundTeamsInfo: pb.boundTeamInfos),
                    createUrgentSetting: pb.createUrgentSetting,
                    createVideoConferenceSetting: pb.createVideoConferenceSetting,
                    pinPermissionSetting: pb.pinPermissionSetting,
                    chatPinPermissionSetting: pb.chatPinPermissionSetting,
                    chatterExtraStates: transformChatterExtraStates(pb.chatterExtraStates),
                    feedLabels: pb.feedTag,
                    restrictedModeSetting: pb.restrictedModeSetting,
                    scheduleMessageDraftID: pb.scheduleMessageDraftID,
                    displayMode: pb.chatDisplayModeSetting,
                    defDisplaySetting: pb.defDisplaySetting,
                    adminPostSetting: pb.adminPostSetting,
                    tagData: pb.tagInfo,
                    canBeSortedAlphabetically: pb.canBeSortedAlphabetically,
                    inRestrictedModeWhiteList: pb.restrictedModeSetting.whiteListSetting.hitWhitelist,
                    isUserCountVisible: pb.isUserCountVisible,
                    userCountVisibleSetting: pb.userCountVisibleSetting,
                    isOcicCustomerService: pb.isOcicCustomerService
                )
    }

    public static func transform(
        entity: RustPB.Basic_V1_Entity,
        chatOptionInfo: Basic_V1_ChatOptionInfo? = nil,
        pb: PBModel
    ) -> Chat {
        let chat = transform(pb: pb)
        chat.chatOptionInfo = chatOptionInfo
        if let chatter = try? Chatter.transformChatChatter(entity: entity, chatID: pb.id, id: pb.chatterID) {
            chat.atomicExtra.unsafeValue.chatter = chatter
            if pb.type == .p2P, pb.avatarKey.isEmpty {
                chat.avatarKey = chatter.avatarKey
            }
        }
        if let mailSetting = entity.mailSetting[pb.id] {
            chat.mailSetting = mailSetting
        }
        if let themeData = entity.chatThemes[pb.themeID], let theme = try? ServerPB_Entities_ChatTheme(serializedData: themeData) {
            chat.theme = theme
        }
        return chat
    }

    // swiftlint:disable function_body_length
    public func copy() -> Chat {
        let chat = Chat(
            id: self.id,
            type: self.type,
            name: self.name,
            namePinyin: self.namePinyin,
            lastMessageId: self.lastMessageId,
            lastMessagePosition: self.lastMessagePosition,
            updateTime: self.updateTime,
            createTime: self.createTime,
            chatterId: self.chatterId,
            description: self.description,
            avatar: self.avatar,
            avatarKey: self.avatarKey,
            miniAvatarKey: self.miniAvatarKey,
            ownerId: self.ownerId,
            chatterCount: self.chatterCount,
            userCount: self.userCount,
            isDepartment: self.isDepartment,
            isPublic: self.isPublic,
            isArchived: self.isArchived,
            isDeleted: self.isDeleted,
            isRemind: self.isRemind,
            role: self.role,
            hasVcChatPermission: self.hasVcChatPermission,
            isCustomerService: self.isCustomerService,
            isCustomIcon: self.isCustomIcon,
            textDraftId: self.textDraftId,
            postDraftId: self.postDraftId,
            isShortCut: self.isShortCut,
            announcement: self.announcement,
            offEditGroupChatInfo: self.offEditGroupChatInfo,
            tenantId: self.tenantId,
            isDissolved: self.isDissolved,
            isFrozen: self.isFrozen,
            messagePosition: self.messagePosition,
            addMemberPermission: self.addMemberPermission,
            atAllPermission: self.atAllPermission,
            messageVisibilitySetting: self.messageVisibilitySetting,
            joinMessageVisible: self.joinMessageVisible,
            quitMessageVisible: self.quitMessageVisible,
            shareCardPermission: self.shareCardPermission,
            addMemberApply: self.addMemberApply,
            putChatterApplyCount: self.putChatterApplyCount,
            anonymousTotalQuota: self.anonymousTotalQuota,
            showBanner: self.showBanner,
            lastVisibleMessageId: self.lastVisibleMessageId,
            burnLife: self.burnLife,
            isCrypto: self.isCrypto,
            isP2PAi: self.isP2PAi,
            isMeeting: self.isMeeting,
            chatable: self.chatable,
            muteable: self.muteable,
            isTenant: self.isTenant,
            isCrossTenant: self.isCrossTenant,
            isCrossWithKa: self.isCrossWithKa,
            isInBox: self.isInBox,
            isDelayed: self.isDelayed,
            isFlaged: self.isFlaged,
            isMuteAtAll: self.isMuteAtAll,
            firstMessagePostion: self.firstMessagePostion,
            bannerSetting: self.bannerSetting,
            isOfficialOncall: self.isOfficialOncall,
            isOfflineOncall: self.isOfflineOncall,
            oncallId: self.oncallId,
            lastVisibleMessagePosition: self.lastVisibleMessagePosition,
            readPosition: self.readPosition,
            readPositionBadgeCount: self.readPositionBadgeCount,
            lastMessagePositionBadgeCount: self.lastMessagePositionBadgeCount,
            isAutoTranslate: self.isAutoTranslate,
            typingTranslateSetting: self.typingTranslateSetting,
            chatMode: self.chatMode,
            lastThreadPositionBadgeCount: self.lastThreadPositionBadgeCount,
            readThreadPosition: self.readThreadPosition,
            readThreadPositionBadgeCount: self.readThreadPositionBadgeCount,
            lastVisibleThreadPosition: self.lastVisibleThreadPosition,
            lastVisibleThreadId: self.lastVisibleThreadId,
            lastThreadId: self.lastThreadId,
            lastThreadPosition: self.lastThreadPosition,
            myThreadsReadTimestamp: self.myThreadsReadTimestamp,
            myThreadsLastTimestamp: self.myThreadsLastTimestamp,
            myThreadsUnreadCount: self.myThreadsUnreadCount,
            sidebarButtons: self.sidebarButtons,
            isAllowPost: self.isAllowPost,
            postType: self.postType,
            hasWaterMark: self.hasWaterMark,
            lastDraftId: self.lastDraftId,
            editMessageDraftId: self.editMessageDraftId,
            lastReadPosition: self.lastReadPosition,
            lastReadOffset: self.lastReadOffset,
            topNoticePermissionSetting: self.topNoticePermissionSetting,
            chatTabPermissionSetting: self.chatTabPermissionSetting,
            tags: self.tags,
            isGroupAdmin: self.isGroupAdmin,
            anonymousId: self.anonymousId,
            isSuper: self.isSuper,
            isPrivateMode: self.isPrivateMode,
            teams: self.teamEntity,
            createUrgentSetting: self.createUrgentSetting,
            createVideoConferenceSetting: self.createVideoConferenceSetting,
            pinPermissionSetting: self.pinPermissionSetting,
            chatPinPermissionSetting: self.chatPinPermissionSetting,
            chatterExtraStates: self.chatterExtraStates,
            feedLabels: self.feedLabels,
            restrictedModeSetting: self.restrictedModeSetting,
            scheduleMessageDraftID: self.scheduleMessageDraftID,
            displayMode: self.displayMode,
            defDisplaySetting: self.defDisplaySetting,
            adminPostSetting: self.adminPostSetting,
            canBeSortedAlphabetically: self.canBeSortedAlphabetically,
            inRestrictedModeWhiteList: self.inRestrictedModeWhiteList,
            isUserCountVisible: self.isUserCountVisible,
            userCountVisibleSetting: self.userCountVisibleSetting,
            isOcicCustomerService: self.isOcicCustomerService
        )

        chat.chatOptionInfo = self.chatOptionInfo
        chat.mailSetting = self.mailSetting
        let extra = self.atomicExtra.value
        chat.atomicExtra = SafeAtomic(value: extra)
        return chat
    }
    // swiftlint:enable function_body_length

    // 信息防泄漏某个配置是否生效
    public func enableRestricted(_ type: RestrictedModeSettingType) -> Bool {
        switch type {
        case .copy:
            return self.enableRestricted(self.restrictedModeSetting.copy, checkWhiteList: true)
        case .forward:
            return self.enableRestricted(self.restrictedModeSetting.forward, checkWhiteList: true)
        case .screenshot:
            return self.enableRestricted(self.restrictedModeSetting.screenshot, checkWhiteList: true)
        case .download:
            return self.enableRestricted(self.restrictedModeSetting.download, checkWhiteList: true)
        }
    }

    public var enableMessageBurn: Bool {
        Self.logger.info("chat enableMessageBurn \(self.id) \(self.restrictedModeSetting.switch) \(self.restrictedModeSetting.onTimeDelMsgSetting.status)")
        guard self.restrictedModeSetting.switch else {
            return false
        }
        return self.restrictedModeSetting.onTimeDelMsgSetting.status
    }

    /// 此群下的资源文件应该被安全检测，仅从群维度看是否应该，实际还要根据子业务场景依据此属性做叠加判断
    public var shouldDetectFile: Bool {
        return !self.isPrivateMode && !self.isCrypto
    }

    // 信息防泄漏某个配置是否生效, 会前置判断switch是否开启
    private func enableRestricted(_ participant: Basic_V1_Chat.RestrictedModeSetting.Participant, checkWhiteList: Bool) -> Bool {
        Self.logger.info("chat enableRestricted \(self.id) \(participant.rawValue)  \(self.restrictedModeSetting.switch) \(self.inRestrictedModeWhiteList)")
        guard self.restrictedModeSetting.switch else {
            return false
        }
        if participant != .allMembers {
            // 如果在白名单中，不受管控
            if checkWhiteList, self.inRestrictedModeWhiteList {
                return false
            }
            return true
        }
        return false
    }

    private static func transformChatterExtraStates(_ dictionary: [Int32: Int32]) -> [ChatterExtraStatesType: Int32] {
        var res = [ChatterExtraStatesType: Int32]()
        for (key, value) in dictionary {
            guard let key = ChatterExtraStatesType(rawValue: Int(key)) else {
                Self.logger.debug("transformChatterExtraStates fail, no key: \(key)")
                continue
            }
            res[key] = value
        }
        return res
    }
}

public extension Chat {
    var badge: Int32 {
        return self.lastMessagePositionBadgeCount - self.readPositionBadgeCount
    }

    var threadBadge: Int32 {
        return self.lastThreadPositionBadgeCount - self.readThreadPositionBadgeCount
    }
}
