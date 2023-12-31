//
//  InlinePreviewViewModel.swift
//  LarkCore
//
//  Created by 袁平 on 2021/6/7.
//

import UIKit
import Foundation
import TangramService
import RustPB
import ByteWebImage
import RxSwift
import LarkModel
import Swinject
import RichLabel
import UniverseDesignColor
import LarkContainer
import LKCommonsTracker
import EditTextView
import EEAtomic
import LKRichView
import UniverseDesignTheme
import LarkRichTextCore
import LarkBaseKeyboard

public extension MessageInlineViewModel {
    static let iconColorKey = NSAttributedString.Key("inline.iconColor")
    static let tagTypeKey = NSAttributedString.Key("inline.tagType")
}

public final class MessageInlineViewModel {
    public typealias RefreshTask = (_ push: URLPreviewPush) -> Void
    private let inlinePreviewService: InlinePreviewService
    public var refreshTask: RefreshTask?

    public init() {
        inlinePreviewService = InlinePreviewService()
    }

    /// 由调用方决定是否接 Push 更新
    public func subscribePush(refreshTask: RefreshTask? = nil) {
        self.refreshTask = refreshTask
        inlinePreviewService.subscribePush(ability: self)
    }

    /// 合并转发的消息需要递归取 inline
    public func getInlinePreviewBody(message: Message, pair: InlinePreviewEntityPair) -> InlinePreviewEntityBody? {
        if message.type == .text || message.type == .post {
            return pair.inlinePreviewEntities[message.id]
        } else if message.type == .mergeForward, let content = message.content as? MergeForwardContent {
            var inlines = InlinePreviewEntityBody()
            let bodys = content.messages.compactMap({ getInlinePreviewBody(message: $0, pair: pair) })
            bodys.forEach({ inlines += $0 })
            return inlines.isEmpty ? nil : inlines
        }
        return nil
    }

    /// 对于合并转发消息，只取第一层的 hangPoint
    public func getMessagePreviewPair(messages: [Message]) -> [String: Im_V1_GetMessagePreviewsRequest.PreviewPair] {
        var pairMap = [String: Im_V1_GetMessagePreviewsRequest.PreviewPair]()
        var messages = messages
        while !messages.isEmpty {
            if let message = messages.popLast() {
                if message.type == .mergeForward, let content = message.content as? MergeForwardContent {
                    messages.append(contentsOf: content.messages)
                    continue
                }
                if !message.urlPreviewHangPointMap.isEmpty {
                    // 合并转发会重新生成 previewID，会导致 sourceID 相同，previewID 不同
                    var pair = pairMap[message.id] ?? Im_V1_GetMessagePreviewsRequest.PreviewPair()
                    let previewIDs = message.urlPreviewHangPointMap.map({ $0.value.previewID })
                    pair.previewIds.append(contentsOf: previewIDs)
                    pairMap[message.id] = pair
                }
            }
        }
        return pairMap
    }

    /// sync body to message
    @discardableResult
    public func update(message: Message, body: InlinePreviewEntityBody) -> Bool {
        var needUpdate = false
        if message.type == .post, var content = message.content as? PostContent {
            content.inlinePreviewEntities += body
            message.content = content
            needUpdate = !body.isEmpty
        } else if message.type == .text, var content = message.content as? TextContent {
            content.inlinePreviewEntities += body
            message.content = content
            needUpdate = !body.isEmpty
        } else if message.type == .mergeForward, let content = message.content as? MergeForwardContent {
            content.messages.forEach { subMessage in
                if update(message: subMessage, body: body) {
                    needUpdate = true
                }
            }
        }
        return needUpdate
    }

    /// 返回 needLoadIDs 中包含 message.id 的 sourceID，当 message 是合并转发消息时，需要递归查找
    public func getNeedLoadIDs(message: Message, needLoadIDs: [String: Im_V1_PushMessagePreviewsRequest.PreviewPair]) -> [String] {
        guard !needLoadIDs.isEmpty else { return [] }
        let messageIDs = getAllMessageIDs(message: message)
        return messageIDs.filter({ needLoadIDs[$0] != nil })
    }

