//
//  MergeForwardContentViewModel.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/6/18.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import LarkCore
import Swinject
import LarkSetting
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import TangramService
import RustPB
import LarkUIKit
import LarkContainer

public protocol MergeForwardContentViewModelContext: PageContext {
    var scene: ContextScene { get }
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterId: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    func getSummerize(_ content: MergeForwardContent,
                      fontColor: UIColor,
                      urlPreviewProvider: ((String, [NSAttributedString.Key: Any], Message) -> (NSMutableAttributedString?, String?)?)?) -> NSAttributedString?
    func checkPermissionPreview(chat: Chat, message: Message) -> (Bool, ValidateResult?)
    func checkPreviewAndReceiveAuthority(chat: Chat, message: Message) -> PermissionDisplayState
    func handlerPermissionPreviewOrReceiveError(receiveAuthResult: DynamicAuthorityEnum?,
                                                previewAuthResult: ValidateResult?,
                                                resourceType: SecurityControlResourceType)
    var downloadFileScene: RustPB.Media_V1_DownloadFileScene? { get }
    var translateService: NormalTranslateService? { get }
}

struct MergeForwardConfig {
    let needContentPadding: Bool
}

class MergeForwardContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentViewModelContext>: NewMessageSubViewModel<M, D, C> {
    override public var identifier: String {
        return "mergeForward"
    }

    private var content: MergeForwardContent? {
        return message.content as? MergeForwardContent
    }

    var title: String {
        return self.content?.title ?? ""
    }

    var isMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    var needContentPadding: Bool {
        return (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail) && message.showInThreadModeStyle
    }

    private lazy var threadReplyBubbleOptimize: Bool = {
        return self.context.getStaticFeatureGating("im.message.thread_reply_bubble_optimize")
    }()

    /// 是否需要自己给内容添加border，如果是话题回复，边框颜色有特化，这里自己进行添加，不在上层BubbleViewLayoutComponentd等处统一添加
    var addBorderBySelf: Bool {
        return (context.scene == .newChat || context.scene == .mergeForwardDetail) && (self.threadReplyBubbleOptimize && message.showInThreadModeStyle && !message.displayInThreadMode)
    }

    /// 内容的最大宽度
    var contentMaxWidth: CGFloat {
        if (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail), message.showInThreadModeStyle {
            return self.metaModelDependency.getContentPreferMaxWidth(self.message)
        }
        return metaModelDependency.getContentPreferMaxWidth(message) - 2 * metaModelDependency.contentPadding
    }

    var contentText: NSAttributedString {
        let fontColor = self.context.scene == .pin ? UIColor.ud.N900 : UIColor.ud.textCaption
        guard let content = content else {
            return NSAttributedString(string: "")
        }
        return self.context.getSummerize(
            content,
            fontColor: fontColor,
            urlPreviewProvider: { [weak self] elementID, customAttributes, message in
                guard let self = self else { return nil }
                var attr = customAttributes
                attr[MessageInlineViewModel.iconColorKey] = fontColor
                attr[MessageInlineViewModel.tagTypeKey] = TagType.normal
                let inlinePreviewVM = MessageInlineViewModel()
                // 合并转发看root消息的翻译状态
                let isOrigin = (self.message.displayRule == .noTranslation || self.message.displayRule == .unknownRule)
                var translatedInlines: InlinePreviewEntityBody?
                if !isOrigin {
                    let translateParam = MessageTranslateParameter(message: self.message,
                                                                   source: MessageSource.common(id: self.message.id),
                                                                   chat: self.metaModel.getChat())
                    translatedInlines = self.context.translateService?.getTranslatedInline(translateParam: translateParam)
                }
                return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, translatedInlines: translatedInlines, isOrigin: isOrigin, customAttributes: attr)
            }
        ) ?? NSAttributedString(string: "")
    }

    let config: MergeForwardConfig

    init(metaModel: M,
         metaModelDependency: D,
         context: C,
         config: MergeForwardConfig = MergeForwardConfig(needContentPadding: false)) {
        self.config = config
        let translateParam = MessageTranslateParameter(message: metaModel.message,
                                                       source: MessageSource.common(id: metaModel.message.id),
                                                       chat: metaModel.getChat())
        context.translateService?.translateURLInlines(translateParam: translateParam)
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }

    override func update(metaModel: M, metaModelDependency: D?) {
        let translateParam = MessageTranslateParameter(message: metaModel.message,
                                                       source: MessageSource.common(id: metaModel.message.id),
                                                       chat: metaModel.getChat())
        context.translateService?.translateURLInlines(translateParam: translateParam)
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    override var contentConfig: ContentConfig? {
        return ContentConfig(supportMutiSelect: true, threadStyleConfig: ThreadStyleConfig(addBorderBySelf: self.addBorderBySelf))
    }
}

/// 消息链接化 & 话题转发卡片，上层添加border
class MessageLinkMergeForwardContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentViewModelContext>: MergeForwardContentViewModel<M, D, C> {
    override var needContentPadding: Bool {
        return config.needContentPadding || message.showInThreadModeStyle
    }
    override var addBorderBySelf: Bool {
        return false
    }
    override var contentConfig: ContentConfig? {
        // 上层添加border
        return ContentConfig(maskToBounds: true,
                             supportMutiSelect: true,
                             hasBorder: true,
                             threadStyleConfig: ThreadStyleConfig(addBorderBySelf: self.addBorderBySelf))
    }
}

public final class DefaultMesageSummerizeFactory: MetaModelSummerizeFactory, UserResolverWrapper {
    public let userResolver: UserResolver

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    public override func canHandle(_ metaModel: Message) -> Bool {
        return true
    }

