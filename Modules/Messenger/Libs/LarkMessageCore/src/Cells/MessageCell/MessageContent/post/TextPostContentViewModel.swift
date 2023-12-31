//
//  PostContentViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/18.
//

import Foundation
import LarkModel
import LarkCore
import LarkRichTextCore
import EEFlexiable
import AsyncComponent
import RichLabel
import EENavigator
import LarkContainer
import Swinject
import LarkUIKit
import LarkMessageBase
import ByteWebImage
import RxCocoa
import RxSwift
import LKCommonsLogging
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkFoundation
import LarkSetting
import RustPB
import TangramService
import UniverseDesignTheme
import UniverseDesignColor
import UniverseDesignFont
import LKRichView
import LarkAccountInterface
import LarkAlertController
import LarkSDKInterface
import UniverseDesignToast
import ThreadSafeDataStructure
import UIKit
import UniverseDesignIcon
import UniverseDesignMenu
import LarkSearchCore
import Homeric
import LKCommonsTracker
import LarkOpenChat

public protocol TextPostContentContext: PageContext, ColorConfigContext {
    var translateService: NormalTranslateService? { get }
    var feedbackService: TranslateFeedbackService? { get }
    var phoneNumberAndLinkParser: PhoneNumberAndLinkParser? { get }
    var contextScene: ContextScene { get }
    var modelService: ModelService? { get }
    var heightWithoutSafeArea: CGFloat { get }
    /// enable ner
    var abbreviationEnable: Bool { get }
    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>]
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterID: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate?
    func checkPermissionPreview(chat: Chat, message: Message) -> (Bool, ValidateResult?)
    func checkPreviewAndReceiveAuthority(chat: Chat, message: Message) -> PermissionDisplayState
    func handlerPermissionPreviewOrReceiveError(receiveAuthResult: DynamicAuthorityEnum?,
                                                previewAuthResult: ValidateResult?,
                                                resourceType: SecurityControlResourceType)
    func getChatAlbumDataSourceImpl(chat: Chat, isMeSend: @escaping (String) -> Bool) -> LKMediaAssetsDataSource
}

public struct GroupAnnouncementConfig {
    public static let contentMaxWidth: CGFloat = 400
    public static let contentPadding: CGFloat = 12
}
public extension TextContent {
    func getAbbreviationWrapper(currentUserId: String, tenantId: String) -> [String: AbbreviationInfoWrapper]? {
        return AbbreviationV2Processor.filterAbbreviation(
            abbreviation: abbreviation,
            typedElementRefs: typedElementRefs,
            tenantId: tenantId,
            userId: currentUserId
        )
    }
}
public extension PostContent {
    func getAbbreviationWrapper(currentUserId: String, tenantId: String) -> [String: AbbreviationInfoWrapper]? {
        return AbbreviationV2Processor.filterAbbreviation(
            abbreviation: abbreviation,
            typedElementRefs: typedElementRefs,
            tenantId: tenantId,
            userId: currentUserId
        )
    }
}

/// text/post消息展示需要的内容
public struct TextPostContent {
    public var title: String
    public var titleAttributedString: NSAttributedString?
    public var richText: RustPB.Basic_V1_RichText
    public let isPost: Bool
    public let isGroupAnnouncement: Bool
    public var botIds: [String]
    public var docEntity: RustPB.Basic_V1_DocEntity?
    public var inlineEntities: [String: InlinePreviewEntity] = [:]
    public var isUntitledPost: Bool {
        return ["无标题帖子", "Untitled Post", "タイトルなし", "", "Untitled post"].contains(title)
    }
    public var abbreviation: [String: AbbreviationInfoWrapper]?
    private let currentUserId: String
    private let currentTenantId: String

    public init(
        title: String = "",
        titleAttributedString: NSAttributedString? = nil,
        richText: RustPB.Basic_V1_RichText,
        isPost: Bool,
        isGroupAnnouncement: Bool = false,
        botIds: [String] = [],
        docEntity: RustPB.Basic_V1_DocEntity?,
        inlineEntities: [String: InlinePreviewEntity],
        abbreviation: RustPB.Basic_V1_Abbreviation?,
        typedElementRefs: [String: RustPB.Basic_V1_ElementRefs]?,
        currentUserId: String,
        currentTenantId: String
    ) {
        self.title = title
        self.titleAttributedString = titleAttributedString
        self.richText = richText
        self.isPost = isPost
        self.isGroupAnnouncement = isGroupAnnouncement
        self.botIds = botIds
        self.docEntity = docEntity
        self.inlineEntities = inlineEntities
        self.currentUserId = currentUserId
        self.currentTenantId = currentTenantId
        self.abbreviation = AbbreviationV2Processor.filterAbbreviation(abbreviation: abbreviation, typedElementRefs: typedElementRefs, tenantId: currentTenantId, userId: currentUserId)
    }

    public static func transform(from content: MessageContent, config: TextPostConfig? = nil, currentUserId: String, currentTenantId: String) -> TextPostContent {
        switch content {
        case let content as TextContent:
            return TextPostContent(
                richText: content.richText,
                isPost: false,
                botIds: content.botIds,
                docEntity: content.docEntity,
                inlineEntities: content.inlinePreviewEntities,
                abbreviation: content.abbreviation,
                typedElementRefs: content.typedElementRefs,
                currentUserId: currentUserId,
                currentTenantId: currentTenantId
            )
        case let content as PostContent:
            if let config = config, let titleRichAttributes = config.titleRichAttributes {
                let titleAttributText = NSAttributedString(string: content.title, attributes: titleRichAttributes)
                return TextPostContent(
                    title: content.title,
                    titleAttributedString: titleAttributText,
                    richText: content.richText,
                    isPost: true,
                    isGroupAnnouncement: content.isGroupAnnouncement,
                    botIds: content.botIds,
                    docEntity: content.docEntity,
                    inlineEntities: content.inlinePreviewEntities,
                    abbreviation: content.abbreviation,
                    typedElementRefs: content.typedElementRefs,
                    currentUserId: currentUserId,
                    currentTenantId: currentTenantId
                )
            } else {
                return TextPostContent(
                    title: content.title,
                    richText: content.richText,
                    isPost: true,
                    isGroupAnnouncement: content.isGroupAnnouncement,
                    botIds: content.botIds,
                    docEntity: content.docEntity,
                    inlineEntities: content.inlinePreviewEntities,
                    abbreviation: content.abbreviation,
                    typedElementRefs: content.typedElementRefs,
                    currentUserId: currentUserId,
                    currentTenantId: currentTenantId
                )
            }

        default:
            assertionFailure()
            return TextPostContent(richText: RustPB.Basic_V1_RichText(),
                                   isPost: false,
                                   docEntity: nil,
                                   inlineEntities: [:],
                                   abbreviation: nil,
                                   typedElementRefs: nil,
                                   currentUserId: currentUserId,
                                   currentTenantId: currentTenantId)
        }
    }
}

public struct TextPostConfig {
    /// 一行最多显示字符数
    /// 1 字符 16 size font 宽度约为 7.2
    /// 避免极端 case 这里取7
    public let calculateMaxCharCountAtOneLine: (CGFloat) -> Int = { maxContentWidth in
        let oneNumberWidth: CGFloat = 7
        return Int(maxContentWidth / oneNumberWidth)
    }
    /// 帖子图片最小大小
    public var imageMinSize: CGSize = CGSize(width: 50, height: 50)
    /// 是否显示帖子标题
    public var isShowTitle: Bool = true
    /// 原文是否自动展开
    public var isAutoExpand: Bool = false
    /// 译文是否自动展开
    public var translateIsAutoExpand: Bool = false
    /// 绘制时强制使用同步绘制
    public var syncDisplayMode: Bool = false
    /// title 富文本内容，在 titleRichAttributes 有值时使用富文本。
    public var titleRichAttributes: [NSAttributedString.Key: Any]?
    /// content 内容行高
    public var contentLineSpacing: CGFloat = 2
    /// content 内容字体
    public var contentTextFont: UIFont = UIFont.ud.body0
    /// image 内容最大宽度 默认值：300
    public var maxWidthOfImageContent: (Message) -> CGFloat = { _ in
        return 300
    }
    /// 图片 圆角
    public var attacmentImageCornerRadius: CGFloat = 4
    /// 图片 描边颜色
    public var attacmentImageborderColor: UIColor = UIColor.ud.lineBorderCard
    /// 图片 描边宽度
    public var attacmentImageborderWidth: CGFloat = 1 / UIScreen.main.scale
    /// PostView是否需要添加点击事件
    public var needPostViewTapHandler: Bool = false
    /// post中是否支持视频格式
    public var supportVideoInPost: Bool = true
    // 是否高亮at人；话题转发卡片等场景不需要高亮
    public var highlightAt: Bool = true
    // at人时是否显示已读未读状态
    public var isShowReadStatus: Bool = true
    // 群公告padding，话题转发卡片场景需要减去padding
    public var groupAnnouncementPadding: CGFloat = 0
    public var groupAnnouncementNeedBorder: Bool = false
    public var groupAnnouncementBorderColor: UIColor?
    // showMore mask color
    public var supportShowMoreMaskColor: Bool = true
    // 图片/视频是否允许左右横滑
    public var supportImageAndVideoFlip: Bool = true
    // 图片/适配是否允许「跳转至会话」
    public var supportImageAndVideoViewInChat: Bool = true
    // 是否支持独立卡片
    public var supportSinglePreview: Bool = false
    // 是否显示保存到云盘
    public var showSaveToCloud: Bool = true
    // 是否显示添加表情
    public var showAddToSticker: Bool = true

    public init() {}
}

var phoneNumDetecotor: NSRegularExpression? = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)

private var logger = Logger.log(NSObject(), category: "LarkMessage.TextPostContent")
struct AtColorConfig {
    public static func getMessageAtColorWithContext(_ context: ColorConfigContext, isFromMe: Bool) -> AtColor {
        var atColor = AtColor()
        atColor.ReadBackgroundColor = context.getColor(for: .Message_At_Read, type: .mine)
        atColor.UnReadRadiusColor = context.getColor(for: .Message_At_UnRead, type: isFromMe ? .mine : .other)
        atColor.MeForegroundColor = context.getColor(for: .Message_At_Foreground_Me, type: isFromMe ? .mine : .other)
        atColor.MeAttributeNameColor = context.getColor(for: .Message_At_Background_Me, type: isFromMe ? .mine : .other)
        atColor.OtherForegroundColor = context.getColor(for: .Message_At_Foreground_InnerGroup, type: isFromMe ? .mine : .other)
        atColor.AllForegroundColor = context.getColor(for: .Message_At_Foreground_All, type: isFromMe ? .mine : .other)
        atColor.OuterForegroundColor = context.getColor(for: .Message_At_Foreground_OutterGroup, type: isFromMe ? .mine : .other)
        atColor.AnonymousForegroundColor = context.getColor(for: .Message_At_Foreground_Anonymous, type: isFromMe ? .mine : .other)
        return atColor
    }

    public static func getUnHighlightAtColorWithContext(defaultTextColor: UIColor) -> AtColor {
        var atColor = AtColor()
        atColor.MeForegroundColor = defaultTextColor
        atColor.MeAttributeNameColor = .clear
        atColor.OtherForegroundColor = defaultTextColor
        atColor.AllForegroundColor = defaultTextColor
        atColor.OuterForegroundColor = defaultTextColor
        atColor.AnonymousForegroundColor = defaultTextColor
        return atColor
    }
}
/// 处理text/post展示逻辑
open class TextPostContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: TextPostContentContext>: AuthenticationMessageSubViewModel<M, D, C>, MessageMenuHideProtocol {

    @PageContext.InjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?
    @PageContext.InjectedLazy var enterpriseEntityWordService: EnterpriseEntityWordService?
    @PageContext.InjectedLazy private var guideService: ChatTabsGuideService?
    @PageContext.InjectedLazy private var replyInThreadConfig: ReplyInThreadConfigService?
    @PageContext.InjectedLazy var settings: UserGeneralSettings?
    @PageContext.InjectedLazy var passportUserService: PassportUserService?
    @PageContext.InjectedLazy var ntpAPI: NTPAPI?

    private lazy var fetchKeyWithCrypto: Bool = {
        return self.context.getStaticFeatureGating("messenger.image.resource_not_found")
    }()

    public lazy var permissionPreview: (Bool, ValidateResult?) = {
        return context.checkPermissionPreview(chat: metaModel.getChat(), message: metaModel.message)
    }()

