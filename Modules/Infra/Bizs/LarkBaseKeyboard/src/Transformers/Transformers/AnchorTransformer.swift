//
//  AnchorTransformer.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/3/31.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import LarkFeatureGating

public final class AnchorTransformInfo: NSObject, TagDeleteConfigProtocol {

    public var allDeleFromTail: Bool {
        return isCustom
    }

    public let isCustom: Bool
    public let scene: Basic_V1_RichTextElement.AnchorProperty.Scene
    public let href: String?
    public let contentLength: Int
    public var customTransformToRichTextBlock: ((AnchorTransformInfo) -> Basic_V1_RichTextElement.AnchorProperty?)?

    public init(isCustom: Bool,
                scene: Basic_V1_RichTextElement.AnchorProperty.Scene,
                contentLength: Int,
                href: String? = nil,
                customTransformToRichTextBlock: ((AnchorTransformInfo) -> Basic_V1_RichTextElement.AnchorProperty?)? = nil) {
        self.isCustom = isCustom
        self.scene = scene
        self.href = href
        self.contentLength = contentLength
        self.customTransformToRichTextBlock = customTransformToRichTextBlock
    }
}

public final class AnchorTransformer: RichTextTransformProtocol {
    public static let AnchorAttributedKey = NSAttributedString.Key(rawValue: "lark.anchor.key")

    /// There are some test cases below:
    /// 1. let url = "http://www.bytedangce.com/这个网站不错」"
    /// 2. let url = "https://中.文.中国.cn/这个网站不错"
    /// 3. let url = "https://www.baidu.com/?s=中[]{}+=_-?/.,%7C';:ほᠮᠤᠩᠭᠤᠯ\""
    /// 4. let url = "https://www.google.com.hk/search?q=？，%E3%80%82；‘：”、》《【】「」&hl=zh-CN&ei=_-62Y6LrHfTl2roPloy2wAU&ved=0ahUKEwji5sfC4bD8AhX0slYBHRaGDVgQ4dUDCA4&uact=5&oq=？，%E3%80%82；‘：”、》《【】「」&gs_lcp=Cgxnd3Mtd2l6LXNlcnAQAzIFCCEQoAEyBQghEKABOgoIABBHENYEELADOgUIABCABDoFCC4QgAQ6BQgAEKIESgQIQRgASgQIRhgAUOkNWNSFAWD4mQFoAXABeACAAZMBiAGhDpIBBDAuMTSYAQCgAQHIAQrAAQE&sclient=gws-wiz-serp"
    /// 5. let url = "https://www.baidu.com"
    static let hostRegexp = "(\(domainRegexp)\\.){1,50}\(domainRegexp)"
    static let domainRegexp = "[^\\./:@\\s#\\?\\,=]+"
    static let isURLRegexp = (try? NSRegularExpression(pattern: "^https?://\(hostRegexp)(:[0-9]{2,5})?([/?#]\\S*)?$", options: .caseInsensitive)) ?? NSRegularExpression()

    /// There are some test cases below:
    /// 1. www.baidu.com
    /// 2. http://www.bytedangce
    /// 对齐PC的正则逻辑
    static var URL_REG = "(((\(PROTOCOL))://\(URL_HOST_BODY)\(ANY_TOP_DOMAIN))|(\(URL_HOST_BODY)(\(TOP_DOMAIN))))(:[0-9]{2,5})?\(LINK_SUFFIX)"
    // -----以下是上面用到的变量-----
    static var PROTOCOL = "https?"
    private static var LINK_SUFFIX = "\\b([/?#][-a-zA-Z0-9@:%_+.~#?&/=;()$,!\\*\\[\\]{}^|<>]*)?"
    private static  var URL_HOST_BODY = "([\\-a-zA-Z0-9:%_+~#@]{1,256}\\.){1,50}"
    private static var ANY_TOP_DOMAIN = "[a-z\\-]{2,15}"
    private static var TOP_DOMAIN =
    "com|org|net|int|edu|gov|mil|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gh|gi|gl|gm|gn|gp|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mf|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw|site|top|wtf|xxx|xyz|cloud|engineering|help|one"
    ///内部使用 需要确保当前的文字符就是URL 而不是包含URL 故添加 "^" + URL_REG + "$"
    private static let isGeneralURLRegexp = (try? NSRegularExpression(pattern: ("^" + URL_REG + "$"), options: .caseInsensitive)) ?? NSRegularExpression()

