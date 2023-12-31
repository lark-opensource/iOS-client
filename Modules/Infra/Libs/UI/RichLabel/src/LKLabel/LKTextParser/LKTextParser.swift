//
//  LKTextParser.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/11/28.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// 一组连续的相同属性的字符集
public struct LKTextCharacterGroup {
    /// 对应原始的字符串的range，以NSAttributedString Range为标准
    var originRange: NSRange
    var attributes: [NSAttributedString.Key: Any]

    public init(range: NSRange, attributes: [NSAttributedString.Key: Any] = [:]) {
        self.originRange = range
        self.attributes = attributes
    }
}

public protocol LKTextParser {
    var defaultFont: UIFont { get set }
    var originAttrString: NSAttributedString? { get set }
    var renderAttrString: NSMutableAttributedString? { get }
    var parserIndicesToOriginIndices: [CFIndex] { get set }
    func getOriginIndex(from parserIndex: CFIndex) -> CFIndex
    func getParserIndex(from originIndex: CFIndex) -> CFIndex
    func parserRangeToOriginRange(_ parserRange: NSRange, length: Int) -> NSRange
    func parse()
    func clone() -> LKTextParser
}

public extension LKTextParser {
    func parserRangeToOriginRange(_ parserRange: NSRange, length: Int) -> NSRange {
        /*
         检测lowerBound是否处在合并占位符中，如果是则需要调整为占位符对应的原始字符串最左侧下标，
         一个原始字符串为"hello@ly"，假设"@ly"会处理成占位符"x"，此时得到处理后的字符串"hellox"，
         indices = [0,1,2,3,4,7]。
         因为length = upperBound - lowerBound，故upperBound表示range最右侧有效下标+1。
         假设调用方parserRange传(5,1)，预期originLowerBound应为5，originUpperBound应为8，对应原始字符串"@ly"。
         */
        var originLowerBound = parserRange.lowerBound
        if originLowerBound > 0 {
            // 7
            originLowerBound = self.getOriginIndex(from: originLowerBound)
            // 4
            let prevIndex = self.getOriginIndex(from: parserRange.lowerBound - 1)
            // 7 - 4 > 1，说明lowerBound在占位符中，lowerBound应调整为5
            if originLowerBound - prevIndex > 1 {
                originLowerBound = prevIndex + 1
            }
        }
        /*
         因parserRange.upperBound=6，故正确的parserRange最右侧有效下标为5，
         得到原始字符串最右侧有效下标index=getOriginIndex(from: parserRange.upperBound - 1)=7，还需要对结果进行+1得到upperBound
         */
        var originUpperBound = self.getOriginIndex(from: parserRange.upperBound - 1) + 1
        // 如果parserUpperBound >= 可选择的长度，表明是从lowerBound全选后面的内容，故设置upperBound为length即可
        if parserRange.upperBound >= length { originUpperBound = length }
        return NSRange(location: originLowerBound, length: originUpperBound - originLowerBound)
    }
}

public protocol LKTextParserIndices {
    var parserIndicesToOriginIndices: [CFIndex] { get set }
    func getOriginIndex(from parserIndex: CFIndex) -> CFIndex
    func getParserIndex(from originIndex: CFIndex) -> CFIndex
}

public extension LKTextParserIndices {
    func getOriginIndex(from parserIndex: CFIndex) -> CFIndex {
        guard !self.parserIndicesToOriginIndices.isEmpty, parserIndex != kCFNotFound else {
            return kCFNotFound
        }
        var parserIndex = max(0, parserIndex)
        parserIndex = min(self.parserIndicesToOriginIndices.count - 1, parserIndex)

        return self.parserIndicesToOriginIndices[parserIndex]
    }

