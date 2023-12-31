//
//  ForwardService.swift
//  Lark
//
//  Created by zc09v on 2018/6/7.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkSDKInterface
import Swinject
import LarkAccountInterface
import RustPB
import UniverseDesignToast
import LKCommonsLogging
import LarkFeatureGating
import LarkContainer

/// ForwardAlertContent是ForwardAlertProvider的数据

/// bot: 机器人 user：单聊 chat：群组 threadMessage: 话题帖子 replyThreadMessage: 消息帖子， unknown：未知
public enum ForwardItemType: Int {
    case unknown = 0, user, bot, myAi, chat, threadMessage, replyThreadMessage, generalFilter
    public var isThread: Bool {
        return self == .threadMessage || self == .replyThreadMessage
    }
    public var isMyAi: Bool {
        return self == .myAi
    }
}

/// 标记转发item的来源，默认是picker搜索出来的
public enum ForwardItemSource {
    case search // 搜索
    case recentForward // 最近转发
    case recentChat // 最近访问
}

public typealias WikiSpaceType = Search_V2_UniversalFilters.WikiSpaceFilter.SpaceType

public struct ForwardItem: Equatable {
    public static var logger = Logger.log(ForwardItem.self, category: "ForwardItem")
    public let avatarKey: String
    public let name: String
    public let subtitle: String
    public let description: String
    public let attributedTitle: NSAttributedString?
    public let attributedSubtitle: NSAttributedString?
    public let descriptionType: Chatter.DescriptionType
    public let localizeName: String
    // 在所在文件夹筛选器中id=docToken，在所在知识空间筛选器中：id=spaceId
    public var id: String
    public let chatId: String?
    public var chatterId: String?
    public var type: ForwardItemType
    public var isCrossTenant: Bool
    public let isCrossWithKa: Bool
    public let isCrypto: Bool
    public var isThread: Bool
    public let isPrivate: Bool
    // 对于转发到帖子时使用channelID记录该message所属的chat
    public var channelID: String?
    public let doNotDisturbEndTime: Int64
    public var hasInvitePermission: Bool
    public let userTypeObservable: Observable<PassportUserType>?
    public var enableThreadMiniIcon: Bool
    public let isOfficialOncall: Bool
    public var chatUserCount: Int32 = 0
    public var tags: [Chat.Tag]
    public var customStatus: Basic_V1_Chatter.ChatterCustomStatus?
    public var source: ForwardItemSource = .search
    public var deniedReasons: [Basic_V1_Auth_DeniedReason]?
    /// 所在文件夹筛选器接入ChatPicker
    public let isShardFolder: Bool?
    public let wikiSpaceType: WikiSpaceType?
    public var tagData: Basic_V1_TagData?
    /// 索引，用于埋点
    public var index: Int = 0
    public var avatarId: String?
    public var imageURLStr: String?
    public var enterpriseMailAddress: String?
    public var isUserCountVisible: Bool?

    public static func == (lhs: ForwardItem, rhs: ForwardItem) -> Bool {
        return lhs.id == rhs.id
    }