    public func getContentString(message: Message,
                                 fontColor: UIColor,
                                 urlPreviewProvider: URLPreviewProvider? = nil) -> NSAttributedString {
        let iconColor = UIColor.ud.textCaption
        let defautAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.ud.body2,
            .foregroundColor: fontColor
        ]
        var contentStr = NSMutableAttributedString(string: "")

        switch message.type {
        case .text:
            var content: TextContent?
            if message.displayRule == .noTranslation || message.displayRule == .unknownRule {
                content = message.content as? TextContent
            } else {
                content = message.translateContent as? TextContent
            }
            if var content = content {
                let textDocsVM = TextDocsViewModel(
                    userResolver: userResolver,
                    richText: content.richText, docEntity: content.docEntity, hangPoint: message.urlPreviewHangPointMap)
                let parseResult = textDocsVM.parseRichText(
                    isShowReadStatus: false,
                    checkIsMe: { _ in false },
                    maxLines: 1,
                    needNewLine: false,
                    iconColor: iconColor,
                    customAttributes: defautAttributes,
                    urlPreviewProvider: urlPreviewProvider
                )
                // 覆盖richText，适配copy场景
                content.richText = textDocsVM.richText
                contentStr = NSMutableAttributedString(attributedString: parseResult.attriubuteText)
            }
            // 如果有译文，前面需要加上[译]
            if message.displayRule == .onlyTranslation || message.displayRule == .withOriginal {
                contentStr.insert(NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_TranslateInChat, attributes: defautAttributes), at: 0)
            }
        case .post:
            var content: PostContent?
            if message.displayRule == .noTranslation || message.displayRule == .unknownRule {
                content = message.content as? PostContent
            } else {
                content = message.translateContent as? PostContent
            }
            if let content = content {
                // 无标题帖子展示内容
                if content.isUntitledPost {
                    let fixRichText = content.richText.lc.convertText(tags: [.img, .media])
                    let textDocsVM = TextDocsViewModel(
                        userResolver: userResolver,
                        richText: fixRichText, docEntity: content.docEntity, hangPoint: message.urlPreviewHangPointMap)
                    let parseResult = textDocsVM.parseRichText(
                        isShowReadStatus: false,
                        checkIsMe: { _ in false },
                        maxLines: 1,
                        needNewLine: false,
                        iconColor: iconColor,
                        customAttributes: defautAttributes,
                        urlPreviewProvider: urlPreviewProvider
                    )
                    contentStr = NSMutableAttributedString(attributedString: parseResult.attriubuteText)
                } else {
                    contentStr = NSMutableAttributedString(string: content.title, attributes: defautAttributes)
                }
            }
            // 如果有译文，前面需要加上[译]
            if message.displayRule == .onlyTranslation || message.displayRule == .withOriginal {
                contentStr.insert(NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_TranslateInChat, attributes: defautAttributes), at: 0)
            }
        case .image:
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_ImageSummarize, attributes: defautAttributes)
        case .location:
            if let content = message.content as? LocationContent {
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Chat_MessageReplyStatusLocation(content.location.name), attributes: defautAttributes)
            }
        case .sticker:
            //如果是商店表情,则优先展示商店表情的描述
            let stickerContent = message.content as? StickerContent
            if let sticker = stickerContent?.transformToSticker(), sticker.mode == .meme, !sticker.description_p.isEmpty {
                contentStr = NSMutableAttributedString(string: "[" + sticker.description_p + "]", attributes: defautAttributes)
                break
            }
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_StickerHolder, attributes: defautAttributes)
        case .file, .folder:
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_FileHolder, attributes: defautAttributes)
        case .shareUserCard:
            let content = message.content as? ShareUserCardContent
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_PreviewUserCard(content?.chatter?.localizedName ?? ""), attributes: defautAttributes)
        case .shareGroupChat:
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_SharegroupSummarize, attributes: defautAttributes)
        case .mergeForward:
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoMergeforward, attributes: defautAttributes)
            // 如果有译文，前面需要加上[译]
            if message.displayRule == .onlyTranslation || message.displayRule == .withOriginal {
                contentStr.insert(NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_TranslateInChat, attributes: defautAttributes), at: 0)
            }
        case .email, .calendar, .generalCalendar, .unknown, .system, .card, .shareCalendarEvent:
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_UnknownMessageTypeTip(), attributes: defautAttributes)
        case .videoChat:
            if let content = message.content as? VChatMeetingCardContent {
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_View_VideoMeetingInviteLabel + content.topic, attributes: defautAttributes)
            } else {
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_View_VideoMeetingInviteLabel, attributes: defautAttributes)
            }
        case .media:
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_VideoSummarize, attributes: defautAttributes)
        case .audio:
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_AudioHolder, attributes: defautAttributes)
        case .hongbao, .commercializedHongbao:
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_AudioRedPacket, attributes: defautAttributes)
        case .todo:
            // TODO: todo 适配
            contentStr = NSMutableAttributedString(string: "")
        case .vote:
            contentStr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_Poll_PollMessage_Text, attributes: defautAttributes)
        case .diagnose:
            assertionFailure("new value")
            break
        @unknown default:
            assertionFailure("new value")
            break
        }

        return contentStr
    }

    public override func getSummerize(message: Message,
                                      chatterName: String,
                                      fontColor: UIColor,
                                      urlPreviewProvider: URLPreviewProvider? = nil) -> NSAttributedString? {
        let defautAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.ud.body2,
            .foregroundColor: fontColor
        ]

        let attrStr = NSMutableAttributedString(string: chatterName + ": ", attributes: defautAttributes)
        attrStr.append(getContentString(message: message, fontColor: fontColor, urlPreviewProvider: urlPreviewProvider))
        return attrStr
    }
}