    // 消息链接化场景有特化，单独开一个属性
    var videoHasPermissionPreview: Bool {
        return self.permissionPreview.0
    }

    open override var identifier: String {
        return "post"
    }

    func getPreviewSize(_ size: CGSize) -> CGSize {
        return permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed ? size : ChatNoPreviewPermissionLayerSizeConfig.normalSize
    }

    func noPermissionImageTappedAction() {
        self.context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: self.dynamicAuthorityEnum,
                                                            previewAuthResult: permissionPreview.1,
                                                            resourceType: .image)
    }

    func noPermissionVideoTappedAction() {
        self.context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: self.dynamicAuthorityEnum,
                                                            previewAuthResult: permissionPreview.1,
                                                            resourceType: .video)
    }

    override public var needAuthority: Bool {
        guard message.type == .post else { return false }
        guard let postContent = message.content as? PostContent else { return false }
        if postContent.richText.mediaIds.isEmpty && postContent.richText.imageIds.isEmpty {
            return false
        }
        return super.needAuthority
    }

    private let disposeBag = DisposeBag()

    public var contextScene: ContextScene {
        return context.contextScene
    }

    /// 显示规则：原文、译文、原文+译文
    public private(set) var displayRule: RustPB.Basic_V1_DisplayRule

    private var showOriginal: Bool {
        return displayRule != .onlyTranslation
    }

    private var showTranslate: Bool {
        return displayRule == .onlyTranslation || displayRule == .withOriginal
    }

    private var content: ThreadSafeDataStructure.SafeAtomic<MessageContent>
    /// 译文content，虽然可能没有译文，但是我们向内部传的时候保证一定有值，简化逻辑
    /// 如果message.translate没有值，则默认设置成content
    private var _translateContent: TextPostContent?
    public var translateContent: TextPostContent {
        get {
            pthread_mutex_lock(&mutex)
            defer {
                pthread_mutex_unlock(&mutex)
            }
            if let content = _translateContent {
                return content
            }
            let textPostContent: TextPostContent
            if let content = metaModel.message.translateContent {
                textPostContent = TextPostContent.transform(from: content,
                                                            config: config,
                                                            currentUserId: self.passportUserService?.user.userID ?? "",
                                                            currentTenantId: self.passportUserService?.userTenant.tenantID ?? "")
            } else {
                textPostContent = self.originContent
            }
            _translateContent = textPostContent
            return textPostContent
        }
        set {
            pthread_mutex_lock(&mutex)
            defer {
                pthread_mutex_unlock(&mutex)
            }
            _translateContent = newValue
        }
    }

    /// 原文content
    private var _originContent: TextPostContent?
    public var originContent: TextPostContent {
        get {
            pthread_mutex_lock(&mutex)
            defer {
                pthread_mutex_unlock(&mutex)
            }
            if let content = _originContent {
                return content
            }
            let content = TextPostContent.transform(from: metaModel.message.content,
                                                    config: config,
                                                    currentUserId: self.passportUserService?.user.userID ?? "",
                                                    currentTenantId: self.passportUserService?.userTenant.tenantID ?? "")
            _originContent = content
            return content
        }
        set {
            pthread_mutex_lock(&mutex)
            defer {
                pthread_mutex_unlock(&mutex)
            }
            _originContent = newValue
        }
    }

    /// 内容的最大宽度
    public var contentMaxWidth: CGFloat {
        if (self.context.contextScene == .newChat || self.context.contextScene == .mergeForwardDetail), message.showInThreadModeStyle {
            if self.isGroupAnnouncement {
                let contentPreferMaxWidth = metaModelDependency.getContentPreferMaxWidth(message) - config.groupAnnouncementPadding
                return min(GroupAnnouncementConfig.contentMaxWidth, contentPreferMaxWidth)
            }
            return metaModelDependency.getContentPreferMaxWidth(message)
        } else {
            if self.isGroupAnnouncement {
                let contentPreferMaxWidth = metaModelDependency.getContentPreferMaxWidth(message) - config.groupAnnouncementPadding
                return min(GroupAnnouncementConfig.contentMaxWidth, contentPreferMaxWidth)
            }
            return metaModelDependency.getContentPreferMaxWidth(message) - 2 * metaModelDependency.contentPadding
        }
    }

    /// 分割线颜色
    public lazy var lineColor: UIColor = {
        return self.context.getColor(for: .Message_BubbleSplitLine, type: self.isFromMe ? .mine : .other)
    }()

    /// 图片的最大宽度
    public var imageContentMaxSize: CGSize {
        if self.isGroupAnnouncement {
            let width = self.contentMaxWidth - GroupAnnouncementConfig.contentPadding * 2
            return CGSize(width: width, height: width)
        }
        let maxWidth = self.contentMaxWidth
        let width = min(config.maxWidthOfImageContent(message), maxWidth)
        return CGSize(width: width, height: width)
    }

    /// 链接按压态样式
    public lazy var activeLinkAttributes: [NSAttributedString.Key: Any] = {
        let color = self.context.getColor(for: .Message_Text_ActionPressed, type: self.isFromMe ? .mine : .other)
        return [LKBackgroundColorAttributeName: color]
    }()

    /// 是否显示title，用来区分text和post消息
    public let isShowTitle: Bool

    /// 是不是我发的消息
    public lazy var isFromMe: Bool = {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }()

    public var hasReaction: Bool {
        return !message.reactions.isEmpty
    }
    public var hasReply: Bool {
        return message.rootMessage != nil
    }

    public var postTitle: String? {
        guard let posContent = self.content.value as? PostContent else {
            return nil
        }
        return posContent.title
    }

    public var contentTextFont: UIFont {
        // Chat和小组相关界面使用17号字体
        if self.context.contextScene == .newChat || contextScene.isThreadScence() {
            return UIFont.ud.title4
        }
        return config.contentTextFont
    }

    private lazy var threadReplyBubbleOptimize: Bool = {
        return self.context.getStaticFeatureGating("im.message.thread_reply_bubble_optimize")
    }()

    private lazy var fixSplitForTextrunbox: Bool = {
        return self.context.getStaticFeatureGating("im_messenger_fix_split_for_textrunbox")
    }()

    private lazy var keepVisualIfNeeded: Bool = {
        return self.context.getStaticFeatureGating("im_messenger_resign_keep_visual_if_needed")
    }()

    public var showMoreMaskBackgroundColors: [UIColor] {
        if self.message.displayInThreadMode {
            return []
        }
        // 话题回复 没开FG，使用话题模式一样的颜色
        if self.message.showInThreadModeStyle, !self.message.displayInThreadMode, !self.threadReplyBubbleOptimize {
            return []
        }
        if !config.supportShowMoreMaskColor {
            return []
        }
        let topColor = self.context.getColor(for: .Message_Mask_GradientTop, type: self.isFromMe ? .mine : .other)
        let bottomColor = self.context.getColor(for: .Message_Mask_GradientBottom, type: self.isFromMe ? .mine : .other)
        return [topColor, bottomColor]
    }

    private var _originRichElement: LKRichElement?
    public var originRichElement: LKRichElement {
        get {
            pthread_mutex_lock(&mutex)
            // 已初始化，直接返回
            if let richElement = _originRichElement {
                pthread_mutex_unlock(&mutex)
                return richElement
            }
            // 未初始化，先unlock，避免getRichElementWithDetector耗时加锁 & 方法内部访问锁造成死锁
            pthread_mutex_unlock(&mutex)
            let richElement = getRichElementWithDetector(isOrigin: true)
            // lock之后再赋值
            pthread_mutex_lock(&mutex)
            defer { pthread_mutex_unlock(&mutex) }
            if let originRichElement = _originRichElement {
                return originRichElement
            }
            _originRichElement = richElement
            return richElement
        }
        set {
            pthread_mutex_lock(&mutex)
            _originRichElement = newValue
            pthread_mutex_unlock(&mutex)
        }
    }

    private var _translateRichElement: LKRichElement?
    public var translateRichElement: LKRichElement {
        get {
            pthread_mutex_lock(&mutex)
            // 已初始化，直接返回
            if let richElement = _translateRichElement {
                pthread_mutex_unlock(&mutex)
                return richElement
            }
            // 未初始化，先unlock，避免getRichElementWithDetector耗时加锁 & 方法内部访问锁造成死锁
            pthread_mutex_unlock(&mutex)
            let richElement = getRichElementWithDetector(isOrigin: false)
            // lock之后再赋值
            pthread_mutex_lock(&mutex)
            defer { pthread_mutex_unlock(&mutex) }
            if let translateRichElement = _translateRichElement {
                return translateRichElement
            }
            _translateRichElement = richElement
            return richElement
        }
        set {
            pthread_mutex_lock(&mutex)
            _translateRichElement = newValue
            pthread_mutex_unlock(&mutex)
        }
    }

    var needCleanCacheByPhoneDetect: Bool = true
    public var originTiledCache: LKTiledCache?

    public var translateTiledCache: LKTiledCache?

    private var _configOptions: ConfigOptions?
    public var configOptions: ConfigOptions {
        if let _configOptions = self._configOptions {
            return _configOptions
        }

        let _configOptions = ConfigOptions([
           .debug(false),
           .fixSplitForTextRunBox(self.fixSplitForTextrunbox),
           .maxHeightBuffer(max(abs(triggerFoldHeight - foldedHeight), 20)),
           .visualConfig(VisualConfig(
               selectionColor: UIColor.ud.colorfulBlue.withAlphaComponent(0.16),
               cursorColor: UIColor.ud.colorfulBlue,
               cursorHitTestInsets: UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25)
           ))
        ])
        self._configOptions = _configOptions
        return _configOptions
    }

    private let iconColor: UIColor = UIColor.ud.textLinkNormal

    private var atColor: AtColor {
        if config.highlightAt {
            return AtColorConfig.getMessageAtColorWithContext(self.context, isFromMe: isFromMe)
        }
        return AtColorConfig.getUnHighlightAtColorWithContext(defaultTextColor: defaultTextColor)
    }

    private var isShowReadStatus: Bool {
        return config.isShowReadStatus && !isSuperChat
    }

    /// 文本默认颜色
    private var defaultTextColor: UIColor {
        if self.message.isDecryptoFail {
            return UIColor.ud.textCaption
        } else if message.setGrey || message.isCleaned {
            return context.getColor(for: .Message_SystemText_Foreground, type: isFromMe ? .mine : .other)
        }
        return UIColor.ud.N900
    }

    private weak var targetElement: LKRichElement?
    /// 需要监听事件的Tag
    public let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: CodeTag.code)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)],
        [CSSSelector(match: .className, value: RichViewAdaptor.ClassName.abbreviation)],
        [CSSSelector(match: .className, value: RichViewAdaptor.ClassName.unavailableMention)]
    ]

    public var styleSheets: [CSSStyleSheet] {
        if self.isGroupAnnouncement {
            return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: contentTextFont,
                                                                                    atColor: atColor,
                                                                                    figurePadding: .init(.value, .init(.point(0)))))
        }
        return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: contentTextFont, atColor: atColor))
    }

    /// size 发生变化，处理富文本中 attachment size
    override open func onResize() {
        self.cleanTiledCache()
        self.rebuildAttributeElementIniPadIfNeeded()
        super.onResize()
    }

    /// 原文是否展开，原文译文支持分别展开
    private var isExpand: Bool
    /// 译文是否展开，原文译文支持分别展开
    private var translateIsExpand: Bool

    /// postView 显示图片
    private var imageViewWrappers: NSHashTable = NSHashTable<ChatImageViewWrapper>.weakObjects()

    /// 原文showMore
    public private(set) var isShowMore: Bool = false {
        didSet {
            if isShowMore != oldValue {
                safeUpdate(animation: isShowMore ? .none : .fade)
            }
        }
    }
    /// 译文showMore
    public private(set) var translateIsShowMore: Bool = false {
        didSet {
            if translateIsShowMore != oldValue {
                safeUpdate(animation: translateIsShowMore ? .none : .fade)
            }
        }
    }

    /// 权限变化时，图片和视频尺寸会改变
    override public func updateUIWhenAuthorityChanged() {
        self.rebuildElement(isOrigin: true)
        self.rebuildElement(isOrigin: false)
        safeUpdate(animation: .fade)
    }

    /// post是否是群公告
    public lazy var isGroupAnnouncement: Bool = {
        return (content.value as? PostContent)?.isGroupAnnouncement ?? false
    }()

    public var groupAnnouncementNeedBorder: Bool {
        guard isGroupAnnouncement else {
            return false
        }
        if config.groupAnnouncementNeedBorder {
            return true
        }
        if (self.context.contextScene == .newChat || self.context.contextScene == .mergeForwardDetail), self.message.showInThreadModeStyle {
            return true
        }
        return !(context.contextScene == .newChat || context.contextScene == .mergeForwardDetail)
    }

    var groupAnnouncementBorderColor: UIColor {
        guard isGroupAnnouncement else {
            return UIColor.clear
        }
        if let borderColor = config.groupAnnouncementBorderColor {
            return borderColor
        }
        return message.showInThreadModeStyle ? UIColor.ud.lineBorderCard : UDMessageColorTheme.imMessageCardBorder
    }

    /// 显示的一些常规配置：最大行数等，vm中的部分逻辑会依赖config
    var config: TextPostConfig

    public var contentLineSpacing: CGFloat {
        return config.contentLineSpacing
    }

    /// 文本内容检查
    public var textCheckingDetecotor: NSRegularExpression?

    /// PostView是否需要添加点击事件
    public var needPostViewTapHandler: Bool {
        // 感觉下面的代码没有必要？Chat、MergeForward场景不是有bubbleTouchView吗？
        let isThreadRootMessage = metaModel.message.threadMessageType == .threadRootMessage
        // MyAI场景不能进ReplyInThread
        if self.context.contextScene == .newChat, isThreadRootMessage, metaModel.getChat().isP2PAi { return false }

        return self.config.needPostViewTapHandler || (isThreadRootMessage)
    }

    private var isDisplay: Bool = false

    private var mutex: pthread_mutex_t
    private var _imageResources: [LarkImageResource] = []
    private var imageResources: [LarkImageResource] {
        get {
            pthread_mutex_lock(&mutex)
            defer {
                pthread_mutex_unlock(&mutex)
            }
            return _imageResources
        }
        set {
            pthread_mutex_lock(&mutex)
            _imageResources = newValue
            pthread_mutex_unlock(&mutex)
        }
    }

    // 是否需要上报埋点：减少inlineRenderTrack加解锁访问
    private var inlineRenderNeedTrack: Bool
    private var _inlineRenderTrack: InlinePreviewRenderTrack = .init()
    private var inlineRenderTrack: InlinePreviewRenderTrack {
        get {
            pthread_mutex_lock(&mutex)
            defer {
                pthread_mutex_unlock(&mutex)
            }
            return _inlineRenderTrack
        }
        set {
            pthread_mutex_lock(&mutex)
            _inlineRenderTrack = newValue
            pthread_mutex_unlock(&mutex)
        }
    }

    private lazy var isSuperChat: Bool = {
        return self.metaModel.getChat().isSuper
    }()

    var triggerFoldHeight: CGFloat {
        return context.heightWithoutSafeArea
    }

    var foldedHeight: CGFloat {
        return context.heightWithoutSafeArea - contentTextFont.lineHeight
    }

    private var binderUpdateMutex = pthread_mutex_t()

    public init(content: MessageContent,
                metaModel: M,
                metaModelDependency: D,
                context: C,
                binder: TextPostContentComponentBinder<M, D, C>,
                config: TextPostConfig = TextPostConfig()) {
        mutex = pthread_mutex_t()
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attr)
        pthread_mutexattr_destroy(&attr)
        pthread_mutex_init(&binderUpdateMutex, nil)
        self.isShowTitle = config.isShowTitle
        self.isExpand = config.isAutoExpand
        self.translateIsExpand = config.translateIsAutoExpand
        /// 内容
        self.content = ThreadSafeDataStructure.SafeAtomic(content, with: .readWriteLock)
        self.config = config
        var displayRule = metaModel.message.displayRule
        var isGroupAnnouncement: Bool = false
        if let content = content as? PostContent, content.isGroupAnnouncement {
            isGroupAnnouncement = true
            self.config.attacmentImageCornerRadius = 0
            self.config.attacmentImageborderWidth = 0
            self.config.attacmentImageborderColor = UIColor.clear
            self.config.needPostViewTapHandler = true
        }
        /// 新版群公告 -- > 不展示译文
        /// 消息被清理 -- > 不展示译文
        if isGroupAnnouncement || metaModel.message.isCleaned {
            displayRule = .noTranslation
        }
        self.displayRule = displayRule

        // copy from update(metaModel: M, metaModelDependency: D?)，解决问题：进会话后部分消息会重新刷一次（消息内容有个隐藏->显示的动画）
        // 原因：因为这三个值没在init中没赋值，导致updateMetaModel时cleanTiledCacheIfNeed一定为true，会清除分片缓存
        lastTranslateMessage = metaModel.message.translateLanguage
        lastDisplayRule = metaModel.message.displayRule
        lastIsFlag = metaModel.message.isFlag
        lastStreamStatus = metaModel.message.streamStatus

        textCheckingDetecotor = phoneNumDetecotor
        // 密聊不支持翻译
        /// 一级msg都是commonMessage
        let translateParam = MessageTranslateParameter(message: metaModel.message,
                                                       source: MessageSource.common(id: metaModel.message.id),
                                                       chat: metaModel.getChat())
        context.translateService?.translateURLInlines(translateParam: translateParam)
        inlineRenderNeedTrack = InlinePreviewRenderTrack.needTrack(message: metaModel.message)
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    deinit {
        pthread_mutex_destroy(&self.mutex)
        pthread_mutex_destroy(&self.binderUpdateMutex)
        guard !self.isDisplay else {
            return
        }
        let resources = self.imageResources
        for resource in resources {
            LarkImageService.shared.removeCache(resource: resource, options: .memory)
        }
    }

    /// 翻译反馈函数
    func translateFeedBackTapHandler() {
        translateMoreActionHandler.translateFeedBackTapHandler()
    }

    func translateMoreTapHandler(_ view: UIView) {
        translateMoreActionHandler.translateMoreTapHandler(view)
    }

    /// translate Tracking
    var chatTypeForTracking: String {
        if metaModel.getChat().chatMode == .threadV2 {
            return "topic"
        } else if metaModel.getChat().type == .group {
            return "group"
        } else {
            return "single"
        }
    }

    private lazy var translateMoreActionHandler: TranslateMoreActionHandler = {
        return TranslateMoreActionHandler(context: context, metaModel: metaModel)
    }()

    open override func didEndDisplay() {
        super.didEndDisplay()
        self.imageViewWrappers.allObjects.forEach {
            $0.toggleAnimation(false)
        }
        // cancel preload post video
        if let postContent = self.content.value as? PostContent,
           self.config.supportVideoInPost {
            let medias = postContent.richText.mediaIds.flatMap { id in
                return postContent.richText.elements[id]?.property.media
            }
            VideoPreloadManager.shared.cancelPreloadVideoIfNeeded(medias, currentAccessToken: self.passportUserService?.user.sessionKey)
        }
        self.isDisplay = false
    }

    open override func willDisplay() {
        super.willDisplay()
        self.imageViewWrappers.allObjects.forEach {
            $0.toggleAnimation(true)
            // Jira：https://jira.bytedance.com/browse/SUITE-22889
            // reason：sublayer's animation will be removed when dequeueReusableCell
            // solution：re-add sublayer's animation when willDisplay
            // fix version：3.12.0
            $0.showLoadingIfNeeded()
            // 对齐单条图片消息，退出查看大图时若失败则重试图片
            $0.retryIfNeed(needLoading: true, animatedDelegate: nil, forceStartIndex: 0, forceStartFrame: nil)
        }
        // preload post video
        if let postContent = self.content.value as? PostContent,
           self.config.supportVideoInPost {
            let medias = postContent.richText.mediaIds.flatMap { id in
                return postContent.richText.elements[id]?.property.media
            }
            VideoPreloadManager.shared.preloadVideoIfNeeded(medias,
                                                            currentAccessToken: self.passportUserService?.user.sessionKey,
                                                            userResolver: self.context.userResolver)
        }
        self.isDisplay = true
        trackInlineRender()
    }

    open override var contentConfig: ContentConfig? {
        if isGroupAnnouncement {
            var contentConfig = ContentConfig(hasMargin: false,
                                              maskToBounds: true,
                                              supportMutiSelect: true,
                                              hasBorder: true)
            contentConfig.isCard = true
            return contentConfig
        }
        if let contentConfig = singlePreviewContentConfig {
            return contentConfig
        }
        return ContentConfig(hasMargin: true,
                             maskToBounds: false,
                             supportMutiSelect: true)
    }

    // 独立卡片无气泡
    public var singlePreviewContentConfig: ContentConfig? {
        if config.supportSinglePreview,
           TCPreviewContainerComponentFactory.canCreateSinglePreview(message: message, chat: metaModel.getChat(), context: context) {
            message.isSinglePreview = true
            let hasBubble = TCPreviewContainerComponentFactory.isSinglePreviewWithBubble(message: message, scene: context.scene)
            var config = ContentConfig(
                hasMargin: hasBubble,
                maskToBounds: true,
                supportMutiSelect: true,
                hasBorder: !hasBubble,
                hideContent: true,
                threadStyleConfig: nil
            )
            // 独立卡片时气泡背景色和卡片一致
            config.borderStyle = .custom(strokeColor: UDMessageColorTheme.imMessageCardBorder, backgroundColor: TCPreviewConfig.cardBgColor)
            return config
        }
        return nil
    }

    /// 当message发生变化时，上层会调用到本方法，后面会调用binder的update(vm)方法
    /// 此方法用来更新vm的数据
    open override func update(metaModel: M, metaModelDependency: D?) {
        // 对于假消息，hangPoint走update过来，需要重新检测是否需要上报
        if !inlineRenderNeedTrack {
            inlineRenderNeedTrack = InlinePreviewRenderTrack.needTrack(message: metaModel.message)
        }
        self.cleanTiledCacheIfNeed(newMessage: metaModel.message)
        /// 获取content
        self.content.value = metaModel.message.content
        // 后续的rebuildElement等操作会取message，此处应先替换旧metaModel，否则将取到旧message
        self.metaModel = metaModel
        self.displayRule = metaModel.message.displayRule

        /// 新版群公告 聊天界面下 -- > 不展示译文
        /// 消息被清理 -- > 不展示译文
        if isGroupAnnouncement || metaModel.message.isCleaned {
            displayRule = .noTranslation
        }
        if showOriginal {
            self.originContent = TextPostContent.transform(from: content.value,
                                                           config: config,
                                                           currentUserId: self.passportUserService?.user.userID ?? "",
                                                           currentTenantId: self.passportUserService?.userTenant.tenantID ?? "")
            self.rebuildElement(isOrigin: true)
        }
        if showTranslate {
            /// 确保translateContent一定有值，简化后续逻辑
            if let content = metaModel.message.translateContent {
                self.translateContent = TextPostContent.transform(from: content,
                                                                  config: config,
                                                                  currentUserId: self.passportUserService?.user.userID ?? "",
                                                                  currentTenantId: self.passportUserService?.userTenant.tenantID ?? "")
            } else {
                self.translateContent = self.originContent
            }
            self.rebuildElement(isOrigin: false)
        }
        let translateParam = MessageTranslateParameter(message: metaModel.message,
                                                       source: MessageSource.common(id: metaModel.message.id),
                                                       chat: metaModel.getChat())
        context.translateService?.translateURLInlines(translateParam: translateParam)
        lastTranslateMessage = metaModel.message.translateLanguage
        lastDisplayRule = metaModel.message.displayRule
        lastIsFlag = metaModel.message.isFlag
        lastStreamStatus = metaModel.message.streamStatus
        pthread_mutex_lock(&binderUpdateMutex)
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        pthread_mutex_unlock(&binderUpdateMutex)
    }

    open func customImageDownloadFailedLayer(error: Error) -> UIView? {
        return nil
    }
    // 由于之前翻译在使用 updateMessage 接口的时候使用的不对，newMessage 和 currentMsg 是同一个对象，导致 needClean 判断失效
    // 暂时先用这种方式处理，之后修改外层使用 updateMessage 的方式
    private var lastTranslateMessage: String?
    private var lastDisplayRule: RustPB.Basic_V1_DisplayRule?
    // 标记状态变化时，消息宽度会变化，也需要清缓存
    private var lastIsFlag: Bool?
    // (流式状态变化||流式中)内容可能会发生变化，所以需要清除；因为message是引用，所以currentMsg、newMessage可能是同一份实例，所以需要单独存储
    private var lastStreamStatus: RustPB.Basic_V1_Message.StreamStatus = .streamUnknown
    private func cleanTiledCacheIfNeed(newMessage: Message) {
        let currentMsg = self.message
        var needClean = false
        if isAbbreviationChanged(newMessage: newMessage) {
            needClean = true
        } else if currentMsg.readAtChatterIds.count != newMessage.readAtChatterIds.count {
            needClean = true
        } else if isInlineChanged(newMessage: newMessage) {
            needClean = true
        } else if currentMsg.editVersion < newMessage.editVersion {
            needClean = true
        } else if lastTranslateMessage != newMessage.translateLanguage {
            needClean = true
        } else if lastDisplayRule != newMessage.displayRule {
            needClean = true
        } else if lastIsFlag != newMessage.isFlag {
            needClean = true
        } else if lastStreamStatus != newMessage.streamStatus || lastStreamStatus == .streamTransport || newMessage.streamStatus == .streamTransport {
            // 董伟反馈MyAI内容很长时，底部会出现空白；但是我没复现
            needClean = true
        }

        if needClean {
            self.cleanTiledCache()
        }
    }

    // URL中台的Inline内容是否改变，Inline变更也需要清除缓存
    private func isInlineChanged(newMessage: Message) -> Bool {
        // Message是引用，不能用oldMessage和newMessage比较，但是originContent做了一次transform，可以比较
        let oldInlines = self.originContent.inlineEntities
        let newInlines = MessageInlineViewModel.getInlinePreviewBody(message: newMessage)
        guard oldInlines.count == newInlines.count else { return true }
        for (previewID, oldInline) in oldInlines {
            if let newInline = newInlines[previewID], isInlineChanged(old: oldInline, new: newInline) {
                return true
            } else if newInlines[previewID] == nil {
                return true
            }
        }
        return false
    }

    // 比较inline的内容是否变更，否则在视频会议频繁入会出会时，会导致缓存清除，文本不断闪烁
    private func isInlineChanged(old: InlinePreviewEntity, new: InlinePreviewEntity) -> Bool {
        guard new.version >= old.version else { return false }
        return old.title != new.title ||
        old.udIcon != new.udIcon ||
        old.imageSetPassThrough != new.imageSetPassThrough ||
        old.iconKey != new.iconKey ||
        old.iconUrl != new.iconUrl ||
        old.iconImage !== new.iconImage ||
        old.tag != new.tag ||
        old.url != new.url ||
        old.unifiedHeader != new.unifiedHeader
    }

    // 企业词典是否改变
    private func isAbbreviationChanged(newMessage: Message) -> Bool {
        let oldAbbr = self.originContent.abbreviation ?? [:]
        // 转换abbreviation，对齐TextPostContent中转换规则
        let userId = self.passportUserService?.user.userID ?? ""
        let tenantId = self.passportUserService?.userTenant.tenantID ?? ""
        var abbreviation: Basic_V1_Abbreviation?
        var typedElementRefs: [String: Basic_V1_ElementRefs]?
        switch newMessage.content {
        case let content as TextContent:
            abbreviation = content.abbreviation
            typedElementRefs = content.typedElementRefs
        case let content as PostContent:
            abbreviation = content.abbreviation
            typedElementRefs = content.typedElementRefs
        default: break
        }
        let newAbbr = AbbreviationV2Processor.filterAbbreviation(abbreviation: abbreviation, typedElementRefs: typedElementRefs, tenantId: tenantId, userId: userId)

        return oldAbbr.keys != newAbbr.keys
    }

    private func cleanTiledCache() {
        self.originTiledCache = nil
        self.translateTiledCache = nil
        needCleanCacheByPhoneDetect = true
    }

    /// postView被点击
    /// 什么时候postViewTapped 会被调用 而不是传递下去取决于needPostViewTapHandler该属性 + metaModel.message.threadMessageType == .threadRootMessage
    /// chat中needPostViewTapHandler = (metaModel.message.type == .post && context.contextScene != .pin)
    /// 密聊 + 消息详情页 + Thread详情页 + reply in thread详情页都是false
    /// 目前chat + crypto 在container注册的，也有些页面比如 合并转发 + reply in thread 是在pageContaienr注册的
    func postViewTapped() {

        /// 点击消息跳转详情页等 禁止跳转事件
        if self.hideSheetMenuIfNeedForMenuService(self.context.pageContainer.resolve(MessageMenuOpenService.self)) {
            return
        }

        if self.isGroupAnnouncement {
            self.jumpToAnnouncementVC()
            return
        }

        switch context.contextScene {
        case .threadChat, .threadDetail, .replyInThread, .threadPostForwardDetail:
            break
        case .mergeForwardDetail:
            if message.threadMessageType == .threadRootMessage {
                let chat = message.mergeForwardInfo?.originChat
                if chat?.role == .member {
                    guard let chat = chat else { return } //这条路径一定是有chat的
                    let loadType: ThreadDetailLoadType
                    switch message.threadMessageType {
                    case .unknownThreadMessage, .threadReplyMessage:
                        logger.error("ReplyThreadInfoComponentViewModel replyDidTapped: threadMessageType error ")
                        assertionFailure("threadMessageType error")
                        return
                    case .threadRootMessage:
                        loadType = .root
                    @unknown default:
                        assertionFailure("threadMessageType error")
                        return
                    }
                    let body = ReplyInThreadByModelBody(message: message,
                                                        chat: chat,
                                                        loadType: loadType,
                                                        sourceType: .chat,
                                                        chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
                    context.navigator(type: .push, body: body, params: nil)
                } else {
                    var originMergeForwardId = message.id
                    if let chatPageAPI = context.targetVC as? ChatPageAPI,
                       let forwardID = chatPageAPI.originMergeForwardId() {
                        originMergeForwardId = forwardID
                    }
                    //如果拿不到chat，也说明自己不在会话里。此时mock一个
                    let chat = chat ?? ReplyInThreadMergeForwardDataManager.getMockP2pChat(id: String(message.mergeForwardInfo?.originChatID ?? 0))
                    let body = ThreadPostForwardDetailBody(originMergeForwardId: originMergeForwardId,
                                                           message: message,
                                                           chat: chat)
                    context.navigator(type: .push, body: body, params: nil)
                }
            }
        case .pin:
            break
        case .newChat:
            if message.threadMessageType != .unknownThreadMessage {
                let body = ReplyInThreadByModelBody(message: message,
                                                    chat: metaModel.getChat(),
                                                    loadType: .unread,
                                                    sourceType: .chat,
                                                    chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
                context.navigator(type: .push, body: body, params: nil)
            } else {
                let body = MessageDetailBody(chat: metaModel.getChat(),
                                             message: message,
                                             source: .postMsg,
                                             chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
                context.navigator(type: .push, body: body, params: nil)
            }
        case .messageDetail:
            let body = MessageDetailBody(chat: metaModel.getChat(),
                                         message: message,
                                         source: .postMsg,
                                         chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
            context.navigator(type: .push, body: body, params: nil)
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    /// 跳转群公告
    func jumpToAnnouncementVC() {
        let chat = self.metaModel.getChat()
        /// 密盾群不支持跳转群公告
        if chat.isPrivateMode { return }
        let body = ChatAnnouncementBody(chatId: message.channel.id)
        context.navigator(type: .push, body: body, params: nil)
        LarkMessageCoreTracker.trackOpenChatAnnouncementFromMessage(chatType: chat.type)
    }

    /// postView中图片被点击
    func imageViewTapped(_ view: ChatImageViewWrapper) {
        assertionFailure("must override")
    }

    /// 点击了原文"显示更多"，该方法会最终由原文maskView调用
    public func showMore() {
        self.isExpand = true
        self.rebuildElement(isOrigin: true)
        self.isShowMore = false
        // 他人发送的消息未读时显示100行，此时可能也会命中分片，因此更多展开时也需要清除缓存
        self.cleanTiledCache()
    }
    /// 点击了原文"显示更多"，该方法会最终由译文maskView调用
    public func translateShowMore() {
        self.translateIsExpand = true
        self.rebuildElement(isOrigin: false)
        self.translateIsShowMore = false
        // 他人发送的消息未读时显示100行，此时可能也会命中分片，因此更多展开时也需要清除缓存
        self.cleanTiledCache()
    }

    /// 最大行数，原文、译文相同
    public func getContentNumberOfLines() -> Int {
        if isExpand { return 0 }
        if self.contextScene == .pin {
            return message.type == .post ? 4 : 5
        }
        return Int((triggerFoldHeight / contentTextFont.lineHeight).rounded())
    }

    /// 计算一行最多可以展示的字符数量
    private func getMaxCharCountAtOneLine() -> Int {
        return self.config.calculateMaxCharCountAtOneLine(self.contentMaxWidth)
    }

    public func openURL(_ url: String) {
        let chat = self.metaModel.getChat()
        self.chatSecurityAuditService?.auditEvent(.clickLink(url: url, chatId: chat.id, chatType: chat.type), isSecretChat: false)
        self.guideService?.triggerGuide(chat.id)
        do {
            let url = try URL.forceCreateURL(string: url)
            let userInfo = self.getOpenLinkUserInfo()
            context.navigator(type: .push, url: url, params: NavigatorParams(context: userInfo))
        } catch {
            logger.warn(logId: "url_parse", error.localizedDescription)
        }
    }

    private func getOpenLinkUserInfo() -> [String: Any] {
        var userInfo: [String: Any] = [
            "from": "message",
            "message_type": "richtext",
            "scene": "messenger",
            "location": "messenger_chat",
            "url_click_type": "inline"
        ]
        let chat = self.metaModel.getChat()
        if chat.isMeeting {
            userInfo["chat_type"] = "meeting"
        } else {
            let chatType: String
            // ThreadDetail场景获取的chat是此话题所在的话题群，这两种场景都传"topicGroup"
            if chat.chatMode == .threadV2 {
                chatType = "topicGroup"
            } else if chat.type == .group {
                chatType = "group"
            } else {
                chatType = "single"
            }
            userInfo["chat_type"] = chatType
        }
        return userInfo
    }

    /// 获取 label 选中态 delegate
    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return self.context.getSelectionLabelDelegate()
    }

    // 处理匿名和普通场景的收敛判断方法
    private func isMe(_ id: String) -> Bool {
        return self.context.isMe(id, chat: self.metaModel.getChat())
    }

    /// onResize 的时候重置属性字符串
    private func rebuildAttributeElementIniPadIfNeeded() {
        guard Display.pad else { return }
        self.rebuildElement(isOrigin: true)
        self.rebuildElement(isOrigin: false)
    }

    /// 视频被点击
    func mediaImageViewTapped(_ videoImageView: VideoImageViewWrapper) {
        assertionFailure("must override")
    }

    private func imageAttachmentView(
        property: RustPB.Basic_V1_RichTextElement.ImageProperty,
        customFont: UIFont
        ) -> LKAttachmentProtocol {
        let originSize = getPreviewSize(CGSize(width: CGFloat(property.originWidth),
                                               height: CGFloat(property.originHeight)
                                              ))

        let size = ChatImageViewWrapper.calculateSize(originSize: originSize, maxSize: self.imageContentMaxSize, minSize: self.config.imageMinSize)
        let attachMent = LKAsyncAttachment(viewProvider: { [weak self] () -> UIView in
            guard let `self` = self else { return UIView() }
            return self.createImageView(property: property, originSize: originSize, size: size)
        }, size: size)
        attachMent.fontAscent = customFont.ascender
        attachMent.fontDescent = customFont.descender
        attachMent.margin = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)

        return attachMent
    }
    /// 服务端不下发toolName信息，需要端上异步获取后再重新刷新
    private var toolInfoMap: [String: MyAIToolInfo] = [:]
}

// MARK: - NewRichComponent
extension TextPostContentViewModel {
    func rebuildElement(isOrigin: Bool) {
        if isOrigin {
            self.originRichElement = self.getRichElementWithDetector(isOrigin: isOrigin)
        } else {
            self.translateRichElement = self.getRichElementWithDetector(isOrigin: isOrigin)
        }
    }

    func getRichElementWithDetector(isOrigin: Bool) -> LKRichElement {
        parsePhoneNumber(isOrigin: isOrigin)
        return getRichElement(isOrigin: isOrigin)
    }

    func getRichElement(isOrigin: Bool, phoneNumberAndLinkProvider: ((String, String) -> [PhoneNumberAndLinkParser.ParserResult])? = nil) -> LKRichElement {
        if isOrigin, inlineRenderNeedTrack {
            inlineRenderTrack.setStartTime(message: message)
        }
        let content = isOrigin ? self.originContent : self.translateContent
        let maxLines = getContentNumberOfLines()
        let maxCharLine = getMaxCharCountAtOneLine()

        let textDocsVMResult = TextDocsViewModel(
            userResolver: self.context.userResolver,
            richText: content.richText,
            docEntity: content.docEntity,
            hangPoint: message.urlPreviewHangPointMap
        )
        let richText = textDocsVMResult.richText

        self.imageResources = []

        var mediaAttachmentProvider: ((Basic_V1_RichTextElement.MediaProperty) -> LKRichAttachment)?
        if self.message.type == .post, config.supportVideoInPost {
            mediaAttachmentProvider = { [weak self] property in
                guard let self = self else { return LKRichAttachmentImp(view: UIView(frame: .zero)) }
                return self.mediaViewRichAttachment(property: property)
            }
        }
        let readAtUserIDs = getAtReadUserIDs(isOrigin: isOrigin)
        // 存储当前是否有正在loading的插件
        var hasLoadingExtension: Bool = false
        // only origin show abbreviation
        let showAbbre = isOrigin && context.abbreviationEnable
        var result = RichViewAdaptor.parseRichTextToRichElement(
            richText: richText,
            isFromMe: isMe(self.message.fromId),
            isShowReadStatus: isShowReadStatus,
            checkIsMe: isMe,
            botIDs: content.botIds,
            readAtUserIDs: readAtUserIDs,
            defaultTextColor: self.defaultTextColor,
            maxLines: maxLines,
            maxCharLine: maxCharLine,
            abbreviationInfo: showAbbre ? content.abbreviation : nil,
            mentions: message.mentions,
            imageAttachmentProvider: { [weak self] property in
                guard let self = self else { return LKRichAttachmentImp(view: UIView(frame: .zero)) }
                return self.imageViewRichAttachment(property: property)
            },
            toolAttachmentProvider: { [weak self] property in
                guard let self = self else { return LKRichAttachmentImp(view: UIView(frame: .zero)) }
                // 判断当前插件是否正在loading
                if !hasLoadingExtension { hasLoadingExtension = (property.status == .runing) }
                return self.toolViewRichAttachment(property: property)
            },
            mediaAttachmentProvider: mediaAttachmentProvider,
            urlPreviewProvider: { [weak self] elementID in
                guard let self = self else { return nil }
                var translatedInlines: InlinePreviewEntityBody?
                if !isOrigin {
                    let translateParam = MessageTranslateParameter(message: self.message,
                                                                   source: MessageSource.common(id: self.message.id),
                                                                   chat: self.metaModel.getChat())
                    translatedInlines = self.context.translateService?.getTranslatedInline(translateParam: translateParam)
                }
                let inlinePreviewVM = MessageInlineViewModel()
                return inlinePreviewVM.getNodeSummerizeAndURL(
                    elementID: elementID,
                    message: self.message,
                    translatedInlines: translatedInlines,
                    isOrigin: isOrigin,
                    font: self.contentTextFont,
                    textColor: UIColor.ud.textLinkNormal,
                    iconColor: self.iconColor,
                    tagType: TagType.link
                )
            },
            phoneNumberAndLinkProvider: phoneNumberAndLinkProvider,
            edited: message.isMultiEdited
        )
        // 拼接loading标记
        self.addOrRemoveLoadingIfNeeded(result: &result)
        // 拼接流式输出标记
        self.addOrRemoveStreamingIfNeeded(result: &result, hasLoadingExtension: hasLoadingExtension)
        let maxHeight = isOrigin ? getOriginContentMaxHeight() : getTranslateContentMaxHeight()
        result.style.maxHeight(maxHeight)
        trackInlineRender(isOrigin: isOrigin)
        return result
    }

    func parsePhoneNumber(isOrigin: Bool) {
        // 当消息发送成功/失败才解析电话号码
        guard message.localStatus == .success || message.localStatus == .fail else { return }
        let richText = isOrigin ? self.originContent.richText : self.translateContent.richText
        let contents = PhoneNumberAndLinkParser.getNeedParserContent(richText: richText)
        // 密盾群需要本地识别 link
        let detector: PhoneNumberAndLinkParser.Detector = self.metaModel.getChat().isPrivateMode ? .phoneNumberAndLink : .onlyPhoneNumber

        context.phoneNumberAndLinkParser?.asyncParser(contents: contents, detector: detector) { [weak self] phoneNumberAndLinkResult in
            guard let self = self, !phoneNumberAndLinkResult.isEmpty else { return }
            let richElement = self.getRichElement(isOrigin: isOrigin, phoneNumberAndLinkProvider: { elementID, _ in
                return phoneNumberAndLinkResult[elementID] ?? []
            })
            if isOrigin {
                self.originRichElement = richElement
            } else {
                self.translateRichElement = richElement
            }
            //电话号码识别每次数据更新都会重复执行，但实际上不会产生变化，cache并不需要每次都清除
            if self.needCleanCacheByPhoneDetect {
                self.cleanTiledCache()
                self.needCleanCacheByPhoneDetect = false
            }
            self.safeUpdate(animation: .none, reloadTable: true)
        }
    }

    /// https://t.wtturl.cn/68fA1KQ/
    /// Fix dbfree.
    private func safeUpdate(animation: UITableView.RowAnimation, reloadTable: Bool = false) {
        pthread_mutex_lock(&binderUpdateMutex)
        self.binder.update(with: self)
        if reloadTable {
            self.updateComponentAndRoloadTable(component: self.binder.component)
        } else {
            self.update(component: self.binder.component, animation: animation)
        }
        pthread_mutex_unlock(&binderUpdateMutex)
    }

    func toolViewRichAttachment(property: Basic_V1_RichTextElement.MyAIToolProperty) -> LKRichAttachment {
        let toolStatus = self.processMyAIToolPropertyStatus(property: property)

        let font = contentTextFont
        let toolName = property.localToolName.isEmpty ? (toolInfoMap[property.toolID]?.toolName ?? "") : property.localToolName
        let size = MyAIToolsCotThinkingProcessView.sizeToFit(toolName: toolName,
                                                             toolStatus: toolStatus,
                                                             maxWidth: contentMaxWidth,
                                                             font: contentTextFont)
        let attachmentSize = CGSize(width: min(size.width, contentMaxWidth), height: size.height)
        logger.info("text post tool view richAttachment toolId: \(property.toolID) toolNameIsEmpty:\(toolName.isEmpty) localToolNameIsEmpty:\(property.localToolName.isEmpty) attachmentSize:\(attachmentSize)")
        let attachment = LKAsyncRichAttachmentImp(
            size: attachmentSize,
            viewProvider: { [weak self] in
                guard let self = self else { return UIView(frame: .zero) }
                let view = self.createToolView(property: property, maxWidth: self.contentMaxWidth)
                return view
            },
            ascentProvider: { _ in return font.ascender },
            verticalAlign: .middle
        )
        return attachment
    }

    func imageViewRichAttachment(property: Basic_V1_RichTextElement.ImageProperty) -> LKRichAttachment {
        let font = contentTextFont
        if let docIcon = TextDocsViewModel.getDocIconRichAttachment(property: property, font: font, iconColor: iconColor) {
            return docIcon
        }
        let originSize = getPreviewSize(CGSize(width: CGFloat(property.originWidth),
                                               height: CGFloat(property.originHeight)
                                        ))
        let size = ChatImageViewWrapper.calculateSize(originSize: originSize, maxSize: self.imageContentMaxSize, minSize: self.config.imageMinSize)

        let attachment = LKAsyncRichAttachmentImp(
            size: size,
            viewProvider: { [weak self] in
                guard let self = self else { return UIView(frame: .zero) }
                return self.createImageView(property: property, originSize: originSize, size: size)
            },
            ascentProvider: { _ in return font.ascender },
            verticalAlign: .baseline
        )
        return attachment
    }

    func createToolView(property: Basic_V1_RichTextElement.MyAIToolProperty, maxWidth: CGFloat) -> MyAIToolsCotThinkingProcessView {
        if let toolInfo = toolInfoMap[property.toolID] {
            logger.info("text post create tool view use toolItem: \(property.toolID)")
            let toolCotView = MyAIToolsCotThinkingProcessView(toolItem: toolInfo,
                                                              toolStatus: self.processMyAIToolPropertyStatus(property: property),
                                                              userResolver: self.context.userResolver,
                                                              font: contentTextFont,
                                                              textColor: defaultTextColor,
                                                              maxWidth: maxWidth)
            return toolCotView
        } else {
            logger.info("text post create tool view use toolId: \(property.toolID)")
            let toolCotView = MyAIToolsCotThinkingProcessView(
                toolId: property.toolID,
                toolStatus: self.processMyAIToolPropertyStatus(property: property),
                toolName: property.localToolName,
                userResolver: self.context.userResolver,
                font: contentTextFont,
                maxWidth: maxWidth,
                textColor: defaultTextColor
            ) { [weak self] (tooInfo, isRefresh) in
                self?.updateToolInfo(tooInfo, isRefresh: isRefresh)
            }
            return toolCotView
        }
    }

    func updateToolInfo(_ toolInfo: MyAIToolInfo, isRefresh: Bool) {
        logger.info("text post update toolInfo: \(toolInfo)")
        if !toolInfoMap.keys.contains(toolInfo.toolId) {
            toolInfoMap[toolInfo.toolId] = toolInfo
        }
        guard isRefresh else {
            logger.info("not update tool info")
            return
        }
        updateToolElement()
    }

    func updateToolElement() {
        rebuildElement(isOrigin: true)
        rebuildElement(isOrigin: false)
        safeUpdate(animation: .none)
    }

    func processMyAIToolPropertyStatus(property: Basic_V1_RichTextElement.MyAIToolProperty) -> MyAIToolCotState {
        // AI cot会存在超时的case,端上兜底处理如果超过1个小时，强制将cot 状态设置为 success
        let interval = 1000 * 60 * 60
        if let ntpServiceTime = ntpAPI?.getNTPTime(),
            ntpServiceTime - message.createTimeMs > interval,
            case .runing = property.status {
            logger.info("process myAIToolPropertyStatus expired use success")
            return MyAIToolCotState.success
        }
        return MyAIToolCotState.transform(pb: property.status)
    }

    func createImageView(property: Basic_V1_RichTextElement.ImageProperty,
                         originSize: CGSize,
                         size: CGSize) -> ChatImageViewWrapper {
        let imageView = ChatImageViewWrapper(maxSize: self.imageContentMaxSize, minSize: self.config.imageMinSize)
        if !self.imageViewWrappers.contains(imageView) {
            self.imageViewWrappers.add(imageView)
        }

        imageView.imageKey = property.originKey
        imageView.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase // 对齐聊天页面颜色
        imageView.clipsToBounds = true
        if self.config.attacmentImageCornerRadius > 0 {
            imageView.layer.cornerRadius = self.config.attacmentImageCornerRadius
        }

        imageView.layer.ud.setBorderColor(self.config.attacmentImageborderColor)
        imageView.layer.borderWidth = self.config.attacmentImageborderWidth

        let resource: LarkImageResource
        var inline: UIImage?
        if self.dynamicAuthorityEnum.authorityAllowed {
            let imageSet = ImageItemSet.transform(imageProperty: property)
            inline = imageSet.inlinePreview
            if fetchKeyWithCrypto {
                if let cacheItem = ImageDisplayStrategy.messageImage(imageItem: imageSet, scene: .postMessage, originSize: Int(property.originSize)) {
                    resource = cacheItem.imageResource()
                } else {
                    resource = imageSet.getThumbResource()
                }
            } else {
                if let downgradeKey = ImageDisplayStrategy.messageImage(imageItem: imageSet, scene: .postMessage, originSize: Int(property.originSize))?.key {
                    resource = .default(key: downgradeKey)
                } else {
                    resource = .default(key: imageSet.getThumbKey())
                }
            }
        } else {
            resource = .default(key: "")
        }
        self.imageResources.append(resource)
        let metrics: [String: Any] = [
            "message_id": metaModel.message.id,
            "is_message_delete": metaModel.message.isDeleted
        ]
        imageView.set(
            originSize: getPreviewSize(originSize),
            dynamicAuthorityEnum: self.dynamicAuthorityEnum,
            permissionPreview: self.permissionPreview,
            needLoading: true,
            animatedDelegate: nil,
            forceStartIndex: 0,
            forceStartFrame: nil,
            imageTappedCallback: { [weak self] imageView in
                if let imageView = imageView as? ChatImageViewWrapper {
                    self?.imageViewTapped(imageView)
                }
            },
            setImageAction: { (imageView, completion) in
                imageView.bt.setLarkImage(
                    with: resource,
                    placeholder: inline,
                    trackStart: {
                        TrackInfo(biz: .Messenger,
                                  scene: .Chat,
                                  fromType: .post,
                                  metric: metrics
                        )
                    },
                    completion: { result in
                        switch result {
                        case .success(let imageResult):
                            completion(imageResult.image, nil)
                        case .failure(let error):
                            // completion的image是指view上要贴的图
                            // 如果FG开启，请求图片失败，也会贴上inline
                            // 如果FG关闭，请求图片失败，则返回空，接受方拿到空，一般会设置一个裂图
                            completion(inline, error)
                        }
                    }
                )
            },
            downloadFailedLayerProvider: { [weak self] (error) -> UIView? in
                guard let self = self else { return nil }
                return self.customImageDownloadFailedLayer(error: error)
            },
            settingGifLoadConfig: self.settings?.gifLoadConfig
        )
        imageView.frame = CGRect(origin: .zero, size: size)
        if self.isGroupAnnouncement {
            imageView.imageView.contentMode = .scaleAspectFit
            imageView.imageView.adaptiveContentModel = false
        }
        //是否需要透传点击事件
        imageView.isUserInteractionEnabled = !self.isGroupAnnouncement
        return imageView
    }

    func mediaViewRichAttachment(property: Basic_V1_RichTextElement.MediaProperty) -> LKRichAttachment {
        let font = contentTextFont
        let originSize = getPreviewSize(CGSize(width: CGFloat(property.image.thumbnail.width),
                                               height: CGFloat(property.image.thumbnail.height)
                                              ))
        let (size, contentMode) = VideoImageView.calculateSizeAndContentMode(
            originSize: originSize,
            maxSize: self.imageContentMaxSize,
            minSize: self.config.imageMinSize
        )

        return LKAsyncRichAttachmentImp(size: size, viewProvider: { [weak self] in
            guard let self = self else { return UIView(frame: .zero) }
            return self.createMediaView(property: property, size: size, contentMode: contentMode)
        }, ascentProvider: { mode in
            switch mode {
            case .horizontalTB: return size.height
            case .verticalLR, .verticalRL: return size.width
            }
        })
    }

    func createMediaView(property: Basic_V1_RichTextElement.MediaProperty,
                         size: CGSize,
                         contentMode: UIView.ContentMode) -> VideoImageViewWrapper {
        let videoView = VideoImageViewWrapper()
        videoView.handleAuthority(dynamicAuthorityEnum: self.dynamicAuthorityEnum, hasPermissionPreview: videoHasPermissionPreview)
        videoView.status = self.message.localStatus == .success ? .normal : .notWork
        videoView.previewView.contentMode = contentMode
        videoView.setDuration(property.duration)
        let resource: LarkImageResource
        var inline: UIImage?
        if self.dynamicAuthorityEnum.authorityAllowed {
            let imageSet = ImageItemSet.transform(imageSet: property.image)
            inline = imageSet.inlinePreview
            if fetchKeyWithCrypto {
                resource = imageSet.getThumbResource()
            } else {
                let key = imageSet.getThumbKey()
                resource = LarkImageResource.default(key: key)
            }
        } else {
            resource = .default(key: "")
        }
        self.imageResources.append(resource)
        videoView.setVideoPreviewSize(originSize: size, authorityAllowed: self.permissionPreview.0 && self.dynamicAuthorityEnum.authorityAllowed)
        videoView.previewView.bt.setLarkImage(
            with: resource,
            placeholder: inline,
            trackStart: {
                TrackInfo(scene: .Chat, fromType: .media)
            },
            completion: { result in
                switch result {
                case .failure:
                    videoView.previewView.backgroundColor = UIColor.ud.N200
                case .success:
                    break
                }
            }
        )

        videoView.videoKey = property.key
        videoView.backgroundColor = UIColor.clear
        if self.config.attacmentImageCornerRadius > 0 {
            videoView.layer.cornerRadius = self.config.attacmentImageCornerRadius
            videoView.clipsToBounds = true
        }

        videoView.layer.ud.setBorderColor(self.config.attacmentImageborderColor)
        videoView.layer.borderWidth = self.config.attacmentImageborderWidth

        videoView.tapAction = { [weak self] (videoImageViewWrapper, _) in
            self?.mediaImageViewTapped(videoImageViewWrapper)
        }

        videoView.frame = CGRect(origin: .zero, size: size)
        return videoView
    }

    /// 原文最大高度
    func getOriginContentMaxHeight() -> NumbericValue? {
        if isExpand { return .init(.init(.unset)) }
        return .init(.point(foldedHeight))
    }

    /// 译文最大高度
    func getTranslateContentMaxHeight() -> NumbericValue? {
        if translateIsExpand { return .init(.init(.unset)) }
        return .init(.point(foldedHeight))
    }

    func getAtReadUserIDs(isOrigin: Bool) -> [String] {
        let content = isOrigin ? self.originContent : self.translateContent
        let botIDs = content.botIds
        let readAtChatterIDs = message.readAtChatterIds
        guard !readAtChatterIDs.isEmpty, isShowReadStatus else { return [] }
        let readAtUserIDs = readAtChatterIDs.filter({ !botIDs.contains($0) && !context.isMe($0, chat: metaModel.getChat()) && $0 != "all" })
        return readAtUserIDs
    }
}

extension TextPostContentViewModel: LKRichViewDelegate {
    public func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {
        guard cache.checksum.isTiledCacheValid else { return }
        // 原文
        if view.tag == PostViewComponentTag.contentTag {
            self.originTiledCache = cache
        }
        // 译文
        if view.tag == PostViewComponentTag.translateContentTag {
            self.translateTiledCache = cache
        }
    }

    public func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        // 原文
        if view.tag == PostViewComponentTag.contentTag {
            return originTiledCache
        }
        // 译文
        if view.tag == PostViewComponentTag.translateContentTag {
            return translateTiledCache
        }
        return nil
    }

    public func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {
        if contextScene == .pin {
            self.isShowMore = false
            return
        }
        // 原文
        if view.tag == PostViewComponentTag.contentTag {
            self.isShowMore = isContentScroll
        }
        // 译文
        if view.tag == PostViewComponentTag.translateContentTag {
            self.translateIsShowMore = isContentScroll
        }
    }

    /// 判断是否应该保持住选中态，排除当前正在进行左/右滑返回手势：https://meego.feishu.cn/larksuite/issue/detail/14384961
    public func keepVisualModeWhenResignFirstResponder(_ view: LKRichView) -> Bool {
        guard self.keepVisualIfNeeded else { return false }

        var nextResponder: UIResponder = view
        while let next = nextResponder.next {
            // UINavigationController.interactivePopGestureRecognizer生效时，会导致LKRichView的resignFirstResponder触发
            if let navigationController = next as? UINavigationController, let popGestureRecognizer = navigationController.interactivePopGestureRecognizer {
                if popGestureRecognizer.state == .began || popGestureRecognizer.state == .changed {
                    logger.info("keep visual for interactivePopGestureRecognizer, name: \(String(describing: type(of: navigationController.self)))")
                    return true
                }
            }
            // UIScreenEdgePanGestureRecognizer生效时，会导致LKRichView的resignFirstResponder触发
            if let view = next as? UIView, let gestureRecognizers = view.gestureRecognizers, !gestureRecognizers.isEmpty {
                var needKeepVisualMode: Bool = false
                gestureRecognizers.filter({ $0 is UIScreenEdgePanGestureRecognizer }).forEach { screenEdgePanGestureRecognizer in
                    if screenEdgePanGestureRecognizer.state == .began || screenEdgePanGestureRecognizer.state == .changed {
                        needKeepVisualMode = true
                    }
                }
                if needKeepVisualMode {
                    logger.info("keep visual for UIScreenEdgePanGestureRecognizer, name: \(String(describing: type(of: view.self)))")
                    return true
                }
            }
            nextResponder = next
        }
        return false
    }

    public func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = event?.source
    }

    public func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        if targetElement !== event?.source { targetElement = nil }
    }

    public func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard targetElement === event?.source else { return }
        let isOrigin = (view.tag == PostViewComponentTag.contentTag)

        var needPropagation = true
        switch element.tagName.typeID {
        case RichViewAdaptor.Tag.at.typeID: needPropagation = handleTagAtEvent(isOrigin: isOrigin, element: element, event: event)
        case CodeTag.code.typeID: needPropagation = handleCodeEvent(isOrigin: isOrigin, element: element, event: event)
        case RichViewAdaptor.Tag.a.typeID: needPropagation = handleTagAEvent(element: element, event: event)
        default: needPropagation = handleClassNameEvent(isOrigin: isOrigin, view: view, element: element, event: event)
        }
        if !needPropagation {
            event?.stopPropagation()
            targetElement = nil
        }
    }

    public func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = nil
    }

    // MARK: - Event Handler
    /// Return - 事件是否需要继续冒泡
    func handleTagAtEvent(isOrigin: Bool, element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        let content = isOrigin ? self.originContent : self.translateContent
        guard let atElement = content.richText.elements[element.id] else { return true }
        handleAtClick(property: atElement.property.at)
        return false
    }

    /// Return - 事件是否需要继续冒泡
    func handleCodeEvent(isOrigin: Bool, element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        let content = isOrigin ? self.originContent : self.translateContent
        guard let codeElement = content.richText.elements[element.id] else { return true }
        // 如果当前消息正在流式生成中，则代码块不能点击进到详情：详情没有接push，用户体验不好
        if self.metaModel.message.streamStatus == .streamTransport || self.metaModel.message.streamStatus == .streamPrepare { return false }
        context.navigator(type: .present, body: CodeDetailBody(property: codeElement.property.codeBlockV2), params: nil)
        return false
    }

    /// Return - 事件是否需要继续冒泡
    func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        guard let anchor = element as? LKAnchorElement else { return true }
        if anchor.classNames.contains(RichViewAdaptor.ClassName.phoneNumber) {
            handlePhoneNumberClick(phoneNumber: anchor.href ?? anchor.text)
            return false
        } else if let href = anchor.href {
            do {
                let url = try URL.forceCreateURL(string: href)
                handleURLClick(url: url)
            } catch {
                logger.error(logId: "url_parse", "Error: \(error.localizedDescription), SpecURL: \(href)")
            }
            return false
        }
        return true
    }

    /// Return - 事件是否需要继续冒泡
    func handleClassNameEvent(isOrigin: Bool, view: LKRichView, element: LKRichElement, event: LKRichTouchEvent?) -> Bool {
        let content = isOrigin ? self.originContent : self.translateContent
        // 企业词典事件
        if element.classNames.contains(RichViewAdaptor.ClassName.abbreviation) {
            if isOrigin, context.abbreviationEnable,
               let abbreviationInfoWrapper = content.abbreviation?[element.id],
               let inlineBlockElement = element as? LKInlineBlockElement,
               let subElement = inlineBlockElement.subElements[0] as? LKTextElement {
                handleAbbreClick(abbres: abbreviationInfoWrapper, query: subElement.text)
            }
            return false
        }
        // mention事件
        if element.classNames.contains(RichViewAdaptor.ClassName.availableMention) ||
            element.classNames.contains(RichViewAdaptor.ClassName.availableMention) {
            if let mentionElement = content.richText.elements[element.id],
               mentionElement.tag == .mention,
               let entity = message.mentions[mentionElement.property.mention.item.id] {
                handleMentionClick(mention: entity)
            }
            return false
        }
        return true
    }

    func handleAtClick(property: Basic_V1_RichTextElement.AtProperty) {
        // 非匿名用户 & 非艾特全体才有点击事件和跳转
        guard !property.isAnonymous, property.userID != "all" else { return }
        handleAtClick(userID: property.userID)
    }

    func handleAtClick(userID: String) {
        if self.contextScene == .newChat || self.contextScene == .threadChat {
            IMTracker.Chat.Main.Click.Msg.Someone(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        } else if self.contextScene == .threadDetail || self.contextScene == .replyInThread {
            ChannelTracker.TopicDetail.Click.Msg.Someone(self.metaModel.getChat(), self.message)
        }
        let body = PersonCardBody(chatterId: userID,
                                  chatId: message.channel.id,
                                  source: .chat)
        if Display.phone {
            context.navigator(type: .push, body: body, params: nil)
        } else {
            context.navigator(
                type: .present,
                body: body,
                params: NavigatorParams(wrap: LkNavigationController.self, prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                }))
        }
    }

    func handlePhoneNumberClick(phoneNumber: String) {
        context.navigator(type: .open, body: OpenTelBody(number: phoneNumber), params: nil)
    }

    func handleURLClick(url: URL) {
        if let httpUrl = url.lf.toHttpUrl() {
            let userInfo = getOpenLinkUserInfo()
            func pushVC() {
                context.navigator(type: .push, url: httpUrl, params: NavigatorParams(context: userInfo))
            }
            if let myAiPageService = try? context.userResolver.resolve(type: MyAIPageService.self),
               let targetVC = self.context.targetVC {
                myAiPageService.onMessageURLTapped(fromVC: targetVC,
                                                   url: httpUrl,
                                                   context: userInfo) {
                    pushVC()
                }
            } else {
                pushVC()
            }
        }
        // 如果点击的是一个Doc的url
        if self.originContent.docEntity?.elementEntityRef.values.contains(where: { $0.docURL == url.absoluteString }) ?? false {
            if self.contextScene == .newChat || self.contextScene == .threadChat {
                IMTracker.Chat.Main.Click.Msg.Doc(self.metaModel.getChat(), self.message, url, self.context.trackParams[PageContext.TrackKey.sceneKey] as? String)
            } else if self.contextScene == .threadDetail || self.contextScene == .replyInThread {
                ChannelTracker.TopicDetail.Click.Msg.Doc(self.metaModel.getChat(), self.message)
            }
        } else {
            IMTracker.Chat.Main.Click.Msg.URL(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String, url)
        }
        let chat = self.metaModel.getChat()
        self.chatSecurityAuditService?.auditEvent(.clickLink(url: url.absoluteString,
                                                            chatId: chat.id,
                                                            chatType: chat.type),
                                                 isSecretChat: false)
        self.guideService?.triggerGuide(chat.id)
        IMTracker.Chat.Main.Click.Msg.URLPreviewClick(chat, self.message, context.contextScene, url)
    }

    func handleAbbreClick(abbres: AbbreviationInfoWrapper, query: String) {
        logger.info("TextPostContentViewModel: show ner menu",
                     additionalData: ["messageId": message.id,
                                      "chatId": message.chatID])

        var id = AbbreviationV2Processor.getAbbrId(wrapper: abbres, query: query)
        var clientArgs: String?
        /// 自己发送的消息可以编辑百科
        var enableEdit: Bool = context.isMe(message.fromId, chat: metaModel.getChat()) && context.getStaticFeatureGating(.lingoHighlightOnKeyboard)
        let analysisParams: [String: Any] = [
            "card_source": "im_card",
            "message_id": message.id,
            "chat_id": message.chatID
        ]
        let extra: [String: Any] = [
            "spaceId": message.chatID,
            "spaceSubId": message.id,
            "space": SpaceType.IM.rawValue,
            "showPin": enableEdit
        ]
        let params: [String: Any] = [
            "page": LingoPageEnum.LingoCard.rawValue,
            "showIgnore": enableEdit,
            "analysisParams": analysisParams,
            "extra": extra
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: params) {
            clientArgs = String(data: jsonData, encoding: String.Encoding.utf8)
        }
        enterpriseEntityWordService?.showEnterpriseTopicForIM(
            abbrId: id ?? "",
            query: query,
            chatId: self.metaModel.getChat().id,
            msgId: self.metaModel.message.id,
            sense: .messenger,
            targetVC: context.targetVC,
            clientArgs: clientArgs,
            completion: nil,
            passThroughAction: nil
        )
    }

    func handleMentionClick(mention: Basic_V1_HashTagMentionEntity) {
        switch mention.clickAction.actionType {
        case .none:
            break
        case .redirect:
            if let url = URL(string: mention.clickAction.redirectURL) {
                context.navigator(type: .open, url: url, params: nil)
            }
        @unknown default: assertionFailure("unknow type")
        }
    }
}