    public init(
        avatarKey: String,
        name: String,
        subtitle: String,
        description: String,
        descriptionType: Chatter.DescriptionType,
        localizeName: String,
        id: String,
        chatId: String? = nil,
        type: ForwardItemType,
        isCrossTenant: Bool,
        isCrossWithKa: Bool = false,
        isCrypto: Bool,
        isThread: Bool,
        isPrivate: Bool = false,
        channelID: String? = nil,
        doNotDisturbEndTime: Int64,
        hasInvitePermission: Bool,
        userTypeObservable: Observable<PassportUserType>?,
        enableThreadMiniIcon: Bool,
        isOfficialOncall: Bool,
        tags: [Chat.Tag] = [],
        attributedTitle: NSAttributedString? = nil,
        attributedSubtitle: NSAttributedString? = nil,
        customStatus: Basic_V1_Chatter.ChatterCustomStatus? = nil,
        wikiSpaceType: WikiSpaceType? = nil,
        isShardFolder: Bool? = nil,
        tagData: Basic_V1_TagData? = nil,
        imageURLStr: String? = nil,
        enterpriseMailAddress: String? = nil) {
        self.avatarKey = avatarKey
        self.name = name
        self.subtitle = subtitle
        self.description = description
        self.descriptionType = descriptionType
        self.localizeName = localizeName
        self.id = id
        self.chatId = chatId
        self.type = type
        self.isCrossTenant = isCrossTenant
        self.isCrossWithKa = isCrossWithKa
        self.isCrypto = isCrypto
        self.isThread = isThread
        self.isPrivate = isPrivate
        self.channelID = channelID
        self.doNotDisturbEndTime = doNotDisturbEndTime
        self.hasInvitePermission = hasInvitePermission
        self.userTypeObservable = userTypeObservable
        self.enableThreadMiniIcon = enableThreadMiniIcon
        self.isOfficialOncall = isOfficialOncall
        self.tags = tags
        self.attributedTitle = attributedTitle
        self.attributedSubtitle = attributedSubtitle
        self.customStatus = customStatus
        self.wikiSpaceType = wikiSpaceType
        self.isShardFolder = isShardFolder
        self.tagData = tagData
        self.imageURLStr = imageURLStr
        self.enterpriseMailAddress = enterpriseMailAddress
        Self.logger.info("init forwardItem with id:\(id), chatId:\(chatId), type:\(type)")
    }

    public init(
        avatarKey: String,
        name: String,
        subtitle: String,
        description: String,
        descriptionType: Chatter.DescriptionType,
        localizeName: String,
        id: String,
        chatId: String? = nil,
        type: ForwardItemType,
        isCrossTenant: Bool,
        isCrossWithKa: Bool = false,
        isCrypto: Bool,
        isThread: Bool,
        isPrivate: Bool = false,
        channelID: String? = nil,
        doNotDisturbEndTime: Int64,
        hasInvitePermission: Bool,
        userTypeObservable: Observable<PassportUserType>?,
        enableThreadMiniIcon: Bool,
        isOfficialOncall: Bool,
        tags: [Chat.Tag] = [],
        tagData: Basic_V1_TagData? = nil,
        imageURLStr: String? = nil,
        enterpriseMailAddress: String? = nil) {
        self.init(avatarKey: avatarKey,
                  name: name,
                  subtitle: subtitle,
                  description: description,
                  descriptionType: descriptionType,
                  localizeName: localizeName,
                  id: id,
                  chatId: chatId,
                  type: type,
                  isCrossTenant: isCrossTenant,
                  isCrossWithKa: isCrossWithKa,
                  isCrypto: isCrypto,
                  isThread: isThread,
                  isPrivate: isPrivate,
                  channelID: channelID,
                  doNotDisturbEndTime: doNotDisturbEndTime,
                  hasInvitePermission: hasInvitePermission,
                  userTypeObservable: userTypeObservable,
                  enableThreadMiniIcon: enableThreadMiniIcon,
                  isOfficialOncall: isOfficialOncall,
                  tags: tags,
                  attributedTitle: nil,
                  attributedSubtitle: nil,
                  customStatus: nil,
                  tagData: tagData,
                  imageURLStr: imageURLStr,
                  enterpriseMailAddress: enterpriseMailAddress)
    }

