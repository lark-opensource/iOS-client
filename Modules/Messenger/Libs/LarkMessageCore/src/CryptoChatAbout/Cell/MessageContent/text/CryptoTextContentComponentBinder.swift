//
//  CryptoTextContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by zc09v on 2021/9/10.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import LarkRustClient
import LarkCore
import LarkRichTextCore
import TangramService
import LarkContainer
import RustPB
import LarkModel
import RichLabel
import LarkMessengerInterface
import LarkUIKit
import LKCommonsLogging
import LarkAccountInterface

final public class CryptoTextContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: TextPostContentContext>: ComponentBinder<C> {

    private let contentDecoder: CryptoContentDecoder = CryptoContentDecoder()
    private let contentComponentKey: String = "text_post_content"
    /// 原文style
    private let maskPostStyle = ASComponentStyle()
    /// 原文props
    private lazy var maskPostProps: MaskPostViewComponent<C>.Props = {
        let maskPostProps = MaskPostViewComponent<C>.Props()
        maskPostProps.titleComponentKey = PostViewComponentConstant.titleKey
        maskPostProps.contentComponentKey = PostViewComponentConstant.contentKey
        maskPostProps.contentComponentTag = PostViewComponentTag.contentTag
        return maskPostProps
    }()

    private var updateIsShowMore: ((Bool) -> Void)?

    /// 原文component
    private lazy var postViewComponent: MaskPostViewComponent<C> = {
        return MaskPostViewComponent<C>(props: maskPostProps, style: maskPostStyle)
    }()

    private lazy var _component: ASLayoutComponent<C> = .init(key: "", style: .init(), context: nil, [])
    public override var component: ComponentWithContext<C> {
        return _component
    }

    private var attributeElement: ParseRichTextResult?
    private var context: TextPostContentContext?
    private var metaModel: CellMetaModel?