// MARK: - Inline Tracker
// URL中台Inline渲染耗时
extension TextPostContentViewModel {
    func trackInlineRender() {
        guard isDisplay, inlineRenderNeedTrack else { return }
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            // 埋点上报完成，将inlineRenderNeedTrack置为false，避免锁访问
            self.inlineRenderNeedTrack = !self.inlineRenderTrack.trackRender(contextScene: self.contextScene)
        }
    }

    func trackInlineRender(isOrigin: Bool) {
        guard isOrigin, inlineRenderNeedTrack else { return }
        let endTime = CACurrentMediaTime()
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.inlineRenderTrack.setEndTime(message: self.message, endTime: endTime)
            if self.isDisplay {
                // 埋点上报完成，将inlineRenderNeedTrack置为false，避免锁访问
                self.inlineRenderNeedTrack = !self.inlineRenderTrack.trackRender(contextScene: self.contextScene)
            }
        }
    }
}

// MARK: - MyAI "..."、"|" 效果
private extension TextPostContentViewModel {
    /// 拼接loading标记，目前只需要在newChat场景添加，其他场景不需要，所以没有写到RichViewAdaptor.parseRichTextToRichElement里
    /// prepare中点停止生成，偶现过几次气泡宽度很短，只显示了"已停"两个字，然后没有赞踩，点击气泡也没有出时间，但是时间位置的空白是留出来了的。
    func addOrRemoveLoadingIfNeeded(result: inout LKRichElement) {
        // 这里不用加Scene判断，因为My AI正在生成时无法进行菜单操作，所以不用考虑扩散场景展示出了"..."，换句话说：如果展示了"..."那么都是应该展示的
        // guard self.contextScene == .newChat else { return }
        guard self.message.streamStatus == .streamPrepare else { return }

        let attachmentSize = CGSize(width: MyAILoadingView.size.width, height: self.contentTextFont.lineHeight)
        let attachment = LKAsyncRichAttachmentImp(size: attachmentSize, viewProvider: { [weak self] in
            guard let `self` = self else { return UIView(frame: .zero) }
            // 虽然"..."高度只有8，但是我们外面还是包一层有一行高度的UIView，因为当一个内容都没有时，也可以让"..."撑起一行的高度，进而撑起气泡
            let view = UIView(frame: CGRect(origin: .zero, size: attachmentSize))
            let loadingView = MyAILoadingView.createView(); loadingView.center.y = attachmentSize.height / 2
            view.addSubview(loadingView)
            return view
        // verticalAlign设置啥都无所谓，因为此场景下LKInlineBlockElement的高度和LKAttachmentElement是一样的
        }, verticalAlign: .middle)
        // 这里不需要再对attachmentElement.style赋值，LKAttachmentElement.init时会把attachment.verticalAlign设置到attachmentElement.style上
        let attachmentElement = LKAttachmentElement(style: LKRichStyle().display(.inlineBlock), attachment: attachment)
        self.addElementToLastLine(addElement: attachmentElement, result: &result)
    }