    public init(chat: Chat) {
        let id = {
            switch chat.type {
            case .p2P: return chat.chatterId
            @unknown default: return chat.id
            }
        }()
        let type: ForwardItemType = {
            switch chat.type {
            case .group: return .chat
            case .p2P: return .user
            case .topicGroup: return .threadMessage
            @unknown default: return .unknown
            }
        }()
        let displayName: String = {
            switch chat.type {
            case .p2P: return chat.chatter?.displayName ?? chat.name
            @unknown default: return chat.name
            }
        }()
        self.init(avatarKey: chat.avatarKey,
                  name: displayName,
                  subtitle: "",
                  description: chat.description,
                  descriptionType: .onDefault,
                  localizeName: chat.name,
                  id: id,
                  chatId: chat.id,
                  type: type,
                  isCrossTenant: chat.isCrossTenant,
                  isCrossWithKa: chat.isCrossWithKa,
                  isCrypto: chat.isCrypto,
                  isThread: chat.chatMode == .thread || chat.chatMode == .threadV2,
                  isPrivate: chat.isPrivateMode,
                  doNotDisturbEndTime: 0,
                  hasInvitePermission: true,
                  userTypeObservable: nil,
                  enableThreadMiniIcon: false,
                  isOfficialOncall: false,
                  tags: chat.tags,
                  attributedTitle: nil,
                  attributedSubtitle: nil,
                  customStatus: nil)
    }
    public var log: String {
        return """
{"type": \(type), "index": \(index), "source": \(source)}
"""
    }
}

public struct ForwardItemParam {
    public var isSuccess: Bool
    public var type: String
    public var name: String?
    public var chatID: String
    public var threadID: String?
    public var isCrossTenant: Bool?
    public init(isSuccess: Bool,
                type: String,
                name: String?,
                chatID: String,
                threadID: String? = nil,
                isCrossTenant: Bool?) {
        self.isSuccess = isSuccess
        self.type = type
        self.name = name
        self.chatID = chatID
        self.threadID = threadID
        self.isCrossTenant = isCrossTenant
    }
}

/// 转发完成后返回的一些参数，各业务可选择需要的参数
public struct ForwardParam {
    public var forwardItems: [ForwardItemParam]
    public init(forwardItems: [ForwardItemParam]) {
        self.forwardItems = forwardItems
    }
}

public typealias ForwardResult = Result<ForwardParam, Error>

public protocol ForwardAlertContent {
    var getForwardContentCallback: GetForwardContentCallback { get }
}

public extension ForwardAlertContent {
    var getForwardContentCallback: GetForwardContentCallback {
        return nil
    }
}

public typealias ForwardDataFilter = ((ForwardItem) -> Bool)

public typealias ForwardItemDisabledBlock = ((PickerItem) -> Bool)

public typealias ForwardVCDismissBlock = (() -> Void)

// 转发过滤参数，目前只用于最近转发
public struct ForwardFilterParameters {
    public var includeThread: Bool?
    public var includeOuterChat: Bool?
    public init() {}
}

/// 给ForwardAlert提供必要的View以及行为、属性等
open class ForwardAlertProvider: UserResolverWrapper {
    public var filterParameters: ForwardFilterParameters?
    /// 转发过滤参数配置设计方案: https://bytedance.feishu.cn/docx/ZJoedpUfkoxTE8xqf2Nc5k8Xnch
    public var resolver: UserResolver { userResolver }
    public let userResolver: UserResolver
    public let content: ForwardAlertContent
    public var permissions: [RustPB.Basic_V1_Auth_ActionType]?
    public weak var targetVc: UIViewController?

    // 是否支持at
    open var isSupportMention: Bool {
        return false
    }

    //picker打点场景 https://bytedance.feishu.cn/sheets/shtcnXUxTZFU0bKVuodlxS1BS6g
    open var pickerTrackScene: String? {
        return nil
    }

    /// 是否展示最近转发
    open var shouldShowRecentForward: Bool {
        return true
    }

    // 是否支持目标预览
    open var targetPreview: Bool {
        return true
    }

    /// 是否需要展示创建群的入口
    open var shouldCreateGroup: Bool {
        return true
    }

    /// 最多可选人数
    open var maxSelectCount: Int {
        return 10
    }

    /// 是否支持多选
    open var isSupportMultiSelectMode: Bool {
        return true
    }

    /// 是否支持转发到外部联系人
    open var needSearchOuterTenant: Bool {
        return true
    }
    /// 是否支持转发到外部群
    open var includeOuterChat: Bool? { return nil }

