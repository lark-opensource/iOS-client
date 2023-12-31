//
//  Message.swift
//  Model
//
//  Created by qihongye on 2018/3/12.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

// swiftlint:disable file_length
import Foundation
import RustPB
import LKCommonsLogging

public enum DocsIconType: String {
    case unknown
    case doc
    case sheet
    case bitable
    case mindnote
    case file
    case slide
    case docx
    case wiki
    case folder
    case catalog
    case slides

    public init(docType: RustPB.Basic_V1_Doc.TypeEnum) {
        switch docType {
        case .unknown: self = .unknown
        case .doc: self = .doc
        case .sheet: self = .sheet
        case .bitable: self = .bitable
        case .mindnote: self = .mindnote
        case .file: self = .file
        case .slide: self = .slide
        case .docx: self = .docx
        case .wiki: self = .wiki
        case .folder: self = .folder
        case .catalog: self = .catalog
        case .slides: self = .slides
        case .shortcut: self = .unknown // 移动端尚未接入shortcut
        @unknown default:
            assert(false, "new value")
            self = .unknown
        }
    }
}

extension RustPB.Basic_V1_Doc.TypeEnum {
    public init(docsIconType: DocsIconType) {
        switch docsIconType {
        case .unknown: self = .unknown
        case .doc: self = .doc
        case .sheet: self = .sheet
        case .bitable: self = .bitable
        case .mindnote: self = .mindnote
        case .file: self = .file
        case .slide: self = .slide
        case .docx: self = .docx
        case .wiki: self = .wiki
        case .folder: self = .folder
        case .catalog: self = .catalog
        case .slides: self = .slides
        }
    }
}

public struct FoldUserInfo {
    public let chatter: Chatter
    public let count: Int32
    public init(chatter: Chatter, count: Int32) {
        self.chatter = chatter
        self.count = count
    }
}

public typealias MessageDisabledAction = RustPB.Basic_V1_Message.DisabledAction
public typealias PartialReplyInfo = RustPB.Basic_V1_Message.PartialReplyInfo

public final class Message: ModelProtocol, AtomicExtra {
    static var logger = Logger.log(Message.self, category: "TransformEntity")

    public typealias PBModel = RustPB.Basic_V1_Message
    public typealias AnonymousInfo = RustPB.Basic_V1_Message.AnonymousInfo

    public typealias EditMessageInfo = RustPB.Basic_V1_EditingMessageInfo

    public typealias TypeEnum = RustPB.Basic_V1_Message.TypeEnum

    public typealias FromType = RustPB.Basic_V1_Message.FromType
    public typealias SourceType = RustPB.Basic_V1_Message.SourceType
    public typealias AbbreviationEntity = RustPB.Basic_V1_AbbreviationEntity
    // 文件删除状态
    public typealias FileDeletedStatus = RustPB.Basic_V1_Message.FileDeletedStatus
    public typealias UrlPreviewEntity = RustPB.Basic_V1_UrlPreviewEntity
    // DLP权限管控
    public typealias MessageDLPState = RustPB.Basic_V1_MessageDLPState
    /// 折叠信息
    public typealias FoldDetail = RustPB.Basic_V1_MessageFoldDetail
    /// 消息产生时会话模式
    public typealias DisplayMode = RustPB.Basic_V1_Message.ChatDisplayModeSetting
    /// 流式消息状态，status = STREAM_TRANSPORT表示正在流式输出
    public typealias StreamStatus = RustPB.Basic_V1_Message.StreamStatus
    /// AI 回复的消息类型
    public typealias AIMessageType = RustPB.Basic_V1_Message.AIMessageType

    public var id: String
    public var cid: String
    public var type: TypeEnum
    public var channel: RustPB.Basic_V1_Channel
    /// 秒
    public var createTime: TimeInterval
    /// 毫秒
    public var createTimeMs: Int64
    /// 秒
    public var updateTime: TimeInterval
    public var rootId: String
    public var parentId: String
    public var syncToChatThreadRootID: String
    public var syncToChatRelatedMessageID: String
    public var syncToChatMessageType: RustPB.Basic_V1_Message.SyncToChatMessageType
    public var fromId: String
    public var reactions: [Reaction]
    public var isRecalled: Bool
    public var isCleaned: Bool
    public var isNoTraceDeleted: Bool
    public var isEdited: Bool
    public var replyCount: Int32
    public var position: Int32
    public var meRead: Bool
    public var parentSourceId: String
    public var rootSourceId: String
    public var isUrgent: Bool
    public var urgentId: String
    public var isAtMe: Bool
    public var isFlag: Bool
    public var isAtAll: Bool
    public var isTruncated: Bool
    public var unreadChatterIds: [String]
    public var textDraftId: String
    public var postDraftId: String
    public var editDraftId: String
    public var partialReplyInfo: PartialReplyInfo?
    //msgThread使用的草稿
    public var msgThreadDraftId: String
    public var isDeleted: Bool
    public var fromType: FromType
    /// 消息中最后一个doc的key
    public var docKey: String
    public var unreadCount: Int32
    public var readCount: Int32
    public var contentVersion: Int32 // 消息的版本，同步自 entities.Message.Version
    public var editVersion: Int32 // 编辑版本，大于0时UI应该显示"(已编辑)"
    public var editTimeMs: TimeInterval // 最新一次编辑时间, 单位毫秒
    /// 流式消息状态，status = STREAM_TRANSPORT表示正在流式输出
    public var streamStatus: StreamStatus
    /// AI 回复的消息类型
    public var aiMessageType: AIMessageType
    public var canShowAIProgress: Bool
    /// 消息赞踩状态
    public var feedbackStatus: Basic_V1_Message.AIMessageLikeFeedbackStatus
    public var isMultiEdited: Bool { //被二次编辑过
        return editVersion > 0
    }
    // 是否是此次ai对话的session的根消息
    public var isAiSessionFirstMsg: Bool

    public var editMessageInfo: EditMessageInfo?

    public var unackUrgentChatterIds: [String]
    public var ackUrgentChatterIds: [String]
    public var unackUrgentChatters: [Chatter] {
        get {
            return atomicExtra.value.unackUrgentChatters
        }
        set {
            atomicExtra.value.unackUrgentChatters = newValue
        }
    }
    public var ackUrgentChatters: [Chatter] {
       get {
           return atomicExtra.value.ackUrgentChatters
       }
       set {
           atomicExtra.value.ackUrgentChatters = newValue
       }
   }
    public var content: MessageContent {
        get {
            return atomicExtra.value.content
        }
        set {
            atomicExtra.value.content = newValue
        }
    }
    public var isVisible: Bool
    public var burnLife: Int32 /// 秒
    public var burnTime: Int64 /// 毫秒
    public var isBurned: Bool
    public var isCryptoIntermediate: Bool
    public var sourceType: SourceType
    public var sourceID: String
    public var recallerId: String
    public var recallerIdentity: RecallerIdentity
    public var pinTimestamp: Int64
    public var isReeditable: Bool
    public var badgeCount: Int32 // 该条消息之前有多少条计算badge的消息
    public var isBadged: Bool // 本条消息是否算badge
    public var isUntranslateable: Bool
    public var readAtChatterIds: [String] { // 已读at的chatterIds
        get {
            return atomicExtra.value.readAtChatterIds
        }
        set {
            atomicExtra.value.readAtChatterIds = newValue
        }
    }
    public var thread: RustPB.Basic_V1_Thread?
    public var threadId: String
    public var threadPosition: Int32
    public var threadBadgeCount: Int32
    /// 和MyAI在分会场产生的所有消息（包括我发的、系统消息等）都会有一个大于0的aiChatModeID
    public var aiChatModeID: Int64
    /// MyAI回复的原始内容，目前是MarkDown格式
    public var aiAnswerRawData: String
    /// 折叠消息的foldid. 第一条折叠消息的foldid = messageId
    public var foldId: Int64
    /// isFoldSubMessage需要被隐藏，fold message中 第一条折叠消息不会被隐藏
    public var isFoldSubMessage: Bool {
        return foldId > 0 && "\(foldId)" != self.id
    }
    public var isFoldRootMessage: Bool {
        return foldId > 0 && "\(foldId)" == self.id
    }

    public var foldUsers: [FoldUserInfo] {
        get {
            return atomicExtra.value.foldUsers
        }
        set {
            atomicExtra.value.foldUsers = newValue
        }
    }

    public var foldRecaller: Chatter? {
        get {
            return atomicExtra.value.foldRecaller
        }
        set {
            atomicExtra.value.foldRecaller = newValue
        }
    }

    public var securityExtra: Basic_V1_SecurityESCReviewExtra? {
        get {
            return atomicExtra.value.securityExtra
        }
        set {
            atomicExtra.value.securityExtra = newValue
        }
    }