    /// 获取合并转发内层消息的所有 ID
    private func getAllMessageIDs(message: Message) -> [String] {
        if message.type == .mergeForward, let content = message.content as? MergeForwardContent {
            var messageIDs = [message.id]
            content.messages.forEach { subMessage in
                messageIDs.append(contentsOf: getAllMessageIDs(message: subMessage))
            }
            return messageIDs
        }
        if let parentMessage = message.parentMessage {
            return [parentMessage.id, message.id]
        }
        return [message.id]
    }

    public func getTitleAttr(entity: InlinePreviewEntity, customAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        if let title = entity.title, !title.isEmpty {
            return NSAttributedString(string: title, attributes: customAttributes)
        }
        return nil
    }

    public func getImageAttr(entity: InlinePreviewEntity, customAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        guard inlinePreviewService.hasIcon(entity: entity) else { return nil }
        let font = customAttributes[.font] as? UIFont ?? UIFont.ud.body0
        let iconColor = (customAttributes[Self.iconColorKey] as? UIColor) ?? customAttributes[.foregroundColor] as? UIColor
        let inlineService = inlinePreviewService
        let attachMent = LKAsyncAttachment(viewProvider: {
            return inlineService.iconView(entity: entity, iconColor: iconColor)
        }, size: CGSize(width: font.pointSize, height: font.pointSize * 0.95))
        attachMent.fontAscent = font.ascender
        attachMent.fontDescent = font.descender
        attachMent.margin = UIEdgeInsets(top: 1, left: 2, bottom: 0, right: 4)
        return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                  attributes: [LKAttachmentAttributeName: attachMent])
    }

    public func getTagAttr(entity: InlinePreviewEntity, customAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        guard inlinePreviewService.hasTag(entity: entity) else { return nil }
        let tag = entity.tag ?? ""
        let tagType = customAttributes[MessageInlineViewModel.tagTypeKey] as? TagType ?? .link
        let font = customAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 10)
        let inlineService = inlinePreviewService
        let attachMent = LKAsyncAttachment(viewProvider: {
            let tagView = inlineService.tagView(text: tag, titleFont: font, type: tagType)
            return tagView ?? UIView()
        }, size: inlinePreviewService.tagViewSize(text: tag, titleFont: font))
        attachMent.fontAscent = font.ascender
        attachMent.fontDescent = font.descender
        attachMent.margin = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 2)
        return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                  attributes: [LKAttachmentAttributeName: attachMent])
    }

    public func getSummerizeAttr(entity: InlinePreviewEntity, customAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString? {
        let titleAttr = getTitleAttr(entity: entity, customAttributes: customAttributes)
        let imageAttr = getImageAttr(entity: entity, customAttributes: customAttributes)
        let tagAttr = getTagAttr(entity: entity, customAttributes: customAttributes)
        // 没有 title 时，展示原链接
        if titleAttr == nil { return nil }
        let summerize = NSMutableAttributedString()
        if let imageAttr = imageAttr {
            summerize.append(imageAttr)
        }
        if let titleAttr = titleAttr {
            summerize.append(titleAttr)
        }
        if let tagAttr = tagAttr {
            summerize.append(tagAttr)
        }
        return summerize
    }

    public func getSummerizeAttrAndURL(elementID: String,
                                       message: Message,
                                       customAttributes: [NSAttributedString.Key: Any] = [:]) -> (NSMutableAttributedString?, String?)? {
        return getSummerizeAttrAndURL(elementID: elementID,
                                      message: message,
                                      translatedInlines: nil,
                                      isOrigin: true, // 默认原文
                                      customAttributes: customAttributes)
    }

    // 当是译文时（isOrigin = false），会使用外部传入的 translatedInlines
    public func getSummerizeAttrAndURL(elementID: String,
                                       message: Message,
                                       translatedInlines: InlinePreviewEntityBody?,
                                       isOrigin: Bool, // 是否原文，默认原文
                                       customAttributes: [NSAttributedString.Key: Any] = [:]) -> (NSMutableAttributedString?, String?)? {
        guard let entity = getEntity(elementID: elementID, message: message, translatedInlines: translatedInlines, isOrigin: isOrigin) else { return nil }
        let attr = getSummerizeAttr(entity: entity, customAttributes: customAttributes)
        return (attr, entity.url?.tcURL)
    }

    public func getEntity(elementID: String,
                          message: Message,
                          translatedInlines: InlinePreviewEntityBody? = nil,
                          isOrigin: Bool = true) -> InlinePreviewEntity? {
        let hangPoint = message.urlPreviewHangPointMap
        if let point = hangPoint[elementID] {
            // 三端对齐，无译文 Inline 时用原文 Inline 兜底
            if !isOrigin, let inline = translatedInlines?[point.previewID] {
                return inline
            }
            let inlines = Self.getInlinePreviewBody(message: message)
            return inlines[point.previewID]
        }
        return nil
    }

    /// 复制时，需要将图片，Tag 处理成" "
    public func getCopySummerizeAttr(elementID: String, message: Message, isOrigin: Bool) -> NSMutableAttributedString? {
        guard let entity = getEntity(elementID: elementID, message: message, isOrigin: isOrigin) else { return nil }
        let titleAttr = getTitleAttr(entity: entity, customAttributes: [:])
        let hasIcon = inlinePreviewService.hasIcon(entity: entity)
        let hasTag = inlinePreviewService.hasTag(entity: entity)
        if titleAttr == nil { return nil }
        let summerize = NSMutableAttributedString()
        if hasIcon {
            summerize.append(NSAttributedString(string: " "))
        }
        if let titleAttr = titleAttr {
            summerize.append(titleAttr)
        }
        if hasTag {
            summerize.append(NSAttributedString(string: " "))
        }
        return summerize
    }

    public func copy(elementID: String, message: Message, subString: String, originURL: String?) -> String {
        let defaultCopy = originURL ?? subString
        guard let entity = getEntity(elementID: elementID, message: message) else { return defaultCopy }
        var length = entity.title?.count ?? 0
        if inlinePreviewService.hasIcon(entity: entity) {
            length += 1
        }
        if inlinePreviewService.hasTag(entity: entity) {
            length += 1
        }
        if length == subString.count {
            return defaultCopy
        }
        return subString
    }
}

