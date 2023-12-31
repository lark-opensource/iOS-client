//
//  CryptoReplyCompontentBinder.swift
//  LarkMessageCore
//
//  Created by zc09v on 2021/9/26.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel
import RustPB
import LarkCore
import LarkContainer
import TangramService
import RichLabel
import LarkAccountInterface

final class CryptoTextReplyCompontentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: CryptoReplyContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = ReplyComponentProps()
    private lazy var _component: ReplyComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ReplyComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = ReplyComponent<C>(props: props, style: style, context: context)
    }

    private let contentDecoder: CryptoContentDecoder = CryptoContentDecoder()

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CryptoTextReplyComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        let attributedText = NSMutableAttributedString(attributedString: self.getReplyMessageSummerize(vm.message.parentMessage,
                                                                                                       chat: vm.metaModel.getChat(),
                                                                                                       textColor: vm.textColor,
                                                                                                       nameProvider: vm.context.getDisplayName,
                                                                                                       isBurned: vm.context.isBurned(message: vm.message),
                                                                                                       userResolver: vm.context.userResolver))
        attributedText.mutableString.replaceOccurrences(
            of: "\n",
            with: " ",
            options: [],
            range: NSRange(location: 0, length: attributedText.length)
        )
        let lineAttachment = LKAsyncAttachment(
            viewProvider: { [weak vm] in
                guard let vm = vm else { return UIView() }
                let lineView = UIView()
                lineView.backgroundColor = vm.lineColor
                return lineView
            },
            size: CGSize(width: 2, height: UIFont.ud.body2.pointSize)
        )
        lineAttachment.fontDescent = vm.font.descender
        lineAttachment.fontAscent = vm.font.ascender
        lineAttachment.margin.right = 4
        attributedText.insert(
            NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: lineAttachment]
            ),
            at: 0)
        attributedText.addAttributes(
            [.font: vm.font, .foregroundColor: vm.textColor],
            range: NSRange(location: 0, length: attributedText.length)
        )
        props.message = vm.message
        props.attributedText = attributedText
        props.outofRangeText = vm.outOfRangeText
        props.font = vm.font
        props.delegate = vm
        props.textColor = vm.textColor
        props.bgColors = vm.backgroundColors
        _component.props = props
    }

    private func getReplyMessageSummerize(
        _ message: Message?,
        chat: Chat,
        textColor: UIColor,
        nameProvider: @escaping NameProvider,
        isBurned: Bool,
        userResolver: UserResolver) -> NSAttributedString {
        guard let message = message else {
            return NSAttributedString(string: "")
        }
        let paragraphStyle = NSMutableParagraphStyle()
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        let textFont = UIFont.ud.body2
        let attribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: textFont,
            .paragraphStyle: paragraphStyle
        ]
        /// attributeText内容前添加名字
        func addNameAttriubuteString(attributeText: NSAttributedString) -> NSAttributedString {
            guard let fromChatter = message.fromChatter else { return attributeText }
            let nameInfo: String
            if chat.type == .p2P, fromChatter.id != userResolver.userID {
                nameInfo = "\(BundleI18n.LarkMessageCore.Lark_IM_SecureChatUser_Title): "
            } else {
                nameInfo = "\(nameProvider(fromChatter, chat, .reply)): "
            }
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributeText)
            mutableAttributedString.insert(NSAttributedString(string: nameInfo, attributes: attribute), at: 0)
            return mutableAttributedString
        }
        var recallerName = ""
        if let recaller = message.recaller {
            recallerName = nameProvider(recaller, chat, .reply)
        }
        let groupownerName = "@\(recallerName)"
        var messageInfo = ""
        if message.isDeleted {
            messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageAlreadyDeleted
        } else if message.isRecalled {
            messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageIsrecalled
        } else if message.isSecretChatDecryptedFailed {
            messageInfo = BundleI18n.LarkMessageCore.Lark_IM_SecureChat_UnableLoadMessage_Text
        } else if isBurned {
            messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageIsburned
        } else {
            switch message.type {
            case .text:
                guard let textContent = contentDecoder.getRealContent(token: message.cryptoToken) else {
                    return NSAttributedString(string: "")
                }
                // 密聊未接入URL中台
                let textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: textContent.richText, docEntity: textContent.docEntity)
                let customAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: textColor,
                                                                       .font: textFont,
                                                                       MessageInlineViewModel.iconColorKey: textColor,
                                                                       MessageInlineViewModel.tagTypeKey: TagType.normal]
                let parseRichText = textDocsVM.parseRichText(
                    checkIsMe: nil,
                    needNewLine: false,
                    iconColor: textColor,
                    customAttributes: customAttributes
                )
                let attriubuteText = parseRichText.attriubuteText
                attriubuteText.addAttributes(attribute, range: NSRange(location: 0, length: attriubuteText.length))
                return addNameAttriubuteString(attributeText: attriubuteText)
            @unknown default:
                assert(false, "new value")
                break
            }
        }

        let attributeText = NSAttributedString(string: messageInfo, attributes: attribute)
        return addNameAttriubuteString(attributeText: attributeText)
    }
}