    public var isCryptoMessage: Bool {
        //有焚毁时间，同时不是定时删除消息
        return self.burnLife > 0 && !self.isOnTimeDel
    }

    /// 原文语言
    public var messageLanguage: String
    /// 字符数（翻译用）
    public var characterLength: Int32
    /// 是否自动翻译的消息
    public var isManualTranslated: Bool
    /// 消息是否被其他人自动翻译过
    public var isAutoTranslatedByReceiver: Bool
    /// 译文语言
    public var translateLanguage: String
    /// 消息的展示规则：原文、译文、原文+译文
    public var displayRule: RustPB.Basic_V1_DisplayRule
    public var originalSenderID: String
    public var isForwardFromFriend: Bool
    public var isFileDeleted: Bool
    public var fileDeletedStatus: FileDeletedStatus
    /// 消息是否同步过消息依赖，埋点使用
    public var syncDependency: Bool
    /// 消息的密钥是否被删除
    public var isDecryptoFail: Bool
    /// URL预览Entity
    public var urlPreviewEntities: [String: URLPreviewEntity] {
        get {
            return atomicExtra.value.urlPreviewEntities
        }
        set {
            atomicExtra.value.urlPreviewEntities = newValue
        }
    }
    /// key: previewID
    public var messageLinks: [String: MessageLink] {
        get {
            return atomicExtra.value.messageLinks
        }
        set {
            atomicExtra.value.messageLinks = newValue
        }
    }
    /// MyAI分会话根消息上挂的InlinePreview。可能会挂在各种消息类型上（Text、Post、卡片等）。
    public var aiChatModeInlinePreviewEntities: [String: InlinePreviewEntity] {
        get {
            return atomicExtra.value.aiChatModeInlinePreviewEntities
        }
        set {
            atomicExtra.value.aiChatModeInlinePreviewEntities = newValue
        }
    }
    /// hangPoint：urlPreviewPush更新时需要
    public internal(set) var urlPreviewHangPointMap: [String: RustPB.Basic_V1_UrlPreviewHangPoint] = [:]
    // 只显示前四个url的卡片，卡片数据也只存前四个，因此需要保存previewID的顺序，用于展示和更新
    public internal(set) var orderedPreviewIDs: [String] = []
    // 是否独立卡片，独立卡片判断需要一些上下文，在菜单、子组件等场景都需要，因此在Message上加个字段记录这个状态
    public var isSinglePreview: Bool = false
    public var cryptoToken: String = ""

    public enum LocalStatus: Int {
        case process
        case fakeSuccess
        case success
        case fail
    }

    public var localStatus: LocalStatus = .process

    public typealias RecallerIdentity = RustPB.Basic_V1_Message.RecallerIdentity

    /// NER : abbreviationID ->  AbbreviationEntity
    public var abbreviationInfo: [String: AbbreviationEntity] {
        get {
            return atomicExtra.value.abbreviationInfo
        }
        set {
            atomicExtra.value.abbreviationInfo = newValue
        }
    }

    /// 提及结构：支持pano打标签功能引入的
    public var mentions: [String: Basic_V1_HashTagMentionEntity] {
        get {
            return atomicExtra.value.mentions
        }
        set {
            atomicExtra.value.mentions = newValue
        }
    }

    public var votedInfo: Vote_V1_VotedInfo? {
        get {
            return atomicExtra.value.votedInfo
        }
        set {
            atomicExtra.value.votedInfo = newValue
        }
    }

    public var voters: [String: Basic_V1_Chatter] {
        get {
            return atomicExtra.value.voters
        }
        set {
            atomicExtra.value.voters = newValue
        }
    }

    /// 是否是临时消息
    public var isEphemeral = false

    /// 图片是否支持被翻译的map
    public var imageTranslationAbilitys: [String: ImageTranslationAbility] = [:]
    public var anonymousInfo: AnonymousInfo?
    public var isAnnoymousSendFromMe: Bool {
        guard let info = anonymousInfo else { return false }
        return info.isAnonymous && info.isSender
    }

    // 附加属性
    struct MessageExtra {
        var unackUrgentChatters: [Chatter] = []
        var ackUrgentChatters: [Chatter] = []
        var content: MessageContent
        var fromChatter: Chatter?
        var parentMessage: Message?
        var rootMessage: Message?
        var syncToChatThreadRootMessage: Message?
        var syncToChatRelatedMessage: Message?
        var recaller: Chatter?
        var originalSender: Chatter?
        var translateContent: MessageContent?
        var pinChatter: Chatter?
        var mentions: [String: Basic_V1_HashTagMentionEntity] = [:]
        var votedInfo: Vote_V1_VotedInfo?
        var voters: [String: Basic_V1_Chatter] = [:]
        var abbreviationInfo: [String: AbbreviationEntity] = [:]
        var urlPreviewEntities: [String: URLPreviewEntity] = [:]
        var aiChatModeInlinePreviewEntities: [String: InlinePreviewEntity] = [:]
        // key: previewID
        var messageLinks: [String: MessageLink] = [:]
        var foldDetailInfo: FoldDetail?
        var foldUsers: [FoldUserInfo] = []
        var foldRecaller: Chatter?
        var securityExtra: Basic_V1_SecurityESCReviewExtra?
        weak var fatherMFMessage: Message?
        var mergeMessageIdPath: [String] = []
        var readAtChatterIds: [String] = []
        // 消息中存储的业务数据
        // i64表示消息id,内部的hashmap中，key表示业务名（BusinessKey），value表示业务存入的数据，以json格式写入。
        var localData: Basic_V1_MessageLocalDataInfoMap?
        init(_ content: MessageContent, readAtChatterIds: [String]) {
            self.content = content
            self.readAtChatterIds = readAtChatterIds
        }
    }
    
    typealias ExtraModel = MessageExtra
    var atomicExtra: SafeAtomic<MessageExtra>

    public var fromChatter: Chatter? {
        get {
            return atomicExtra.value.fromChatter
        }
        set {
            atomicExtra.value.fromChatter = newValue
        }
    }
    public var mergeMessageIdPath: [String] {
        get {
            return atomicExtra.value.mergeMessageIdPath
        }
        set {
            atomicExtra.value.mergeMessageIdPath = newValue
        }
    }
    // 子合并转发消息的父消息
    public var fatherMFMessage: Message? {
        get {
            return atomicExtra.value.fatherMFMessage
        }
        set {
            atomicExtra.value.fatherMFMessage = newValue
        }
    }
    public var parentMessage: Message? {
        get {
            return atomicExtra.value.parentMessage
        }
        set {
            atomicExtra.value.parentMessage = newValue
        }
    }
    public var rootMessage: Message? {
        get {
            return atomicExtra.value.rootMessage
        }
        set {
            atomicExtra.value.rootMessage = newValue
        }
    }

    public var syncToChatThreadRootMessage: Message? {
        get {
            return atomicExtra.value.syncToChatThreadRootMessage
        }
        set {
            atomicExtra.value.syncToChatThreadRootMessage = newValue
        }
    }

    public var syncToChatRelatedMessage: Message? {
        get {
            return atomicExtra.value.syncToChatRelatedMessage
        }
        set {
            atomicExtra.value.syncToChatRelatedMessage = newValue
        }
    }

    /// 折叠卡片相关信息
    public var foldDetailInfo: FoldDetail? {
        get {
            return atomicExtra.value.foldDetailInfo
        }
        set {
            atomicExtra.value.foldDetailInfo = newValue
        }
    }

    /// 有多少个不同的Doc，docKey -> Doc
    public var docs: [String: RustPB.Basic_V1_Doc]?
    /// 每个Doc对应的权限信息，docKey -> DocPermission
    public var docPermissions: [String: RustPB.Basic_V1_DocPermission]?
    /// 下载Doc预览图时根据DocPermission设置下载参数，docURL -> DocPermission
    public var url2Permissions: [String: RustPB.Basic_V1_DocPermission]?
    /// 和message.docKey对应同一个Doc，下载预览图时根据docsUrl从url2Permissions得到对应的DocPermission设置下载参数
    public var docsUrl: String?
    // CCM接入URL中台之后标识message中是否包含Doc URL
    public var isIncludeDocURL: Bool = false
    public var recaller: Chatter? {
        get {
            return atomicExtra.value.recaller
        }
        set {
            atomicExtra.value.recaller = newValue
        }
    }
    public var readChatterIds: [String] = []
    public var originalSender: Chatter? {
        get {
            return atomicExtra.value.originalSender
        }
        set {
            atomicExtra.value.originalSender = newValue
        }
    }
    /// 译文
    public var translateContent: MessageContent? {
       get {
           return atomicExtra.value.translateContent
       }
       set {
           atomicExtra.value.translateContent = newValue
       }
    }
    public var pinChatter: Chatter? {
       get {
           return atomicExtra.value.pinChatter
       }
       set {
           atomicExtra.value.pinChatter = newValue
       }
    }
    public var localData: Basic_V1_MessageLocalDataInfoMap? {
        get {
            return atomicExtra.value.localData
        }
        set {
            atomicExtra.value.localData = newValue
        }
    }
    public enum TranslateState: Int {
        case origin
        case translating
        case translated
    }

