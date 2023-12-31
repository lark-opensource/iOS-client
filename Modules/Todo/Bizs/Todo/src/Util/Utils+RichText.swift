//
//  Utils+RichText.swift
//  Todo
//
//  Created by 张威 on 2021/1/15.
//

import LarkExtensions

extension Utils {
    struct RichText {
        public static func randomId() -> Int32 {
            return Int32(arc4random() % 100_000_000)
        }
    }
}

extension Utils.RichText {

    /// 基于 user 信息构建 RichContent
    static func makeRichContent(for user: Rust.User, isOuter: Bool) -> Rust.RichContent {
        var ele = Rust.RichText.Element()
        ele.tag = .at
        var pro = Rust.RichText.Element.AtProperty()
        pro.userID = user.userID
        pro.content = user.name
        pro.isOuter = isOuter
        ele.property.at = pro
        let eleId = String(randomId())

        var richText = Rust.RichText()
        richText.elements = [eleId: ele]
        richText.elementIds = [eleId]
        richText.innerText = user.name
        richText.atIds = [eleId]

        var richContent = Rust.RichContent()
        richContent.richText = richText
        return richContent
    }

    static func makePlainText(from richContent: Rust.RichContent, needsFixAnchor: Bool = true) -> String {
        var richContent = richContent
        if needsFixAnchor {
            fixAnchorContent(in: &richContent)
        }
        return richContent.richText.lc.summerize()
    }

    /// 构建 RichText
    static func makeRichText(from text: String) -> RichText {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return .init()
        }
        return RichText.text(text)
    }

    /// at 标签的 text
    static func atText(from at: Rust.RichText.Element.AtProperty) -> String {
        var content = at.content
        if !content.hasPrefix("@") {
            content = "@\(content)"
        }
        return content
    }

    /// mention/pano 标签的 text
    static func mentionText(from mention: Rust.RichText.Element.MentionProperty) -> String {
        var content = mention.content
        if !content.hasPrefix("#") {
            content = "#\(content)"
        }
        return content
    }

    /// 替换 RichText 里 Anchor 结构的 content 信息
    static func fixAnchorContent(in richContent: inout Rust.RichContent) {
        for (key, ele) in richContent.richText.elements where ele.tag == .a {
            guard let anchor = richContent.richText.elements[key]?.property.anchor else { continue }
            var content = anchor.textContent.isEmpty ? anchor.content : anchor.textContent
            if let point = richContent.urlPreviewHangPoints[key],
               let entity = richContent.urlPreviewEntities.previewEntity[point.previewID],
               !entity.serverTitle.isEmpty || !entity.sdkTitle.isEmpty {
                if !entity.serverTitle.isEmpty {
                    content = entity.serverTitle
                } else {
                    content = entity.sdkTitle
                }
            }
            richContent.richText.elements[key]?.property.anchor.content = content
            richContent.richText.elements[key]?.property.anchor.textContent = content
        }
    }

    /// 降级 RichText 的 elements
    static func degradeElements(in richText: inout RichText, inclueImage: Bool = true) {
        // 记录 parent id
        var parentIds = [String: String]()
        for (key, ele) in richText.elements {
            ele.childIds.forEach { parentIds[$0] = key }
        }
        let makeTextElement = { (content: String) -> Rust.RichText.Element in
            var ele = Rust.RichText.Element()
            ele.tag = .text
            var pro = Rust.RichText.Element.TextProperty()
            pro.content = content
            ele.property.text = pro
            return ele
        }
        let makeParagraphElement = { (childIds: [String]) -> Rust.RichText.Element in
            var ele = Rust.RichText.Element()
            ele.tag = .p
            ele.childIds = childIds
            ele.property.paragraph = Rust.RichText.Element.ParagraphProperty()
            return ele
        }
        let eleMap = richText.elements
        // 获取 list 的前缀
        let listPrefix = { (eleId: String) -> String? in
            guard
                let parentEleId = parentIds[eleId],
                let parentEle = eleMap[parentEleId],
                let index = parentEle.childIds.firstIndex(of: eleId)
            else {
                return nil
            }
            switch parentEle.tag {
            case .ol:
                return "\(parentEle.property.ol.start + Int32(index)). "
            case .ul:
                return "- "
            @unknown default:
                return nil
            }
        }
        for (key, ele) in eleMap {
            // 清除掉 style（加粗、斜体、删除线、下划线等）
            if inclueImage {
                richText.elements[key]?.style = [:]
            } else {
                if ele.tag != .img {
                    richText.elements[key]?.style = [:]
                }
            }
            switch ele.tag {
            case .text, .a, .p, .link, .at, .mention, .emotion:
                break
            case .li:
                var pEle = makeParagraphElement(ele.childIds)
                if let prefix = listPrefix(key) {
                    let newEleId = "\(randomId())"
                    let newEle = makeTextElement(prefix)
                    richText.elements[newEleId] = newEle
                    pEle.childIds.insert(newEleId, at: 0)
                }
                richText.elements[key] = pEle
            case .i:
                var content = ele.property.italic.content
                richText.elements[key] = makeTextElement(content)
            case .u:
                var content = ele.property.underline.content
                richText.elements[key] = makeTextElement(content)
            case .media:
                richText.elements[key] = makeTextElement(I18N.Lark_Legacy_MessagePoVideo)
            case .codeBlockV2:
                richText.elements[key] = makeTextElement(I18N.Lark_IM_CodeBlockQuote_Text)
            case .img:
                if inclueImage {
                    richText.elements[key] = makeTextElement(I18N.Lark_Legacy_ImageSummarize)
                } else {
                    break
                }
            // head1...6降级为p
            case .figure, .docs, .ol, .ul, .quote, .h1, .h2, .h3, .h4, .h5, .h6:
                richText.elements[key] = makeParagraphElement(ele.childIds)
            @unknown default:
                richText.elements[key] = makeTextElement("")
            }
        }
        richText.imageIds = []
        richText.mediaIds = []
    }

}