    func getParserIndex(from originIndex: CFIndex) -> CFIndex {
        if self.parserIndicesToOriginIndices.isEmpty { return kCFNotFound }

        // 传入的index比最大的都大，返回最后
        if originIndex > self.parserIndicesToOriginIndices.last! { return self.parserIndicesToOriginIndices.count - 1 }
        // 传入的index比最小的都小，返回最前
        if originIndex < self.parserIndicesToOriginIndices.first! { return 0 }
        // 传入的index肯定存在数组值范围中，lf_bsearch：从数组中找到小于等于目标值的位置
        let (start, _) = self.parserIndicesToOriginIndices.lf_bsearch(originIndex, comparable: { $0 - $1 })
        guard start > -1 else { return kCFNotFound }

        // 如果找到的index不是传入的index，则说明传的index在一个占位符中，start需要做+1处理
        if self.parserIndicesToOriginIndices[start] != originIndex {
            return start + 1
        }
        return start
    }
}

public struct LKCharacterAttrsCommit {
    var range: NSRange
    var updateAttrs: [NSAttributedString.Key: Any]
    var removeAttrs: [NSAttributedString.Key]
}

public struct LKCharacterReplaceWithRunDelegateCommit {
    var range: NSRange
    // swiftlint:disable:next weak_delegate
    var runDelegate: CTRunDelegate
    var updateAttrs: [NSAttributedString.Key: Any]
}

public struct LKTextParserContext {
    var defaultFont: UIFont
}

public protocol LKCharacterParser: AnyObject {
    var inputCharacterGroups: [LKTextCharacterGroup] { get set }
    func filter(character: LKTextCharacterGroup) -> Bool
    func parse(attributedString: NSAttributedString, context: LKTextParserContext)
    func attributesCommit() -> [LKCharacterAttrsCommit]
    func repalceCommit() -> [LKCharacterReplaceWithRunDelegateCommit]
}

open class LKTextParserImpl: LKTextParser, LKTextParserIndices {
    public var isOpenTooLongEmoticonBugFix = true

    public var originAttrString: NSAttributedString? {
        didSet {
            if let attrString = originAttrString {
                // swiftlint:disable:next force_cast
                self.renderAttrString = NSMutableAttributedString(attributedString: attrString.copy() as! NSAttributedString)
                self.indicesMerged = [Bool](repeating: false, count: attrString.length)
                self.specialCharacterRanges = AttributedStringUnicodeScalarRanges(attrString: attrString)
            } else {
                self.characterGroups = []
                self.indicesMerged = []
                self.renderAttrString = nil
            }
        }
    }

    public private(set) var characterGroups: [LKTextCharacterGroup] = []

    public var renderAttrString: NSMutableAttributedString?

    public var parserIndicesToOriginIndices: [CFIndex] = []

