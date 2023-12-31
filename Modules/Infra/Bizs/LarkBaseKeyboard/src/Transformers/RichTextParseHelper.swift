//
//  RichTextParseHelper.swift
//  Lark
//
//  Created by qihongye on 2018/2/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import LarkFoundation
import LarkUIKit
import LarkExtensions
import LarkCompatible
import RustPB
import LarkRichTextCore

public typealias RichTextElementProcess = RichTextOptionsType<NSAttributedString>
/// 使用参考LarkTest/Business/Email/EMailParseHelperTest.swift
public struct RichTextParseHelper {
    public enum PropertyWapper {
        case p(RustPB.Basic_V1_RichTextElement.ParagraphProperty)
        case a(RustPB.Basic_V1_RichTextElement.AnchorProperty)
        case text(RustPB.Basic_V1_RichTextElement.TextProperty)
        case img(RustPB.Basic_V1_RichTextElement.ImageProperty)
        case figure(RustPB.Basic_V1_RichTextElement.FigureProperty)
        case codeBlockV2(RustPB.Basic_V1_RichTextElement.CodeBlockV2Property)
        case at(RustPB.Basic_V1_RichTextElement.AtProperty)
        case b(RustPB.Basic_V1_RichTextElement.BoldProperty)
        case i(RustPB.Basic_V1_RichTextElement.ItalicProperty)
        case u(RustPB.Basic_V1_RichTextElement.UnderlineProperty)
        case emotion(RustPB.Basic_V1_RichTextElement.EmotionProperty)
        case link(RustPB.Basic_V1_RichTextElement.LinkProperty)
        case media(RustPB.Basic_V1_RichTextElement.MediaProperty)
        case mention(RustPB.Basic_V1_RichTextElement.MentionProperty)
        case docs(RustPB.Basic_V1_RichTextElement.DocsProperty)
    }

    public typealias RichTextAttrTuple = (tag: RustPB.Basic_V1_RichTextElement.Tag, id: Int32, property: PropertyWapper, style: [RichTextStyleKey: [RichTextStyleValue]]?)

    /// 把属性字符串转成RustPB.Basic_V1_RichText
    ///
    /// - Parameter array: 属性数组
    /// - Returns: RustPB.Basic_V1_RichText树状结构
    public static func convert(array: [(NSRange, [RichTextAttrTuple])]) throws -> RustPB.Basic_V1_RichText {
        let tuples: [[RichTextAttrTuple]] = array.map { $0.1 }
        var rootIds: [String] = []
        var atIds: [String] = []
        var anchorIds: [String] = []
        var imgIds: [String] = []
        var mediaIds: [String] = []
        var mentionIds: [String] = []

        let (elements, relationships) = buildTuplesAndRelationships(tuples: tuples, rootIds: &rootIds, atIds: &atIds, anchorIds: &anchorIds, imgIds: &imgIds, mediaIds: &mediaIds,
                                                                    mentionIds: &mentionIds)

        var richText = RustPB.Basic_V1_RichText()
        richText.elements = buildElements(tuples: elements, relationships: relationships)
        richText.elementIds = rootIds
        richText.anchorIds = anchorIds
        richText.atIds = atIds
        richText.imageIds = imgIds
        richText.mediaIds = mediaIds
        richText.innerText = ""
        return richText
    }

    public static func convert(
        richText: RustPB.Basic_V1_RichText,
        options: [RustPB.Basic_V1_RichTextElement.Tag: RichTextElementProcess] = [:]) throws -> NSAttributedString {
            let result = richText.lc.walker(options: options)
            let targetAttributedString = NSMutableAttributedString(string: "")
            result.forEach { targetAttributedString.append($0) }
            return (targetAttributedString as NSAttributedString).lf.trimmedAttributedString(
                set: CharacterSet.whitespacesAndNewlines,
                position: .trail
            )
        }
}

