//
//  RichTextConvertOptions.swift
//  Pods
//
//  Created by lichen on 2018/11/16.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import EditTextView
import LarkEmotion
import RustPB
import LarkRichTextCore

public typealias ElementProcessProvider = [RustPB.Basic_V1_RichTextElement.Tag: RichTextElementProcess]

public protocol RichTextTransformProtocol: AnyObject {
    // richtext 转化 编辑显示的 属性字符串
    func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                               attachmentResult: [String: String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]?
    // richtext 转化 降级的属性字符串
    func downgradeTransformFromRichText(attributes: [NSAttributedString.Key: Any],
                               attachmentResult: [String: String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]?

    // 编辑显示的 属性字符串转化为 richText
    func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr]

    // richText 转化为显示使用的纯字符串
    func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]?
    // 编辑框保存个性签名时预处理属性字符串
    func preproccessDescriptionAttributedStr(_ text: NSAttributedString) -> NSAttributedString
    // 发送消息时预处理属性字符串
    func preproccessSendAttributedStr(_ text: NSAttributedString) -> NSAttributedString
    /// 获取NSAttributedString里面的 style: b,i,下划线，删除线
    func styleForAttributedStr(_ text: NSAttributedString, fromLocation: Int) -> [RichTextStyleKey: [RichTextStyleValue]]?
    /// 在一段文字中 被选中的部分是否支持字体样式
    func filterUnsupportStyleRangeFor(text: NSAttributedString) -> [NSRange]

    func uniqueIdentifier() -> String
}

public extension RichTextTransformProtocol {
    func preproccessSendAttributedStr(_ text: NSAttributedString) -> NSAttributedString {
        return text
    }

    func preproccessDescriptionAttributedStr(_ text: NSAttributedString) -> NSAttributedString {
        return text
    }

    func styleForAttributedStr(_ text: NSAttributedString, fromLocation: Int) -> [RichTextStyleKey: [RichTextStyleValue]]? {
        guard text.length > fromLocation else {
            return nil
        }
        var style: [RichTextStyleKey: [RichTextStyleValue]] = [:]
        // 这里只取第一个的字符的样式  来判断是否符合
        text.enumerateAttributes(in: NSRange(location: fromLocation, length: 1), options: []) { (attributes, _, _) in
            if attributes[FontStyleConfig.boldAttributedKey] != nil {
                style[.fontWeight] = [.bold]
            }

            if attributes[FontStyleConfig.italicAttributedKey] != nil {
                style[.fontStyle] = [.italic]
            }

            if attributes[FontStyleConfig.underlineAttributedKey] != nil, attributes[FontStyleConfig.strikethroughAttributedKey] != nil {
                style[.textDecoration] = [.lineThrough, .underline]
            } else {
                if attributes[FontStyleConfig.strikethroughAttributedKey] != nil {
                    style[.textDecoration] = [.lineThrough]
                } else if attributes[FontStyleConfig.underlineAttributedKey] != nil {
                    style[.textDecoration] = [.underline]
                }
            }
        }
        return style.isEmpty ? nil : style
    }

    func filterUnsupportStyleRangeFor(text: NSAttributedString) -> [NSRange] {
        return []
    }

    func uniqueIdentifier() -> String {
        return NSStringFromClass(Self.self)
    }
}

public final class RichTextTransformKit {

    /// 用于判断是否和现有的富文本结点冲突
    /// 举例：doc预览节点不应该被纠错
    public static let digOutRichTextNode: Set<NSAttributedString.Key> = [
        AtTransformer.UserIdAttributedKey,
        LinkTransformer.LinkAttributedKey,
        AnchorTransformer.AnchorAttributedKey,
        CodeTransformer.editCodeKey,
        MentionTransformer.mentionAttributedKey,
        EmotionTransformer.EmojiAttributedKey
    ]
    public static let transformer: [RichTextTransformProtocol] = [
        ParagraphDocsTransformer(),
        HeadTransformer(),
        TextTransformer(),
        ImageTransformer(),
        FigureTransformer(),
        AtTransformer(),
        AnchorTransformer(),
        FontTransformer(),
        EmotionTransformer(),
        CodeTransformer(),
        LinkTransformer(),
//        UnderLineTransformer(),
        VideoTransformer(),
        MentionTransformer(),
        ListTransformer(),
        QuoteTransformer()
    ]