    public var defaultFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) {
        didSet {
            self.context.defaultFont = defaultFont
        }
    }

    var characterParsers: [LKCharacterParser]

    var indicesMerged: [Bool] = []
    // some special character ranges, like 1⃣️, it's length is 3.
    var specialCharacterRanges: [NSRange] = []

    var attrsUppdateQueue: [LKCharacterAttrsCommit] = []
    var replaceWithRunDelegateQueue: [LKCharacterReplaceWithRunDelegateCommit] = []
    private var context: LKTextParserContext

    public init() {
        self.context = LKTextParserContext(defaultFont: self.defaultFont)
        self.characterParsers = [
            ItalicCharacterParser(),
            AtCharacterParser(),
            PointCharacterParser(),
            EmojiCharacterParser(),
            AttachmentCharacterParser(),
            CharacterKernParser()
        ]
    }

    public func parse() {
        guard let renderAttrString = self.renderAttrString else {
            return
        }

        self.initCharacterAttributes()
        self.runParsers(renderAttrString)
        self.execCommits()
        if #available(iOS 13.0, *), isOpenTooLongEmoticonBugFix {
            self.processTooLongBug()
        }
    }

    func initCharacterAttributes() {
        guard let renderAttrString = self.renderAttrString else {
            return
        }
        let wholeRange = NSRange(location: 0, length: renderAttrString.length)

        self.characterGroups = []
        self.parserIndicesToOriginIndices = wholeRange.toArray()
        renderAttrString.enumerateAttributes(in: wholeRange, options: .longestEffectiveRangeNotRequired) { (attrs, range, _) in
            self.characterGroups.append(LKTextCharacterGroup(range: range, attributes: attrs))
        }

        self.fixWrongCharacterRange()
    }

    func runParsers(_ renderAttrString: NSMutableAttributedString) {
        for parser in self.characterParsers {
            parser.inputCharacterGroups = []
        }

        for charGroup in self.characterGroups {
            for parser in self.characterParsers where parser.filter(character: charGroup) {
                parser.inputCharacterGroups.append(charGroup)
            }
        }

        for parser in self.characterParsers {
            parser.parse(attributedString: renderAttrString, context: self.context)
            attrsUppdateQueue.append(contentsOf: parser.attributesCommit())

            // RunDelegaetCommit have to repalce a series of characters, so it would only come into effect when it not be merged.
            let commits = parser.repalceCommit()
            for commit in commits where !self.isIndicesMerged(commit.range) {
                self.markOriginIndicessMerged(commit.range)
                replaceWithRunDelegateQueue.append(commit)
            }
        }
    }

    func execCommits() {
        guard let renderAttrString = self.renderAttrString else {
            return
        }
        for attrUpdate in self.attrsUppdateQueue {
            if !attrUpdate.removeAttrs.isEmpty {
                for k in attrUpdate.removeAttrs {
                    renderAttrString.removeAttribute(k, range: attrUpdate.range)
                }
            }
            renderAttrString.addAttributes(attrUpdate.updateAttrs, range: attrUpdate.range)
        }
        self.attrsUppdateQueue = []

        self.replaceWithRunDelegateQueue.sort(by: { $0.range.location < $1.range.location })
        while let replaceCommit = self.replaceWithRunDelegateQueue.popLast(), replaceCommit.range.length > 0 {
            let substr = renderAttrString.attributedSubstring(from: replaceCommit.range)
            let placeHolder = NSMutableAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: replaceCommit.updateAttrs)
            let range = NSRange(location: 0, length: placeHolder.length)
            placeHolder.addAttribute(LKAtStrAttributeName, value: substr, range: range)
            placeHolder.addAttribute(CTRunDelegateAttributeName, value: replaceCommit.runDelegate, range: range)
            renderAttrString.replaceCharacters(in: replaceCommit.range, with: placeHolder)
            self.parserIndicesToOriginIndices.replaceSubrange(
                Range<Int>(uncheckedBounds: (lower: replaceCommit.range.lowerBound, upper: replaceCommit.range.upperBound)),
                with: [replaceCommit.range.upperBound - 1]
            )
        }
    }

    func isIndicesMerged(_ range: NSRange) -> Bool {
        return self.indicesMerged[range.lowerBound] || self.indicesMerged[range.upperBound - 1]
    }

    func markOriginIndicessMerged(_ range: NSRange) {
        for i in range.lowerBound..<range.upperBound {
            self.indicesMerged[i] = true
        }
    }

    func processTooLongBug() {
        self.renderAttrString?.append(NSAttributedString(string: " "))
        if !self.parserIndicesToOriginIndices.isEmpty {
         self.parserIndicesToOriginIndices.append(self.parserIndicesToOriginIndices.last!)
        }
    }

    /// fix错误的CharacterGroup分组
    private func fixWrongCharacterRange() {
        guard !self.specialCharacterRanges.isEmpty, !self.characterGroups.isEmpty else {
            return
        }
        var splits = self.characterGroups.map({ $0.originRange.location })
        splits.append(self.characterGroups.last!.originRange.upperBound)
        while let specialCharRange = self.specialCharacterRanges.popLast() {
            // 找到特殊字符在当前的第几个分组
            var (start, end) = splits.lf_bsearch(specialCharRange.location, comparable: { $0 - $1 })
            // 判断特殊字符的range是否被拆开的算法：在特殊字符的range内是否插入了split。如：[]表示特殊字符range，|..[.|.]..|
            if end >= splits.count || splits[start + 1] >= specialCharRange.upperBound {
                continue
            }
            // 找到被截断的后面一个characterGroup
            for i in end..<splits.count where splits[i] >= specialCharRange.upperBound {
                end = i
                break
            }
            var attrs = self.characterGroups[start].attributes
            for i in (start + 1)..<end {
                attrs.merge(self.characterGroups[i].attributes, uniquingKeysWith: { $1 })
            }
            var replaceRanges: [LKTextCharacterGroup] = []
            let length = specialCharRange.lowerBound - self.characterGroups[start].originRange.lowerBound
            if length > 0 {
                let range = NSRange(location: self.characterGroups[start].originRange.location, length: length)
                replaceRanges.append(LKTextCharacterGroup(
                    range: range,
                    attributes: self.characterGroups[start].attributes
                ))
            }
            replaceRanges.append(LKTextCharacterGroup(range: specialCharRange, attributes: attrs))
            if end < self.characterGroups.count,
                self.characterGroups[end].originRange.location > specialCharRange.upperBound {
                let range = NSRange(location: specialCharRange.upperBound, length: self.characterGroups[end].originRange.location - specialCharRange.upperBound)
                replaceRanges.append(LKTextCharacterGroup(
                    range: range,
                    attributes: self.characterGroups[end - 1].attributes
                ))
            }
            self.characterGroups.replaceSubrange(start..<end, with: replaceRanges)
        }
    }

    public func clone() -> LKTextParser {
        let textParser = LKTextParserImpl()
        textParser.defaultFont = UIFont.systemFont(ofSize: self.defaultFont.pointSize)
        if let str = self.originAttrString {
            /// include renderAttrString init，so need to copy first
            textParser.originAttrString = NSAttributedString(attributedString: str)
        }
        textParser.characterGroups = self.characterGroups
        if let str = self.renderAttrString {
            textParser.renderAttrString = NSMutableAttributedString(attributedString: str)
        }
        textParser.parserIndicesToOriginIndices = self.parserIndicesToOriginIndices
        textParser.characterParsers = self.characterParsers
        textParser.indicesMerged = self.indicesMerged
        textParser.specialCharacterRanges = self.specialCharacterRanges
        // note：attrsUppdateQueue、replaceWithRunDelegateQueue no need copy，they will be emptied when parse() finished
        return textParser
    }
}

