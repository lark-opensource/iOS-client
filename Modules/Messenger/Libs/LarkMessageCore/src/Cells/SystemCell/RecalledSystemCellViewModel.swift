//
//  RecalledSystemCellViewModel.swift
//  LarkMessageCore
//
//  Created by qihongye on 2023/7/18.
//

import Foundation
import RichLabel
import LarkUIKit
import LarkMessengerInterface
import LarkModel
import AsyncComponent
import LarkMessageBase

public protocol RecalledSystemCellContext: ViewModelContext, SystemCellComponentContext {
    var isNewRecallEnable: Bool { get }
    func reedit(_ message: Message)
    func getChatThemeScene() -> ChatThemeScene
    func isMe(_ chatterID: String, chat: Chat) -> Bool
}

/// 必须保证 nameTemplate 与i18n中要替换的一致
private enum RecalledSystemTemplate: String {
    case name = "{{name}}"
    case owner = "{{owner}}"
    case admin = "{{admin}}"
}

open class RecalledSystemCellViewModel<C: RecalledSystemCellContext>: SimilarToSystemCellViewModel<C> {
    /// 样式上跟system一样，因此reuseIdentifier也用一个
    override open var identifier: String {
        return "system"
    }

    open private(set) var metaModel: CellMetaModel
    open var message: Message {
        return metaModel.message
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    private let config: RecallContentConfig
    private var defaultAttributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: chatComponentTheme.systemTextColor
        ]
    }
    weak var recalledMessageActionDelegate: RecalledMessageCellViewModelActionAbility?

    public init(metaModel: CellMetaModel, context: C, config: RecallContentConfig? = nil) {
        self.metaModel = metaModel
        self.config = config ?? RecallContentConfig()
        super.init(context: context, binder: RecalledSystemCellBinder(context: context))
        formatSystemText()
        self.calculateRenderer()
    }

    public func update(metaModel: CellMetaModel) {
        self.metaModel = metaModel
        formatSystemText()
        self.calculateRenderer()
    }

    open func getChatterDisplayName(chatter: Chatter) -> String {
        return chatter.displayName(
            chatId: message.channel.id,
            chatType: .group,
            scene: .groupOwnerRecall
        )
    }

    private func formatSystemText() {
        guard message.isRecalled else {
            assertionFailure()
            return
        }
        self.textLinks = []
        /// 撤回展示优先级：我 > 企业管理员 > 群主 > 群管理员 > 他人
        let recallerID = message.recallerId
        let senderID = message.fromId
        var recallerName: String?
        if let chatter = message.recaller {
            recallerName = getChatterDisplayName(chatter: chatter)
        }
        var senderName: String?
        if let chatter = message.fromChatter {
            senderName = getChatterDisplayName(chatter: chatter)
        }
        let isMyMessageRecalled = context.isMe(message.fromId, chat: metaModel.getChat())
        switch message.recallerIdentity {
        case .owner:
            /// 群主
            chatOwnerRecalled(
                isMyMessageRecalled: isMyMessageRecalled,
                recallerID: recallerID, recallerName: recallerName,
                senderID: senderID, senderName: senderName
            )
        case .administrator:
            /// 管理员
            chatOwnerRecalled(
                isMyMessageRecalled: isMyMessageRecalled,
                recallerID: recallerID, recallerName: recallerName,
                senderID: senderID, senderName: senderName
            )
        case .groupAdmin:
            /// 群管理员
            chatAdminRecalled(
                isMyMessageRecalled: isMyMessageRecalled,
                recallerID: recallerID,
                recallerName: recallerName,
                senderID: senderID,
                senderName: senderName
            )
        case .enterpriseAdministrator:
            /// 企业管理员
            enterpriseAdminRecalled(isMyMessageRecalled: isMyMessageRecalled, senderID: senderID, senderName: senderName)
        case .unknownIdentity:
            /// 别人撤回别人自己的消息 或 我撤回我的消息
            /// 这种情况 recaller就是sender
            ///
            if context.isMe(senderID, chat: metaModel.getChat()) {
                meRecalled()
                return
            }
            otherRecalled(recallerID: senderID, recallerName: senderName)
        @unknown default:
            assert(false, "new value")
            if context.isMe(senderID, chat: metaModel.getChat()) {
                meRecalled()
                return
            }
            otherRecalled(recallerID: senderID, recallerName: senderName)
        }
    }

    private func meRecalled() {
        guard self.config.isShowReedit, message.isReeditable else {
            // 你撤回了一条消息
            self.labelAttrText = NSMutableAttributedString(
                string: BundleI18n.LarkMessageCore.Lark_IM_RecallMessage_SelectICU_Text(noun: "you", name: ""),
                attributes: defaultAttributes
            )
            return
        }
        // 你撤回了一条消息
        self.labelAttrText = NSMutableAttributedString(
            string: BundleI18n.LarkMessageCore.Lark_IM_RecallMessage_SelectICU_Text(noun: "you", name: ""),
            attributes: defaultAttributes
        )
        appendClickableContent(text: BundleI18n.LarkMessageCore.Lark_IM_YouRecallMsgReedit_System_Button) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.context.reedit(self.message)
        }
    }

    private func otherRecalled(recallerID: String, recallerName: String?) {
        guard let recallerName = recallerName, !recallerName.isEmpty else {
            // 此消息已撤回
            self.labelAttrText = NSMutableAttributedString(
                string: BundleI18n.LarkMessageCore.Lark_Legacy_MessageIsrecalled,
                attributes: defaultAttributes
            )
            return
        }
        /// 必须保证 nameTemplate 与要替换的一致，ICU需要用替换后的文案进行查找
        let nsstring = BundleI18n.LarkMessageCore.Lark_IM_RecallMessage_SelectICU_Text(noun: "other", name: RecalledSystemTemplate.name.rawValue) as NSString
        let location = nsstring.range(of: RecalledSystemTemplate.name.rawValue).location
        if location != NSNotFound {
            self.textLinks.append(getChatterNameTextLink(
                chatterID: recallerID,
                range: NSRange(
                    location: location,
                    length: recallerName.utf16.count
                )
            ))
        }
        // {{name}} 撤回了一条消息
        self.labelAttrText = NSMutableAttributedString(
            string: BundleI18n.LarkMessageCore.Lark_IM_RecallMessage_SelectICU_Text(noun: "other", name: recallerName),
            attributes: defaultAttributes
        )
    }

    private func chatOwnerRecalled(isMyMessageRecalled: Bool, recallerID: String, recallerName: String?, senderID: String, senderName: String?) {
        guard let recallerName = recallerName else {
            unknownRecalled()
            return
        }
        /// 撤回我发的消息
        if isMyMessageRecalled {
            /// 必须保证 Template 与要替换的一致
            let nsstring = BundleI18n.LarkMessageCore.__Lark_IM_GroupOwnerRecallMsgFromYou_System_Text as NSString
            let location = nsstring.range(of: RecalledSystemTemplate.owner.rawValue).location
            if location != NSNotFound {
                self.textLinks.append(getChatterNameTextLink(
                    chatterID: recallerID,
                    range: NSRange(
                        location: location,
                        length: recallerName.utf16.count
                    )
                ))
            }
            // 群主 {{owner}} 撤回了你的一条消息
            self.labelAttrText = NSMutableAttributedString(
                string: BundleI18n.LarkMessageCore.Lark_IM_GroupOwnerRecallMsgFromYou_System_Text(owner: recallerName),
                attributes: defaultAttributes
            )
            return
        }
        if let senderName = senderName {
            // 群主 {{owner}} 撤回了 {{name}} 的一条消息
            self.labelAttrText = NSMutableAttributedString(
                string: BundleI18n.LarkMessageCore.Lark_IM_GroupOwnerRecallMsg_System_Text(
                    owner: recallerName, name: senderName
                ),
                attributes: defaultAttributes
            )
            /// 必须保证 Template 与要替换的一致
            var nsstring = BundleI18n.LarkMessageCore.__Lark_IM_GroupOwnerRecallMsg_System_Text as NSString
            var location = nsstring.range(of: RecalledSystemTemplate.owner.rawValue).location
            if location != NSNotFound {
                self.textLinks.append(getChatterNameTextLink(
                    chatterID: recallerID,
                    range: NSRange(
                        location: location,
                        length: recallerName.utf16.count
                    )
                ))
            }
            nsstring = nsstring.replacingOccurrences(of:
                RecalledSystemTemplate.owner.rawValue, with: recallerName
            ) as NSString
            location = nsstring.range(of: RecalledSystemTemplate.name.rawValue).location
            if location != NSNotFound {
                self.textLinks.append(getChatterNameTextLink(
                    chatterID: senderID,
                    range: NSRange(
                        location: location,
                        length: senderName.utf16.count
                    )
                ))
            }
            return
        }
        unknownRecalled()
    }

    private func chatAdminRecalled(isMyMessageRecalled: Bool, recallerID: String, recallerName: String?, senderID: String, senderName: String?) {
        guard let recallerName = recallerName else {
            unknownRecalled()
            return
        }
        /// 撤回我发的消息
        if isMyMessageRecalled {
            let nsstring = BundleI18n.LarkMessageCore.__Lark_IM_GroupAdminRecallMsgFromYou_System_Text as NSString
            /// 必须保证 Template 与要替换的一致
            let location = nsstring.range(of: RecalledSystemTemplate.admin.rawValue).location
            if location != NSNotFound {
                self.textLinks.append(getChatterNameTextLink(
                    chatterID: recallerID,
                    range: NSRange(
                        location: location,
                        length: recallerName.utf16.count
                    )
                ))
            }
            // 群管理员 {{admin}} 撤回了你的一条消息
            self.labelAttrText = NSMutableAttributedString(
                string: BundleI18n.LarkMessageCore.Lark_IM_GroupAdminRecallMsgFromYou_System_Text(admin: recallerName),
                attributes: defaultAttributes
            )
            return
        }
        if let senderName = senderName {
            // 群管理员 {{admin}} 撤回了 {{name}} 的一条消息
            self.labelAttrText = NSMutableAttributedString(
                string: BundleI18n.LarkMessageCore.Lark_IM_GroupAdminRecallMsg_System_Text(admin: recallerName, name: senderName),
                attributes: defaultAttributes
            )
            /// 必须保证 Template 与要替换的一致
            var nsstring = BundleI18n.LarkMessageCore.__Lark_IM_GroupAdminRecallMsg_System_Text as NSString
            var location = nsstring.range(of: RecalledSystemTemplate.admin.rawValue).location
            if location != NSNotFound {
                self.textLinks.append(getChatterNameTextLink(
                    chatterID: recallerID,
                    range: NSRange(
                        location: location,
                        length: recallerName.utf16.count
                    )
                ))
            }
            nsstring = nsstring.replacingOccurrences(of:
                RecalledSystemTemplate.admin.rawValue, with: recallerName
            ) as NSString
            location = nsstring.range(of: RecalledSystemTemplate.name.rawValue).location
            if location != NSNotFound {
                self.textLinks.append(getChatterNameTextLink(
                    chatterID: senderID,
                    range: NSRange(
                        location: location,
                        length: senderName.utf16.count
                    )
                ))
            }
            return
        }
        unknownRecalled()
    }

    private func enterpriseAdminRecalled(isMyMessageRecalled: Bool, senderID: String, senderName: String?) {
        /// 撤回我发的消息
        if isMyMessageRecalled {
            // 企业管理员撤回了你的一条消息
            self.labelAttrText = NSMutableAttributedString(
                string: BundleI18n.LarkMessageCore.Lark_IM_OrgAdminRecallMsgFromYou_System_Text,
                attributes: defaultAttributes
            )
            return
        }
        if let senderName = senderName {
            // 企业管理员撤回了 {{name}} 的一条消息
            self.labelAttrText = NSMutableAttributedString(
                string: BundleI18n.LarkMessageCore.Lark_IM_OrgAdminRecallMsg_System_Text(name: senderName),
                attributes: defaultAttributes
            )
            /// 必须保证 Template 与要替换的一致
            let nsstring = BundleI18n.LarkMessageCore.__Lark_IM_OrgAdminRecallMsg_System_Text as NSString
            let location = nsstring.range(of: RecalledSystemTemplate.name.rawValue).location
            if location != NSNotFound {
                self.textLinks.append(getChatterNameTextLink(
                    chatterID: senderID,
                    range: NSRange(
                        location: location,
                        length: senderName.utf16.count
                    )
                ))
            }
            return
        }
        unknownRecalled()
    }

    private func unknownRecalled() {
        // 此消息已撤回
        self.labelAttrText = NSMutableAttributedString(
            string: BundleI18n.LarkMessageCore.Lark_Legacy_MessageIsrecalled,
            attributes: defaultAttributes
        )
    }

    private func getChatterNameTextLink(chatterID: String, range: NSRange) -> LKTextLink {
        var textLink = LKTextLink(
            range: range, type: .link,
            attributes: nil
        )
        let chatID = metaModel.getChat().id
        textLink.linkTapBlock = { [context] (_, _) in
            let body = PersonCardBody(chatterId: chatterID,
                                      chatId: chatID,
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
        return textLink
    }
}

class RecalledSystemCellBinder<C: RecalledSystemCellContext>: ComponentBinder<C> {
    let props = SystemCellComponent<C>.Props()
    let style = ASComponentStyle()
    var recalledAcntionHandler: RecalledMessageActionHandler<C>?

    lazy var _component: SystemCellComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? RecalledSystemCellViewModel<C> else {
            assertionFailure()
            return
        }
        props.labelAttrText = vm.labelAttrText
        props.textLinks = vm.textLinks
        props.chatComponentTheme = vm.chatComponentTheme
        props.isUserInteractionEnabled = vm.isUserInteractionEnabled
        vm.recalledMessageActionDelegate = recalledAcntionHandler
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        if let context = context {
            self.recalledAcntionHandler = RecalledMessageActionHandler(context: context)
        } else {
            assertionFailure()
        }
        self._component = SystemCellComponent(props: props, style: style, context: context)
    }
}

extension PageContext: RecalledSystemCellContext {

}
