//
//  FoldMessageDetailCellViewModel.swift
//  LarkChat
//
//  Created by liluobin on 2022/9/20.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import LKRichView
import RustPB
import EENavigator
import LarkModel
import LarkMessageCore
import LarkRichTextCore
import TangramService
import LarkMessengerInterface
import LarkContainer

final class FoldMessageDetailCellViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    let entity: Im_V1_MessageFoldFollow
    private weak var targetElement: LKRichElement?
    private let contentTextFont: UIFont = UIFont.systemFont(ofSize: 16)

    lazy var styleSheets: [CSSStyleSheet] = {
        return RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: self.contentTextFont,
                                                                                atColor: self.atColor))
    }()

    let chatter: Chatter?
    let chat: Chat
    private let content: Basic_V1_RichText
    private let message: Message
    private let atColor: AtColor

    var displayName: String {
        guard let chatter = self.chatter else { return "" }
        guard chat.oncallId.isEmpty else { return chatter.name }
        return chatter.displayName(chatId: chat.id, chatType: chat.type, scene: .head)
    }
    let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: RichViewAdaptor.Tag.a)],
        [CSSSelector(value: RichViewAdaptor.Tag.at)]
    ]

    init(userResolver: UserResolver,
         entity: Im_V1_MessageFoldFollow,
         content: Basic_V1_RichText,
         chatter: Chatter?,
         chat: Chat,
         message: Message,
         atColor: AtColor) {
        self.userResolver = userResolver
        self.content = content
        self.entity = entity
        self.chatter = chatter
        self.message = message
        self.chat = chat
        self.atColor = atColor
    }

    func getRichElement() -> LKRichElement {
        let contentElement: LKRichElement
        switch self.entity.recallType {
        case .notRecall:
            let textDocsVMResult = TextDocsViewModel(
                userResolver: userResolver,
                richText: self.content,
                docEntity: nil,
                hangPoint: message.urlPreviewHangPointMap
            )
            let needParserContents = PhoneNumberAndLinkParser.getNeedParserContent(richText: self.content)
            let phoneNumberResult = PhoneNumberAndLinkParser.syncParser(contents: needParserContents, detector: .phoneNumberAndLink)
            contentElement = RichViewAdaptor.parseRichTextToRichElement(richText: textDocsVMResult.richText,
                                                                       isFromMe: false,
                                                                       isShowReadStatus: false,
                                                                       checkIsMe: nil,
                                                                       botIDs: [],
                                                                       readAtUserIDs: [],
                                                                       defaultTextColor: .ud.textTitle,
                                                                       maxLines: 1,
                                                                       abbreviationInfo: nil,
                                                                        mentions: nil,
                                                                        imageAttachmentProvider: nil,
                                                                        mediaAttachmentProvider: nil,
                                                                        urlPreviewProvider: { [weak self] elementID in
                guard let self = self else { return nil }
                let inlinePreviewVM = MessageInlineViewModel()
                return inlinePreviewVM.getNodeSummerizeAndURL(
                    elementID: elementID,
                    message: self.message,
                    font: self.contentTextFont,
                    textColor: UIColor.ud.textLinkNormal,
                    iconColor: UIColor.ud.textLinkNormal,
                    tagType: TagType.link
                )
            },
                                                                        phoneNumberAndLinkProvider: { elementID, _ in
                return phoneNumberResult[elementID] ?? []
            })
        case .enterpriseAdminRecall, .groupAdminRecall, .userRecall, .groupOwnerRecall:
            contentElement = LKTextElement(text: BundleI18n.LarkChat.Lark_IM_StackMessage_MessageRecalled_Text)
            contentElement.style.font(UIFont.systemFont(ofSize: 16)).color(UIColor.ud.textCaption)
        @unknown default:
            assertionFailure("unknown case")
            contentElement = LKTextElement(text: "")
            break
        }
        contentElement.style.maxHeight(.init(.point(22))).textOverflow(.noWrapEllipsis)
        let document = LKBlockElement(tagName: RichViewAdaptor.Tag.p)
        document.children([contentElement])
        return document
    }
}
extension FoldMessageDetailCellViewModel: LKRichViewDelegate {
    public func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {
    }

    public func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        return nil
    }

    public func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {
    }

    public func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = event?.source
    }

    public func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        if targetElement !== event?.source { targetElement = nil }
    }

    public func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = nil
    }

    public func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard targetElement === event?.source else { return }

        var needPropagation = true
        switch element.tagName.typeID {
        case RichViewAdaptor.Tag.at.typeID: needPropagation = handleTagAtEvent(element: element, event: event, view: view)
        case RichViewAdaptor.Tag.a.typeID: needPropagation = handleTagAEvent(element: element, event: event, view: view)
        default: break
        }
        if !needPropagation {
            event?.stopPropagation()
            targetElement = nil
        }
    }

    /// Return - 事件是否需要继续冒泡
    private func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) -> Bool {
        guard let anchor = element as? LKAnchorElement else { return true }
        if anchor.classNames.contains(RichViewAdaptor.ClassName.phoneNumber) {
            handlePhoneNumberClick(phoneNumber: anchor.href ?? anchor.text, view: view)
            return false
        } else if let href = anchor.href, let url = URL(string: href) {
            handleURLClick(url: url, view: view)
            return false
        }
        return true
    }

    // MARK: - Event Handler
    /// Return - 事件是否需要继续冒泡
    func handleTagAtEvent(element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) -> Bool {
        let content = message.foldDetailInfo?.message.content
        guard let atElement = content?.richText.elements[element.id] else { return true }
        return handleAtClick(property: atElement.property.at, view: view)
    }

    private func handleAtClick(property: Basic_V1_RichTextElement.AtProperty, view: LKRichView) -> Bool {
        guard let window = view.window else {
            assertionFailure()
            return true
        }
        let body = PersonCardBody(chatterId: property.userID)
        if Display.phone {
            navigator.push(body: body, from: window)
        } else {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: window,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
        return false
    }

    private func handleURLClick(url: URL, view: LKRichView) {
        guard let window = view.window else {
            assertionFailure()
            return
        }
        if let httpUrl = url.lf.toHttpUrl() {
            navigator.push(httpUrl, context: [
                "from": "collector",
                "scene": "messenger",
                "location": "messenger_foldMessage"
            ], from: window)
        }
    }

    private func handlePhoneNumberClick(phoneNumber: String, view: LKRichView) {
        guard let window = view.window else {
            assertionFailure()
            return
        }
        navigator.open(body: OpenTelBody(number: phoneNumber), from: window)
    }}