    private var logger = Logger.log(CryptoTextContentComponentBinder.self, category: "LarkMessage.CryptoChatTextContent")

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? CryptoChatTextContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        self.context = vm.context
        self.metaModel = vm.metaModel
        maskPostStyle.display = .flex
        self.configMaskPost(vm: vm)
        postViewComponent.props = maskPostProps
    }

    private var contentTextFont: UIFont {
        return UIFont.ud.title4
    }

    /// 获取Element
    private func getAttributeElement(vm: CryptoChatTextContentViewModel<M, D, C>, maxLines: Int, maxCharLine: Int, isOrigin: Bool) -> (TextPostContent, ParseRichTextResult)? {
        guard let content = contentDecoder.getRealContent(token: vm.message.cryptoToken) else {
            return nil
        }
        var textPostContent = TextPostContent(
            richText: content.richText,
            isPost: false,
            botIds: content.botIds,
            docEntity: content.docEntity,
            inlineEntities: content.inlinePreviewEntities,
            abbreviation: content.abbreviation,
            typedElementRefs: content.typedElementRefs,
            currentUserId: self.context?.currentUserID ?? "",
            currentTenantId: self.context?.currentTenantId ?? ""
        )

        let paragraph = NSMutableParagraphStyle()
        let font = contentTextFont
        let iconColor = UIColor.ud.textLinkNormal
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.N900,
            .font: font,
            .paragraphStyle: paragraph,
            MessageInlineViewModel.iconColorKey: iconColor,
            MessageInlineViewModel.tagTypeKey: TagType.link
        ]
        var parseResult: ParseRichTextResult

        var atColor = AtColor()
        let isFromMe = vm.isFromMe
        let context = vm.context
        atColor.UnReadRadiusColor = context.getColor(for: .Message_At_UnRead, type: isFromMe ? .mine : .other)
        atColor.MeForegroundColor = context.getColor(for: .Message_At_Foreground_Me, type: isFromMe ? .mine : .other)
        atColor.MeAttributeNameColor = context.getColor(for: .Message_At_Background_Me, type: isFromMe ? .mine : .other)
        atColor.OtherForegroundColor = context.getColor(for: .Message_At_Foreground_InnerGroup, type: isFromMe ? .mine : .other)
        atColor.AllForegroundColor = context.getColor(for: .Message_At_Foreground_All, type: isFromMe ? .mine : .other)
        atColor.OuterForegroundColor = context.getColor(for: .Message_At_Foreground_OutterGroup, type: isFromMe ? .mine : .other)
        atColor.AnonymousForegroundColor = context.getColor(for: .Message_At_Foreground_Anonymous, type: isFromMe ? .mine : .other)
        /// docs替换
        let textDocsVMResult = TextDocsViewModel(
            userResolver: vm.context.userResolver,
            richText: content.richText,
            docEntity: content.docEntity
        )
        textPostContent.richText = textDocsVMResult.richText

        /// 处理richText得到(NSMutableAttributedString, urlRangeMap, atRangeMap, textUrlRangeMap, abbreviarionRangeMap)
        parseResult = textDocsVMResult.parseRichText(
            isFromMe: vm.isFromMe,
            isShowReadStatus: true,
            checkIsMe: vm.context.isMe,
            botIds: content.botIds,
            maxLines: maxLines,
            maxCharLine: maxCharLine,
            atColor: atColor,
            iconColor: iconColor,
            customAttributes: attributes,
            abbreviationInfo: nil,
            mentions: vm.message.mentions
        )
        return (textPostContent, parseResult)
    }

    private func configMaskPost(vm: CryptoChatTextContentViewModel<M, D, C>) {
        guard var result = getAttributeElement(vm: vm,
                                               maxLines: vm.getContentNumberOfLines(),
                                               maxCharLine: vm.getMaxCharCountAtOneLine(),
                                               isOrigin: true) else {
            return
        }
        self.attributeElement = result.1
        let attributeElement = result.1
        let content = result.0

        maskPostProps.contentMaxWidth = vm.contentMaxWidth
        maskPostProps.isShowTitle = false
        maskPostProps.rangeLinkMap = attributeElement.urlRangeMap
        let tapableRanges = attributeElement.atRangeMap.flatMap({ $0.value })
            + attributeElement.abbreviationRangeMap.compactMap({ $0.key })
            + attributeElement.mentionsRangeMap.compactMap({ $0.key })

        maskPostProps.tapableRangeList = tapableRanges

        maskPostProps.textLinkMap = attributeElement.textUrlRangeMap
        maskPostProps.textLinkBlock = { [weak vm] (link) in
            vm?.openURL(link)
        }
        maskPostProps.linkAttributesColor = UIColor.ud.B700
        maskPostProps.activeLinkAttributes = vm.activeLinkAttributes
        maskPostProps.tapHandler = nil
        let attrStr: NSMutableAttributedString = attributeElement.attriubuteText
        updateAtUsersPoint(
            vm: vm,
            attributeStr: attrStr,
            attributeElement: attributeElement,
            readAtChatterIds: vm.message.readAtChatterIds,
            botIds: content.botIds
        )
        maskPostProps.contentAttributedText = attrStr
        maskPostProps.contentLineSpacing = vm.contentLineSpacing
        maskPostProps.numberOfLines = vm.getContentNumberOfLines()
        maskPostProps.delegate = self
        maskPostProps.selectionDelegate = vm.getSelectionLabelDelegate()
        /// maskView属性
        maskPostProps.showMoreHandler = { [weak vm] in
            vm?.showMore()
        }
        /// 背景色
        let topColor = vm.context.getColor(for: .Message_Mask_GradientTop, type: vm.isFromMe ? .mine : .other)
        let bottomColor = vm.context.getColor(for: .Message_Mask_GradientBottom, type: vm.isFromMe ? .mine : .other)
        maskPostProps.backgroundColors = [topColor, bottomColor]
        /// maskView style
        maskPostProps.isShowMore = vm.isShowMore

        maskPostProps.textCheckingDetecotor = vm.textCheckingDetecotor
        self.updateIsShowMore = { [weak vm] isShowMore in
            vm?.isShowMore = isShowMore
        }
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        style.flexDirection = .column

        self._component = ASLayoutComponent<C>(
            key: key ?? contentComponentKey,
            style: style,
            context: context,
            [
                postViewComponent
            ]
        )
    }

    private func updateAtUsersPoint(vm: CryptoChatTextContentViewModel<M, D, C>,
                                    attributeStr: NSMutableAttributedString,
                                    attributeElement: ParseRichTextResult,
                                    readAtChatterIds: [String],
                                    botIds: [String]) {
        let atUserIdRangeMap = attributeElement.atRangeMap
        guard !(atUserIdRangeMap.isEmpty || readAtChatterIds.isEmpty) else {
            return
        }
        let context = vm.context
        let readAtUserIds = readAtChatterIds.filter({ !botIds.contains($0) && !vm.isMe($0) && $0 != "all" })
        let atOtherUserIds = atUserIdRangeMap.keys.filter({ !botIds.contains($0) && !vm.isMe($0) && $0 != "all" })
        for id in atOtherUserIds where readAtUserIds.contains(id) {
            if let ranges = atUserIdRangeMap[id] {
                ranges.forEach { (range) in
                    let pointRange = NSRange(location: range.location + range.length - 1, length: 1)
                    if pointRange.location + pointRange.length <= attributeStr.length {
                        attributeStr.removeAttribute(LKPointAttributeName, range: pointRange)
                        attributeStr.removeAttribute(LKPointInnerRadiusAttributeName, range: pointRange)
                        attributeStr.addAttribute(LKPointAttributeName, value: context.getColor(for: .Message_At_Read, type: .mine), range: pointRange)
                    }
                }
            }
        }
    }
}

extension CryptoTextContentComponentBinder: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        if let httpUrl = url.lf.toHttpUrl() {
            context?.navigator(type: .push, url: httpUrl, params: nil)
        }
    }

    public func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        context?.navigator(type: .open, body: OpenTelBody(number: phoneNumber), params: nil)
    }

    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        guard let context = self.context, let metaModel = self.metaModel, let attributeElement = self.attributeElement else {
            return false
        }
        let atUserIdRangeMap = attributeElement.atRangeMap
        for (userID, ranges) in atUserIdRangeMap where ranges.contains(range) && userID != "all" {
            let body = PersonCardBody(chatterId: userID,
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
            return false
        }
        for (ran, mention) in attributeElement.mentionsRangeMap where ran == range {
            switch mention.clickAction.actionType {
            case .none:
                break
            case .redirect:
                if let url = URL(string: mention.clickAction.redirectURL) {
                    context.navigator(type: .open, url: url, params: nil)
                }
            @unknown default: assertionFailure("unknow type")
            }
            return false
        }
        return true
    }

    public func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {
        self.updateIsShowMore?(isShowMore)
    }
}