final public class LKLinkParserImpl: LKTextParser, LKTextParserIndices {

    public var defaultFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    public var tapableRangeList: [NSRange] = []

    public var rangeLinkMapper: [NSRange: URL]?

    public var linkAttributes: [NSAttributedString.Key: Any]

    public var parserIndicesToOriginIndices: [CFIndex] = []

    public var hyperLinkList: [LKTextLink]?

    // 指定文本链接映射关系
    public var hyperlinkMapper: [String: URL]?

    public var textLinkList: [LKTextLink] = []

    public var originAttrString: NSAttributedString? {
        didSet {
            parserIndicesToOriginIndices = []
            if let attrStr = originAttrString {
                self.renderAttrString = NSMutableAttributedString(attributedString: attrStr)
            } else {
                self.renderAttrString = nil
            }
        }
    }

    public var characters: [LKTextCharacterGroup] = []

    public var renderAttrString: NSMutableAttributedString?

    public init(linkAttributes: [NSAttributedString.Key: Any]) {
        self.linkAttributes = linkAttributes
    }

    public func parse() {
        guard let renderAttrString = self.renderAttrString else {
            return
        }
        // reset
        self.hyperLinkList = nil

        self.processRangeLinkStyle(renderAttrString, urlRangeMap: self.rangeLinkMapper)
        self.processLinkStyle(renderAttrString, links: self.textLinkList)
        self.processHyperlinkStyle(renderAttrString, links: self.hyperlinkMapper)
    }