// MARK: convert(NSAttributedString) -> RustPB.Basic_V1_RichText用
fileprivate extension RichTextParseHelper {
    static func buildTuplesAndRelationships(
        tuples: [[RichTextAttrTuple]],
        rootIds: inout [String],
        atIds: inout [String],
        anchorIds: inout [String],
        imgIds: inout [String],
        mediaIds: inout [String],
        mentionIds: inout [String]
    ) -> (elements: [String: RichTextAttrTuple], relationships: [String: [String]]) {
        var elements: [String: RichTextAttrTuple] = [:]
        var relationships: [String: [String]] = [:]
        rootIds = []
        atIds = []
        anchorIds = []
        imgIds = []
        mediaIds = []
        mentionIds = []

        // 当 root id 变多的时候，提高查找速度
        var rootIdMap: [String: Bool] = [:]

        for tuple in tuples {
            var i = tuple.count
            var parentId: String?
            if i > 0 {
                let id = "\(tuple[i - 1].id)"
                if rootIdMap[id] == nil {
                    rootIds.append(id)
                    rootIdMap[id] = true
                }
            }
            while i > 0 {
                i -= 1
                let attrTuple = tuple[i]
                let id = "\(attrTuple.id)"
                if let baseTuple = elements[id] {
                    elements[id] = mergeRichAttrTuple(baseTuple, attrTuple)
                } else {
                    switch attrTuple.tag {
                    case .a:
                        anchorIds.lf_appendIfNotContains(id)
                    case .img:
                        imgIds.lf_appendIfNotContains(id)
                    case .at:
                        atIds.lf_appendIfNotContains(id)
                    case .media:
                        mediaIds.lf_appendIfNotContains(id)
                    case .mention:
                        mentionIds.lf_appendIfNotContains(id)
                    @unknown default:
                        break
                    }

                    elements[id] = attrTuple
                    if parentId != nil {
                        var childIds = relationships[parentId!] ?? []
                        childIds.lf_appendIfNotContains(id)
                        relationships[parentId!] = childIds
                    }
                }
                parentId = id
            }
        }

        return (elements, relationships)
    }

    static func buildElements(tuples: [String: RichTextAttrTuple], relationships: [String: [String]]) -> [String: RustPB.Basic_V1_RichTextElement] {
        return tuples.reduce([:]) { (result, args) -> [String: RustPB.Basic_V1_RichTextElement] in
            var result = result
            let (key, tuple) = args
            result[key] = createRichTextElement(tuple: tuple, childIds: relationships[key] ?? [])
            return result
        }
    }

    static func mergeRichAttrTuple(_ base: RichTextAttrTuple, _ tuple: RichTextAttrTuple) -> RichTextAttrTuple {
        switch (base.property, tuple.property) {
        case (.text(var baseProperty), .text(let mergedProperty)):
            baseProperty.content = mergedProperty.content
            return (base.tag, base.id, .text(baseProperty), base.style)
        case (.u(var baseProperty), .u(let mergedProperty)):
            baseProperty.content = mergedProperty.content
            return (base.tag, base.id, .u(baseProperty), base.style)
        case (.i(var baseProperty), .i(let mergedProperty)):
            baseProperty.content = mergedProperty.content
            return (base.tag, base.id, .i(baseProperty), base.style)
        case (.b(var baseProperty), .b(let mergedProperty)):
            baseProperty.content = mergedProperty.content
            return (base.tag, base.id, .b(baseProperty), base.style)
        case (.a(var baseProperty), .a(let mergedProperty)):
            baseProperty.href = mergedProperty.href
            baseProperty.content = mergedProperty.content
            return (base.tag, base.id, .a(baseProperty), base.style)
        case (.at(var baseProperty), .at(let mergedPropery)):
            baseProperty.content = mergedPropery.content
            return (base.tag, base.id, .at(baseProperty), base.style)
        case (.emotion(var baseProperty), .emotion(let mergedPropery)):
            baseProperty.key = mergedPropery.key
            return (base.tag, base.id, .emotion(baseProperty), base.style)
        case (.codeBlockV2(var baseProperty), .codeBlockV2(let mergedPropery)):
            baseProperty.contents = mergedPropery.contents
            return (base.tag, base.id, .codeBlockV2(baseProperty), base.style)
        case (.mention(var baseProperty), .mention(let mergedPropery)):
            baseProperty.content = mergedPropery.content
            return (base.tag, base.id, .mention(baseProperty), base.style)
        default:
            break
        }

        return base
    }

    static func createRichTextElement(tuple: RichTextAttrTuple, childIds: [String]) -> RustPB.Basic_V1_RichTextElement {
        var element = RustPB.Basic_V1_RichTextElement()
        var propertySet = RustPB.Basic_V1_RichTextElement.PropertySet()
        element.tag = tuple.tag
        /// 设置标签的style
        if let style = transformRichTextStyleInfo(tuple.style) {
            element.style = style
        }
        switch tuple.property {
        case .a(let property):
            propertySet.anchor = property
            element.property = propertySet
            element.childIds = childIds
        case .at(let property):
            propertySet.at = property
            element.property = propertySet
        case .p(let property):
            propertySet.paragraph = property
            element.property = propertySet
            element.childIds = childIds
        case .figure(let property):
            propertySet.figure = property
            element.property = propertySet
            element.childIds = childIds
        case .img(let property):
            propertySet.image = property
            element.property = propertySet
        case .codeBlockV2(let property):
            propertySet.codeBlockV2 = property
            element.property = propertySet
        case .b(let property):
            propertySet.bold = property
            element.property = propertySet
            element.childIds = childIds
        case .i(let property):
            propertySet.italic = property
            element.property = propertySet
            element.childIds = childIds
        case .u(let property):
            propertySet.underline = property
            element.property = propertySet
            element.childIds = childIds
        case .text(let property):
            propertySet.text = property
            element.property = propertySet
        case .emotion(let property):
            propertySet.emotion = property
            element.property = propertySet
        case .link(let property):
            propertySet.link = property
            element.property = propertySet
            element.childIds = childIds
        case .media(let property):
            propertySet.media = property
            element.property = propertySet
        case .mention(let property):
            propertySet.mention = property
            element.property = propertySet
        case .docs(let property):
            propertySet.docs = property
            element.property = propertySet
            element.childIds = childIds
        }
        return element
    }
}
/// style转化和解析逻辑
extension RichTextParseHelper {
    static func transformRichTextStyleInfo(_ info: [RichTextStyleKey: [RichTextStyleValue]]?) -> [String: String]? {
        guard let info = info, !info.isEmpty else {
            return nil
        }
        var style: [String: String] = [:]
        info.forEach { (key: RichTextStyleKey, value: [RichTextStyleValue]) in
            style[key.rawValue] = value.map({ $0.rawValue }).joined(separator: " ")
        }
        return style
    }

