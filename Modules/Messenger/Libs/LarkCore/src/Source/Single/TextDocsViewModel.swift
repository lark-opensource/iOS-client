//
//  TextDocsViewModel.swift
//  Action
//
//  Created by 赵冬 on 2019/4/10.
//

import Foundation
import UIKit
import RichLabel
import LarkModel
import ByteWebImage
import RustPB
import LKRichView
import LarkFeatureGating
import LarkRichTextCore
import LarkBaseKeyboard
import LarkContainer

/// docsurl替换类型
public enum ReplaceStyle {
    /// 不替换
    case unkonwn
    /// 替换为link
    case tolink
    /// 替换为text
    case toText
}

/// 封装docsurl转title的逻辑
public final class TextDocsViewModel {
    let userResolver: UserResolver

    public typealias ReplaceInfo = (result: RustPB.Basic_V1_RichTextElement, origin: RustPB.Basic_V1_RichTextElement)

    private static var fix15_4CrashLock = os_unfair_lock_s()

    /// 处理后的结果
    public var richText: RustPB.Basic_V1_RichText
    /// doc icon是否支持自定义
    public let allowDocCustomIcon: Bool
    /// 存放替换类型为tolink的element
    public lazy var replaceToLinkMap: [String: ReplaceInfo] = {
        os_unfair_lock_lock(&Self.fix15_4CrashLock)
        defer {
            os_unfair_lock_unlock(&Self.fix15_4CrashLock)
        }
        return [:]
    }()

    public init(userResolver: UserResolver, richText: RustPB.Basic_V1_RichText, docEntity: RustPB.Basic_V1_DocEntity?, replceStyle: ReplaceStyle = .tolink) {
        self.userResolver = userResolver
        self.richText = richText
        self.allowDocCustomIcon = userResolver.fg.staticFeatureGatingValue(with: .init(key: .docCustomAvatarEnable))
        self.processTextContent(docEntity: docEntity, replceStyle: replceStyle, hangPoint: [:])
    }

    public init(userResolver: UserResolver,
                richText: RustPB.Basic_V1_RichText,
                docEntity: RustPB.Basic_V1_DocEntity?,
                replceStyle: ReplaceStyle = .tolink,
                hangPoint: [String: RustPB.Basic_V1_UrlPreviewHangPoint]) {
        self.userResolver = userResolver
        self.richText = richText
        self.allowDocCustomIcon = userResolver.fg.staticFeatureGatingValue(with: .init(key: .docCustomAvatarEnable))
        self.processTextContent(docEntity: docEntity, replceStyle: replceStyle, hangPoint: hangPoint)
    }

    public func parseRichText(isFromMe: Bool = false,
                              isShowReadStatus: Bool = true,
                              checkIsMe: ((_ userId: String) -> Bool)?,
                              botIds: [String] = [],
                              maxLines: Int = 0,
                              maxCharLine: Int = 40,
                              atColor: AtColor = AtColor(),
                              needNewLine: Bool = true,
                              iconColor: UIColor? = nil,
                              customAttributes: [NSAttributedString.Key: Any],
                              abbreviationInfo: [String: AbbreviationInfoWrapper]? = nil,
                              mentions: [String: Basic_V1_HashTagMentionEntity]? = nil,
                              imageAttachmentViewProvider: ((RustPB.Basic_V1_RichTextElement.ImageProperty, UIFont) -> LKAttachmentProtocol)? = nil,
                              mediaAttachmentViewProvider: ((RustPB.Basic_V1_RichTextElement.MediaProperty, UIFont) -> LKAttachmentProtocol)? = nil,
                              urlPreviewProvider: LarkRichTextCoreUtils.URLPreviewProvider? = nil,
                              hashTagProvider: ((RichTextWalkerOption<NSMutableAttributedString>, UIFont) -> NSMutableAttributedString)?
    ) -> ParseRichTextResult {
        return LarkRichTextCoreUtils.parseRichText(
            richText: self.richText,
            isFromMe: isFromMe,
            isShowReadStatus: isShowReadStatus,
            checkIsMe: checkIsMe,
            botIds: botIds,
            maxLines: maxLines,
            maxCharLine: maxCharLine,
            atColor: atColor,
            needNewLine: needNewLine,
            customAttributes: customAttributes,
            abbreviationInfo: abbreviationInfo,
            mentions: mentions,
            imageAttachmentViewProvider: { [weak self] (property, font) -> LKAttachmentProtocol in
                guard self != nil else {
                    return LKAsyncAttachment(viewProvider: { UIView() }, size: .zero)
                }
                // docs icon originKey add LocalResources.localDocsPrefix as prefix in TextDocsViewModel.replaceRichTextAnchorWithLink.
                // So just check if the prefix is the same to know if it is the docs icon
                if property.originKey.hasPrefix(LarkRichTextCore.Resources.localDocsPrefix) {
                    return TextDocsViewModel.getDocIconImageAttachment(font: font, property: property, iconColor: iconColor)
                } else if let imageProvider = imageAttachmentViewProvider {
                    return imageProvider(property, font)
                } else {
                    return LKAsyncAttachment(viewProvider: { UIView() }, size: .zero)
                }
            },
            mediaAttachmentViewProvider: mediaAttachmentViewProvider,
            urlPreviewProvider: urlPreviewProvider,
            hashTagProvider: hashTagProvider
        )
    }