    required public init(userResolver: UserResolver, content: ForwardAlertContent) {
        self.userResolver = userResolver
        self.content = content
    }

    /// 是否需要展示输入框
    open func isShowInputView(by items: [ForwardItem]) -> Bool {
        return true
    }

    /// 获取标题，如ShareExtension需要根据ForwardItem来定义标题
    ///
    /// - Parameter items: 选中的标题
    /// - Returns: 返回title
    open func getTitle(by items: [ForwardItem]) -> String? {
        return nil
    }

    /// 获取ForwardViewController确认按钮标题
    ///
    /// - Parameter items: 选中的标题
    /// - Returns: 返回title
    open func getConfirmButtonTitle(by items: [ForwardItem]) -> String? {
        return nil
    }

    /// 获取NewForwardViewController确认框自定义确认文案
    ///
    /// - Parameters
    ///     - isMultiple: 是否多选状态
    ///     - selectCount: 选中目标数
    /// - Returns: 返回text
    open func getConfirmButtonText(isMultiple: Bool, selectCount: Int) -> String? {
        return nil
    }

    /// 根据content获取不同的ContentView
    ///
    /// - Returns: ContentView
    open func getContentView(by items: [ForwardItem]) -> UIView? {
        return nil
    }

    /// 转发内容中是否包含定时删除消息
    ///
    /// - Returns: Bool
    open func containBurnMessage() -> Bool {
        return false
    }

    /// 用来过滤Forward模块中DataSource
    ///
    /// - Returns: ForwardDataFilter?
    open func getFilter() -> ForwardDataFilter? {
        return nil
    }

    /// 用来返回ForwardVC关闭的时机
    ///
    /// - Returns: ForwardVCDismissBlock?
    open func getForwardVCDismissBlock() -> ForwardVCDismissBlock? {
        return nil
    }