    /// 约定此字段只影响"翻译icon"的行为
    public var translateState: TranslateState = .origin
    public var threadMessageType: RustPB.Basic_V1_Message.ThreadMessageType
    // 消息thread前排回复的人
    public var replyInThreadTopRepliers: [Chatter] = []
    public var replyInThreadCount: Int32 = 0
    public var replyInThreadLastVisibleMessagePosition: Int32 = 0
    public var replyInThreadLastReplies: [Message] = []

    public struct MergeForwardInfo {
        public var messageThread: MergeForwardContent.MessageThread? //只有合并转发的消息中 是replyInThread根消息的消息 才有这个属性
        public let originChatID: Int64
        public var originChat: Chat?
        public var fromChatChatters: [String: Chatter.PBModel]?

        public init(originChatID: Int64) {
            self.originChatID = originChatID
        }
    }
    public var mergeForwardInfo: MergeForwardInfo?

    // DLP状态
    public let dlpState: MessageDLPState
    public var scheduleMessageDraftId: String?

    public let disabledAction: MessageDisabledAction
    public let setGrey: Bool

    // 是否被设置为保密消息
    private let _isRestricted: Bool

    // 合并转发的子消息对齐父消息
    public var isRestricted: Bool {
        if let fatherMFMessage = self.fatherMFMessage?._isRestricted {
            return fatherMFMessage
        } else {
            return self._isRestricted
        }
    }

    public var displayMode: DisplayMode
    public var displayInThreadMode: Bool {
        switch self.displayMode {
        case.thread:
            return true
        default:
            return false
        }
    }

    // 风险文件数组
    public var riskObjectKeys: [String]
    // 是否为定时删除消息
    public var isOnTimeDel: Bool

    // 密聊消息是否解密失败
    public var isSecretChatDecryptedFailed: Bool
    // nolint: long_function
    public init(id: String,
                cid: String,
                type: TypeEnum,
                channel: RustPB.Basic_V1_Channel,
                createTime: TimeInterval,
                createTimeMs: Int64,
                updateTime: TimeInterval,
                rootId: String,
                parentId: String,
                syncToChatThreadRootID: String,
                syncToChatRelatedMessageID: String,
                fromId: String,
                foldId: Int64,
                isRecalled: Bool,
                isCleaned: Bool,
                isNoTraceDeleted: Bool,
                isEdited: Bool,
                replyCount: Int32,
                position: Int32,
                meRead: Bool,
                parentSourceId: String,
                rootSourceId: String,
                isUrgent: Bool,
                urgentId: String,
                isAtMe: Bool,
                isFlag: Bool,
                isAtAll: Bool,
                isTruncated: Bool,
                unreadChatterIds: [String],
                textDraftId: String,
                postDraftId: String,
                editDraftId: String,
                msgThreadDraftId: String,
                isDeleted: Bool,
                fromType: FromType,
                docKey: String,
                unreadCount: Int32,
                readCount: Int32,
                unackUrgentChatterIds: [String],
                ackUrgentChatterIds: [String],
                content: MessageContent,
                reactions: [Reaction],
                isVisible: Bool,
                burnLife: Int32,
                burnTime: Int64,
                isBurned: Bool,
                isCryptoIntermediate: Bool,
                sourceType: SourceType,
                sourceID: String,
                recallerId: String,
                recallerIdentity: RecallerIdentity,
                pinTimestamp: Int64,
                isReeditable: Bool,
                badgeCount: Int32,
                isBadged: Bool,
                isUntranslateable: Bool,
                readAtChatterIds: [String],
                threadId: String,
                threadPosition: Int32,
                threadBadgeCount: Int32,
                aiChatModeID: Int64,
                aiAnswerRawData: String,
                messageLanguage: String,
                characterLength: Int32,
                isManualTranslated: Bool = false,
                displayRule: RustPB.Basic_V1_DisplayRule,
                isAutoTranslatedByReceiver: Bool,
                translateLanguage: String,
                originalSenderID: String,
                isForwardFromFriend: Bool,
                isFileDeleted: Bool,
                fileDeletedStatus: FileDeletedStatus,
                syncDependency: Bool,
                isDecryptoFail: Bool,
                anonymousInfo: AnonymousInfo? = nil,
                cryptoToken: String = "",
                threadMessageType: RustPB.Basic_V1_Message.ThreadMessageType = .unknownThreadMessage,
                syncToChatMessageType: RustPB.Basic_V1_Message.SyncToChatMessageType,
                contentVersion: Int32 = 0,
                editVersion: Int32 = 0,
                editTimeMs: TimeInterval = 0,
                dlpState: MessageDLPState = .unknownDlpState,
                scheduleMessageDraftId: String? = nil,
                displayMode: DisplayMode,
                riskObjectKeys: [String] = [],
                disabledAction: MessageDisabledAction,
                setGrey: Bool,
                _isRestricted: Bool,
                isOnTimeDel: Bool,
                streamStatus: StreamStatus,
                aiMessageType: AIMessageType,
                canShowAIProgress: Bool,
                feedbackStatus: Basic_V1_Message.AIMessageLikeFeedbackStatus,
                isSecretChatDecryptedFailed: Bool,
                partialReplyInfo: PartialReplyInfo?,
                isAiSessionFirstMsg: Bool
        ) {
        self.id = id
        self.cid = cid
        self.type = type
        self.channel = channel
        self.createTime = createTime
        self.createTimeMs = createTimeMs
        self.updateTime = updateTime
        self.rootId = rootId
        self.parentId = parentId
        self.fromId = fromId
        self.syncToChatThreadRootID = syncToChatThreadRootID
        self.syncToChatRelatedMessageID = syncToChatRelatedMessageID
        self.foldId = foldId
        self.isRecalled = isRecalled
        self.isCleaned = isCleaned
        self.isNoTraceDeleted = isNoTraceDeleted
        self.isEdited = isEdited
        self.replyCount = replyCount
        self.position = position
        self.meRead = meRead
        self.parentSourceId = parentSourceId
        self.rootSourceId = rootSourceId
        self.isUrgent = isUrgent
        self.urgentId = urgentId
        self.isAtMe = isAtMe
        self.isFlag = isFlag
        self.isAtAll = isAtAll
        self.isTruncated = isTruncated
        self.unreadChatterIds = unreadChatterIds
        self.textDraftId = textDraftId
        self.postDraftId = postDraftId
        self.editDraftId = editDraftId
        self.msgThreadDraftId = msgThreadDraftId
        self.isDeleted = isDeleted
        self.fromType = fromType
        self.docKey = docKey
        self.unreadCount = unreadCount
        self.readCount = readCount
        self.unackUrgentChatterIds = unackUrgentChatterIds
        self.ackUrgentChatterIds = ackUrgentChatterIds
        self.reactions = reactions
        self.isVisible = isVisible
        self.burnLife = burnLife
        self.isBurned = isBurned
        self.burnTime = burnTime
        self.isCryptoIntermediate = isCryptoIntermediate
        self.sourceType = sourceType
        self.sourceID = sourceID
        self.recallerId = recallerId
        self.recallerIdentity = recallerIdentity
        self.pinTimestamp = pinTimestamp
        self.isReeditable = isReeditable
        self.badgeCount = badgeCount
        self.isBadged = isBadged
        self.isUntranslateable = isUntranslateable
        self.threadId = threadId
        self.threadPosition = threadPosition
        self.threadBadgeCount = threadBadgeCount
        self.aiChatModeID = aiChatModeID
        self.aiAnswerRawData = aiAnswerRawData
        self.messageLanguage = messageLanguage
        self.characterLength = characterLength
        self.isManualTranslated = isManualTranslated
        self.displayRule = displayRule
        self.isAutoTranslatedByReceiver = isAutoTranslatedByReceiver
        self.translateLanguage = translateLanguage
        self.originalSenderID = originalSenderID
        self.isForwardFromFriend = isForwardFromFriend
        self.isFileDeleted = isFileDeleted
        self.fileDeletedStatus = fileDeletedStatus
        self.syncDependency = syncDependency
        self.isDecryptoFail = isDecryptoFail
        self.anonymousInfo = anonymousInfo
        self.atomicExtra = SafeAtomic(value: MessageExtra(content, readAtChatterIds: readAtChatterIds))
        self.cryptoToken = cryptoToken
        self.threadMessageType = threadMessageType
        self.syncToChatMessageType = syncToChatMessageType
        self.contentVersion = contentVersion
        self.editVersion = editVersion
        self.editTimeMs = editTimeMs
        self.dlpState = dlpState
        self.scheduleMessageDraftId = scheduleMessageDraftId
        self.displayMode = displayMode
        self.riskObjectKeys = riskObjectKeys
        self.disabledAction = disabledAction
        self.setGrey = setGrey
        self._isRestricted = _isRestricted
        self.isOnTimeDel = isOnTimeDel
        self.streamStatus = streamStatus
        self.aiMessageType = aiMessageType
        self.canShowAIProgress = canShowAIProgress
        self.feedbackStatus = feedbackStatus
        self.isSecretChatDecryptedFailed = isSecretChatDecryptedFailed
        self.partialReplyInfo = partialReplyInfo
        self.isAiSessionFirstMsg = isAiSessionFirstMsg
    }

