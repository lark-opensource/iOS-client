//
//  PinComponentViewModel.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/3.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RxSwift

public protocol PinComponentViewModelContext: ViewModelContext {
    func getPinChatterName(chatter: Chatter, chat: Chat) -> String
    func getChatThemeScene() -> ChatThemeScene
    var currentUserID: String { get }
}

final class PinComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PinComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    private var operatorName: String {
        guard let chatter = message.pinChatter else { return "" }
        return context.getPinChatterName(chatter: chatter, chat: metaModel.getChat())
    }

    /// The font of "from" text
    public var textFont: UIFont { UIFont.ud.caption1 }

    /// The size of forward icon
    public var iconSize: CGSize { .square(textFont.pointSize) }

    private var text: String {
        switch metaModel.getChat().type {
        case .p2P:
            return BundleI18n.LarkMessageCore.Lark_Pin_PinDiscriptionInSingleChat(operatorName)
        case .group, .topicGroup:
            return BundleI18n.LarkMessageCore.Lark_Pin_PinDiscriptionInGroup(operatorName)
        @unknown default:
            assert(false, "new value")
            return BundleI18n.LarkMessageCore.Lark_Pin_PinDiscriptionInGroup(operatorName)
        }
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    var icon: UIImage {
        return Resources.message_pin.ud.withTintColor(chatComponentTheme.pinTipColor)
    }

    public var attributeText: NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(
            [
                .font: textFont,
                .foregroundColor: chatComponentTheme.pinTipColor
            ],
            range: NSRange(location: 0, length: attributedText.length)
        )
        return attributedText
    }
}

public class ThreadPinComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PinComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    fileprivate var operatorName: String {
        guard let chatter = message.pinChatter else { return "" }
        return context.getPinChatterName(chatter: chatter, chat: metaModel.getChat())
    }

    public override func shouldUpdate(_ new: Message) -> Bool {
        return self.message.pinChatter?.id != new.pinChatter?.id
    }

    fileprivate var text: String {
        return BundleI18n.LarkMessageCore.Lark_Chat_TopicPinTip(operatorName)
    }

    var icon: UIImage {
        return BundleResources.thread_pin
    }

    public var attributeText: NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(
            [.font: UIFont.ud.caption1,
            .foregroundColor: UDMessageColorTheme.imMessageTextPin],
            range: NSRange(location: 0, length: attributedText.length)
        )
        return attributedText
    }
}

public final class ReplyInThreadPinComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PinComponentViewModelContext>: ThreadPinComponentViewModel<M, D, C> {
    override var text: String {
        switch metaModel.getChat().type {
        case .p2P:
            return BundleI18n.LarkMessageCore.Lark_Pin_PinDiscriptionInSingleChat(operatorName)
        case .group, .topicGroup:
            return BundleI18n.LarkMessageCore.Lark_Pin_PinDiscriptionInGroup(operatorName)
        @unknown default:
            assert(false, "new value")
            return BundleI18n.LarkMessageCore.Lark_Pin_PinDiscriptionInGroup(operatorName)
        }
    }
}