    /// 配置该参数来控制转发场景最近访问/最近转发/转发搜索展示哪些目标，没传入的实体对应的目标将被过滤
    ///
    /// - Returns: IncludeConfigs?
    open func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        /// 传入一组实体，实体内属性间取交集，实体之间取并集，目前暂不支持传多个同种实体
        /// 下列默认实现表示不过滤
        var includeConfigs: IncludeConfigs = [
            ForwardUserEntityConfig(),
            ForwardGroupChatEntityConfig(),
            ForwardBotEntityConfig(),
            ForwardThreadEntityConfig()
        ]
        return includeConfigs
    }

    /// 配置该置灰闭包，由业务自身定义何时置灰哪些转发目标，优先级高于置灰参数
    ///
    /// - Returns: ForwardItemDisabledBlock?
    open func getDisabledBlock() -> ForwardItemDisabledBlock? {
        return nil
    }

    /// 配置该参数来控制转发场景最近访问/最近转发/转发搜索展示哪些目标，没传入的实体对应的目标将被置灰
    ///
    /// - Returns: IncludeConfigs?
    open func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        /// 传入一组实体供置灰操作使用，实体内属性间取交集，实体之间取并集，目前暂不支持传多个同种实体
        /// 下列默认实现表示不置灰,都正常展示
        var includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig(),
            ForwardThreadEnabledEntityConfig()
        ]
        return includeConfigs
    }

    /// 展示ConfirmContentVC前调用的逻辑
    open func beforeShowAction() {

    }
    /// 点击关闭页面时调用的逻辑
    open func dismissAction() {
    }
    /// Alert cancel时调用的逻辑
    open func cancelAction() {

    }

    /// Alert sure时调用的逻辑
    ///
    /// - Parameters:
    ///   - items: 选中的item
    ///   - input: 输入附加信息
    /// - Returns: Observable
    open func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        return .just([])
    }

    /// Alert sure时调用的逻辑，用于发送富文本附加信息
    ///
    /// - Parameters:
    ///   - items: 选中的item
    ///   - input: 输入附加信息
    /// - Returns: Observable
    open func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        return .just([])
    }

    /// Alert sure时调用的逻辑，用于发送富文本附加信息
    ///
    /// - Parameters:
    ///   - items: 选中的item
    ///   - input: 输入附加信息
    /// - Returns: Observable
    open func shareSureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<ForwardResult> {
        return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
    }

    /// Alert sure时调用的逻辑，用于发送文本附加信息
    ///
    /// - Parameters:
    ///   - items: 选中的item
    ///   - input: 输入附加信息
    /// - Returns: Observable
    open func shareSureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<ForwardResult> {
        return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
    }

    /// 用来判断能否处理该类型的content，如果可以处理，才能生成相应的Provider
    ///
    /// - Parameter content:
    /// - Returns:
    open class func canHandle(content: ForwardAlertContent) -> Bool {
        return false
    }

    /// 将ForwardItem转换为chatIds和userIds
    ///
    /// - Parameter items: 选中的item
    /// - Returns: 对应的chatId和userId, threadMessage对应的channelID
    final public func itemsToIds(_ items: [ForwardItem]) -> (chatIds: [String], userIds: [String], filterIds: [String]) {
        var chatIds: [String] = []
        var userIds: [String] = []
        var filterIds: [String] = []
        items.forEach { (item) in
            switch item.type {
            case .chat:
                chatIds.append(item.id)
            case .user, .myAi:
                userIds.append(item.id)
            case .bot:
                userIds.append(item.id)
            case .generalFilter:
                filterIds.append(item.id)
            case .threadMessage, .replyThreadMessage:
                // note: 此处逻辑似乎不对，往某个帖子里转发不应该把channelId放到chatIds里
                if let chatID = item.channelID {
                    chatIds.append(chatID)
                }
            case .unknown:
                break
            }
        }
        return (chatIds: chatIds, userIds: userIds, filterIds: filterIds)
    }

    final public func itemsToIdsAndDic(_ items: [ForwardItem]) -> (chatIds: [String], userIds: [String], filterIds: [String], threadMessageIdDic: [String: String]) {
        var chatIds: [String] = []
        var userIds: [String] = []
        var filterIds: [String] = []
        var threadMessageIdDic: [String: String] = [:]
        items.forEach { (item) in
            switch item.type {
            case .chat:
                chatIds.append(item.id)
            case .user, .myAi:
                userIds.append(item.id)
            case .bot:
                userIds.append(item.id)
            case .generalFilter:
                filterIds.append(item.id)
            case .threadMessage, .replyThreadMessage:
                if let chatID = item.channelID {
                    chatIds.append(chatID)
                    threadMessageIdDic[chatID] = item.id
                }
            case .unknown:
                break
            }
        }
        return (chatIds: chatIds, userIds: userIds, filterIds: filterIds, threadMessageIdDic: threadMessageIdDic)
    }

    /// 通过chatID或者userID获取chat
    /// - Parameters:
    ///   - chatIds
    ///   - userIds
    final public func checkAndCreateChats(chatIds: [String], userIds: [String]) -> Observable<[Chat]> {
        let chatAPI = try? userResolver.resolve(assert: ChatAPI.self)
        var results: [Chat] = []
        var userIdsHasNoChat: [String] = []

        guard let chatAPI else { return .empty() }
        return chatAPI.fetchChats(by: chatIds, forceRemote: false)
            .do(onNext: { (chatsMap) in
                let chats = chatsMap.compactMap({ $1 })
                results.append(contentsOf: chats)
            })
            .catchErrorJustReturn([:])
            .flatMap({ _ -> Observable<[Chat]> in
                return chatAPI.fetchLocalP2PChatsByUserIds(uids: userIds)
                    .do(onNext: { (chatsDic) in
                        userIds.forEach { (userId) in
                            if let chat = chatsDic[userId] {
                                results.append(chat)
                            } else {
                                userIdsHasNoChat.append(userId)
                            }
                        }
                    })
                    .catchErrorJustReturn([:])
                    .flatMap({ _ -> Observable<[Chat]> in
                        if !userIdsHasNoChat.isEmpty {
                            return chatAPI.createP2pChats(uids: userIdsHasNoChat).map {
                                results.append(contentsOf: $0)
                                return results
                            }
                        } else {
                            return .just(results)
                        }
                    })
            })
            .observeOn(MainScheduler.instance)
    }
}