    // swiftlint:disable function_body_length
    public static func transform(pb: PBModel) -> Message {
        var content: MessageContent
        var type: Message.TypeEnum = pb.type
        switch type {
        case .unknown:
            content = UnknownContent()
        case .text:
            content = TextContent.transform(pb: pb)
        case .image:
            content = ImageContent.transform(pb: pb)
        case .post:
            content = PostContent.transform(pb: pb)
        case .audio:
            content = AudioContent.transform(pb: pb)
        case .file:
            content = FileContent.transform(pb: pb)
        case .folder:
            content = FolderContent.transform(pb: pb)
        case .sticker:
            content = StickerContent.transform(pb: pb)
        case .system:
            content = SystemContent.transform(pb: pb)
        case .shareUserCard:
            content = ShareUserCardContent.transform(pb: pb)
        case .shareGroupChat:
            content = ShareGroupChatContent.transform(pb: pb)
        case .email:
            content = UnknownContent()
        case .mergeForward:
            content = MergeForwardContent.transform(pb: pb)
        case .card:
            content = CardContent.transform(pb: pb)
        case .media:
            content = MediaContent.transform(pb: pb)
        case .shareCalendarEvent:
            content = EventShareContent(pb: pb.content.shareCalendarEventContent, messageId: pb.id)
        case .hongbao, .commercializedHongbao:
            content = HongbaoContent.transform(pb: pb)
        case .calendar:
            content = CalendarBotCardContent(pb: pb.content.calendarContent)
        case .generalCalendar:
            if pb.content.generalCalendarContent.isUnknownType {
                type = .unknown
                content = UnknownContent()
            } else {
                switch pb.content.generalCalendarContent.calendarType {
                case .rsvpCard:
                    content = GeneralCalendarEventRSVPContent(pb: pb.content.generalCalendarContent.rsvpCardInfo)
                case .appointmentMessageNotify:
                    content = SchedulerAppointmentCardContent(pb: pb.content.generalCalendarContent.appointmentMessageNotifyData)
                case .appointmentMessageRoundRobin:
                    content = RoundRobinCardContent(pb: pb.content.generalCalendarContent.appointmentMessageRoundRobinData)
                @unknown default:
                    content = GeneralCalendarBotCardContent(pb: pb.content.generalCalendarContent)
                }
            }
        case .videoChat:
            let type = pb.content.videochatContent.type
            switch type {
            case .meetingCard:
                content = VChatMeetingCardContent.transform(pb: pb)
            case .chatRoomCard:
                content = VChatRoomCardContent.transform(pb: pb)
            case .unknown:
                content = UnknownContent()
            @unknown default:
                assert(false, "new value")
                content = UnknownContent()
            }
        case .location:
            content = LocationContent.transform(pb: pb)
        case .todo:
            content = TodoContent.transform(pb: pb.content.todoOperationContent)
        case .vote:
            content = VoteContent.transform(pb: pb)
        case .diagnose:
            content = UnknownContent()
        @unknown default:
            assert(false, "new value")
            content = UnknownContent()
        }

        let message = Message(
            id: pb.id,
            cid: pb.cid,
            type: type,
            channel: pb.channel,
            createTime: TimeInterval(pb.createTime),
            createTimeMs: pb.createTimeMs,
            updateTime: TimeInterval(pb.updateTime),
            rootId: pb.rootID,
            parentId: pb.parentID,
            syncToChatThreadRootID: String(pb.syncToChatThreadRootID),
            syncToChatRelatedMessageID: String(pb.syncToChatRelatedMessageID),
            fromId: pb.fromID,
            foldId: pb.foldID,
            isRecalled: pb.isRecalled,
            isCleaned: pb.isCleaned,
            isNoTraceDeleted: pb.isNoTraceDeleted,
            isEdited: pb.isEdited,
            replyCount: pb.replyCount,
            position: pb.position,
            meRead: pb.meRead,
            parentSourceId: pb.parentSourceID,
            rootSourceId: pb.rootSourceID,
            isUrgent: pb.isUrgent,
            urgentId: pb.urgentID,
            isAtMe: pb.isAtMe,
            isFlag: pb.isFlag,
            isAtAll: pb.isAtAll,
            isTruncated: pb.isTruncated,
            unreadChatterIds: pb.unreadChatterIds,
            textDraftId: pb.textDraftID,
            postDraftId: pb.postDraftID,
            editDraftId: pb.editDraftID,
            msgThreadDraftId: pb.msgThreadDraftID,
            isDeleted: pb.isDeleted,
            fromType: pb.fromType,
            docKey: pb.docKey,
            unreadCount: pb.unreadCount,
            readCount: pb.readCount,
            unackUrgentChatterIds: pb.unackUrgentChatterIds,
            ackUrgentChatterIds: pb.ackUrgentChatterIds,
            content: content,
            reactions: pb.reactions.map(Reaction.transform),
            isVisible: pb.isVisible,
            burnLife: pb.burnLife,
            burnTime: pb.burnTime,
            isBurned: pb.isBurned,
            isCryptoIntermediate: pb.isCryptoIntermediate,
            sourceType: pb.sourceType,
            sourceID: pb.sourceID,
            recallerId: pb.recallerID,
            recallerIdentity: pb.recallerIdentity,
            pinTimestamp: pb.pin.timestamp,
            isReeditable: pb.isReeditable,
            badgeCount: pb.badgeCount,
            isBadged: pb.isBadged,
            isUntranslateable: pb.isUntranslateable,
            readAtChatterIds: pb.readAtChatterIds,
            threadId: pb.threadID,
            threadPosition: pb.threadPosition,
            threadBadgeCount: pb.threadBadgeCount,
            aiChatModeID: pb.aiChatModeID,
            aiAnswerRawData: pb.aiAnswerRawData,
            messageLanguage: pb.messageLanguage,
            characterLength: pb.characterLength,
            isManualTranslated: pb.isManualTranslated,
            displayRule: pb.translateMessageDisplayRule.rule,
            isAutoTranslatedByReceiver: pb.isAutoTranslatedByReceiver,
            translateLanguage: pb.translateLanguage,
            originalSenderID: pb.originalSenderID,
            isForwardFromFriend: pb.forwardFromFriend,
            isFileDeleted: pb.isFileDeleted,
            fileDeletedStatus: pb.fileDeletedStatus,
            syncDependency: pb.syncDependency,
            isDecryptoFail: pb.isDecryptoFail,
            anonymousInfo: pb.anonymousInfo,
            cryptoToken: pb.cryptoToken,
            threadMessageType: pb.threadMessageType,
            syncToChatMessageType: pb.syncToChatMessageType,
            contentVersion: pb.version.contentVersion,
            editVersion: pb.editVersion,
            editTimeMs: TimeInterval(pb.editTimeMs),
            dlpState: pb.dlpState,
            scheduleMessageDraftId: pb.scheduleMessageDraftID,
            displayMode: pb.inChatDisplayMode,
            riskObjectKeys: pb.content.riskObjectKeys,
            disabledAction: pb.disabledAction,
            setGrey: pb.setGrey,
            _isRestricted:  pb.isRestricted,
            isOnTimeDel: pb.isOnTimeDel,
            streamStatus: pb.streamStatus,
            aiMessageType: pb.aiMessageType,
            canShowAIProgress: pb.canShowAiProgress,
            feedbackStatus: pb.aiMessageLikeFeedbackStatus,
            isSecretChatDecryptedFailed: pb.isSecretChatDecryptedFailed,
            partialReplyInfo: pb.hasPartialReplyInfo ? pb.partialReplyInfo : nil,
            isAiSessionFirstMsg: pb.isAiSessionFirstMsg
        )
        message.localStatus = .success
        message.imageTranslationAbilitys = pb.imageTranslationAbility
        message.urlPreviewHangPointMap = pb.content.urlPreviewHangPointMap
        message.orderedPreviewIDs = getOrderedPreviewIDs(message: pb)

        return message
    }

    // swiftlint:enable function_body_length