    /// 拼接流式输出标记，目前只需要在newChat场景添加，其他场景不需要，所以没有写到RichViewAdaptor.parseRichTextToRichElement里
    /// QA出现过一次流式中时往上翻历史消息，然后部分其他消息内容不断闪现/消失在屏幕最顶上的消息气泡中，流式完成后恢复正常
    func addOrRemoveStreamingIfNeeded(result: inout LKRichElement, hasLoadingExtension: Bool) {
        // 这里不用加Scene判断，因为My AI正在生成时无法进行菜单操作，所以不用考虑扩散场景展示出了"|"，换句话说：如果展示了"|"那么都是应该展示的
        // guard self.contextScene == .newChat else { return }
        guard self.message.streamStatus == .streamTransport else { return }
        // 如果此时有正在loading的插件，则不展示光标
        guard !hasLoadingExtension else { return }

        /// 8：圆点动画和前面内容的间隔、圆点的大小
        let attachmentSize = CGSize(width: 8.auto() + 8.auto(), height: self.contentTextFont.lineHeight)
        let attachment = LKAsyncRichAttachmentImp(size: attachmentSize, viewProvider: { [weak self] in
            guard let `self` = self else { return UIView(frame: .zero) }
            // 虽然"."高度只有8，但是我们外面还是包一层有一行高度的UIView，因为当一个内容都没有时，也可以让"."撑起一行的高度，进而撑起气泡
            let view = UIView(frame: CGRect(origin: .zero, size: attachmentSize))
            let loadingView = PointAnimationView(frame: CGRect(origin: .zero, size: CGSize(width: 8.auto(), height: 8.auto())))
            loadingView.addAnimation(times: [0, 0.9, 0.91], values: [1.0, 0, 1.0], duration: 0.91)
            loadingView.frame.origin.x = 8.auto(); loadingView.center.y = attachmentSize.height / 2
            view.addSubview(loadingView)
            return view
        // 这里必须设置baseline+ascentProvider，和文字在一行时设置其他对齐方式都会把LineBox撑高
        }, ascentProvider: { [weak self] _ in self?.contentTextFont.ascender ?? 0 }, verticalAlign: .baseline)
        // verticalAlign设置的值会在LKAttachmentElement.init时设置到LKAttachmentElement.style上
        let attachmentElement = LKAttachmentElement(style: LKRichStyle().display(.inlineBlock), attachment: attachment)
        // 如果最内层 & 最后的元素是tool/图片/视频，因为这些元素比较高，光标需要居中对齐
        if var element = result.subElements.last {
            while let lastElement = element.subElements.last { element = lastElement }
            if element.classNames.contains(RichViewAdaptor.ClassName.tool) || element.classNames.contains(RichViewAdaptor.ClassName.attachment) {
                attachmentElement.style.verticalAlign(.middle)
            }
        }
        self.addElementToLastLine(addElement: attachmentElement, result: &result)
    }