public enum TransmitType {
    case unknown
    case message(String)
    case favorite(String)
    case flag(String)

    public var rawValue: Int {
        switch self {
        case .unknown: return 0
        case .message: return 1
        case .favorite: return 2
        case .flag: return 3
        }
    }

    public var id: String {
        switch self {
        case .unknown: return ""
        case .message(let id): return id
        case .favorite(let id): return id
        case .flag(let id): return id
        }
    }
}

public protocol ForwardService {
    func forward(content: String, to chatIds: [String], userIds: [String], extraText: String) -> Observable<[String]>

    func forward(content: String, to chatIds: [String], userIds: [String], attributeExtraText: NSAttributedString) -> Observable<[String]>

    //支持返回转发结果
    func forwardWithResults(content: String, to chatIds: [String], userIds: [String], attributeExtraText: NSAttributedString) -> Observable<[(String, Bool)]>

    //支持返回转发结果
    func forwardWithResults(content: String, to chatIds: [String], userIds: [String], extraText: String) -> Observable<[(String, Bool)]>

    /// originMergeForwardId: 私有话题群转发的详情页传入 其他业务传入nil
    /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题，需要originMergeForwardId
    func forward(
        originMergeForwardId: String?,
        type: TransmitType,
        message: Message,
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        extraText: String,
        from: ForwardMessageBody.From
    ) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    func forward(
        originMergeForwardId: String?,
        type: TransmitType,
        message: Message,
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        attributeExtraText: NSAttributedString,
        from: ForwardMessageBody.From
    ) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    func mergeForward(
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        title: String,
        extraText: String,
        needQuasiMessage: Bool) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    func mergeForward(
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        title: String,
        attributeExtraText: NSAttributedString,
        needQuasiMessage: Bool) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    func mergeForward(
        originMergeForwardId: String?,
        threadID: String,
        needCopyReaction: Bool,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        title: String,
        isLimit: Bool,
        extraText: String) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    // swiftlint:disable function_parameter_count
    func mergeForward(
        originMergeForwardId: String?,
        threadID: String,
        needCopyReaction: Bool,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        threadModeChatIds: [String],
        title: String,
        isLimit: Bool,
        extraText: String) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>
    // swiftlint:enable function_parameter_count

    func mergeForward(
        originMergeForwardId: String?,
        threadID: String,
        needCopyReaction: Bool,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        title: String,
        isLimit: Bool,
        attributeExtraText: NSAttributedString) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    // swiftlint:disable function_parameter_count
    func mergeForward(
        originMergeForwardId: String?,
        threadID: String,
        needCopyReaction: Bool,
        checkChatIDs: [String],
        to chatIDs: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        threadModeChatIds: [String],
        title: String,
        isLimit: Bool,
        attributeExtraText: NSAttributedString) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>
    // swiftlint:enable function_parameter_count

    /// 逐条转发
      /// - Returns: 观察序列
    func batchTransmitForward(
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        extraText: String) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    func batchTransmitForward(
        originMergeForwardId: String?,
        messageIds: [String],
        checkChatIDs: [String],
        to chatIds: [String],
        to threadIDAndChatIDs: [(messageID: String, chatID: String)],
        userIds: [String],
        attributeExtraText: NSAttributedString) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    func checkAndCreateChats(chatIds: [String], userIds: [String]) -> Observable<[Chat]>