    public static func transformRichTextToStr(
        richText: RustPB.Basic_V1_RichText,
        attributes: [NSAttributedString.Key: Any],
        attachmentResult: [String: String],
        processProvider: ElementProcessProvider = [:]) -> NSAttributedString {

        let options = RichTextTransformKit.richTextConvertOptions(attributes: attributes,
                                                                  attachmentResult: attachmentResult,
                                                                  processProvider: processProvider)
        let content: NSAttributedString
        do {
            content = try RichTextParseHelper.convert(richText: richText, options: options)
        } catch {
            content = NSAttributedString()
        }
        return content
    }

    public static func transformRichTextToStrWithoutDowngrade(
        richText: RustPB.Basic_V1_RichText,
        attributes: [NSAttributedString.Key: Any],
        attachmentResult: [String: String],
        supportTypes: [String],
        processProvider: ElementProcessProvider = [:]) -> NSAttributedString {

        let options = RichTextTransformKit.richTextConvertOptions(attributes: attributes,
                                                                  attachmentResult: attachmentResult,
                                                                  processProvider: processProvider,
                                                                  supportTypes: supportTypes)
        let content: NSAttributedString
        do {
            content = try RichTextParseHelper.convert(richText: richText, options: options)
        } catch {
            content = NSAttributedString()
        }
        return content
    }

    public static func transformStringToRichText(string: NSAttributedString) -> RustPB.Basic_V1_RichText? {

        let attributed = TextTransformer.removeWhitespacesAndNewlines(string)

        var results: [RichTextFragmentAttr] = []
        self.transformer.forEach { (item) in
            results = merge(results, item.transformToRichText(attributed))
        }
        results = sortAndDeleteRepetition(results)

        #if DEBUG
        self.checkoutResultValidity(results: results)
        #endif

        let richTextTuples = results.map { (fragment) -> (NSRange, [RichTextParseHelper.RichTextAttrTuple]) in
            return (fragment.range, fragment.attrs.map { $0.tuple })
        }

        let content: RustPB.Basic_V1_RichText?
        do {
            content = try RichTextParseHelper.convert(array: richTextTuples)
        } catch {
            content = nil
        }
        return content
    }

    /// processProvider优先级更高
    public static func richTextConvertOptions(attributes: [NSAttributedString.Key: Any],
                                              attachmentResult: [String: String],
                                              processProvider: ElementProcessProvider,
                                              supportTypes: [String]? = nil) -> [RustPB.Basic_V1_RichTextElement.Tag: RichTextElementProcess] {
        var options: [RustPB.Basic_V1_RichTextElement.Tag: RichTextElementProcess] = [:]
        self.transformer.forEach { (transformer) in
            var downgrade = false
            if  let supportTypes = supportTypes,
                !supportTypes.contains(transformer.uniqueIdentifier()) {
                downgrade = true
            }
            let block: (([(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]?) -> Void) = { info in
                if let info = info {
                    info.forEach({ (tag, defaultProcess) in
                        if let process = processProvider[tag] {
                            let newProcess: RichTextElementProcess = { option -> [NSAttributedString] in
                                let attr = process(option)
                                // 若processProvider提供的attr为空，走内置process
                                return attr.isEmpty ? defaultProcess(option) : attr
                            }
                            options[tag] = newProcess
                        } else {
                            options[tag] = defaultProcess
                        }
                    })
                }
            }
            var info: [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]?
            if !downgrade {
                info = transformer.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult)
            } else {
                info = transformer.downgradeTransformFromRichText(attributes: attributes, attachmentResult: attachmentResult)
            }
            block(info)
        }
        return options
    }

    public static func transformDraftToText(content: String) -> String? {
        guard let richText = try? RustPB.Basic_V1_RichText(jsonString: content) else {
            return nil
        }
        return self.transformRichTexToText(richText)
    }