    public func transformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: false)
    }

    public func downgradeTransformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: true)
    }

    public init() {}

    public static func isURL(url: String) -> Bool {
        var result = Self.isURLRegexp.numberOfMatches(in: url, range: NSRange(location: 0, length: url.utf16.count)) > 0
        if !result, TextViewCustomPasteConfig.useNewPasteFG {
            result = Self.isGeneralURLRegexp.numberOfMatches(in: url, range: NSRange(location: 0, length: url.utf16.count)) > 0
        }
        return result
    }

    public static func transformToURLAttributedString(
        anchor: RustPB.Basic_V1_RichTextElement.AnchorProperty,
        style: [String: String],
        attributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(
            string: "\(anchor.hasTextContent ? anchor.textContent : anchor.content)",
            attributes: attributes
        )
        let anchorInfo = AnchorTransformInfo(isCustom: anchor.isCustom, scene: anchor.scene, contentLength: attributedString.length, href: anchor.href)
        attributedString.addAttribute(Self.AnchorAttributedKey, value: anchorInfo, range: NSRange(location: 0, length: attributedString.length))
        if TextViewCustomPasteConfig.useNewPasteFG {
            attributedString.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal,
                                          range: NSRange(location: 0, length: attributedString.length))
            // 标记蓝色
            if let fontAttributes = RichTextParseHelper.transformStyleToAttributes(style, font: attributes[.font] as? UIFont) {
                attributedString.addAttributes(fontAttributes,
                                               range: NSRange(location: 0, length: attributedString.length))
            }
        } else if URLInputManager.checkURLType(anchor.href ?? "") == .entityNum {
            attributedString.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal,
                                          range: NSRange(location: 0, length: attributedString.length))
        }
        return attributedString
    }

    public func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                                      attachmentResult: [String: String],
                                      downgrade: Bool) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let anchor = option.element.property.anchor
            if downgrade {
                return [NSMutableAttributedString(string: "\(anchor.hasTextContent ? anchor.textContent : anchor.content)",
                                                  attributes: attributes)]
            }
            return [Self.transformToURLAttributedString(anchor: anchor, style: option.element.style, attributes: attributes)]
        }

        return [(.a, process)]
    }

    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []

        text.enumerateAttribute(AnchorTransformer.AnchorAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (anchor, range, _) in
            guard let anchor = anchor as? AnchorTransformInfo else {
                return
            }
            let contentAttr = text.attributedSubstring(from: range)
            var anchorProperty: RustPB.Basic_V1_RichTextElement.AnchorProperty?
            if let customAnchorBlock = anchor.customTransformToRichTextBlock {
                anchorProperty = customAnchorBlock(anchor)
            } else {
                let contentStr = contentAttr.string
                if TextViewCustomPasteConfig.useNewPasteFG, anchor.isCustom {
                    anchorProperty = makeAnchorProperty(anchor: anchor, contentStr: contentStr, href: anchor.href ?? "")
                } else if URLInputManager.checkURLType(anchor.href ?? "") == .entityNum {
                    anchorProperty = makeAnchorProperty(anchor: anchor, contentStr: contentStr, href: anchor.href ?? "")
                } else {
                    guard Self.isURL(url: contentStr) else { return }
                    anchorProperty = makeAnchorProperty(anchor: anchor, contentStr: contentStr, href: contentStr)
                }
            }
            if let anchorProperty = anchorProperty {
                let tuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.a, InputUtil.randomId(), .a(anchorProperty),
                                                                    styleForAttributedStr(contentAttr, fromLocation: 0))
                let attr = RichTextAttr(priority: .content, tuple: tuple)
                result.append(RichTextFragmentAttr(range, [attr]))
            }
        }
        return result
    }

    private func makeAnchorProperty(anchor: AnchorTransformInfo, contentStr: String, href: String) -> RustPB.Basic_V1_RichTextElement.AnchorProperty {
        var anchorProperty = RustPB.Basic_V1_RichTextElement.AnchorProperty()
        anchorProperty.href = href
        anchorProperty.content = contentStr
        anchorProperty.textContent = contentStr
        anchorProperty.isCustom = anchor.isCustom
        anchorProperty.scene = anchor.scene
        return anchorProperty
    }

    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            var content = ""
            let anchor = option.element.property.anchor
            if anchor.hasTextContent {
                content = anchor.textContent
            } else {
                content = anchor.content
            }
            return [NSAttributedString(string: content)]
        }
        return [(.a, process)]
    }
}