    func forwardCopyFromFolderMessage(folderMessageId: String,
                                      key: String,
                                      chatIds: [String],
                                      userIds: [String],
                                      threadIDAndChatIDs: [(threadID: String, chatID: String)],
                                      extraText: String) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    func forwardCopyFromFolderMessage(folderMessageId: String,
                                      key: String,
                                      chatIds: [String],
                                      userIds: [String],
                                      threadIDAndChatIDs: [(threadID: String, chatID: String)],
                                      attributeExtraText: NSAttributedString) -> Observable<([String], Im_V1_FilePermCheckBlockInfo?)>

    func share(shareChatterId: String,
               message: String?,
               chatIds: [String],
               userIds: [String],
               threadIDAndChatIDs: [(threadID: String, chatID: String)]) -> Observable<[String]>

    func share(shareChatterId: String,
               attributeMessage: NSAttributedString?,
               chatIds: [String],
               userIds: [String],
               threadIDAndChatIDs: [(threadID: String, chatID: String)]) -> Observable<[String]>

    func share(chat: Chat, message: String?, to chatIds: [String], userIds: [String]) -> Observable<[String]>

    func share(chat: Chat, attributeMessage: NSAttributedString?, to chatIds: [String], userIds: [String]) -> Observable<[String]>

    func share(chat: Chat, attributeMessage: NSAttributedString?, threadMessageIdDic: [String: String], to chatIds: [String], userIds: [String]) -> Observable<[String]>

    func share(image: UIImage, message: String?, to chatIds: [String], userIds: [String]) -> Observable<[String]>

    func share(image: UIImage, attributeMessage: NSAttributedString?, to chatIds: [String], userIds: [String]) -> Observable<[String]>

    func shareWithResults(image: UIImage, attributeMessage: NSAttributedString?, to chatIds: [String], userIds: [String]) -> Observable<[(String, Bool)]>

    func shareWithResults(image: UIImage, message: String?, to chatIds: [String], userIds: [String]) -> Observable<[(String, Bool)]>

    func share(imageUrls: [URL], extraText: String?, to chatIds: [String], userIds: [String]) -> Observable<[String]>

    /// 专门用于ShareExtension场景
    func extensionShare(content data: Data, to chatIds: [String], userIds: [String], extraText: String) -> Observable<[String]>
    func extensionShare(content data: Data, to chatIds: [String], userIds: [String], attributeExtraText: NSAttributedString) -> Observable<[String]>
    /// 被调用场景：shareExtension发送视频到IM中
    /// 遇到的问题：在选人组件中，选人确认后，会发送视频，同时调用dismiss关闭自己。但是视频可能会超限，从而弹框提示用户。导致用户看到弹框提示，一瞬间消失，并且发送失败
    /// 解决方案：在点击确认选人后，将Chat信息存储，等选人组件完全dismiss后，取出Chat上下文，再调用发视频流程。
    func getAndDeleteChatInfoInShareVideo() -> [Chat]

    func share(fileUrl: String, fileName: String, to chatIds: [String], userIds: [String], extraText: String) -> Observable<[(String, Bool)]>

    func share(fileUrl: String, fileName: String, to chatIds: [String], userIds: [String], attributeExtraText: NSAttributedString) -> Observable<[(String, Bool)]>

    func itemsToTargetIds(_ items: [ForwardItem]) -> ForwardTargetIds

    // swiftlint:disable line_length
    func forwardMessageInComponent(selectItems: [ForwardItem], forwardContent: ForwardAlertContent, forwardParam: ForwardContentParam, additionNote: NSAttributedString?) -> Observable<ForwardComponentResponse>
    // swiftlint:enable line_length
}

// MARK: - Include Config Entity

public struct ForwardUserEntityConfig: ChatterEntityConfigType, TenantConfigurable {
    public var tenant: TenantCondition
    public var description: String {
        return "ForwardUserEntityConfig,tenant: \(tenant)"
    }
    public init(tenant: TenantCondition = .all) {
        self.tenant = tenant
    }
}

public struct ForwardGroupChatEntityConfig: GroupChatEntityConfigType, TenantConfigurable {
    public var tenant: TenantCondition
    public var description: String {
        return "ForwardGroupChatEntityConfig,tenant: \(tenant)"
    }
    public init(tenant: TenantCondition = .all) {
        self.tenant = tenant
    }
}