    /// 在result的最后一行的最后位置添加一个element
    func addElementToLastLine(addElement: LKRichElement, result: inout LKRichElement) {
        // 这里elements不一定有值，比如是空内容，只有title
        guard var element = result.subElements.last else { result.addChild(addElement); return }

        // 找到最内层 & 最后的元素，再依次递归往父元素添加内容，这样就能保证"..."一定是添加到内容最后了
        while let lastElement = element.subElements.last { element = lastElement }

        // LKRichElement外层是个p标签，所以addElement一定是可以添加进去的
        while let parentElement = element.parent {
            // 如果是代码块则利用代码块本身内容做到流式效果
            if parentElement is LKCodeElement {
                // 最后一行代码末尾添加"|"；代码被包裹在LKBlockElement中，然后每行代码是LKCodeLineElement
                if let blockElement = parentElement.subElements[0] as? LKBlockElement, let lineElement = blockElement.subElements.last as? LKCodeLineElement {
                    let richStyle = LKRichStyle(); richStyle.fontSize(.point(12))
                    lineElement.addChild(LKTextElement(style: richStyle, text: "|"))
                }
                // 去掉末尾的"x行代码 >"；因为目前还没有生成完成；这里不能去掉，因为移动端只能显示7行代码
                /* if let textIndicatorElement = parentElement.subElements.last as? LKTextIndicatorElement {
                    textIndicatorElement.removeFromParent()
                } */
                break
            }
            // 如果是at me，则需要跳过，不然"..."、"|"会被蓝色背景包裹（虽然效果上看着没什么问题，但 @xx是整体返回的,不存在名字流式的情况）
            if parentElement.classNames.contains(RichViewAdaptor.ClassName.atMe) { element = parentElement; continue }

            // 如果遇到addChild失败（1.inline中不能添加block等,2.LKTextElement等不能添加子元素,3...），则继续递归
            let oldCount = parentElement.subElements.count; parentElement.addChild(addElement)
            if oldCount != parentElement.subElements.count { break }
            element = parentElement
        }
    }
}