    public func parseRichText(isFromMe: Bool = false,
                              isShowReadStatus: Bool = true,
                              checkIsMe: ((_ userId: String) -> Bool)?,
                              botIds: [String] = [],
                              maxLines: Int = 0,
                              maxCharLine: Int = 40,
                              atColor: AtColor = AtColor(),
                              needNewLine: Bool = true,
                              iconColor: UIColor? = nil,
                              customAttributes: [NSAttributedString.Key: Any],
                              abbreviationInfo: [String: AbbreviationInfoWrapper]? = nil,
                              mentions: [String: Basic_V1_HashTagMentionEntity]? = nil,
                              imageAttachmentViewProvider: ((RustPB.Basic_V1_RichTextElement.ImageProperty, UIFont) -> LKAttachmentProtocol)? = nil,
                              mediaAttachmentViewProvider: ((RustPB.Basic_V1_RichTextElement.MediaProperty, UIFont) -> LKAttachmentProtocol)? = nil,
                              urlPreviewProvider: LarkRichTextCoreUtils.URLPreviewProvider? = nil
    ) -> ParseRichTextResult {
        return parseRichText(isFromMe: isFromMe,
                             isShowReadStatus: isShowReadStatus,
                             checkIsMe: checkIsMe,
                             botIds: botIds,
                             maxLines: maxLines,
                             maxCharLine: maxCharLine,
                             atColor: atColor,
                             needNewLine: needNewLine,
                             iconColor: iconColor,
                             customAttributes: customAttributes,
                             abbreviationInfo: abbreviationInfo,
                             mentions: mentions,
                             imageAttachmentViewProvider: imageAttachmentViewProvider,
                             mediaAttachmentViewProvider: mediaAttachmentViewProvider,
                             urlPreviewProvider: urlPreviewProvider,
                             hashTagProvider: nil)
    }

    // FG开启且生成了previewID，则走URL中台解析
    private func isCCMPreviewEnabled(elementID: String, hangPoint: [String: RustPB.Basic_V1_UrlPreviewHangPoint]) -> Bool {
        return hangPoint[elementID] != nil
    }

    private func processTextContent(docEntity: RustPB.Basic_V1_DocEntity?,
                                    replceStyle: ReplaceStyle,
                                    hangPoint: [String: RustPB.Basic_V1_UrlPreviewHangPoint]) {
        guard let docEntity = docEntity else { return }

        switch replceStyle {
        case .unkonwn: break
        case .tolink: replaceRichTextAnchorWithLink(richText: &self.richText, docEntity: docEntity, hangPoint: hangPoint)
        case .toText: replaceRichTextAnchorWithText(richText: &self.richText, docEntity: docEntity, hangPoint: hangPoint)
        }
    }

    /// 把docsurl替换为另一段文本
    private func replaceRichTextAnchorWithText(richText: inout RustPB.Basic_V1_RichText,
                                               docEntity: RustPB.Basic_V1_DocEntity,
                                               hangPoint: [String: RustPB.Basic_V1_UrlPreviewHangPoint]) {
        for (elementId, elementEntity) in docEntity.elementEntityRef {
            guard !isCCMPreviewEnabled(elementID: elementId, hangPoint: hangPoint),
                  let element = richText.elements[elementId],
                  element.tag != .text else { continue }
            // 创建title
            var textElement = RustPB.Basic_V1_RichTextElement()
            textElement.tag = RustPB.Basic_V1_RichTextElement.Tag.text
            var textProperty = RustPB.Basic_V1_RichTextElement.TextProperty()
            if elementEntity.hasTitle { textProperty.content = BundleI18n.LarkCore.Lark_Chat_HideDocsURL(elementEntity.title) }
            textElement.property.text = textProperty
            richText.elements[elementId] = textElement
        }
    }

