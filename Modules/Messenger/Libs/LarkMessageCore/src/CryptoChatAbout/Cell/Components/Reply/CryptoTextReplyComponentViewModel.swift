//
//  CryptoReplyComponentViewModel.swift
//  LarkMessageCore
//
//  Created by zc09v on 2021/9/26.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RichLabel
import EENavigator
import LarkMessageBase
import ByteWebImage
import LarkMessengerInterface
import LarkSetting
import UniverseDesignColor
import LarkCore
import LarkContainer

public protocol CryptoReplyViewModelContext: ViewModelContext, ColorConfigContext {
    var userResolver: UserResolver { get }
    func isBurned(message: Message) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    func getDisplayName(chatter: Chatter, chat: Chat, scene: GetChatterDisplayNameScene) -> String
}

public final class CryptoTextReplyComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: CryptoReplyViewModelContext>: MessageSubViewModel<M, D, C> {
    let font: UIFont = UIFont.ud.body2

    lazy var outOfRangeText: NSAttributedString = {
        return NSAttributedString(
            string: "\u{2026}",
            attributes: [.font: font, .foregroundColor: textColor]
        )
    }()

    var isMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    public var backgroundColors: [UIColor] {
        if let content = message.content as? CardContent {
            return content.header.backgroundColors
        }
        return []
    }

    /// 文本颜色
    lazy var textColor: UIColor = {
        var key: ColorKey = .Message_Reply_Foreground
        return self.context.getColor(for: key, type: self.isMe ? .mine : .other)
    }()

    /// 竖线颜色
    lazy var lineColor: UIColor = {
        var key: ColorKey = .Message_Reply_SplitLine
        return self.context.getColor(for: key, type: self.isMe ? .mine : .other)
    }()

    private weak var imgView: ByteImageView?

    public override func willDisplay() {
        super.willDisplay()
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
    }
}

// MARK: - ReplyComponentDelegate
extension CryptoTextReplyComponentViewModel: ReplyComponentDelegate {
    public func replyViewTapped(_ replyMessage: Message?) {
        guard let replyMessage = replyMessage else {
            return
        }
        let chat = metaModel.getChat()
        /// 密聊不需要关心topNotice
        let body = MessageDetailBody(chat: chat, message: replyMessage, chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
        context.navigator(type: .push, body: body, params: nil)
        LarkMessageCoreTracker.trackShowMessageDetail(type: .parentMessage)
    }
}