    public func copy() -> Message {
        let message = Message(
            id: self.id,
            cid: self.cid,
            type: self.type,
            channel: self.channel,
            createTime: self.createTime,
            createTimeMs: self.createTimeMs,
            updateTime: self.updateTime,
            rootId: self.rootId,
            parentId: self.parentId,
            syncToChatThreadRootID: self.syncToChatThreadRootID,
            syncToChatRelatedMessageID: self.syncToChatRelatedMessageID,
            fromId: self.fromId,
            foldId: self.foldId,
            isRecalled: self.isRecalled,
            isCleaned: self.isCleaned,
            isNoTraceDeleted: isNoTraceDeleted,
            isEdited: self.isEdited,
            replyCount: self.replyCount,
            position: self.position,
            meRead: self.meRead,
            parentSourceId: self.parentSourceId,
            rootSourceId: self.rootSourceId,
            isUrgent: self.isUrgent,
            urgentId: self.urgentId,
            isAtMe: self.isAtMe,
            isFlag: self.isFlag,
            isAtAll: self.isAtAll,
            isTruncated: self.isTruncated,
            unreadChatterIds: self.unreadChatterIds,
            textDraftId: self.textDraftId,
            postDraftId: self.postDraftId,
            editDraftId: self.editDraftId,
            msgThreadDraftId: self.msgThreadDraftId,
            isDeleted: self.isDeleted,
            fromType: self.fromType,
            docKey: self.docKey,
            unreadCount: self.unreadCount,
            readCount: self.readCount,
            unackUrgentChatterIds: self.unackUrgentChatterIds,
            ackUrgentChatterIds: self.ackUrgentChatterIds,
            content: self.content,
            reactions: self.reactions,
            isVisible: self.isVisible,
            burnLife: self.burnLife,
            burnTime: self.burnTime,
            isBurned: self.isBurned,
            isCryptoIntermediate: self.isCryptoIntermediate,
            sourceType: self.sourceType,
            sourceID: self.sourceID,
            recallerId: self.recallerId,
            recallerIdentity: self.recallerIdentity,
            pinTimestamp: self.pinTimestamp,
            isReeditable: self.isReeditable,
            badgeCount: self.badgeCount,
            isBadged: self.isBadged,
            isUntranslateable: self.isUntranslateable,
            readAtChatterIds: self.readAtChatterIds,
            threadId: self.threadId,
            threadPosition: self.threadPosition,
            threadBadgeCount: self.threadBadgeCount,
            aiChatModeID: self.aiChatModeID,
            aiAnswerRawData: self.aiAnswerRawData,
            messageLanguage: self.messageLanguage,
            characterLength: self.characterLength,
            displayRule: self.displayRule,
            isAutoTranslatedByReceiver: self.isAutoTranslatedByReceiver,
            translateLanguage: self.translateLanguage,
            originalSenderID: self.originalSenderID,
            isForwardFromFriend: self.isForwardFromFriend,
            isFileDeleted: self.isFileDeleted,
            fileDeletedStatus: self.fileDeletedStatus,
            syncDependency: self.syncDependency,
            isDecryptoFail: self.isDecryptoFail,
            anonymousInfo: self.anonymousInfo,
            cryptoToken: self.cryptoToken,
            threadMessageType: self.threadMessageType,
            syncToChatMessageType: self.syncToChatMessageType,
            contentVersion: self.contentVersion,
            editVersion: self.editVersion,
            editTimeMs: self.editTimeMs,
            dlpState: self.dlpState,
            scheduleMessageDraftId: self.scheduleMessageDraftId,
            displayMode: self.displayMode,
            riskObjectKeys: self.riskObjectKeys,
            disabledAction: self.disabledAction,
            setGrey: self.setGrey,
            _isRestricted: self._isRestricted,
            isOnTimeDel: self.isOnTimeDel,
            streamStatus: self.streamStatus,
            aiMessageType: self.aiMessageType,
            canShowAIProgress: self.canShowAIProgress,
            feedbackStatus: self.feedbackStatus,
            isSecretChatDecryptedFailed: self.isSecretChatDecryptedFailed,
            partialReplyInfo: self.partialReplyInfo,
            isAiSessionFirstMsg: self.isAiSessionFirstMsg
        )

        message.docs = self.docs
        message.docPermissions = self.docPermissions
        message.url2Permissions = self.url2Permissions
        message.docsUrl = self.docsUrl
        message.isIncludeDocURL = self.isIncludeDocURL
        message.readChatterIds = self.readChatterIds
        message.translateState = self.translateState
        message.localStatus = self.localStatus
        message.originalSender = self.originalSender
        message.imageTranslationAbilitys = self.imageTranslationAbilitys
        message.urlPreviewEntities = self.urlPreviewEntities
        message.messageLinks = self.messageLinks
        message.urlPreviewHangPointMap = self.urlPreviewHangPointMap
        message.orderedPreviewIDs = self.orderedPreviewIDs
        message.replyInThreadCount = self.replyInThreadCount
        message.replyInThreadLastVisibleMessagePosition = self.replyInThreadLastVisibleMessagePosition
        message.replyInThreadTopRepliers = self.replyInThreadTopRepliers
        message.thread = self.thread
        message.mergeForwardInfo = self.mergeForwardInfo

        let extra = self.atomicExtra.value
        message.atomicExtra = SafeAtomic(value: extra)
        return message
    }