public struct ForwardBotEntityConfig: BotEntityConfigType {
    public var description: String {
        return "ForwardBotEntityConfig"
    }
    public init() {}
}

public struct ForwardThreadEntityConfig: ThreadEntityConfigType {
    public var description: String {
        return "ForwardThreadEntityConfig"
    }
    public init() {}
}

public struct ForwardMyAiEntityConfig: MyAiEntityConfigType {
    public var description: String {
        return "ForwardMyAiEntityConfig"
    }
    public init() {}
}

// MARK: - Enable Config Entity

public struct ForwardUserEnabledEntityConfig: ChatterEntityConfigType, TenantConfigurable, SelfConfigurable {
    public var tenant: TenantCondition
    public var selfType: SelfCondition
    public var description: String {
        return "ForwardUserEnabledEntityConfig,tenant: \(tenant),selfType: \(selfType)"
    }
    public init(tenant: TenantCondition = .all, selfType: SelfCondition = .all) {
        self.tenant = tenant
        self.selfType = selfType
    }
}

public struct ForwardGroupChatEnabledEntityConfig: GroupChatEntityConfigType, GroupChatTypeConfigurable, TenantConfigurable {
    public var chatType: GroupChatTypeCondition
    public var tenant: TenantCondition
    public var description: String {
        return "ForwardGroupChatEnabledEntityConfig,tenant: \(tenant),chatType: \(chatType)"
    }
    public init(chatType: GroupChatTypeCondition = .all, tenant: TenantCondition = .all) {
        self.chatType = chatType
        self.tenant = tenant
    }
}

public typealias ForwardBotEnabledEntityConfig = ForwardBotEntityConfig

public struct ForwardThreadEnabledEntityConfig: ThreadEntityConfigType, ThreadTypeConfigurable {
    public var threadType: ThreadTypeCondition
    public var description: String {
        return "ForwardThreadEnabledEntityConfig,threadType: \(threadType)"
    }
    public init(threadType: ThreadTypeCondition = .all) {
        self.threadType = threadType
    }
}

public typealias ForwardMyAiEnabledEntityConfig = ForwardMyAiEntityConfig

public typealias ForwardTargetIds = (groupTargetIds: [String], userTargetIds: [String], threadTargets: [String: String], filterIds: [String])

public protocol ForwardComponentVCType: UIViewController {
    var isMultiSelectMode: Bool { get set }
    var currentSelectItems: [ForwardItem] { get }
    // 获取转发内容
    func content() -> ForwardAlertContent
    // 建群后单选
    func selectNew(item: ForwardItem)
}

public protocol ForwardComponentDelegate: AnyObject {
    // Picker选人结果变化时，业务方可选实现的委托方法；若业务给组件传入Delegate，则走业务逻辑，组件逻辑不再执行；不传则走组件逻辑
    // forwardVC: 转发的UIViewController
    // didSelectItem: 表示选中or取消选中的目标结果
    // isMultipleMode: 表示结果变化时的多选状态
    // addSelected: 表示结果变化时是选中还是取消选中
    func forwardVC(_ forwardVC: ForwardComponentVCType, didSelectItem: ForwardItem, isMultipleMode: Bool, addSelected: Bool)

    // 点击选人列表导航栏确认按钮时，业务方可选实现的委托方法；若业务给组件传入Delegate，则走业务逻辑，组件逻辑不再执行；不传则走组件逻辑
    // pickerSelectedVC: 选人列表UIViewController
    func confirmButtonTapped(pickerSelectedVC: UIViewController)
}

public extension ForwardComponentDelegate {
    func forwardVC(_ forwardVC: ForwardComponentVCType, didSelectItem: ForwardItem, isMultipleMode: Bool, addSelected: Bool) {}
    func confirmButtonTapped(pickerSelectedVC: UIViewController) {}
}
