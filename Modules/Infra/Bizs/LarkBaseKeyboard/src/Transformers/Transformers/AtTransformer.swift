//
//  AtTransformer.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/3/31.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import LarkSetting

public final class AtChatterInfo: NSObject {
    public var id: String
    /// 用户展示的名字
    public var name: String
    public var isOuter: Bool
    public var isAnonymous: Bool = false
    public var actualName: String = ""

    public init(id: String,
                name: String,
                isOuter: Bool,
                actualName: String,
                isAnonymous: Bool = false) {
        self.id = id
        self.name = name
        self.actualName = actualName
        self.isOuter = isOuter
        self.isAnonymous = isAnonymous
        super.init()
    }
}

public final class AtTransformer: RichTextTransformProtocol {

    public static let UserIdAttributedKey = NSAttributedString.Key(rawValue: "userId")

    public init() {}

    public static func transformContentToString(_ info: AtChatterInfo,
                                                style: [String: String],
                                                attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        var contentStr = info.name
        if !contentStr.hasPrefix("@") {
            contentStr = "@\(info.name)"
        }
        let attributedStr = NSMutableAttributedString(string: contentStr, attributes: attributes)
        if info.isOuter {
            attributedStr.addAttributes(
                [AtTransformer.UserIdAttributedKey: info,
                 .foregroundColor: UIColor.ud.textCaption],
                range: NSRange(location: 0, length: attributedStr.length))
        } else if info.isAnonymous {
            // 如果是匿名的话 颜色为N900
            attributedStr.addAttributes(
                [AtTransformer.UserIdAttributedKey: info,
                 .foregroundColor: UIColor.ud.N900],
                range: NSRange(location: 0, length: attributedStr.length))
        } else {
            attributedStr.addAttributes(
                [AtTransformer.UserIdAttributedKey: info,
                 .foregroundColor: UIColor.ud.textLinkNormal],
                range: NSRange(location: 0, length: attributedStr.length))
        }
        if let fontAttributes = RichTextParseHelper.transformStyleToAttributes(style, font: attributes[.font] as? UIFont) {
            attributedStr.addAttributes(fontAttributes,
                                        range: NSRange(location: 0, length: attributedStr.length))
        }
        if FeatureGatingManager.shared.featureGatingValue(with: "messenger.input.click_profile"),
           let url = LinkAttributeValue.at.rawValue {
            attributedStr.addAttribute(.link, value: url, range: NSRange(location: 0, length: attributedStr.length))
        }
        return attributedStr
    }

    public static func getAllChatterActualNameMapForAttributedString(_ text: NSAttributedString) -> [String: String] {
        var map: [String: String] = [:]
        text.enumerateAttribute(AtTransformer.UserIdAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { info, _, _ in
            if let info = info as? AtChatterInfo, !info.actualName.isEmpty {
                map[info.id] = info.actualName
            }
        }
        return map
    }

    private static func downgradeAtStringFor(name: String, attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString] {
        var fixName = name
        if !fixName.hasPrefix("@") {
            fixName = "@\(fixName)"
        }
        return [NSAttributedString(string: fixName, attributes: attributes)]
    }

    public static func getAllChatterInfoForAttributedString(_ text: NSAttributedString) -> [AtChatterInfo] {
        var arr: [AtChatterInfo] = []
        text.enumerateAttribute(AtTransformer.UserIdAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { info, _, _ in
            if let info = info as? AtChatterInfo {
                arr.append(info)
            }
        }
        return arr
    }

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
            let at = option.element.property.at
            if downgrade {
                return Self.downgradeAtStringFor(name: at.content, attributes: attributes)
            }
            let info = AtChatterInfo(id: at.userID,
                                     name: at.content,
                                     isOuter: at.isOuter,
                                     actualName: "",
                                     isAnonymous: false)
            return [AtTransformer.transformContentToString(info, style: option.element.style, attributes: attributes)]
        }
        return [(.at, process)]
    }

    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let priority: RichTextAttrPriority = .content
        text.enumerateAttribute(AtTransformer.UserIdAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (info, range, _) in
            if let info = info as? AtChatterInfo {
                let userId = info.id
                var userName = text.attributedSubstring(from: range).string
                // NOTE: 兼容老数据, 确保新的 richText 中 at content 前带 @
                if !userName.hasPrefix("@") {
                    userName = "@\(userName)"
                }
                if !userId.isEmpty,
                    !userName.isEmpty {
                    let id = InputUtil.randomId()
                    var atProperty = RustPB.Basic_V1_RichTextElement.AtProperty()
                    atProperty.userID = userId
                    atProperty.content = userName
                    atProperty.isOuter = info.isOuter
                    atProperty.isAnonymous = info.isAnonymous
                    let subAttributeStr = text.attributedSubstring(from: range)
                    let tuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.at,
                                                                        id,
                                                                        .at(atProperty),
                                                                        styleForAttributedStr(subAttributeStr, fromLocation: 0))
                    let attr = RichTextAttr(priority: priority, tuple: tuple)
                    result.append(RichTextFragmentAttr(range, [attr]))
                }
            }
        }
        return result
    }

    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            var userName = option.element.property.at.content
            return Self.downgradeAtStringFor(name: userName, attributes: [:])
        }

        return [(.at, process)]
    }

    public func filterUnsupportStyleRangeFor(text: NSAttributedString) -> [NSRange] {
        var ranges: [NSRange] = []
        text.enumerateAttribute(AtTransformer.UserIdAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { info, range, _ in
            if let info = info as? AtChatterInfo {
                var userName = info.name
                if !userName.hasPrefix("@") {
                    userName = "@\(userName)"
                }
                if (userName as NSString).length != range.length {
                    ranges.append(range)
                }
            }
        }
        return ranges
    }

    public func preproccessSendAttributedStr(_ text: NSAttributedString) -> NSAttributedString {
        return self.updateAtChatterInfoFor(text)
    }

    private func updateAtChatterInfoFor(_ text: NSAttributedString, fromLoaction: Int = 0) -> NSAttributedString {
        var nextlocation: Int?
        let mutable = NSMutableAttributedString(attributedString: text)
        text.enumerateAttribute(AtTransformer.UserIdAttributedKey,
                                in: NSRange(location: fromLoaction, length: text.length - fromLoaction), options: []) { (info, range, stop) in
            /// 如果是匿名或者actualName = info.name不做替换
            if let info = info as? AtChatterInfo,
               !info.actualName.isEmpty,
               info.actualName != info.name,
               !info.isAnonymous {
                info.name = info.actualName
                let subAttributeText = text.attributedSubstring(from: range)
                var attributes: [NSAttributedString.Key : Any] = [:]
                if subAttributeText.length > 0 {
                    attributes = subAttributeText.attributes(at: 0, effectiveRange: nil)
                }
                attributes[AtTransformer.UserIdAttributedKey] = info
                /// 需要将备注名替换为原名
                var actualName = info.actualName
                /// 如果原来的名字前有@,就再拼接一个@
                if subAttributeText.string.hasPrefix("@"), range.length == info.name.utf16.count + 1 {
                    actualName = "@\(actualName)"
                }
                let actualNameAttr = NSAttributedString(string: actualName, attributes: attributes)
                mutable.replaceCharacters(in: range, with: actualNameAttr)
                nextlocation = range.location + actualNameAttr.length
                stop.pointee = true
            }
        }

        if let nextlocation = nextlocation {
            return self.updateAtChatterInfoFor(mutable, fromLoaction: nextlocation)
        } else {
            return text
        }
    }
}