public class ChatTextPostContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: TextPostContentContext>: TextPostContentViewModel<M, D, C> {

    override var foldedHeight: CGFloat {
        if contextScene == .pin {
            return super.foldedHeight
        }
        return (settings?.messageBubbleFoldConfig.chatFoldedHeightFactor ?? 1) * context.heightWithoutSafeArea
    }

    override var triggerFoldHeight: CGFloat {
        if contextScene == .pin {
            return super.foldedHeight
        }
        return (settings?.messageBubbleFoldConfig.chatFoldingTriggerHeightFactor ?? 1) * context.heightWithoutSafeArea
    }

    override public var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if isGroupAnnouncement {
            var contentConfig = ContentConfig(hasMargin: false,
                                              maskToBounds: true,
                                              supportMutiSelect: true,
                                              hasBorder: true,
                                              threadStyleConfig: threadStyleConfig)
            contentConfig.isCard = true
            return contentConfig
        }
        // 独立卡片无气泡
        if let contentConfig = singlePreviewContentConfig {
            return contentConfig
        }
        return ContentConfig(hasMargin: true,
                             maskToBounds: true,
                             supportMutiSelect: true,
                             threadStyleConfig: threadStyleConfig)
    }

    override func imageViewTapped(_ view: ChatImageViewWrapper) {
        if !self.permissionPreview.0 || !self.dynamicAuthorityEnum.authorityAllowed {
            self.noPermissionImageTappedAction()
            return
        }
        IMTracker.Chat.Main.Click.Msg.Image(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        self.imageOrVideoTapped(visibleThumbnail: view.imageView) { () -> String in
            return view.imageKey ?? ""
        }
    }

    override func mediaImageViewTapped(_ videoImageView: VideoImageViewWrapper) {
        if !self.permissionPreview.0 || !self.dynamicAuthorityEnum.authorityAllowed {
            self.noPermissionVideoTappedAction()
            return
        }
        let chat = self.metaModel.getChat()
        /// 密盾群不支持视频在线播放，需要先下载到本地再播放。这里目前会禁止播放，待视频播放器支持先下载到本地再播放的能力后去掉
        if chat.isPrivateMode, let targetView = self.context.targetVC?.view {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ExclusiveChat_UnableToViewOnMobilePleaseGoToDesktop_Toast, on: targetView)
            return
        }
        IMTracker.Chat.Main.Click.Msg.Media(chat, self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        self.imageOrVideoTapped(visibleThumbnail: videoImageView.previewView) { () -> String in
            return videoImageView.videoKey ?? ""
        }
    }

    private func imageOrVideoTapped(visibleThumbnail: UIImageView?, selectKey: () -> String) {
        let selectKey = selectKey()
        var messages = [Message]()
        if config.supportImageAndVideoFlip {
            let viewModels: [ChatMessageCellViewModel<M, D>] = self.context.filter { _ in true }
            messages = viewModels.map { $0.content.message }
        } else {
            messages = [self.message]
        }
        let chat = self.metaModel.getChat()
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: messages,
            selectedKey: selectKey,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: self.metaModel.getChat()
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else {
            return
        }
        result.assets[index].visibleThumbnail = visibleThumbnail
        let context = self.context
        let extensionButtonType: LKAssetBrowserViewController.ButtonType = .stack(
            config: .init(
                getAllAlbumsBlock: result.assets[index].isVideo
                ? nil : { [weak context, weak self] in
                    if let context = context, let self = self {
                        return context.getChatAlbumDataSourceImpl(chat: self.metaModel.getChat(), isMeSend: context.isMe(_:))
                    }
                    return DefaultAlbumDataSourceImpl()
                }
            )
        )
        let messageId = self.message.id
        var scene: PreviewImagesScene = .chat(chatId: message.channel.id, chatType: metaModel.getChat().type, assetPositionMap: result.assetPositionMap)
        if !config.supportImageAndVideoFlip {
            scene = .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id)
        }
        var body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: scene,
            trackInfo: PreviewImageTrackInfo(scene: .Thread, messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            showSaveToCloud: !chat.enableRestricted(.download) && config.showSaveToCloud,
            canTranslate: !chat.isPrivateMode && context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            canViewInChat: config.supportImageAndVideoViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: extensionButtonType,
            showAddToSticker: !chat.isPrivateMode && !chat.enableRestricted(.download) && config.showAddToSticker
        )
        if visibleThumbnail is BaseImageView {
            body.customTransition = BaseImageViewWrapperTransition()
        }
        /// 进入大图语言界面
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

public final class ThreadTextPostContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: TextPostContentContext>: TextPostContentViewModel<M, D, C> {

    // 是否是无痕删除，默认为 false
    // 由于无痕删除不会整体刷新 metaModel，所以由上层 vm 主动修改该 bool 参数
    public var isNoTraceDeleted: Bool = false

    override var foldedHeight: CGFloat {
        return (settings?.messageBubbleFoldConfig.topicFoldedHeightFactor ?? 1) * context.heightWithoutSafeArea
    }

    override var triggerFoldHeight: CGFloat {
        return (settings?.messageBubbleFoldConfig.topicFoldingTriggerHeightFactor ?? 1) * context.heightWithoutSafeArea
    }

    override func imageViewTapped(_ view: ChatImageViewWrapper) {
        if !self.permissionPreview.0 || !self.dynamicAuthorityEnum.authorityAllowed {
            self.noPermissionImageTappedAction()
            return
        }
        if self.contextScene == .threadChat {
            IMTracker.Chat.Main.Click.Msg.Image(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        } else if self.contextScene == .threadDetail || self.contextScene == .replyInThread {
            ChannelTracker.TopicDetail.Click.Msg.Image(self.metaModel.getChat(), self.message)
        }
        self.imageOrVideoTapped(visibleThumbnail: view.imageView) { () -> String in
            return view.imageKey ?? ""
        }
    }

    override func mediaImageViewTapped(_ videoImageView: VideoImageViewWrapper) {
        if !self.permissionPreview.0 || !self.dynamicAuthorityEnum.authorityAllowed {
            self.noPermissionVideoTappedAction()
            return
        }
        if self.contextScene == .threadChat {
            IMTracker.Chat.Main.Click.Msg.Media(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        } else if self.contextScene == .threadDetail || self.contextScene == .replyInThread {
            ChannelTracker.TopicDetail.Click.Msg.Media(self.metaModel.getChat(), self.message)
        }
        self.imageOrVideoTapped(visibleThumbnail: videoImageView.previewView) { () -> String in
            return videoImageView.videoKey ?? ""
        }
    }

    private func imageOrVideoTapped(visibleThumbnail: UIImageView?, selectKey: () -> String) {
        let selectKey = selectKey()
        var originMergeForwardID: String?
        if contextScene == .threadPostForwardDetail, let pageApi = context.targetVC as? ChatPageAPI {
            originMergeForwardID = pageApi.originMergeForwardId()
        }
        let chat = self.metaModel.getChat()
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: [message],
            selectedKey: selectKey,
            mergeForwardOriginID: originMergeForwardID,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: self.metaModel.getChat()
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else {
            return
        }
        let messageId = self.message.id
        result.assets[index].visibleThumbnail = visibleThumbnail
        result.assets.forEach { $0.isAutoLoadOriginalImage = true }
        let context = self.context
        var body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            showSaveToCloud: false,
            canTranslate: context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil)),
            showAddToSticker: !chat.enableRestricted(.download)
        )
        if visibleThumbnail is BaseImageView {
            body.customTransition = BaseImageViewWrapperTransition()
        }
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }

    public override func customImageDownloadFailedLayer(error: Error) -> UIView? {
        let noTraceDeleteTipEnable = context.getStaticFeatureGating("lark.thread.no_trace_delete.img.opt")
        if noTraceDeleteTipEnable,
           self.isNoTraceDeleted {
            return CustomFailedLayerView(string: BundleI18n.LarkMessageCore.Lark_IM_ThreadDeletedImageGone_Placeholder)
        }
        return nil
    }
}

final class MergeForwardDetailTextPostContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: TextPostContentContext>: TextPostContentViewModel<M, D, C> {

    override var foldedHeight: CGFloat {
        return (settings?.messageBubbleFoldConfig.chatFoldedHeightFactor ?? 1) * context.heightWithoutSafeArea
    }

    override var triggerFoldHeight: CGFloat {
        return (settings?.messageBubbleFoldConfig.chatFoldingTriggerHeightFactor ?? 1) * context.heightWithoutSafeArea
    }

    override public var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if isGroupAnnouncement {
            var contentConfig = ContentConfig(hasMargin: false,
                                              maskToBounds: true,
                                              supportMutiSelect: true,
                                              hasBorder: true,
                                              threadStyleConfig: threadStyleConfig)
            contentConfig.isCard = true
            return contentConfig
        }
        return ContentConfig(hasMargin: true,
                             maskToBounds: true,
                             supportMutiSelect: true,
                             threadStyleConfig: threadStyleConfig)
    }

    override func imageViewTapped(_ view: ChatImageViewWrapper) {
        if !self.permissionPreview.0 || !self.dynamicAuthorityEnum.authorityAllowed {
            self.noPermissionImageTappedAction()
            return
        }
        self.imageOrVideoTapped(visibleThumbnail: view.imageView) { () -> String in
            return view.imageKey ?? ""
        }
    }

    override func mediaImageViewTapped(_ videoImageView: VideoImageViewWrapper) {
        if !self.permissionPreview.0 || !self.dynamicAuthorityEnum.authorityAllowed {
            self.noPermissionVideoTappedAction()
            return
        }
        let chat = self.metaModel.getChat()
        /// 密盾群不支持视频在线播放，需要先下载到本地再播放。这里目前会禁止播放，待视频播放器支持先下载到本地再播放的能力后去掉
        if chat.isPrivateMode, let targetView = self.context.targetVC?.view {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ExclusiveChat_UnableToViewOnMobilePleaseGoToDesktop_Toast, on: targetView)
            return
        }
        self.imageOrVideoTapped(visibleThumbnail: videoImageView.previewView) { () -> String in
            return videoImageView.videoKey ?? ""
        }
    }

    private func imageOrVideoTapped(visibleThumbnail: UIImageView?, selectKey: () -> String) {
        let selectKey = selectKey()
        let viewModels: [MergeForwardMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        let messages = viewModels.map { $0.content.message }
        let chat = self.metaModel.getChat()
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: messages,
            selectedKey: selectKey,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: self.metaModel.getChat()
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else {
            return
        }
        result.assets[index].visibleThumbnail = visibleThumbnail
        let context = self.context
        let messageId = self.message.id
        var body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            showSaveToCloud: !chat.enableRestricted(.download),
            canTranslate: !chat.isPrivateMode && context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil)),
            showAddToSticker: !chat.isPrivateMode && !chat.enableRestricted(.download)
        )
        if visibleThumbnail is BaseImageView {
            body.customTransition = BaseImageViewWrapperTransition()
        }
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

