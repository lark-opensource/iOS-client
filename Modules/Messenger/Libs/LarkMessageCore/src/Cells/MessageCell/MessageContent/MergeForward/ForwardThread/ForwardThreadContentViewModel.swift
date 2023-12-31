//
//  ForwardThreadContentViewModel.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/3/29.
//

import Foundation
import RichLabel
import LarkModel
import LarkSetting
import LarkBizAvatar
import AsyncComponent
import LarkMessageBase
import UniverseDesignFont
import ThreadSafeDataStructure

public protocol ForwardThreadViewModelContext: ViewModelContext {
    var scene: ContextScene { get }
    func getRevealReplyInTreadSummerize(message: Message, chat: Chat, textColor: UIColor) -> NSAttributedString
    var currentChatterId: String { get }
    func getStaticFeatureGating(_ key: FeatureGatingManager.Key) -> Bool
}

enum ForwardThreadContentConfig {
    static let contentPadding: CGFloat = 12
    static let cornerRadius: CGFloat = 10
    static var headerAvatarSize: CGFloat {
        return 20.auto()
    }
    static var tripAvatarSize: CGFloat {
        return 16.auto()
    }
}

/// 「转发话题外露回复」需求：话题回复、话题使用一套逻辑 & 使用嵌套UI
final class ForwardThreadContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ForwardThreadViewModelContext>: NewMessageSubViewModel<M, D, C>, ForwardThreadPropsDelegate {
    override public var identifier: String {
        return "forwardThread"
    }

    // 气泡背景、宽度FG，FG开后：话题模式创建的背景为白色，气泡宽度固定为屏幕的宽度；话题回复背景为蓝/灰色，气泡宽度根据内容自适应
    lazy var threadReplyBubbleOptimize: Bool = {
        return self.context.getStaticFeatureGating("im.message.thread_reply_bubble_optimize")
    }()

    // Chat里需要上层添加border，否则reaction等会漏在外面
    var addBorderBySelf: Bool {
        switch context.scene {
        case .newChat:
            // 话题回复优化时为蓝/灰色背景，也需要自己加border
            if message.showInThreadModeStyle, threadReplyBubbleOptimize {
                return true
            }
            return false
        default: return true
        }
    }

    var needPaddingBottom: Bool {
        /// 是否需要底部间距，在Chat内，border是上层添加的，reaction和卡片会包在一起，
        /// 此时需要去掉卡片内的底部padding，因为上层会统一添加
        if !addBorderBySelf, !message.reactions.isEmpty {
            return false
        }
        return true
    }

    override var contentConfig: ContentConfig? {
        let addBorderBySelf = self.addBorderBySelf
        var config = ContentConfig(
            hasMargin: false,
            backgroundStyle: addBorderBySelf ? .clear : .white,
            maskToBounds: !addBorderBySelf,
            supportMutiSelect: true,
            hasBorder: !addBorderBySelf,
            threadStyleConfig: ThreadStyleConfig(addBorderBySelf: addBorderBySelf)
        )
        config.borderStyle = .custom(strokeColor: UIColor.ud.lineBorderCard, backgroundColor: UIColor.ud.bgBody)
        config.isCard = true
        return config
    }

    private let messageEngineFactory: MessageEngineCellViewModelFactory<PageContext>

    init(metaModel: M, metaModelDependency: D, context: C, messageEngineFactory: MessageEngineCellViewModelFactory<PageContext>) {
        self.messageEngineFactory = messageEngineFactory
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }

    /// 此属性用于限制内部最外层话题回复区域的评论最大宽度
    func contentMaxWidth() -> CGFloat {
        return self.metaModelDependency.getContentPreferMaxWidth(message) - 2 * ForwardThreadContentConfig.contentPadding
    }

    // MARK: - ForwardThreadPropsDelegate
    /// 内部是否还是一个话题转发消息
    func subMessageIsForwardThread(_ message: Message) -> Bool {
        // 子消息是合并转发消息
        guard let subMessage = (message.content as? MergeForwardContent)?.messages.first else { return false }
        // 合并转发的是一条话题
        return (subMessage.content as? MergeForwardContent)?.isFromPrivateTopic == true
    }