    // swiftlint:disable function_body_length
    private static func transform(quasi: Basic_V1_QuasiMessage) -> Message {
        var content: MessageContent
        var type: Message.TypeEnum = quasi.type
        switch type {
        case .unknown:
            content = UnknownContent()
        case .text:
            content = TextContent(
                text: quasi.content.text,
                previewUrls: quasi.content.previewUrls,
                richText: quasi.content.richText,
                docEntity: quasi.content.hasDocEntity ? quasi.content.docEntity : nil,
                abbreviation: quasi.content.hasAbbreviation ? quasi.content.abbreviation : nil,
                typedElementRefs: quasi.content.typedElementRefs
            )
        case .image:
            var imageContent = ImageContent(image: quasi.content.image, cryptoToken: quasi.content.cryptoToken)
            imageContent.image.origin.key = quasi.cid
            imageContent.image.thumbnail.key = quasi.cid
            imageContent.image.middle.key = quasi.cid
            content = imageContent
        case .post:
            content = PostContent(
                title: quasi.content.title,
                text: quasi.content.text,
                isGroupAnnouncement: quasi.content.isGroupAnnouncement,
                richText: quasi.content.richText,
                previewUrls: quasi.content.previewUrls,
                docEntity: quasi.content.hasDocEntity ? quasi.content.docEntity : nil,
                abbreviation: quasi.content.hasAbbreviation ? quasi.content.abbreviation : nil,
                typedElementRefs: quasi.content.typedElementRefs
            )
        case .audio:
            content = AudioContent(
                key: quasi.content.key,
                duration: quasi.content.duration,
                size: quasi.content.size,
                voiceText: quasi.content.voice2Text,
                hideVoice2Text: quasi.content.hideVoice2Text,
                originSenderID: quasi.content.originSenderIDStr,
                localUploadID: quasi.content.localUploadID,
                originTosKey: quasi.content.originTosKey,
                originSenderName: quasi.content.originSenderName,
                isFriend: quasi.content.isFriend,
                isAudioRecognizeFinish: quasi.content.isAudioRecognizeFinish,
                audio2TextStartTime: TimeInterval(quasi.content.audio2TextStartTime),
                isAudioWithText: quasi.content.isAudioWithText
            )
        case .file:
            content = FileContent(
                key: quasi.content.key,
                name: quasi.content.name,
                size: quasi.content.size,
                mime: quasi.content.mime,
                filePath: quasi.content.filePath,
                cacheFilePath: quasi.content.cacheFilePath,
                fileSource: quasi.content.fileSource,
                namespace: quasi.content.namespace,
                isInMyNutStore: quasi.content.isInMyNutStore,
                lanTransStatus: quasi.content.lanTransStatus,
                hangPoint: quasi.content.urlPreviewHangPointMap[FileContent.FILE_PREVIEW_HANG_POINT_KEY],
                fileAbility: quasi.content.fileAbility,
                filePermission: quasi.content.filePermission,
                fileLastUpdateUserId: quasi.content.fileLastUpdateUserID,
                fileLastUpdateTimeMs: quasi.content.fileLastUpdateTimeMs,
                filePreviewStage: .normal,
                isEncrypted: quasi.content.isEncrypted
            )
        case .folder:
            content = FolderContent(
                key: quasi.content.key,
                name: quasi.content.name,
                size: quasi.content.size,
                fileSource: quasi.content.fileSource,
                lanTransStatus: quasi.content.lanTransStatus
            )
        case .sticker:
            content = StickerContent(
                key: quasi.content.key,
                width: quasi.content.width,
                height: quasi.content.height,
                stickerID: quasi.content.stickerID,
                stickerSetID: quasi.content.stickerSetID,
                stickerInfo: quasi.content.stickerInfo
            )
        case .system:
            var e2eeCallInfo: SystemContent.E2EECallInfo?
            if !quasi.content.e2EeFromID.isEmpty,
                !quasi.content.e2EeToID.isEmpty {
                e2eeCallInfo = SystemContent.E2EECallInfo(
                    e2EeFromID: quasi.content.e2EeFromID,
                    e2EeToID: quasi.content.e2EeToID,
                    manipulatorID: quasi.content.triggerID)
            }
            content = SystemContent(
                template: quasi.content.template,
                values: quasi.content.values,
                systemType: quasi.content.systemType,
                e2eeCallInfo: e2eeCallInfo,
                systemContentValues: quasi.content.systemContentValues,
                systemExtraContent: quasi.content.systemExtraContent,
                itemActions: quasi.content.itemActions,
                version: quasi.content.systemMessageVersion
            )
        case .shareUserCard:
            content = ShareUserCardContent(shareChatterID: quasi.content.shareChatterID)
        case .shareGroupChat:
            content = ShareGroupChatContent(
                shareChatID: quasi.content.shareChatID,
                joinToken: quasi.content.joinToken,
                expireTime: TimeInterval(quasi.content.expireTime)
            )
        case .calendar:
            content = CalendarBotCardContent(pb: quasi.content.calendarContent)
        case .generalCalendar:
            if quasi.content.generalCalendarContent.isUnknownType {
                type = .unknown
                content = UnknownContent()
            } else if quasi.content.generalCalendarContent.calendarType == .rsvpCard {
                content = GeneralCalendarEventRSVPContent(pb: quasi.content.generalCalendarContent.rsvpCardInfo)
            } else {
                content = GeneralCalendarBotCardContent(pb: quasi.content.generalCalendarContent)
            }
        case .email:
            content = UnknownContent()
        case .mergeForward:
            let mergeForwardContent = quasi.content.mergeForwardContent
            content = MergeForwardContent(
                messageId: quasi.id,
                messages: mergeForwardContent.messages.map({ Message.transform(pb: $0) }),
                chatType: mergeForwardContent.chatType,
                originChatID: mergeForwardContent.originChatID,
                groupChatName: mergeForwardContent.groupChatName,
                p2PCreatorName: mergeForwardContent.p2PCreatorName,
                p2PPartnerName: mergeForwardContent.p2PPartnerName,
                p2PCreatorID: mergeForwardContent.p2PCreatorID,
                p2PPartnerID: mergeForwardContent.p2PPartnerID,
                chatters: mergeForwardContent.chatters,
                thread: mergeForwardContent.thread.id.isEmpty ? nil : mergeForwardContent.thread,
                messageReactionInfo: mergeForwardContent.reactionSnapshots,
                messageThreads: mergeForwardContent.messageThreads)
        case .card:
            content = CardContent.transform(cardContent: quasi.content.cardContent)
        case .media:
            content = MediaContent.transform(
                content: quasi.content.mediaContent,
                filePath: quasi.content.filePath
            )
        case .shareCalendarEvent:
            content = EventShareContent(pb: quasi.content.shareCalendarEventContent, messageId: quasi.id)
        case .hongbao, .commercializedHongbao:
            content = UnknownContent()
        case .videoChat:
            let videoChatContent = quasi.content.videochatContent
            switch videoChatContent.type {
            case .meetingCard:
                let meetingCard = videoChatContent.meetingCard
                content = VChatMeetingCardContent(meetingCard: meetingCard,
                                                  chatID: quasi.chatID, messageID: quasi.id)
            case .chatRoomCard:
                let meetingCard = videoChatContent.meetingCard
                content = VChatRoomCardContent(forwarderID: meetingCard.forwarderID)
            case .unknown:
                content = UnknownContent()
            @unknown default:
                assert(false, "new value")
                content = UnknownContent()
            }
        case .location:
            let locationContent = quasi.content.locationContent
            content = LocationContent(
                latitude: locationContent.latitude,
                longitude: locationContent.longitude,
                zoomLevel: locationContent.zoomLevel,
                vendor: locationContent.vendor,
                image: locationContent.image,
                location: locationContent.location,
                isInternal: locationContent.isInternal)
        case .todo:
            content = TodoContent.transform(pb: quasi.content.todoOperationContent)
        case .diagnose:
            content = UnknownContent()
        case .vote:
            content = VoteContent.transform(content: quasi.content.voteContent)
        @unknown default:
            assert(false, "new value")
            content = UnknownContent()
        }
        let message = Message(
            id: quasi.id,
            cid: quasi.cid,
            type: type,
            channel: quasi.channel,
            createTime: TimeInterval(quasi.createTime),
            createTimeMs: quasi.createTime * 1000,
            updateTime: TimeInterval(quasi.createTime),
            rootId: quasi.rootID,
            parentId: quasi.parentID,
            syncToChatThreadRootID: String(quasi.syncToChatThreadRootID),
            syncToChatRelatedMessageID: "0",
            fromId: quasi.fromID,
            foldId: 0,
            isRecalled: false,
            isCleaned: false,
            isNoTraceDeleted: false,
            isEdited: false,
            replyCount: 0,
            position: quasi.position,
            meRead: true,
            parentSourceId: quasi.parentSourceID,
            rootSourceId: quasi.rootSourceID,
            isUrgent: false,
            urgentId: "",
            isAtMe: false,
            isFlag: false,
            isAtAll: false,
            isTruncated: false,
            unreadChatterIds: quasi.unreadChatterIds,
            textDraftId: "",
            postDraftId: "",
            editDraftId: "",
            msgThreadDraftId: "",
            isDeleted: false,
            fromType: .user,
            docKey: "",
            unreadCount: quasi.unreadCount,
            readCount: quasi.readCount,
            unackUrgentChatterIds: [],
            ackUrgentChatterIds: [],
            content: content,
            reactions: [],
            isVisible: true,
            burnLife: 0,
            burnTime: 0,
            isBurned: false,
            isCryptoIntermediate: false,
            sourceType: .typeFromMessage,
            sourceID: quasi.id,
            recallerId: "",
            recallerIdentity: .unknownIdentity,
            pinTimestamp: 0,
            isReeditable: false,
            badgeCount: 0,
            isBadged: true,
            isUntranslateable: false,
            readAtChatterIds: [],
            threadId: quasi.threadID,
            threadPosition: quasi.threadPosition,
            threadBadgeCount: 0,
            aiChatModeID: quasi.aiChatModeID,
            aiAnswerRawData: "",
            messageLanguage: "",
            characterLength: 0,
            displayRule: .unknownRule,
            isAutoTranslatedByReceiver: false,
            translateLanguage: "",
            originalSenderID: "",
            isForwardFromFriend: false,
            isFileDeleted: false,
            fileDeletedStatus: .normal,
            syncDependency: false,
            isDecryptoFail: false,
            cryptoToken: quasi.cryptoToken,
            threadMessageType: .unknownThreadMessage,
            syncToChatMessageType: quasi.syncToChatMessageType,
            dlpState: quasi.dlpState,
            scheduleMessageDraftId: nil,
            displayMode: quasi.inChatDisplayMode,
            disabledAction: MessageDisabledAction(),
            setGrey: false,
            _isRestricted: false,
            isOnTimeDel: false,
            streamStatus: .streamUnknown,
            aiMessageType: .other,
            canShowAIProgress: false,
            feedbackStatus: .unknownStatus,
            isSecretChatDecryptedFailed: false,
            partialReplyInfo: quasi.hasPartialReplyInfo ? quasi.partialReplyInfo : nil,
            isAiSessionFirstMsg: quasi.isNewTopic
        )

        switch quasi.status {
        case .failed:
            message.localStatus = .fail
        case .pending:
            message.localStatus = .process
        @unknown default:
            #if DEBUG
            assert(false, "new value")
            #else
            break
            #endif
        }
        message.imageTranslationAbilitys = [:]
        message.securityExtra = quasi.hasSecurityExtra ? quasi.securityExtra : nil
        return message
    }

    public func isMeSend(userId: String) -> Bool {
        return self.fromId == userId || self.isAnnoymousSendFromMe
    }

    public static func transform(
        entity: RustPB.Basic_V1_Entity,
        pb: PBModel,
        currentChatterID: String,
        needPackParentRootMessage: Bool = true
    ) -> Message {
        let message = transform(pb: pb)
        self.configMessageInfo(message: message, pb: pb, entity: entity, currentChatterID: currentChatterID, needPackParentRootMessage: needPackParentRootMessage)
        return message
    }