    static func transformStyleToAttributes(_ style: [String: String], font: UIFont?) -> [NSAttributedString.Key: Any]? {
        if style.isEmpty {
            return nil
        }
        var attributes: [NSAttributedString.Key: Any] = [:]
        let textDecoration = style[RichTextStyleKey.textDecoration.rawValue]
        if let decorations = textDecoration?.components(separatedBy: " "), !decorations.isEmpty {
            if decorations.contains(RichTextStyleValue.underline.rawValue) {
                attributes[.underlineStyle] = FontStyleConfig.underlineStyle
                attributes[FontStyleConfig.underlineAttributedKey] = FontStyleConfig.underlineAttributedValue
            }
            if decorations.contains(RichTextStyleValue.lineThrough.rawValue) {
                attributes[.strikethroughStyle] = FontStyleConfig.strikethroughStyle
                attributes[FontStyleConfig.strikethroughAttributedKey] = FontStyleConfig.strikethroughAttributedValue
            }
        }
        guard let font = font else {
            return attributes
        }
        var isBold = false
        if let fontWeight = style[RichTextStyleKey.fontWeight.rawValue],
           fontWeight == RichTextStyleValue.bold.rawValue {
            isBold = true
        }
        var isItalic = false
        if let fontStyle = style[RichTextStyleKey.fontStyle.rawValue],
           fontStyle == RichTextStyleValue.italic.rawValue {
            isItalic = true
        }
        if isBold, isItalic {
            attributes[.font] = font.boldItalic
            attributes[FontStyleConfig.italicAttributedKey] = FontStyleConfig.italicAttributedValue
            attributes[FontStyleConfig.boldAttributedKey] = FontStyleConfig.boldAttributedValue
        } else if isItalic {
            attributes[.font] = font.italic
            attributes[FontStyleConfig.italicAttributedKey] = FontStyleConfig.italicAttributedValue
        } else if isBold {
            attributes[.font] = font.medium
            attributes[FontStyleConfig.boldAttributedKey] = FontStyleConfig.boldAttributedValue
        }
        return attributes.isEmpty ? nil : attributes
    }
}
