//
//  ChatPinComponentFactory.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/7/20.
//

import Foundation
import LarkModel
import LarkCore
import LarkMessageBase
import LarkMessengerInterface
import RxSwift
import LarkSDKInterface
import LarkFeatureGating
import AsyncComponent
import RichLabel
import LarkUIKit

public final class ChatPinComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .chatPin
    }

    private var pinService: ChatPinPageService? {
        context.pageContainer.resolve(ChatPinPageService.self)
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        guard ChatNewPinConfig.supportPinMessage(chat: metaModel.getChat(), self.context.userResolver.fg),
              let pinService = pinService else { return false }
        switch context.scene {
        case .newChat, .messageDetail, .replyInThread:
            return pinService.getPinInfo(messageId: metaModel.message.id) != nil
        default:
            return false
        }
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ChatPinComponentViewModel(
            chatter: pinService?.getPinInfo(messageId: metaModel.message.id)?.pinChatter,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ChatPinComponentBinder<M, D, C>(context: context)
        )
    }
}

public class ChatPinComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PinComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    public var iconSize: CGSize { CGSize(width: UIFont.ud.caption2.rowHeight,
                                         height: UIFont.ud.caption2.rowHeight) }

    private let chatter: Chatter?

    public init(chatter: Chatter?, metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        self.chatter = chatter
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public override func initialize() {
        self.parse()
    }

    private(set) var attributedText: NSAttributedString = NSAttributedString(string: "")
    private(set) var textLinks: [LKTextLink] = []
    private let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12),
        .foregroundColor: UIColor.ud.T400
    ]

    private func parse() {
        let operatorName = chatter?.displayWithAnotherName ?? ""
        let chat = metaModel.getChat()
        switch chat.type {
        case .p2P:
            if self.context.currentUserID == chat.chatterId {
                self.attributedText = NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_SuperApp_PinnedToYou_Text, attributes: attributes)
                self.textLinks = []
            } else {
                self.parseAttributedText(name: operatorName,
                                         chatterID: chatter?.id ?? "",
                                         template: BundleI18n.LarkMessageCore.__Lark_IM_SuperApp_PinnedToBoth_Text,
                                         replace: { return BundleI18n.LarkMessageCore.Lark_IM_SuperApp_PinnedToBoth_Text($0) })
            }
        case .group, .topicGroup:
            self.parseAttributedText(name: operatorName,
                                     chatterID: chatter?.id ?? "",
                                     template: BundleI18n.LarkMessageCore.__Lark_IM_SuperApp_PinnedToAll_Text,
                                     replace: { return BundleI18n.LarkMessageCore.Lark_IM_SuperApp_PinnedToAll_Text($0) })
        @unknown default:
            assert(false, "new value")
            self.parseAttributedText(name: operatorName,
                                     chatterID: chatter?.id ?? "",
                                     template: BundleI18n.LarkMessageCore.__Lark_IM_SuperApp_PinnedToAll_Text,
                                     replace: { return BundleI18n.LarkMessageCore.Lark_IM_SuperApp_PinnedToAll_Text($0) })
        }
    }

    private func parseAttributedText(name: String, chatterID: String, template: String, replace: (String) -> String) {
        let template = template as NSString
        let startRange = template.range(of: "{{name}}")
        self.attributedText = NSMutableAttributedString(string: replace(name), attributes: attributes)

        if startRange.location == NSNotFound {
            self.textLinks = []
        } else {
            let nameRange = NSRange(location: startRange.location, length: (name as NSString).length)
            var link = LKTextLink(range: nameRange, type: .link)
            link.linkTapBlock = { [weak self] (_, _) in
                self?.jumpProfile(chatterID)
            }
            self.textLinks = [link]
        }
    }

    private func jumpProfile(_ chatterID: String) {
        let body = PersonCardBody(chatterId: chatterID,
                                  chatId: metaModel.getChat().id,
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

    var icon: UIImage {
        return Resources.message_pin
    }
}

final public class ChatPinComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PinComponentViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = IconViewComponentProps()
    private lazy var _component: IconViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: IconViewComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.numberOfLines = 0
        _component = IconViewComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ChatPinComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.iconSize = vm.iconSize
        props.icon = vm.icon
        props.attributedText = vm.attributedText
        props.textLinkList = vm.textLinks
        _component.props = props
        style.marginTop = 4
    }
}
