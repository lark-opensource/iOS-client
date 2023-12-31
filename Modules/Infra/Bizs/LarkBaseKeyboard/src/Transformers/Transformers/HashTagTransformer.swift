//
//  HashTagTransformer.swift
//  LarkRichTextCore
//
//  Created by liluobin on 2021/6/24.
//

import UIKit
import Foundation
import LarkModel
import RustPB
/**
hashTag 高亮:
 1 直接attributeString 加高亮
 2 使用@的方式加载
 */

public final class HashTagInfo: NSObject {
    public var content: String
    public init(content: String) {
        self.content = content
        super.init()
    }
}
public final class HashTagTransformer: RichTextTransformProtocol {
    public static let HashTagAttributedKey = NSAttributedString.Key(rawValue: "lark.hashTag.key")
    public init() {}

    public static func transformAttributeStringFor(tagInfo: HashTagInfo, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let attributedStr = NSMutableAttributedString(string: tagInfo.content, attributes: attributes)
        attributedStr.addAttributes(
            [HashTagTransformer.HashTagAttributedKey: tagInfo,
             .foregroundColor: UIColor.ud.textLinkNormal],
            range: NSRange(location: 0, length: attributedStr.length))
        return attributedStr
    }

    public func transformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: false)
    }

    public func downgradeTransformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: true)
    }

    // richtext 转化 编辑显示的 属性字符串
    public func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                                      attachmentResult: [String: String],
                                      downgrade: Bool) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let hashTag = option.element.property.mention
            if downgrade {
                return Self.downgradeHashTagForContent(hashTag.content, attributes: attributes)
            }
            let hashTagInfo = HashTagInfo(content: hashTag.content)
            return [HashTagTransformer.transformAttributeStringFor(tagInfo: hashTagInfo, attributes: attributes)]
        }
        return [(.mention, process)]
    }

    // 编辑显示的 属性字符串转化为 richText
    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        return []
    }

    // richText 转化为显示使用的纯字符串
    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            return Self.downgradeHashTagForContent(option.element.property.mention.content, attributes: [:])
        }
        return [(.mention, process)]
    }
    static func downgradeHashTagForContent(_ content: String,
                                           attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString] {
        return [NSAttributedString(string: content, attributes: attributes)]
    }
}