    /// 发帖人头像、名称
    func senderInfo(_ message: Message) -> (entityID: String, key: String, name: NSAttributedString) {
        guard let content = message.content as? MergeForwardContent,
              let rootMessage = content.messages.first,
              let chatterInfo = content.chatters[rootMessage.fromId] else {
            return ("", "", NSAttributedString(string: ""))
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 24
        paragraph.maximumLineHeight = 24
        paragraph.lineBreakMode = .byWordWrapping
        return (chatterInfo.id, chatterInfo.avatarKey, NSAttributedString(
            string: chatterInfo.name,
            attributes: [.font: UDFont.title3, .foregroundColor: UIColor.ud.textTitle, .paragraphStyle: paragraph])
        )
    }

    func tripInfo(_ message: Message) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 22
        paragraph.maximumLineHeight = 22
        paragraph.lineBreakMode = .byWordWrapping
        let font = UDFont.body2
        let padding: CGFloat = 4
        func stringTrip(_ content: String, _ font: UIFont = font) -> NSAttributedString {
            return NSAttributedString(string: content, attributes: [.font: font, .foregroundColor: UIColor.ud.textCaption, .paragraphStyle: paragraph])
        }
        func avatarTrip(_ entityID: String, _ key: String) -> NSAttributedString {
            let avatarSize = ForwardThreadContentConfig.tripAvatarSize
            let blank = LKAsyncAttachment(viewProvider: {
                let avatar = LarkMedalAvatar(frame: CGRect(origin: .zero, size: CGSize(width: avatarSize, height: avatarSize)))
                avatar.setAvatarByIdentifier(entityID, avatarKey: key, avatarViewParams: .init(sizeType: .size(avatarSize)))
                return avatar
            }, size: CGSize(width: avatarSize, height: avatarSize))
            blank.verticalAlignment = .middle
            blank.fontAscent = font.ascender
            blank.fontDescent = font.descender
            blank.margin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: padding)
            return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [LKAttachmentAttributeName: blank])
        }
        func tripInfoWithGroupName(groupName: NSAttributedString) -> NSAttributedString {
            let palceholder = UUID().uuidString
            let contentString = NSMutableAttributedString(attributedString: stringTrip(BundleI18n.LarkMessageCore.Lark_IM_ForwardCard_TopicPostedInChatName_Text(palceholder)))
            var range = contentString.mutableString.range(of: palceholder)
            if range.length <= 0 {
                assertionFailure("error range")
                return stringTrip(BundleI18n.LarkMessageCore.Lark_IM_ForwardCard_PostedATopicNoGroupName_Text)
            }
            contentString.insert(groupName, at: range.location)
            range = contentString.mutableString.range(of: palceholder)
            if range.length <= 0 {
                assertionFailure("error range")
                return stringTrip(BundleI18n.LarkMessageCore.Lark_IM_ForwardCard_PostedATopicNoGroupName_Text)
            }
            contentString.mutableString.deleteCharacters(in: range)
            return contentString
        }

        // 必须是合并转发消息
        guard let content = message.content as? MergeForwardContent else {
            return stringTrip(BundleI18n.LarkMessageCore.Lark_IM_ForwardCard_PostedATopicNoGroupName_Text)
        }
        // 单聊且有权限
        if ReplyInThreadMergeForwardDataManager.isP2pChatType(content: content),
           ReplyInThreadMergeForwardDataManager.isChatMember(content: content, currentChatterId: self.context.currentChatterId) {
            let groupName = stringTrip(ReplyInThreadMergeForwardDataManager.p2pTitleFor(content: content), UDFont.body1)
            return tripInfoWithGroupName(groupName: groupName)
        }
        // 群成员或公开群，展示 群头像 + 群名
        if ReplyInThreadMergeForwardDataManager.isChatMemberOrPublicChat(content: content, currentChatterId: self.context.currentChatterId) {
            let (entityID, avatarKey) = ReplyInThreadMergeForwardDataManager.avatarOfMemberOrPublic(content: content, currentChatterId: self.context.currentChatterId)
            let groupName = NSMutableAttributedString(attributedString: avatarTrip(entityID, avatarKey))
            groupName.append(stringTrip(ReplyInThreadMergeForwardDataManager.titleOfMemberOrPublic(content: content, currentChatterId: self.context.currentChatterId), UDFont.body1))
            return tripInfoWithGroupName(groupName: groupName)
        }
        // 无权限不展示群名
        return stringTrip(BundleI18n.LarkMessageCore.Lark_IM_ForwardCard_PostedATopicNoGroupName_Text)
    }

    /// 获取根消息的话题回复信息：总数 + 最近5条回复
    func replyInfo(_ message: Message) -> (replyCount: Int32, infos: [RevealReplyInfo]) {
        // 必须是合并转发消息，获取最近的5条回复
        guard let content = message.content as? MergeForwardContent else { return (0, []) }
        var replyMessages = content.messages
        if !replyMessages.isEmpty {
            // -1：除去根消息，剩下的才是话题回复
            replyMessages.removeFirst()
        }
        replyMessages = replyMessages.suffix(5)
        guard !replyMessages.isEmpty else { return (0, []) }

        var replys: [RevealReplyInfo] = []
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 21
        paragraph.maximumLineHeight = 21
        paragraph.lineBreakMode = .byWordWrapping
        replyMessages.forEach { currMessage in
            // 这里预期是有fromChatter的，如果没有则需要看看MergeForwardContent的组装逻辑
            guard let fromChatter = currMessage.fromChatter, let chatterInfo = content.chatters[currMessage.fromId] else {
                assertionFailure("should have from chatter, @yuanping")
                return
            }
            // 回复人名称，SDK处理优先级：备注 > 原名（别名）
            let nameAttri = NSMutableAttributedString(string: "\(chatterInfo.name)")
            nameAttri.addAttributes([.font: UDFont.body1, .foregroundColor: UIColor.ud.textTitle], range: NSRange(location: 0, length: nameAttri.length))
            // 回复内容
            let reply = context.getRevealReplyInTreadSummerize(message: currMessage,
                                                               chat: ReplyInThreadMergeForwardDataManager.getFromChatFor(content: content),
                                                               textColor: UIColor.ud.textCaption)
            let replyAttri = NSMutableAttributedString(attributedString: reply)
            replyAttri.addAttributes([.font: UDFont.body2, .foregroundColor: UIColor.ud.textCaption],
                                     range: NSRange(location: 0, length: replyAttri.length))
            let result = NSMutableAttributedString()
            result.append(nameAttri)
            // 「回复人名称」「回复内容」间距为6
            let blank = LKAsyncAttachment(viewProvider: { UIView(frame: .zero) }, size: .zero)
            blank.verticalAlignment = .middle
            blank.margin = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
            result.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [LKAttachmentAttributeName: blank]))
            result.append(replyAttri)
            result.addAttributes([NSAttributedString.Key.paragraphStyle: paragraph], range: NSRange(location: 0, length: result.length))

            replys.append(RevealReplyInfo(nameAndReply: result, position: currMessage.threadPosition, chatter: fromChatter))
        }

        return (Int32(content.thread?.replyCount ?? 0), replys)
    }

    var engineVM: SafeAtomic<MessageListEngineViewModel<MessageEngineMetaModel, MessageEngineCellMetaModelDependency, PageContext>?> = nil + .readWriteLock
    var engineVMDependency: MessageEngineCellMetaModelDependency?
    func componentRenderer(_ message: Message, contentMaxWidth: CGFloat) -> ASComponentRenderer? {
        let metaModel = MessageEngineMetaModel(message: message, getChat: metaModel.getChat)
        engineVMDependency?.contentPreferMaxWidth = { message in
            return ChatCellUIStaticVariable.getContentPreferMaxWidth(
                message: message,
                maxCellWidth: contentMaxWidth,
                maxContentWidth: contentMaxWidth,
                bubblePadding: 0
            )
        }
        engineVMDependency?.maxCellWidth = { _ in return contentMaxWidth }
        if let engineVM = self.engineVM.value, let metaModelDependency = self.engineVMDependency {
            // 如果messageID变更，则完全替换
            if !engineVM.update(metaModels: [metaModel], metaModelDependency: metaModelDependency) {
                engineVM.reset(metaModels: [metaModel], metaModelDependency: metaModelDependency)
            }
            return engineVM.renderer
        } else {
            let engineVM = MessageListEngineViewModel(
                metaModels: [metaModel],
                metaModelDependency: { [weak self] renderer in
                    let metaModelDependency = MessageEngineCellMetaModelDependency(
                        renderer: renderer,
                        contentPadding: ForwardThreadContentConfig.contentPadding,
                        contentPreferMaxWidth: { message in
                            return ChatCellUIStaticVariable.getContentPreferMaxWidth(
                                message: message,
                                maxCellWidth: contentMaxWidth,
                                maxContentWidth: contentMaxWidth,
                                bubblePadding: 0
                            )
                        },
                        maxCellWidth: { _ in return contentMaxWidth },
                        updateRootComponent: { [weak self] in
                            self?.engineVM.value?.updateRootComponent()
                        },
                        avatarConfig: MessageEngineAvatarConfig(showAvatar: false),
                        headerConfig: MessageEngineHeaderConfig(showHeader: false)
                    )
                    self?.engineVMDependency = metaModelDependency
                    return metaModelDependency
                },
                vmFactory: messageEngineFactory
            )
            self.engineVM.value = engineVM
            return engineVM.renderer
        }
    }

    override func willDisplay() {
        self.engineVM.value?.willDisplay()
        super.willDisplay()
    }

    override func didEndDisplay() {
        self.engineVM.value?.didEndDisplay()
        super.didEndDisplay()
    }

    override func onResize() {
        // 需要先通过super.onResize()触发binder.update()，更新宽度，然后再出发engine的onResize
        super.onResize()
        self.engineVM.value?.onResize()
    }
}
