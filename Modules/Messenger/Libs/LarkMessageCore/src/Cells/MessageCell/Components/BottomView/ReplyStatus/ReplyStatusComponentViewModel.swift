//
//  ReplyStatusComponentViewModel.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/3.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import EENavigator
import LarkMessengerInterface
import LarkReleaseConfig
import EEAtomic
import LarkContainer

private var overseaReplyIcon = StaticColorizeIcon(icon: Resources.reply_quote)
private var replyIcon = StaticColorizeIcon(icon: Resources.reply_quote)

private var defaultOverseaReplyIcon = StaticColorizeIcon(icon: Resources.reply_message)
private var defaultReplyIcon = StaticColorizeIcon(icon: Resources.reply_message_feishu)

public protocol ReplyStatusComponentViewModelContext: ViewModelContext, ColorConfigContext {
    var pageSupportReply: Bool { get }
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterID: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    func getChatThemeScene() -> ChatThemeScene
    func hitABTest(chat: Chat) -> Bool
}

public struct ReplyStatusConfig {
    var replyCanTap: Bool = true
    public init() {}
}

final class ReplyStatusComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ReplyStatusComponentViewModelContext>: MessageSubViewModel<M, D, C> {

    private var replyCount: Int32 {
        return message.replyCount
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene,
                                                           isMe: context.isMe(message.fromId, chat: metaModel.getChat())
        )
    }

    /// The font of "from" text
    public var textFont: UIFont { UIFont.ud.caption1 }

    /// The size of forward icon
    public var iconSize: CGSize { .square(textFont.pointSize) }

    private let hitABTest: Bool
    private var text: String {
        if hitABTest {
            return BundleI18n.LarkMessageCore.Lark_IM_QuotedReply_Test_Desc(num: replyCount)
        } else {
            let defaultText = replyCount > 1
                ? BundleI18n.LarkMessageCore.Lark_Legacy_ChatNumReplyPlural(replyCount)
                : BundleI18n.LarkMessageCore.Lark_Legacy_ChatNumReplySinglular(replyCount)
            return defaultText
        }
    }

    var config: ReplyStatusConfig

    /// 回复icon

    @SafeLazy
    public var icon: UIImage
    // 染色后的icon
    public var colorfulIcon: UIImage {
        let color = chatComponentTheme.replyIconAndTextColor
        return icon.ud.withTintColor(color)
    }

    /// 回复描述
    public var attributeText: NSAttributedString {
        let textColor = chatComponentTheme.replyIconAndTextColor
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(
            [.font: textFont, .foregroundColor: textColor],
            range: NSRange(location: 0, length: attributedText.length)
        )
        return attributedText
    }

    public init(
        metaModel: M,
        metaModelDependency: D,
        context: C,
        binder: ComponentBinder<C>,
        config: ReplyStatusConfig = ReplyStatusConfig(),
        hitABTest: Bool
        ) {
        self.config = config
        let isMe = context.isMe(metaModel.message.fromId, chat: metaModel.getChat())
        let scene = context.getChatThemeScene()
        let theme = ChatComponentThemeManager.getComponentTheme(scene: scene,
                                                                isMe: context.isMe(metaModel.message.fromId, chat: metaModel.getChat()))
        self.hitABTest = hitABTest
        self._icon = SafeLazy {
            let icon: StaticColorizeIcon
            if hitABTest {
                icon = ReleaseConfig.isLark ? overseaReplyIcon : replyIcon
            } else {
                icon = ReleaseConfig.isLark ? defaultOverseaReplyIcon : defaultReplyIcon
            }
            let colorThemeType: Type = isMe ? .mine : .other
            return icon.get(textColor: theme.replyIconAndTextColor, type: colorThemeType)
        }
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public func replyDidTapped() {
        let chat = metaModel.getChat()
        let body = MessageDetailBody(chat: chat,
                                     message: message,
                                     source: .rootMsg,
                                     chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
        context.navigator(type: .push, body: body, params: nil)
        LarkMessageCoreTracker.trackShowMessageDetail(type: .replyCount)
    }
}