    private func replaceRichTextAnchorWithLink(richText: inout RustPB.Basic_V1_RichText,
                                               docEntity: RustPB.Basic_V1_DocEntity,
                                               hangPoint: [String: RustPB.Basic_V1_UrlPreviewHangPoint]) {
        for (elementId, elementEntity) in docEntity.elementEntityRef {
            guard !isCCMPreviewEnabled(elementID: elementId, hangPoint: hangPoint),
                  let element = richText.elements[elementId],
                  element.tag != .link,
                  elementEntity.hasTitle,
                  elementEntity.hasDocType else { continue }
            // 创建icon
            let imageElementId = elementId + "-1"
            var imageElement = RustPB.Basic_V1_RichTextElement()
            imageElement.tag = RustPB.Basic_V1_RichTextElement.Tag.img
            var imageProperty = RustPB.Basic_V1_RichTextElement.ImageProperty()
            let iconKey = getDocIconKey(docElement: elementEntity)
            imageProperty.originKey = iconKey
            imageProperty.thumbKey = iconKey
            imageProperty.middleKey = iconKey
            imageProperty.token = elementEntity.token
            imageElement.property.image = imageProperty
            richText.elements[imageElementId] = imageElement
            richText.imageIds.append(imageElementId)
            // 创建title
            let textElementId = elementId + LarkBaseKeyboard.Resources.customTitle
            var textElement = RustPB.Basic_V1_RichTextElement()
            textElement.tag = RustPB.Basic_V1_RichTextElement.Tag.text
            var textProperty = RustPB.Basic_V1_RichTextElement.TextProperty()
            textProperty.content = elementEntity.title
            textElement.property.text = textProperty
            richText.elements[textElementId] = textElement
            // 包装icon+title为link
            var linkElement = RustPB.Basic_V1_RichTextElement()
            linkElement.tag = RustPB.Basic_V1_RichTextElement.Tag.link
            var urlProperty = RustPB.Basic_V1_RichTextElement.LinkProperty()
            if element.property.anchor.hasHref, !element.property.anchor.href.isEmpty {
                urlProperty.url = element.property.anchor.href
            }
            if element.property.anchor.hasIosHref, !element.property.anchor.iosHref.isEmpty {
                urlProperty.iosURL = element.property.anchor.iosHref
            }
            linkElement.property.link = urlProperty
            linkElement.childIds = [imageElementId, textElementId]
            richText.elements[elementId] = linkElement

            self.replaceToLinkMap[elementId] = (linkElement, element)
        }
    }

    private func getDocIconKey(docElement: Basic_V1_DocEntity.ElementEntity) -> String {
        var customKey = ""
        if self.allowDocCustomIcon, docElement.hasIcon, docElement.icon.type == .image {
            customKey = docElement.icon.value
        }
        return LarkBaseKeyboard.Resources.docIconOriginKey(type: docElement.docType, filename: docElement.title, customKey: customKey)
    }

    private static func getDocIconImageAttachment(font: UIFont, property: RustPB.Basic_V1_RichTextElement.ImageProperty, iconColor: UIColor?) -> LKAttachmentProtocol {
        let attachMent = LKAsyncAttachment(viewProvider: {
            return getDocIcon(property: property, iconColor: iconColor)
        }, size: CGSize(width: font.pointSize, height: font.pointSize * 0.95))
        attachMent.fontAscent = font.ascender
        attachMent.fontDescent = font.descender
        let edgeInsets = font.pointSize * 0.25
        attachMent.margin = UIEdgeInsets(top: 1, left: edgeInsets, bottom: 0, right: edgeInsets)
        return attachMent
    }

    @inline(__always)
    private static func isCustomDocIcon(property: RustPB.Basic_V1_RichTextElement.ImageProperty) -> Bool {
        return !property.token.isEmpty && property.originKey.contains(LarkBaseKeyboard.Resources.customKey)
    }
}

// MARK: - NewRichComponent
extension TextDocsViewModel {
    public static func isDocTitle(elementID: String) -> Bool {
        return elementID.hasSuffix(LarkBaseKeyboard.Resources.customTitle)
    }

    public static func getDocIconRichAttachment(property: Basic_V1_RichTextElement.ImageProperty, font: UIFont, iconColor: UIColor?) -> LKRichAttachment? {
        guard property.originKey.hasPrefix(LarkRichTextCore.Resources.localDocsPrefix) else { return nil }
        let size = CGSize(width: font.pointSize, height: font.pointSize * 0.95)
        let ascentRatio = font.ascender / font.lineHeight
        let attathment = LKAsyncRichAttachmentImp(
            size: size,
            viewProvider: {
                return getDocIcon(property: property, iconColor: iconColor)
            },
            ascentProvider: { mode in
                switch mode {
                case .horizontalTB: return size.height * ascentRatio
                case .verticalLR, .verticalRL: return size.width * ascentRatio
                }
            },
            verticalAlign: .baseline
        )
        attathment.padding = Edges(.point(0), .point(0), .point(1), .point(0))
        return attathment
    }

    private static func getDocIcon(property: Basic_V1_RichTextElement.ImageProperty, iconColor: UIColor?) -> UIImageView {
        let imageView = UIImageView(frame: .zero)
        let imageSet = ImageItemSet.transform(imageProperty: property)
        imageView.setPostMessage(imageSet: imageSet)
        if !isCustomDocIcon(property: property),
            let iconColor = iconColor {
            guard let img = imageView.image else {
                return imageView
            }
            imageView.image = img.lu.colorize(color: iconColor, resizingMode: .stretch)
        }
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
}
