//
//  LinkTransformer.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/3/31.
//

import UIKit
import Foundation
import LarkModel
import TangramService
import EditTextView
import RustPB

public final class LinkTransformInfo: NSObject {
    public var url: URL
    public var titleLength: Int
    public init(url: URL, titleLength: Int) {
        self.titleLength = titleLength
        self.url = url
        super.init()
    }
}

public final class LinkTransformer: RichTextTransformProtocol {

    public static let LinkAttributedKey = NSAttributedString.Key(rawValue: "lark.link.key")
    public static let TagAttributedKey = NSAttributedString.Key(rawValue: "lark.tag.key")

    public init() {}

    public typealias DocInsertContent = (title: String, docType: RustPB.Basic_V1_Doc.TypeEnum, herf: URL, customKey: String)

    public func transformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: false)
    }

    public func downgradeTransformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: true)
    }

    public func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                                      attachmentResult: [String: String],
                                      downgrade: Bool) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            if downgrade {
                return [NSAttributedString(string: option.element.property.link.url, attributes: attributes)]
            }
            if let url = URL(string: option.element.property.link.url) {
                let link = LinkTransformInfo(url: url, titleLength: (option.element.property.link.url as NSString).length)
                var length = 0
                let results = option.results.map({ (attr) -> NSAttributedString in
                    let attr = NSMutableAttributedString(attributedString: attr)
                    attr.addAttribute(LinkTransformer.LinkAttributedKey, value: link, range: NSRange(location: 0, length: attr.length))
                    attr.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: NSRange(location: 0, length: attr.length))
                    if let fontAttributes = RichTextParseHelper.transformStyleToAttributes(option.element.style, font: attributes[.font] as? UIFont) {
                        attr.addAttributes(fontAttributes,
                                                    range: NSRange(location: 0, length: attr.length))
                    }
                    length += attr.length
                    return attr
                })
                if length > 0 { link.titleLength = length }
                return results
            } else {
                return option.results
            }
        }

        return [(.link, process)]
    }

    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let priority: RichTextAttrPriority = .medium
        text.enumerateAttribute(LinkTransformer.LinkAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (info, range, _) in
            if let info = info as? LinkTransformInfo {
                let id = InputUtil.randomId()
                var linkProperty = RustPB.Basic_V1_RichTextElement.LinkProperty()
                linkProperty.url = info.url.absoluteString
                let subAttributeStr = text.attributedSubstring(from: range)
                let tuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.link, id, .link(linkProperty), styleForAttributedStr(subAttributeStr, fromLocation: 1))
                let attr = RichTextAttr(priority: priority, tuple: tuple)
                result.append(RichTextFragmentAttr(range, [attr]))
            }
        }
        return result
    }

    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let title: String = option.results.reduce("", { (result, attributedStr) -> String in
                    return result + attributedStr.string
            })
            return [NSAttributedString(string: BundleI18n.LarkBaseKeyboard.Lark_Chat_HideDocsURL(doctitle: title))]
        }
        return [(.link, process)]
    }

    public func preproccessSendAttributedStr(_ text: NSAttributedString) -> NSAttributedString {
        var transform: Bool = false
        let mutable = NSMutableAttributedString(attributedString: text)
        text.enumerateAttribute(LinkTransformer.LinkAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (info, range, stop) in
            if let info = info as? LinkTransformInfo {
                let subAttr = mutable.attributedSubstring(from: range)
                var attrs: [NSAttributedString.Key: Any] = [:]
                if subAttr.length > 0 {
                    attrs = subAttr.attributes(at: 0, effectiveRange: nil)
                    attrs.removeValue(forKey: LinkTransformer.LinkAttributedKey)
                }
                mutable.replaceCharacters(in: range, with: NSAttributedString(string: info.url.absoluteString + " ", attributes: attrs))
                transform = true
                stop.pointee = true
            }
        }
        // 发送时Tag替换为""
        text.enumerateAttribute(LinkTransformer.TagAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (tag, range, stop) in
            if tag is String {
                mutable.replaceCharacters(in: range, with: "")
                transform = true
                stop.pointee = true
            }
        }
        if transform {
            return self.preproccessSendAttributedStr(mutable)
        } else {
            return text
        }
    }

    public func preproccessDescriptionAttributedStr(_ text: NSAttributedString) -> NSAttributedString {
        var transform: Bool = false
        let mutable = NSMutableAttributedString(attributedString: text)
        text.enumerateAttribute(LinkTransformer.LinkAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (info, range, stop) in
            if let info = info as? LinkTransformInfo {
                mutable.replaceCharacters(in: range, with: NSAttributedString(string: info.url.absoluteString + "\u{200b}"))
                transform = true
                stop.pointee = true
            }
        }
        // 发送时Tag替换为""
        text.enumerateAttribute(LinkTransformer.TagAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (tag, range, stop) in
            if tag is String {
                mutable.replaceCharacters(in: range, with: "")
                transform = true
                stop.pointee = true
            }
        }
        if transform {
            return self.preproccessDescriptionAttributedStr(mutable)
        } else {
            return text
        }
    }

    public func filterUnsupportStyleRangeFor(text: NSAttributedString) -> [NSRange] {
        var ranges: [NSRange] = []
        text.enumerateAttribute(LinkTransformer.LinkAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { info, range, _ in
            if let info = info as? LinkTransformInfo {
                if info.titleLength != range.length {
                    ranges.append(range)
                }
            }
        }
        return ranges
    }
}