    public static func transform(
        entity: RustPB.Basic_V1_Entity,
        id: String,
        currentChatterID: String
    ) throws -> Message {
        return try transform(entity: entity, id: id, currentChatterID: currentChatterID, needPackParentRootMessage: true)
    }

    public static func transform(
        entity: RustPB.Basic_V1_Entity,
        id: String,
        currentChatterID: String,
        needPackParentRootMessage: Bool
    ) throws -> Message {
        guard let pb = entity.messages[id] ?? entity.ephemeralMessages[id] else {
            throw LarkModelError.entityIncompleteData(message: "entity.messages缺少对应message id: \(id)")
        }
        let message = transform(pb: pb)
        configMessageInfo(message: message, pb: pb, entity: entity, currentChatterID: currentChatterID, needPackParentRootMessage: needPackParentRootMessage)
        return message
    }

    private static func configMessageInfo(message: Message,
                                   pb: RustPB.Basic_V1_Message,
                                   entity: RustPB.Basic_V1_Entity,
                                   currentChatterID: String,
                                   needPackParentRootMessage: Bool = true) {
        if let messageID = Int64(message.id),
           let editMessageInfo = entity.editingMessageInfos[messageID] {
            message.editMessageInfo = editMessageInfo
        }
        let id = message.id
        message.isEphemeral = (entity.ephemeralMessages[id] != nil)

        var extra = message.atomicExtra.value
        extra.mentions = entity.mentions
        extra.abbreviationInfo = entity.abbrevs
        if pb.type == .vote, let voteContent = message.content as? VoteContent {
            extra.votedInfo = entity.votedInfos[voteContent.uuid]
            extra.voters = entity.chatChatters[pb.chatID]?.chatters ?? entity.chatters
        }
        message.atomicExtra = SafeAtomic(value: extra)

        // NOTE: rust有个bug，会有个一个key为空的doc
        if !pb.docKey.isEmpty {
            message.docKey = pb.docKey
        }

        message.urlPreviewHangPointMap = pb.content.urlPreviewHangPointMap

        let orderedPreviewIDs = getOrderedPreviewIDs(message: pb)
        message.orderedPreviewIDs = orderedPreviewIDs
        if let pair = entity.previewEntities[id] {
            message.urlPreviewEntities = pair.previewEntity.filter({ orderedPreviewIDs.contains($0.key) }).mapValues({ URLPreviewEntity.transform(from: $0) })
        } else if message.urlPreviewHangPointMap.isEmpty,
                  let entities = URLPreviewEntity.transform(from: message) {
            // 都未接入中台，保持旧规则，多个URL不展示卡片；orderedPreviewIDs也只有一个
            message.orderedPreviewIDs = Array(entities.keys)
            message.urlPreviewEntities = entities
        }
        var messageLinks: [String: MessageLink] = [:]
        entity.messageLinks.filter({ orderedPreviewIDs.contains($0.key) }).forEach { (previewID, messageLink) in
            messageLinks[previewID] = MessageLink.transform(previewID: previewID, messageLink: messageLink)
        }
        message.messageLinks = messageLinks

        // text和post都需要解析Doc
        func docEntity() -> RustPB.Basic_V1_DocEntity? {
            if let content = message.content as? TextContent {
                return content.docEntity
            } else if let content = message.content as? PostContent {
                return content.docEntity
            }
            return nil
        }
        // 获取doc权限信息
        if let docEntity = docEntity(), let permissionInfo = entity.messageID2DocPermissionInfos[message.id] {
            // 有多少个不同的Doc，docKey -> Doc
            var docs: [String: RustPB.Basic_V1_Doc] = [:]
            // 每个Doc对应的权限信息，docKey -> DocPermission
            var docPermissions: [String: RustPB.Basic_V1_DocPermission] = [:]
            // 下载Doc预览图时根据DocPermission设置下载参数，docURL -> DocPermission
            var url2permissions: [String: RustPB.Basic_V1_DocPermission] = [:]
            docEntity.elementEntityRef.forEach { (arg) in
                let (_, elementEntity) = arg
                if let doc = entity.docs[elementEntity.token] {
                    docs[elementEntity.token] = doc
                }
                if let docPermission = permissionInfo.token2DocPermissions[elementEntity.token] {
                    docPermissions[elementEntity.token] = docPermission
                }
                if let url2permission = permissionInfo.url2DocPermissions[elementEntity.docURL] {
                    message.docsUrl = elementEntity.docURL
                    url2permissions[elementEntity.docURL] = url2permission
                }
            }
            message.docs = docs
            message.docPermissions = docPermissions
            message.url2Permissions = url2permissions
        }
        message.isIncludeDocURL = pb.isIncludeDocURL
        // NOTE: 我发的默认已读
        if pb.fromID == currentChatterID {
            message.meRead = true
        }
        // 群名片拼 chat.
        if var content = message.content as? HasAtUsers {
            content.packBotIDs(entity: entity, channelID: pb.channel.id)
            message.atomicExtra.unsafeValue.content = content
        }

        // 对内容进行额外的补充逻辑，比如：TextContent和PostContent以及ImageContent会填充翻译信息等
        var content = message.atomicExtra.unsafeValue.content
        content.complement(entity: entity, message: message)
        message.atomicExtra.unsafeValue.content = content

        // 修正翻译信息
        self.fixTranslateInfo(message: message)

        if !pb.recallerID.isEmpty {
            message.atomicExtra.unsafeValue.recaller = try? Chatter.transformChatChatter(
                entity: entity,
                chatID: pb.chatID,
                id: pb.recallerID
            )
        }

        // pin的消息品尚chatter
        if pb.hasPin, !pb.pin.id.isEmpty, !pb.pin.operatorID.isEmpty {
            message.atomicExtra.unsafeValue.pinChatter = try? Chatter.transformChatChatter(
                entity: entity,
                chatID: pb.chatID,
                id: pb.pin.operatorID
            )
        }

        // pack extra data
        if message.fromChatter == nil {
            let chatter = try? Chatter.transformChatter(
                entity: entity,
                message: pb,
                id: pb.fromID
            )
            message.atomicExtra.unsafeValue.fromChatter = chatter
        }
        if message.originalSender == nil {
            let chatter = try? Chatter.transformChatter(
                entity: entity,
                message: pb,
                id: pb.originalSenderID
            )
            message.atomicExtra.unsafeValue.originalSender = chatter
        }
        if needPackParentRootMessage, !pb.rootID.isEmpty && message.rootMessage == nil {
            message.atomicExtra.unsafeValue.rootMessage = try? transform(
                entity: entity, id: pb.rootID, currentChatterID: currentChatterID
            )
        }
        if needPackParentRootMessage, !pb.parentID.isEmpty && message.parentMessage == nil {
            message.atomicExtra.unsafeValue.parentMessage = try? transform(
                entity: entity, id: pb.parentID, currentChatterID: currentChatterID
            )
        }
        if needPackParentRootMessage, pb.syncToChatThreadRootID != 0 && message.syncToChatThreadRootMessage == nil {
            let syncToChatThreadRootID = String(pb.syncToChatThreadRootID)
            message.atomicExtra.unsafeValue.syncToChatThreadRootMessage = try? transform(
                entity: entity, id: syncToChatThreadRootID, currentChatterID: currentChatterID
            )
        }
        if needPackParentRootMessage, pb.syncToChatMessageType == .syncToChatSourceMessage {
            let syncToChatRelatedMessageId = String(pb.syncToChatRelatedMessageID)
            message.atomicExtra.unsafeValue.syncToChatRelatedMessage = try? transform(
                entity: entity, id: syncToChatRelatedMessageId, currentChatterID: currentChatterID
            )
        }
        if !pb.reactions.isEmpty {
            message.reactions = pb.reactions.map({ (reaction) -> Reaction in
                return Reaction.transform(
                    entity: entity,
                    message: pb,
                    pb: reaction
                )
            })
        }
        if let id = Int64(message.id), let localData = entity.messageLocalData[id] {
            message.atomicExtra.unsafeValue.localData = localData
        }
        message.atomicExtra.unsafeValue.ackUrgentChatters = message.ackUrgentChatterIds
            .compactMap { (chatterId) -> Chatter? in
                do {
                    return try Chatter.transformChatter(
                        entity: entity,
                        message: pb,
                        id: chatterId
                    )
                } catch {
                    Self.logger.info("ackUrgentChatters transformChatter error, error = \(error)")
                    return nil
                }
            }
        message.atomicExtra.unsafeValue.unackUrgentChatters = message.unackUrgentChatterIds
            .compactMap { (chatterId) -> Chatter? in
                do {
                    return try Chatter.transformChatter(
                        entity: entity,
                        message: pb,
                        id: chatterId
                    )
                } catch {
                    Self.logger.info("unackUrgentChatters transformChatter error, error = \(error)")
                    return nil
                }
            }
        if message.threadMessageType == .threadRootMessage {
            if let thread = entity.threads[message.threadId] {
                message.thread = thread
                
                let aiPreviewID = thread.aiChatModeURLPreviewHangPoint.previewID
                if !aiPreviewID.isEmpty,
                   let pair = entity.previewEntities[thread.id] {
                    message.aiChatModeInlinePreviewEntities = pair.previewEntity.filter({ $0.key == aiPreviewID })
                        .mapValues({InlinePreviewEntity.transform(from: $0) })
                }

                if thread.replyCount == 0 {
                    Self.logger.info("Messsage.transform: thread replyCount isEmpty threadId: \(thread.id) -- message.id: \(message.id)")
                }
                if thread.topRepliers.isEmpty {
                    Self.logger.info("Messsage.transform: thread topRepliers isEmpty threadId: \(thread.id) - message.id: \(message.id)")
                }
                message.replyInThreadCount = thread.replyCount
                message.replyInThreadLastVisibleMessagePosition = thread.lastVisibleMessagePosition
                message.replyInThreadTopRepliers = thread.topRepliers
                    .compactMap { (chatterId) -> Chatter? in
                        do {
                            return try Chatter.transformChatter(
                                entity: entity,
                                message: pb,
                                id: String(chatterId)
                            )
                        } catch {
                            Self.logger.info("topRepliers transformChatter error, error = \(error) chatterId:\(chatterId) threadId:\(thread.id) - message.id: \(message.id)")
                            return nil
                        }
                    }
                var replyMessages: [Message] = []
                // 重新排序，从旧->新
                let replyIds = thread.lastReplyIds.reversed()
                for replyId in replyIds {
                    if let replyMessage = try? Message.transform(
                        entity: entity,
                        id: replyId,
                        currentChatterID: currentChatterID,
                        needPackParentRootMessage: false
                    ) {
                        replyMessages.append(replyMessage)
                    } else {
                        Self.logger.info("Messsage.transform: get replyMessage fail, message.threadId: \(message.id) \(replyId)")
                    }
                }
                message.replyInThreadLastReplies = replyMessages
            } else {
                Self.logger.info("Messsage.transform: get thread fail, message.threadId: \(message.threadId) messageId: \(message.id)")
            }
        }
    }
    static func getOrderedPreviewIDs(message: Basic_V1_Message) -> [String] {
        let content = message.content
        guard !content.urlPreviewHangPointMap.isEmpty else { return [] }
        var orderedAnchorIDs = getOrderedAnchorIDs(richText: content.richText)
        if message.type == .file {
            orderedAnchorIDs.append(FileContent.FILE_PREVIEW_HANG_POINT_KEY)
        }
        let previewIDs = orderedAnchorIDs.compactMap({ content.urlPreviewHangPointMap[$0]?.previewID })
        // 最多显示4个卡片
        return Array(NSOrderedSet(array: previewIDs).compactMap({ $0 as? String }).prefix(4))
    }