extension MessageInlineViewModel: InlinePreviewServiceAbility {
    public func update(push: URLPreviewPush) {
        refreshTask?(push)
    }
}

extension MessageInlineViewModel {

    public static func pasteAnchorInlineProcessProvider(message: Message,
                                                        anchor: Basic_V1_RichTextElement.AnchorProperty,
                                                        elementId: String?,
                                                        fontInfo: ([String: String], UIFont)) -> NSAttributedString {
        var entities: [String: InlinePreviewEntity] = [:]
        if message.type == .text, let content = message.content as? TextContent {
            entities = content.inlinePreviewEntities
        } else if message.type == .post, let content = message.content as? PostContent {
            entities = content.inlinePreviewEntities
        }

        if entities.isEmpty {
            return AnchorTransformer.transformToURLAttributedString(anchor: anchor, style: fontInfo.0, attributes: [.font: fontInfo.1])
        }

        let hangPoint = message.urlPreviewHangPointMap
        let urlStr = anchor.hasTextContent ? anchor.textContent : anchor.content
        if let point = hangPoint[elementId ?? ""],
           let entity = entities[point.previewID],
           let url = URL(string: urlStr),
           !(entity.title?.isEmpty ?? true) {
            let attr = LinkTransformer.transformToURLAttr(entity: entity,
                                                          originURL: url,
                                                          style: fontInfo.0,
                                                          attributes: [.font: fontInfo.1])
            return attr
        }
        return AnchorTransformer.transformToURLAttributedString(anchor: anchor, style: fontInfo.0, attributes: [.font: fontInfo.1])
    }

    public static func urlInlineProcessProvider(message: Message, attributes: [NSAttributedString.Key: Any]) -> ElementProcessProvider {
        if TextViewCustomPasteConfig.useNewPasteFG {
            return self.urlInlineProcessProviderSupportAnchor(message: message, attributes: attributes)
        } else {
            return self.urlInlineProcessProviderNotSupportAnchot(message: message, attributes: attributes)
        }
    }

