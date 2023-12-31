//
//  MentionTransformer.swift
//  LarkRichTextCore
//
//  Created by 夏汝震 on 2020/10/27.
//

import UIKit
import Foundation
import LarkModel
import RustPB

public final class MentionInfo: NSObject {
    public var id: String
    public var content: String
    public var isAvailable: Bool
    public var isDraftScene = true

    public init(id: String, content: String, isAvailable: Bool) {
        self.id = id
        self.content = content
        self.isAvailable = isAvailable
        super.init()
    }
}

public final class MentionTransformer: RichTextTransformProtocol {

    static let mentionAttributedKey = NSAttributedString.Key(rawValue: "mention")
    static let separator = " isAvailable:"

    public init() {}

    // item -> 富文本：在选择面板选择成功后，将item转成富文本在输入框进行展示
    public static func transformContentToString(_ info: MentionInfo, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        var contentStr = info.content
        if !contentStr.hasPrefix("#") {
            contentStr = "#\(info.content)"
        }

        let attributedStr = NSMutableAttributedString(string: contentStr, attributes: attributes)

        if info.isAvailable {
            attributedStr.addAttributes(
                [Self.mentionAttributedKey: info,
                 .foregroundColor: UIColor.ud.textLinkNormal],
                range: NSRange(location: 0, length: attributedStr.length))
        } else {
            attributedStr.addAttributes(
                [Self.mentionAttributedKey: info,
                .foregroundColor: UIColor.ud.N600],
                range: NSRange(location: 0, length: attributedStr.length))
        }
        return attributedStr
    }

    // 富文本 -> RustPB.Basic_V1_RichText：编辑显示的 属性字符串转化为 richText
    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let priority: RichTextAttrPriority = .content
        text.enumerateAttribute(Self.mentionAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (info, range, _) in
            if let info = info as? MentionInfo {
                let subText = text.attributedSubstring(from: range)
                var content = subText.string
                if !content.hasPrefix("#") {
                    content = "#\(content)"
                }
                if !info.id.isEmpty,
                    !content.isEmpty {
                    let id = InputUtil.randomId()
                    var mentionProperty = RustPB.Basic_V1_RichTextElement.MentionProperty()
                    mentionProperty.content = content
                    var item = RustPB.Basic_V1_RichTextElement.MentionItem()
                    if info.isDraftScene {
                        item.id = info.id + "\(Self.separator)\(info.isAvailable ? 1 : 0)"
                    } else {
                        item.id = info.id
                    }
                    item.type = .hashTag
                    mentionProperty.item = item
                    let tuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.mention,
                                                                        id,
                                                                        .mention(mentionProperty),
                                                                        styleForAttributedStr(subText, fromLocation: 0))
                    let attr = RichTextAttr(priority: priority, tuple: tuple)
                    result.append(RichTextFragmentAttr(range, [attr]))
                }
            }
        }
        return result
    }

    public func transformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: false)
    }

    public func downgradeTransformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: true)
    }

    // RustPB.Basic_V1_RichText -> 富文本：richtext 转化 编辑显示的 属性字符串
    public func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                                      attachmentResult: [String: String],
                                      downgrade: Bool) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let mention = option.element.property.mention
            if downgrade {
                return Self.downgradeMentionContentFor(content: mention.content, attributes: attributes)
            }
            var id = mention.item.id
            var isAvailable = false
            if id.contains(MentionTransformer.separator) {
                let params = mention.item.id.components(separatedBy: MentionTransformer.separator)
                id = String(params.first ?? "")
                isAvailable = (Int(String(params.last ?? "")) ?? 0) != 0
            }
            let info = MentionInfo(id: id, content: mention.content, isAvailable: isAvailable)
            return [Self.transformContentToString(info, attributes: attributes)]
        }
        return [(.mention, process)]
    }

    // richText 转化为显示使用的纯字符串
    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let content = option.element.property.mention.content
            return Self.downgradeMentionContentFor(content: content, attributes: nil)
        }
        return [(.mention, process)]
    }

    // 发送消息前预处理
    public func preproccessSendAttributedStr(_ text: NSAttributedString) -> NSAttributedString {
        var transform: Bool = false
        let mutable = NSMutableAttributedString(attributedString: text)
        text.enumerateAttribute(Self.mentionAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (info, range, _) in
            if let info = info as? MentionInfo {
                transform = true
                info.isDraftScene = false
                mutable.removeAttribute(Self.mentionAttributedKey, range: range)
                mutable.addAttributes(
                    [Self.mentionAttributedKey: info],
                    range: range)
            }
        }
        if transform {
            return mutable
        } else {
            return text
        }
    }

    static func downgradeMentionContentFor(content: String, attributes: [NSAttributedString.Key : Any]?) -> [NSAttributedString] {
        var fixContent = content
        if !fixContent.hasPrefix("#") {
            fixContent = "#\(fixContent)"
        }
        return [NSAttributedString(string: "\(fixContent)", attributes: attributes)]
    }
}