    public static func transformRichTexToText(_ richText: RustPB.Basic_V1_RichText?) -> String? {
        guard let richText = richText else {
            return nil
        }
        let options = RichTextTransformKit.richTextToTextConvertOptions()
        let attributedStr: NSAttributedString
        do {
            attributedStr = try RichTextParseHelper.convert(richText: richText, options: options)
        } catch {
            attributedStr = NSAttributedString()
        }
        return attributedStr.string
    }

    public static func preproccessSendAttributedStr(_ text: NSAttributedString) -> NSAttributedString {
        var attributedStr = text
        self.transformer.forEach { (transformer) in
            attributedStr = transformer.preproccessSendAttributedStr(attributedStr)
        }
        return attributedStr
    }

    public static func preproccessDescriptionAttributedStr(_ text: NSAttributedString) -> NSAttributedString {
        var attributedStr = text
        self.transformer.forEach { (transformer) in
            attributedStr = transformer.preproccessDescriptionAttributedStr(attributedStr)
        }
        return attributedStr
    }

    public static func richTextToTextConvertOptions() -> [RustPB.Basic_V1_RichTextElement.Tag: RichTextElementProcess] {
        var options: [RustPB.Basic_V1_RichTextElement.Tag: RichTextElementProcess] = [:]
        self.transformer.forEach { (transformer) in
            if let info = transformer.transformToTextFromRichText() {
                info.forEach({ (tag, process) in
                    options[tag] = process
                })
            }
        }
        return options
    }

    private static func checkoutRangeValidity(results: [RichTextFragmentAttr]) {
        var lastRange: NSRange?
        results.forEach { (result) in
            // 检测 range 不能有交集
            if let lastRange = lastRange {
                assert(lastRange.location + lastRange.length <= result.range.location, "NSRange 有重合的地方")
            }
            lastRange = result.range
        }
    }

    private static func checkoutResultValidity(results: [RichTextFragmentAttr]) {
        self.checkoutRangeValidity(results: results)
        results.forEach { (result) in
            // 检测 result 排序， 且只有一个 content
            var hasContent: Bool = false
            var lastPriority = RichTextAttrPriority(rawValue: UInt.min)!
            result.attrs.forEach({ (attr) in
                assert(attr.priority.rawValue >= lastPriority.rawValue, "attr 排序错误")
                if attr.priority.rawValue <= RichTextAttrPriority.content.rawValue {
                    assert(hasContent == false, "拥有多个 content 级别的")
                    hasContent = true
                }
                lastPriority = attr.priority
            })

        }
    }

    private static func sortAndDeleteRepetition(_ result: [RichTextFragmentAttr]) -> [RichTextFragmentAttr] {
        return result.map({ (fragment) -> RichTextFragmentAttr in
            var hasContent = false
            let attrs: [RichTextAttr]  = fragment.attrs
                .sorted(by: { $0.priority.rawValue > $1.priority.rawValue }) // 按照优先级排序
                .filter({ (attr) -> Bool in // 只保留一个 content 级别的内容
                    if attr.priority.rawValue <= RichTextAttrPriority.content.rawValue {
                        if hasContent { return false }
                        hasContent = true
                    }
                    return true
                })
                .reversed() // 数据需要翻转，嵌套关系为数组前面的元素为后面元素的子元素
            return RichTextFragmentAttr(fragment.range, attrs)
        })
    }

    private enum MergeLastFrom {
        case first, second, unkonwn
    }

    private static func merge(_ first: [RichTextFragmentAttr], _ second: [RichTextFragmentAttr]) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []

        // 排序， range 从小到大
        var first = first.sorted(by: { $0.range.location < $1.range.location })
        var second = second.sorted(by: { $0.range.location < $1.range.location })

        #if DEBUG
        self.checkoutRangeValidity(results: first)
        self.checkoutRangeValidity(results: second)
        #endif

        var lastFrom: MergeLastFrom = .unkonwn