    public static func urlInlineProcessProviderNotSupportAnchot(message: Message, attributes: [NSAttributedString.Key: Any]) -> ElementProcessProvider {
        var entities: [String: InlinePreviewEntity] = [:]
        if message.type == .text, let content = message.content as? TextContent {
            entities = content.inlinePreviewEntities
        } else if message.type == .post, let content = message.content as? PostContent {
            entities = content.inlinePreviewEntities
        }
        if entities.isEmpty {
            let anchorProcess: RichTextElementProcess = { option -> [NSAttributedString] in
                let anchor = option.element.property.anchor
                if anchor.isCustom {
                    return [AnchorTransformer.transformToURLAttributedString(anchor: anchor,
                                                                             style: [:], attributes: attributes)]
                }
                return [NSAttributedString(string: anchor.content, attributes: attributes)]
            }
            return [.a: anchorProcess]
        }

        let anchorProcess: RichTextElementProcess = { option -> [NSAttributedString] in
            let hangPoint = message.urlPreviewHangPointMap
            let anchor = option.element.property.anchor
            let urlStr = anchor.hasTextContent ? anchor.textContent : anchor.content
            if let point = hangPoint[option.elementId],
               let entity = entities[point.previewID],
               let url = URL(string: urlStr),
               !(entity.title?.isEmpty ?? true) {
                let attr = LinkTransformer.transformToURLAttr(entity: entity,
                                                              originURL: url,
                                                              attributes: attributes)
                return [attr]
            }
            if anchor.isCustom {
                return [AnchorTransformer.transformToURLAttributedString(anchor: anchor, style: [:], attributes: attributes)]
            }
            return [NSAttributedString(string: anchor.content, attributes: attributes)]
        }
        return [.a: anchorProcess]
    }

    public static func urlInlineProcessProviderSupportAnchor(message: Message, attributes: [NSAttributedString.Key: Any]) -> ElementProcessProvider {
        var entities: [String: InlinePreviewEntity] = [:]
        if message.type == .text, let content = message.content as? TextContent {
            entities = content.inlinePreviewEntities
        } else if message.type == .post, let content = message.content as? PostContent {
            entities = content.inlinePreviewEntities
        }
        if entities.isEmpty {
            let anchorProcess: RichTextElementProcess = { option -> [NSAttributedString] in
                let anchor = option.element.property.anchor
                return [AnchorTransformer.transformToURLAttributedString(anchor: anchor,
                                                                         style: option.element.style,
                                                                         attributes: attributes)]
            }
            return [.a: anchorProcess]
        }

        let anchorProcess: RichTextElementProcess = { option -> [NSAttributedString] in
            let hangPoint = message.urlPreviewHangPointMap
            let anchor = option.element.property.anchor
            let urlStr = anchor.hasTextContent ? anchor.textContent : anchor.content
            if let point = hangPoint[option.elementId],
               let entity = entities[point.previewID],
               let url = URL(string: urlStr),
               !(entity.title?.isEmpty ?? true) {
                let attr = LinkTransformer.transformToURLAttr(entity: entity,
                                                              originURL: url,
                                                              style: option.element.style,
                                                              attributes: attributes)
                return [attr]
            }
            return [AnchorTransformer.transformToURLAttributedString(anchor: anchor,
                                                                     style: option.element.style,
                                                                     attributes: attributes)]
        }
        return [.a: anchorProcess]
    }
}