    public func findCharacterIndex(from attrStrIdx: CFIndex) -> CFIndex {
        return kCFNotFound
    }

    func processRangeLinkStyle(_ attrText: NSMutableAttributedString, urlRangeMap: [NSRange: URL]?) {
        guard let linkMap = urlRangeMap else {
            return
        }

        var hyperLinks = self.hyperLinkList ?? []

        for (range, url) in linkMap {
            if let parserRange = originRangeToParserRange(range),
                parserRange.location >= 0 && parserRange.location + parserRange.length <= attrText.length {
                var lkLink = LKTextLink(range: range, type: .link)
                lkLink.url = url
                attrText.addAttributes(self.linkAttributes, range: parserRange)
                if hyperLinks.contains(lkLink) == true {
                    continue
                }
                hyperLinks.append(lkLink)
            }
        }
        self.hyperLinkList = hyperLinks
    }

    // 给链接增加样式
    func processLinkStyle(_ attributedText: NSMutableAttributedString, links: [LKTextLink]?) {
        guard let linkList = links else {
            return
        }

        for result in linkList {
            if let range = originRangeToParserRange(result.range),
                range.location >= 0
                && range.location + range.length <= attributedText.length {
                attributedText.addAttributes(result.attributes ?? self.linkAttributes, range: range)
            }
        }
    }

    // 给指定链接的文本添加样式
    func processHyperlinkStyle(_ attrText: NSMutableAttributedString, links: [String: URL]?) {
        guard let linkList = links else {
            return
        }

        var hyperLinks = self.hyperLinkList ?? []

        let attrString = attrText.string
        let originLength = originAttrString?.length ?? 0
        linkList.forEach { result in
            let ranges = nsranges(string: attrString, of: result.key)
            for range in ranges {
                let originRange = parserRangeToOriginRange(range, length: originLength)
                var link = LKTextLink(range: originRange, type: .link)
                link.url = result.value
                hyperLinks.append(link)
                attrText.addAttributes(self.linkAttributes, range: range)
            }
        }
        self.hyperLinkList = hyperLinks
    }

    private func nsranges(string: String, of substr: String) -> [NSRange] {
        if let re = try? NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: substr), options: []) {
            return re.matches(in: string, options: [], range: NSRange(location: 0, length: (string as NSString).length)).map { $0.range }
        }
        return []
    }

    func originRangeToParserRange(_ originRange: NSRange) -> NSRange? {
        guard let originAttrString = self.originAttrString else {
            return nil
        }
        let lowerBound = getParserIndex(from: originRange.location)
        // length = upperBound - lowerBound，故upperBound比range最右侧有效index多1
        let upperBound = getParserIndex(from: originRange.upperBound - 1) + 1
        guard lowerBound >= 0, upperBound <= originAttrString.length else {
            return nil
        }
        return NSRange(location: lowerBound, length: upperBound - lowerBound)
    }

    public func clone() -> LKTextParser {
        let linkParserImpl = LKLinkParserImpl(linkAttributes: self.linkAttributes)
        if let str = self.originAttrString {
            /// include parserIndicesToOriginIndices and renderAttrString init，so need to copy first
            linkParserImpl.originAttrString = NSAttributedString(attributedString: str)
        }
        linkParserImpl.defaultFont = UIFont.systemFont(ofSize: self.defaultFont.pointSize)
        linkParserImpl.tapableRangeList = self.tapableRangeList
        linkParserImpl.rangeLinkMapper = self.rangeLinkMapper
        linkParserImpl.parserIndicesToOriginIndices = self.parserIndicesToOriginIndices
        linkParserImpl.hyperLinkList = self.hyperLinkList
        linkParserImpl.hyperlinkMapper = self.hyperlinkMapper
        linkParserImpl.textLinkList = self.textLinkList
        if let str = self.renderAttrString {
            linkParserImpl.renderAttrString = NSMutableAttributedString(attributedString: str)
        }
        linkParserImpl.characters = self.characters
        return linkParserImpl
    }
}