    private static func getOrderedAnchorIDs(richText: Basic_V1_RichText) -> [String] {
        var anchorIDs: [String] = []
        var stack = richText.elementIds
        // 从下往上开始解，解出来的anchorIDs也是倒序的
        while let elementID = stack.popLast() {
            guard let element = richText.elements[elementID] else { continue }
            // anchor标签支持单独关闭卡片预览
            if element.tag == .a, !element.property.anchor.closeCardPreview {
                anchorIDs.append(elementID)
            } else if !element.childIds.isEmpty { // anchor不再有子节点
                stack.append(contentsOf: element.childIds)
            }
        }
        // 变为正序
        anchorIDs = anchorIDs.reversed()
        return anchorIDs
    }

    // 修复译文信息
    private static func fixTranslateInfo(message: Message) {
        updateMergeForwardState(message: message)
    }

    // 合并转发消息
    private static func updateMergeForwardState(message: Message) -> Bool {
        guard message.type == .mergeForward, let content = message.content as? MergeForwardContent else { return false }
        var haveTranslated = false
        content.messages.forEach { (subMessage) in
            if haveTranslated {
                return
            }
            if subMessage.type == .mergeForward {
                let subMerForwardState = updateMergeForwardState(message: subMessage)
                haveTranslated = haveTranslated || subMerForwardState
            } else if subMessage.type == .text || subMessage.type == .post {
                if !haveTranslated && (subMessage.displayRule == .onlyTranslation || subMessage.displayRule == .withOriginal) {
                    haveTranslated = true
                }
            }
        }
        // 有任何子消息有译文则展示被翻译
        message.translateState = haveTranslated ? .translated : .origin
        message.displayRule = haveTranslated ? .onlyTranslation : .noTranslation
        return haveTranslated
    }

    public static func transformQuasi(entity: RustPB.Basic_V1_Entity, cid: String) throws -> Message {
        guard let pb = entity.quasiMessages[cid] else {
            throw LarkModelError.entityIncompleteData(message: "entity.quasiMessages缺少message cid: \(cid)")
        }
        let message = Message.transform(quasi: pb)
        // NOTE: 假消息是我发的，默认已读
        message.meRead = true
        var extra = message.atomicExtra.value
        if let chatters = entity.chatChatters[message.channel.id]?.chatters, let chatter = chatters[pb.fromID] {
            extra.fromChatter = Chatter.transform(pb: chatter)
        }
        if var content = extra.content as? HasAtUsers {
            content.packBotIDs(entity: entity, channelID: pb.channel.id)
            extra.content = content
        }
        if extra.content is AudioContent || extra.content is ShareUserCardContent {
            extra.content.complement(entity: entity, message: message)
        }
        if !message.rootId.isEmpty && extra.rootMessage == nil {
            extra.rootMessage = try? transform(entity: entity, id: pb.rootID, currentChatterID: message.fromId)
        }
        if !pb.parentID.isEmpty && extra.parentMessage == nil {
            extra.parentMessage = try? transform(entity: entity, id: pb.parentID, currentChatterID: message.fromId)
        }
        if pb.syncToChatThreadRootID != 0 && extra.syncToChatThreadRootMessage == nil {
            extra.syncToChatThreadRootMessage = try? transform(entity: entity, id: pb.rootID, currentChatterID: message.fromId)
        }

        extra.mentions = entity.mentions
        extra.abbreviationInfo = entity.abbrevs
        message.atomicExtra.value = extra
        return message
    }

    /// 收敛消息是否支持翻译逻辑
    public func isSupportToTranslate(imageTranslationEnable: Bool) -> Bool {
        if type == .card {
            return isTranslatableMessageCardType()
        }
        /// 如果是文本消息，只要文本语种不为 not_lang 就支持翻译
        if type == .text && messageLanguage != "not_lang" {
            return true
        }
        /// 如果是富文本消息，文本语种不为 not_lang 或者存在任何一张图片支持翻译
        if type == .post && (messageLanguage != "not_lang" || anyImageElementCanBeTranslated()) {
            return true
        }
        /// 如果是图片消息，且支持翻译
        if imageTranslationEnable && type == .image && anyImageElementCanBeTranslated() {
            return true
        }
        /// 消息类型改变时是否支持更新
        if type == .mergeForward {
            return true
        }
        return false
    }

    /// 消息内是否有图片节点支持翻译
    public func anyImageElementCanBeTranslated() -> Bool {
        return imageTranslationAbilitys.values.first(where: { $0.canTranslate }) != nil
    }

    /// server不会主动替换富文本中的图片节点，图片节点对应的译图信息需要端上从imageTranslationInfo取出手动替换
    public func updateTranslateImage(imageTranslationInfo: ImageTranslationInfo) {
        let translatedImageInfo = imageTranslationInfo.translatedImages
        if translatedImageInfo.keys.isEmpty {
            return
        }

        /// 图片
        if var imageContent = translateContent as? ImageContent {
            if let translatedImageSet = translatedImageInfo[imageContent.image.origin.key]?.translatedImageSet {
                imageContent.image = translatedImageSet
            }
            translateContent = imageContent
            return
        }
        /// 富文本
        if var postContent = translateContent as? PostContent {
            var leafs: [String: RustPB.Basic_V1_RichTextElement] = [:]
            PostContent.parseRichText(elements: postContent.richText.elements,
                                      elementIds: postContent.richText.elementIds,
                                      leafs: &leafs)
            for (elementId, element) in leafs where element.tag == .img {
                /// 只替换图片节点即可
                let imageProperty = element.property.image
                let imageKey = imageProperty.originKey
                if let imageSet = translatedImageInfo[imageKey]?.translatedImageSet {
                    /// 替换 image property
                    let newImageProperty = imageProperty.modifiedImageProperty(imageSet)
                    postContent.richText.elements[elementId]?.property.image = newImageProperty
                }
            }
            translateContent = postContent
            return
        }
    }
}

// enable-lint: long_function
// swiftlint:enable function_body_length
