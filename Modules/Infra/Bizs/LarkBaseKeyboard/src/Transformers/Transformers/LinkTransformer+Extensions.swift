//
//  LinkTransformer+Extensions.swift
//  LarkCore
//
//  Created by 张威 on 2021/12/6.
//

import UIKit
import Foundation
import TangramService
import EditTextView
import RustPB
import LarkModel

public extension LinkTransformer {
    static let tagTypeKey = NSAttributedString.Key("inline.tagType")

    static func transformToAttrWith(_ linkPB: RustPB.Basic_V1_RichTextElement.LinkProperty,
                                    imagePB: RustPB.Basic_V1_RichTextElement.ImageProperty,
                                    title: String,
                                    style: [String: String],
                                    attributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        guard let url = URL(string: linkPB.url) else {
            return nil
        }
        let iconStr = ImageTransformer.transformToIconAttrFrom(imageProperty: imagePB, attributes: attributes)
        let attributedStr = NSMutableAttributedString(attributedString: iconStr)
        attributedStr.append(NSAttributedString(string: title, attributes: attributes))
        attributedStr.addAttribute(LinkTransformer.LinkAttributedKey,
                                   value: LinkTransformInfo(url: url,
                                                            titleLength: attributedStr.length),
                                   range: NSRange(location: 0, length: attributedStr.length))
        attributedStr.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: NSRange(location: 0, length: attributedStr.length))
        if let fontAttributes = RichTextParseHelper.transformStyleToAttributes(style, font: attributes[.font] as? UIFont) {
            attributedStr.addAttributes(fontAttributes,
                                        range: NSRange(location: 0, length: attributedStr.length))
        }
        return attributedStr
    }


    static func transformToDocAttr(_ content: DocInsertContent, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let docIconStr = ImageTransformer.transformDocTypeToString(content.docType, content.title, content.customKey, attributes: attributes)
        let attributedStr = NSMutableAttributedString(attributedString: docIconStr)
        attributedStr.append(NSAttributedString(string: content.title, attributes: attributes))
        attributedStr.addAttribute(LinkTransformer.LinkAttributedKey,
                                   value: LinkTransformInfo(url: content.herf,
                                                            titleLength: attributedStr.length),
                                   range: NSRange(location: 0, length: attributedStr.length))
        attributedStr.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: NSRange(location: 0, length: attributedStr.length))
        return attributedStr
    }

    static func transformToURLAttr(entity: InlinePreviewEntity,
                                   originURL: URL,
                                   style: [String: String] = [:],
                                   attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let summerize = NSMutableAttributedString()
        if let imageAttr = ImageTransformer.transformToURLIconAttr(entity: entity, attributes: attributes) {
            summerize.append(imageAttr)
        }

        if let title = entity.title, !title.isEmpty {
            let titleAttr = NSMutableAttributedString(string: title, attributes: attributes)
            if let fontAttributes = RichTextParseHelper.transformStyleToAttributes(style, font: attributes[.font] as? UIFont) {
                titleAttr.addAttributes(fontAttributes,
                                            range: NSRange(location: 0, length: titleAttr.length))
            }
            summerize.append(titleAttr)
        } else {
            return NSAttributedString(string: originURL.path, attributes: attributes)
        }
        if let tagAttr = transformToURLTagAttr(entity: entity, attributes: attributes) {
            summerize.append(tagAttr)
        }
        summerize.addAttribute(LinkTransformer.LinkAttributedKey,
                               value: LinkTransformInfo(url: originURL, titleLength: summerize.length),
                               range: NSRange(location: 0, length: summerize.length))
        summerize.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: NSRange(location: 0, length: summerize.length))
        return summerize
    }

    static func transformToURLAttrInDescription(entity: InlinePreviewEntity,
                                   originURL: URL,
                                   attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let summerize = NSMutableAttributedString()
        if let imageAttr = ImageTransformer.transformToURLIconAttrInDesCription(entity: entity, attributes: attributes) {
            summerize.append(imageAttr)
        }
        if let title = entity.title {
            summerize.append(NSAttributedString(string: title, attributes: attributes))
        }
        if let tagAttr = transformToURLTagAttr(entity: entity, attributes: attributes) {
            summerize.append(tagAttr)
        }
        summerize.addAttribute(LinkTransformer.LinkAttributedKey,
                               value: LinkTransformInfo(url: originURL, titleLength: summerize.length),
                               range: NSRange(location: 0, length: summerize.length))
        summerize.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: NSRange(location: 0, length: summerize.length))
        return summerize
    }

    static func transformToURLTagAttr(entity: InlinePreviewEntity, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        guard let tag = entity.tag, !tag.isEmpty else { return nil }
        var attributes = attributes
        attributes[LinkTransformer.tagTypeKey] = TagType.link
        guard let attr = self.getKeyboardTagAttr(entity: entity, customAttributes: attributes) else { return nil }
        attr.addAttribute(LinkTransformer.TagAttributedKey, value: tag, range: NSRange(location: 0, length: 1))
        return attr
    }

    static func getKeyboardTagAttr(entity: InlinePreviewEntity, customAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString? {
        let inlinePreviewService = InlinePreviewService()
        guard inlinePreviewService.hasTag(entity: entity) else { return nil }
        let tag = entity.tag ?? ""
        let font = customAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 10)
        let size = inlinePreviewService.tagViewSize(text: tag, titleFont: font)
        let bounds = CGRect(x: 4,
                            y: -(size.height - font.ascender - font.descender) / 2,
                            width: size.width,
                            height: size.height)
        let tagType = customAttributes[LinkTransformer.tagTypeKey] as? TagType ?? .link
        let tagView = inlinePreviewService.tagView(text: tag, titleFont: font, type: tagType)
        let attachMent = CustomTextAttachment(customView: tagView, bounds: bounds)
        let attr = NSMutableAttributedString(attachment: attachMent)
        attr.addAttributes(customAttributes, range: NSRange(location: 0, length: 1))
        return attr
    }
}