// MARK: - NewRichComponent
extension MessageInlineViewModel {
    // swiftlint:disable large_tuple
    public func getNodeSummerizeAndURL(
        elementID: String,
        message: Message,
        translatedInlines: InlinePreviewEntityBody? = nil, // 当是译文时（isOrigin = false），会使用外部传入的 translatedInlines
        isOrigin: Bool = true, // 是否原文，默认原文
        font: UIFont,
        textColor: UIColor,
        iconColor: UIColor?,
        tagType: TagType
    ) -> (imageNode: LKAttachmentElement?, titleNode: LKTextElement?, tagNode: LKAttachmentElement?, clickURL: String?)? {
        guard let entity = getEntity(elementID: elementID, message: message, translatedInlines: translatedInlines, isOrigin: isOrigin) else { return nil }
        let imageNode = getImageNode(entity: entity, font: font, iconColor: iconColor)
        let titleNode = getTitleNode(entity: entity, font: font, textColor: textColor)
        let tagNode = getTagNode(entity: entity, font: font, tagType: tagType)
        if titleNode == nil { return nil }
        return (imageNode, titleNode, tagNode, entity.url?.tcURL)
    }
    // swiftlint:enable large_tuple

    public func getTitleNode(entity: InlinePreviewEntity, font: UIFont, textColor: UIColor) -> LKTextElement? {
        guard let title = entity.title, !title.isEmpty else { return nil }
        let textElement = LKTextElement(text: title)
        textElement.style.font(font).color(textColor)
        return textElement
    }

    public func getImageNode(entity: InlinePreviewEntity, font: UIFont, iconColor: UIColor?) -> LKAttachmentElement? {
        guard let attachment = getImageAttachment(entity: entity, font: font, iconColor: iconColor) else { return nil }
        let element = LKAttachmentElement(attachment: attachment)
        element.style.height(.em(1))
        return element
    }

    public func getImageAttachment(entity: InlinePreviewEntity, font: UIFont, iconColor: UIColor?) -> LKAsyncRichAttachmentImp? {
        guard inlinePreviewService.hasIcon(entity: entity) else { return nil }
        let inlineService = inlinePreviewService
        let size = CGSize(width: font.pointSize, height: font.pointSize * 0.95)
        let ascentRatio = font.ascender / font.lineHeight
        let attchment = LKAsyncRichAttachmentImp(
            size: size,
            viewProvider: {
                return inlineService.iconView(entity: entity, iconColor: iconColor)
            },
            ascentProvider: { mode in
                switch mode {
                case .horizontalTB: return size.height * ascentRatio
                case .verticalLR, .verticalRL: return size.width * ascentRatio
                }
            },
            verticalAlign: .baseline
        )
        attchment.padding = Edges(.point(0), .point(0), .point(2), .point(0))
        return attchment
    }

    public func getTagNode(entity: InlinePreviewEntity, font: UIFont, tagType: TagType) -> LKAttachmentElement? {
        guard let attachment = getTagAttachment(entity: entity, font: font, tagType: tagType) else { return nil }
        return LKAttachmentElement(attachment: attachment)
    }

    public func getTagAttachment(entity: InlinePreviewEntity, font: UIFont, tagType: TagType) -> LKAsyncRichAttachmentImp? {
        guard inlinePreviewService.hasTag(entity: entity) else { return nil }
        let tag = entity.tag ?? ""
        let inlineService = inlinePreviewService
        let size = inlinePreviewService.tagViewSize(text: tag, titleFont: font)
        let attachment = LKAsyncRichAttachmentImp(size: size, viewProvider: {
            let tagView = inlineService.tagView(text: tag, titleFont: font, type: tagType)
            return tagView ?? UIView()
        }, ascentProvider: { mode in
            switch mode {
            case .horizontalTB: return size.height / 2
            case .verticalLR, .verticalRL: return size.width / 2
            }
        })
        return attachment
    }
}

// MARK: Utils
extension MessageInlineViewModel {
    public static func getInlinePreviewBody(message: Message) -> InlinePreviewEntityBody {
        if message.type == .text, let content = message.content as? TextContent {
            return content.inlinePreviewEntities
        } else if message.type == .post, let content = message.content as? PostContent {
            return content.inlinePreviewEntities
        } else if message.type == .mergeForward, let content = message.content as? MergeForwardContent {
            var inlines = InlinePreviewEntityBody()
            let bodys = content.messages.map({ getInlinePreviewBody(message: $0) })
            bodys.forEach({ inlines += $0 })
            return inlines
        }
        return [:]
    }
}