        while !first.isEmpty || !second.isEmpty {
            if first.isEmpty && lastFrom == .second {
                result.append(contentsOf: second)
                second.removeAll()
                break
            }
            if second.isEmpty && lastFrom == .first {
                result.append(contentsOf: first)
                first.removeAll()
                lastFrom = .first
                break
            }

            var insert: RichTextFragmentAttr?
            var insertFrom: MergeLastFrom = .unkonwn
            var isMerge = false
            if second.isEmpty, let itemFromFirst = first.first {
                insert = itemFromFirst
                insertFrom = .first
            } else if first.isEmpty, let itemFromSecond = second.first {
                insert = itemFromSecond
                insertFrom = .second
            } else if let itemFromFirst = first.first, let itemFromSecond = second.first {
                if itemFromFirst.range.location > itemFromSecond.range.location {
                    insert = itemFromSecond
                    insertFrom = .second
                } else {
                    insert = itemFromFirst
                    insertFrom = .first
                }
            }
            guard let insertItem = insert else { break }

            let deferBlock = {
                lastFrom = isMerge ? .unkonwn : insertFrom
                if insertFrom == .first {
                    first.removeFirst(1)
                } else if insertFrom == .second {
                    second.removeFirst(1)
                }
            }

            guard let lastItem = result.last else {
                // 第一次插入数据
                result.append(insertItem)
                deferBlock()
                continue
            }

            if lastFrom == insertFrom {
                // 如果与上次插入来源相同 则直接插入
                result.append(insertItem)
            } else {
                let mergeItems = merge(lastItem, insertItem)
                result.removeLast(1)
                result.append(contentsOf: mergeItems)
                isMerge = true
            }
            deferBlock()
        }

        return result
    }

    private static func merge(_ first: RichTextFragmentAttr, _ second: RichTextFragmentAttr) -> [RichTextFragmentAttr] {

        // 判断是否有交集 没有交集直接返回
        if first.range.location >= second.range.location + second.range.length {
            return [second, first]
        } else if second.range.location >= first.range.location + first.range.length {
            return [first, second]
        }

        var results: [RichTextFragmentAttr] = []
        var range1: NSRange?
        var range2: NSRange?
        var range3: NSRange?

        if first.range.location < second.range.location,
            first.range.location + first.range.length > second.range.location,
            first.range.location + first.range.length < second.range.location + second.range.length {
            // first 与 second 有交集，且 first 在前面
            range1 = NSRange(location: first.range.location, length: second.range.location - first.range.location)
            range2 = NSRange(location: second.range.location, length: first.range.location + first.range.length - second.range.location)
            range3 = NSRange(location: first.range.location + first.range.length, length: second.range.location + second.range.length - first.range.location - first.range.length)
        } else if second.range.location < first.range.location,
            second.range.location + second.range.length > first.range.location,
            second.range.location + second.range.length < first.range.location + first.range.length {
            // first 与 second 有交集，且 second 在前面
            range1 = NSRange(location: second.range.location, length: first.range.location - second.range.location)
            range2 = NSRange(location: first.range.location, length: second.range.location + second.range.length - first.range.location)
            range3 = NSRange(location: second.range.location + second.range.length, length: first.range.location + first.range.length - second.range.location - second.range.length)
        } else if first.range.location <= second.range.location && first.range.location + first.range.length >= second.range.location + second.range.length {
            // second 为 first 的子集
            range1 = NSRange(location: first.range.location, length: second.range.location - first.range.location)
            range2 = second.range
            range3 = NSRange(location: second.range.location + second.range.length, length: first.range.location + first.range.length - second.range.location - second.range.length)
        } else if first.range.location >= second.range.location && first.range.location + first.range.length <= second.range.location + second.range.length {
            // first 为 second 的子集
            range1 = NSRange(location: second.range.location, length: first.range.location - second.range.location)
            range2 = first.range
            range3 = NSRange(location: first.range.location + first.range.length, length: second.range.location + second.range.length - first.range.location - first.range.length)
        }

        let handler = { (range: NSRange) in
            let result = first.attrs.compactMap { $0.split(range: range, origin: first.range) } + second.attrs.compactMap { $0.split(range: range, origin: second.range) }
            results.append(RichTextFragmentAttr(range, result))
        }

        if let range = range1, range.length != 0 { handler(range) }
        if let range = range2, range.length != 0 { handler(range) }
        if let range = range3, range.length != 0 { handler(range) }

        return results
    }
}