extension Utils.RichText {

    static func getRange(for text: String, with templateFunc: (String) -> String) -> NSRange? {
        guard !text.isEmpty else { return nil }
        // text 前后加 uuid，避免 templateFunc 中出现了和 text 相同的文案从而被错误识别
        let uuid: String = UUID().uuidString
        let wrappedText = "\(uuid)\(text)\(uuid)"
        let fullText = templateFunc(wrappedText)
        let nsrange = (fullText as NSString).range(of: wrappedText)
        guard nsrange.location >= 0 && nsrange.location < (fullText as NSString).length && nsrange.location != NSNotFound && nsrange.length < (fullText as NSString).length else { return nil }
        return NSRange(location: nsrange.location, length: (text as NSString).length)
    }

    static func checkRangeValid(_ range: NSRange, in text: AttrText) -> Bool {
        Detail.logger.info("checkRangeValid range: \(range), text: \(text.length)")
        let totalRange = NSRange(location: 0, length: text.length)
        let ret = range.location >= totalRange.location
            && range.length >= 0
            && (range.location + range.length) <= totalRange.length
        return ret
    }

}

import LarkBaseKeyboard
import LarkRichTextCore
import EditTextView

// LarkRichTextCore
typealias RichTextImageTransformInfo = LarkBaseKeyboard.ImageTransformInfo

typealias RichTextElementProcess = LarkBaseKeyboard.RichTextElementProcess
typealias RichTextFragmentAttr = LarkBaseKeyboard.RichTextFragmentAttr
typealias RichTextParseHelper = LarkBaseKeyboard.RichTextParseHelper
typealias RichTextAttr = LarkBaseKeyboard.RichTextAttr
typealias RichTextAttrPriority = LarkBaseKeyboard.RichTextAttrPriority

typealias RichTextLocalResources = LarkBaseKeyboard.Resources
typealias RichTextResources = LarkRichTextCore.LarkRichTextCoreUtils

typealias RichTextTextTransformer = LarkBaseKeyboard.TextTransformer
typealias RichTextEmotionTransformer = LarkBaseKeyboard.EmotionTransformer

extension RichTextTextTransformer: RichTextTransformProtocol { }
extension RichTextEmotionTransformer: RichTextTransformProtocol { }

typealias TextViewInputProtocolSet = EditTextView.TextViewInputProtocolSet
typealias TextViewInputProtocol = EditTextView.TextViewInputProtocol

import LarkKeyboardView

// LarkKeyboardView
typealias LarkKeyboardBuilder = LarkBaseKeyboard.LarkKeyboard
typealias InputKeyboardItem = LarkKeyboardView.InputKeyboardItem
typealias KeyboardItemKey = LarkKeyboardView.KeyboardItemKey
typealias OldBaseKeyboardView = LarkKeyboardView.OldBaseKeyboardView
typealias OldBaseKeyboardDelegate = LarkKeyboardView.OldBaseKeyboardDelegate
typealias KeyboardIconBadgeType = LarkKeyboardView.KeyboardIconBadgeType
typealias KeyboardPanelDelegate = LarkKeyboardView.KeyboardPanelDelegate
typealias KeyboardPanelEvent = LarkKeyboardView.KeyboardPanelEvent
