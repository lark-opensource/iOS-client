//
//  RevealReplyInTreadComponentViewModel.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/9/30.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkCore
import LarkModel
import EENavigator
import LarkSetting
import LarkMessengerInterface
import LarkNavigator
import LarkUIKit
import RichLabel
import ThreadSafeDataStructure

public protocol RevealReplyInTreadViewModelContext: ViewModelContext {
    func getRevealReplyInTreadSummerize(message: Message, chat: Chat, textColor: UIColor) -> NSAttributedString
    var contextScene: ContextScene { get }
    func getStaticFeatureGating(_ key: FeatureGatingManager.Key) -> Bool
}

final class RevealReplyInTreadComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: RevealReplyInTreadViewModelContext>: NewMessageSubViewModel<M, D, C> {
    private(set) var replyInfos = [RevealReplyInfo]() + .readWriteLock
    let outOfRangeText: NSAttributedString = NSMutableAttributedString(string: "\u{2026}",
                                                                       attributes: [
                                                                        .font: UIFont.systemFont(ofSize: 14),
                                                                        .foregroundColor: UIColor.ud.textCaption
                                                                       ])
    public override init(metaModel: M, metaModelDependency: D, context: C) {
        Self.generatorReplyInfos(replys: self.replyInfos, context: context, message: metaModel.message, chat: metaModel.getChat())
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        Self.generatorReplyInfos(replys: self.replyInfos, context: context, message: metaModel.message, chat: metaModel.getChat())
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    var totalReplyCount: Int32 {
        return self.message.replyInThreadCount
    }

    private lazy var threadReplyBubbleOptimize: Bool = {
        return self.context.getStaticFeatureGating("im.message.thread_reply_bubble_optimize")
    }()

    var useLightColor: Bool {
        if self.message.displayInThreadMode {
            return true
        }
        // 如果是话题回复，没有FG，则使用话题模式一样的颜色
        if !self.threadReplyBubbleOptimize, (self.message.showInThreadModeStyle && !self.message.displayInThreadMode) {
            return true
        }
        return false
    }

    private static func generatorReplyInfos(replys: SafeArray<RevealReplyInfo>,
                                            context: RevealReplyInTreadViewModelContext,
                                            message: Message,
                                            chat: Chat) {
        replys.removeAll()
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = 21
        paragraph.maximumLineHeight = 21
        paragraph.lineBreakMode = .byWordWrapping
        let result = message.replyInThreadLastReplies.compactMap({ message in
            if let fromChatter = message.fromChatter {
                let name = fromChatter.displayName(chatId: message.channel.id, chatType: .group, scene: .head)
                let nameAttri = NSMutableAttributedString(string: "\(name)")
                nameAttri.addAttributes(
                    [
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                        .foregroundColor: UIColor.ud.textTitle
                    ],
                    range: NSRange(location: 0, length: nameAttri.length)
                )

                let reply = context.getRevealReplyInTreadSummerize(message: message,
                                                                   chat: chat,
                                                                   textColor: UIColor.ud.textCaption)
                let replyAttri = NSMutableAttributedString(attributedString: reply)
                replyAttri.addAttributes(
                    [
                        .font: UIFont.systemFont(ofSize: 14),
                        .foregroundColor: UIColor.ud.textCaption
                    ],
                    range: NSRange(location: 0, length: replyAttri.length)
                )
                let result = NSMutableAttributedString()
                result.append(nameAttri)
                let blank = LKAsyncAttachment(viewProvider: { UIView(frame: .zero) }, size: .zero)
                blank.verticalAlignment = .middle
                blank.margin = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
                result.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                                 attributes: [LKAttachmentAttributeName: blank]))
                result.append(replyAttri)
                result.addAttributes([NSAttributedString.Key.paragraphStyle: paragraph], range: NSRange(location: 0, length: result.length))

                return RevealReplyInfo(nameAndReply: result, position: message.threadPosition, chatter: fromChatter)
            }
            return nil
        })
        replys.append(contentsOf: result)
    }
}
