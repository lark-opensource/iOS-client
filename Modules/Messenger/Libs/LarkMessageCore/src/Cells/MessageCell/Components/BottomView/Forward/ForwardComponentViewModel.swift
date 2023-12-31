//
//  AudioForwardComponentViewModel.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/17.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import EENavigator
import LarkCore
import LarkUIKit
import LarkMessengerInterface
import EEAtomic

private var forwardIcon = StaticColorizeIcon(icon: Resources.message_audio_forward)

public protocol ForwardComponentViewModelContext: ViewModelContext, ColorConfigContext {
    var currentTenantId: String { get }
    var enableAdvancedForward: Bool { get }
    func isBurned(message: Message) -> Bool
    func getDisplayName(chatter: Chatter, chat: Chat, scene: GetChatterDisplayNameScene) -> String
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterID: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
}

final class ForwardComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ForwardComponentViewModelContext>: MessageSubViewModel<M, D, C> {

    /// The font of "from" text
    public var textFont: UIFont {
        return UIFont.ud.caption1
    }

    /// The size of forward icon
    public var iconSize: CGSize {
        let fontSize = textFont.pointSize
        return CGSize(width: fontSize, height: fontSize)
    }

    /// Public
    public var attributeText: NSAttributedString {
        let textColor = self.context.getColor(for: .Message_Assitant_Forward_Foreground, type: self.context.isMe(message.fromId, chat: metaModel.getChat()) ? .mine : .other)
        return NSAttributedString(string: text, attributes: [.foregroundColor: textColor, .font: textFont])
    }
    /// 转发icon
    @SafeLazy
    public var icon: UIImage

    /// 转发来自某人，链接
    public var textLinkList: [LKTextLink] {
        let range = (text as NSString).range(of: name)
        guard clickEnable, range.location != NSNotFound else { return [] }
        let nameColor = self.context.getColor(for: .Message_Assitant_Forward_UserName, type: self.context.isMe(message.fromId, chat: metaModel.getChat()) ? .mine : .other)
        var link = LKTextLink(
            range: range,
            type: .link,
            attributes: [.foregroundColor: nameColor],
            activeAttributes: [.foregroundColor: nameColor])
        link.linkTapBlock = { [weak self] (_, _) in
            self?.didClickSender()
        }
        return [link]
    }

    private var sender: Chatter? {
        if message.originalSender != nil {
            return message.originalSender
        }
        if let content = message.content as? AudioContent {
            return content.audioSender
        }
        return nil
    }

    private var isFriend: Bool {
        if message.isForwardFromFriend {
            return true
        }

        if let content = message.content as? AudioContent {
            return content.isFriend
        }

        return false
    }

    private var name: String {
        guard let sender else {
            return ""
        }
        return context.getDisplayName(chatter: sender, chat: metaModel.getChat(), scene: .pin)
    }

    private var senderId: String {
        if !message.originalSenderID.isEmpty {
            return message.originalSenderID
        }
        if let content = message.content as? AudioContent {
            return content.originSenderID
        }
        return ""
    }

    private var clickEnable: Bool {
        guard let sender = sender, !sender.isAnonymous else {
            return false
        }
        return isFriend || sender.tenantId == context.currentTenantId
    }

    private var text: String {
        return BundleI18n.LarkMessageCore.Lark_Chat_MessageForward(name)
    }

    private func didClickSender() {
        guard sender != nil else { return }
        let body = PersonCardBody(chatterId: senderId, chatId: metaModel.getChat().id)
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

    public override init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        let isMe = context.isMe(metaModel.message.fromId, chat: metaModel.getChat())
        self._icon = SafeLazy {
            let colorThemeType: Type = isMe ? .mine : .other
            let iconColor = context.getColor(for: .Message_Assitant_Forward_Icon, type: colorThemeType)
            return forwardIcon.get(textColor: iconColor, type: colorThemeType)
        }
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }
}