public final class MessageDetailTextPostContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: TextPostContentContext>: TextPostContentViewModel<M, D, C> {

    override var foldedHeight: CGFloat {
        return (settings?.messageBubbleFoldConfig.chatFoldedHeightFactor ?? 1) * context.heightWithoutSafeArea
    }

    override var triggerFoldHeight: CGFloat {
        return (settings?.messageBubbleFoldConfig.chatFoldingTriggerHeightFactor ?? 1) * context.heightWithoutSafeArea
    }

    override func imageViewTapped(_ view: ChatImageViewWrapper) {
        if !self.permissionPreview.0 || !self.dynamicAuthorityEnum.authorityAllowed {
            self.noPermissionImageTappedAction()
            return
        }
        self.imageOrVideoTapped(visibleThumbnail: view.imageView) { () -> String in
            return view.imageKey ?? ""
        }
    }

    override func mediaImageViewTapped(_ videoImageView: VideoImageViewWrapper) {
        if !self.permissionPreview.0 || !self.dynamicAuthorityEnum.authorityAllowed {
            self.noPermissionVideoTappedAction()
            return
        }
        let chat = self.metaModel.getChat()
        /// 密盾群不支持视频在线播放，需要先下载到本地再播放。这里目前会禁止播放，待视频播放器支持先下载到本地再播放的能力后去掉
        if chat.isPrivateMode, let targetView = self.context.targetVC?.view {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ExclusiveChat_UnableToViewOnMobilePleaseGoToDesktop_Toast, on: targetView)
            return
        }
        self.imageOrVideoTapped(visibleThumbnail: videoImageView.previewView) { () -> String in
            return videoImageView.videoKey ?? ""
        }
    }

    private func imageOrVideoTapped(visibleThumbnail: UIImageView?, selectKey: () -> String) {
        let selectKey = selectKey()
        let viewModels: [MessageDetailMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        let messages = viewModels.map { $0.content.message }
        let chat = self.metaModel.getChat()
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: messages,
            selectedKey: selectKey,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: self.metaModel.getChat()
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else {
            return
        }
        result.assets[index].visibleThumbnail = visibleThumbnail
        let context = self.context
        let messageId = self.message.id
        var body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            showSaveToCloud: !chat.enableRestricted(.download),
            canTranslate: !chat.isPrivateMode && context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil)),
            showAddToSticker: !chat.isPrivateMode && !chat.enableRestricted(.download)
        )
        if visibleThumbnail is BaseImageView {
            body.customTransition = BaseImageViewWrapperTransition()
        }
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

extension ChatImageViewWrapper {
    private struct AssociatedKeys {
        static var key = "ChatImageViewWrapper_key"
    }

    // String 类型
    var imageKey: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.key) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

extension VideoImageViewWrapper {
    private struct AssociatedKeys {
        static var key = "VideoImageViewWrapper_key"
    }

    // String 类型
    public var videoKey: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.key) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}
