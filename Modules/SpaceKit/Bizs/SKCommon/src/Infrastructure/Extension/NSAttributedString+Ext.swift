//
//  AttributedString+Infra.swift
//  SKCommon
//
//  Created by lijuyou on 2020/5/31.
//  


import SKFoundation
import Foundation
import UIKit
import UniverseDesignColor
import SpaceInterface
import SKInfra

public extension DocsExtension where BaseType == NSAttributedString {
    
    /// 识别 URL 链接 已经废弃，后续新需求使用 newUrlAttributed
    var urlAttributed: NSAttributedString {
        if let config = SettingConfig.docsURLRegexConfig, !config.linkRegex.isEmpty {
            var ranges = self.base.string.docs.regularUrlRanges(pattern: config.linkRegex)
            if config.newRuleEnable {
                let corrector = DocURLCorrector(blackList: config.blackSuffixList)
                var temp: [NSRange] = []
                for range in ranges {
                    temp.append(contentsOf: corrector.correctRange(urlRange: range, urlStr: self.base.string, linkRegex: config.linkRegex))
                }
                ranges = temp
            }
            return getUrlAttributedText(with: ranges)
        } else {
            return getUrlAttributedText(with: self.base.string.docs.regularUrlRanges)
        }
    }
    
    /// 识别 URL 链接
    var newUrlAttributed: NSAttributedString {
        return getUrlAttributedText(with: self.base.string.docs.newRegularUrlRanges)
    }
    
    func getUrlAttributedText(with urlRanges: [NSRange]) -> NSAttributedString {
        let attrText = NSMutableAttributedString(attributedString: self.base)
        let plainString = self.base.string
        urlRanges.forEach({ (range) in
            guard let stringRange = Range(range, in: plainString),
                  let url = URL(string: String(plainString[stringRange])) else { return }
            attrText.addAttribute(.foregroundColor, value: UDColor.textLinkNormal, range: range)
            attrText.addAttribute(AtInfo.attributedStringURLKey, value: url, range: range)
        })
        return attrText
    }
    
    var containsNewline: Bool {
        let range = NSRange(location: 0, length: self.base.length)
        let newlineRange = (self.base.string as NSString).rangeOfCharacter(from: CharacterSet.newlines, options: [], range: range)
        return newlineRange.location != NSNotFound
    }
}

public extension DocsExtension where BaseType == NSAttributedString {
    
    /// 利用增量的方式去更新
    func urlAttributedDiff(range: NSRange, filterKeys: [NSAttributedString.Key], notChangeForegroundColor: Bool = false) -> NSAttributedString {
        let attrText = NSMutableAttributedString(attributedString: self.base)
        let plainString = self.base.string
        let diffNSRange = self.getMaxRangeForSearcingUrl(changedRange: range, filterKeys: filterKeys)
        guard diffNSRange.length > 0, let diffRange = Range(diffNSRange, in: plainString) else {
            return attrText
        }
        if !notChangeForegroundColor {
            // 这里为啥要设置foreground？感觉没必要
            attrText.addAttribute(.foregroundColor, value: UDColor.textTitle, range: diffNSRange)
        }
        attrText.removeAttribute(AtInfo.attributedStringURLKey, range: diffNSRange)
        let diffString = String(plainString[diffRange])
        let ranges = diffString.docs.newRegularUrlRanges
        debugPrint("urlAttributedDiff diffString: \(diffString) diffRange: \(diffRange)")
        ranges.forEach({ (range) in
            let currRange = NSRange(location: range.location + diffNSRange.location, length: range.length)
            debugPrint("urlAttributedDiff ranges currRange: \(currRange)")
            guard let stringRange = Range(currRange, in: plainString),
                  let url = URL(string: String(plainString[stringRange])) else { return }
            attrText.addAttribute(.foregroundColor, value: UDColor.textLinkNormal, range: currRange)
            attrText.addAttribute(AtInfo.attributedStringURLKey, value: url, range: currRange)
        })
        return attrText
    }
    
    /// 从富文本中移除链接属性
    func removedURLKeyAttributes(for attributedText: NSAttributedString, range: NSRange) -> NSMutableAttributedString {
        let newAttributedText = NSMutableAttributedString(attributedString: attributedText)
        attributedText.enumerateAttribute(AtInfo.attributedStringURLKey,
                                          in: range,
                                          options: []) { (attrs, range, _) in
            guard attrs != nil else {
                return
            }
            newAttributedText.addAttribute(.foregroundColor, value: UDColor.textTitle, range: range)
            newAttributedText.removeAttribute(AtInfo.attributedStringURLKey, range: range)
        }
        return newAttributedText
    }
    
    /// 计算增量链接的左右边界
    /// - Parameters:
    ///   - plainString: 文本
    ///   - changeRange: 变化的范围
    func getMaxRangeForSearcingUrl(changedRange range: NSRange, filterKeys: [NSAttributedString.Key]) -> NSRange {
        let plainString = self.base.string
        let fullRange = NSRange(location: 0, length: plainString.utf16.count)
        var left = range.location
        var right = range.location + range.length
        let lenReg = "[-a-zA-z:0-9%_+~#@.?!$*,;=&\\\\/]"
        
        func isFitRange(_ range: NSRange) -> Bool {
            return range.location >= 0 && range.location + range.length <= fullRange.length
        }
        
        /// 判断某个位置的字符是否可用于查询链接
        func isFitCharInLocation(_ location: Int, fullString: String, regexDetector: NSRegularExpression) -> Bool {
            let charRange = NSRange(location: location, length: 1)
            guard isFitRange(range), let range = Range(charRange, in: fullString) else {
                return false
            }
            
            // 判断当前字符是否带有需要过滤属
            let attrs = self.base.attributes(at: location, longestEffectiveRange: nil, in: charRange)
            if attrs.contains(where: { filterKeys.contains($0.key) }) {
                return false
            }
            
            // 判断当前字符是否符合 url
            let subString = String(fullString[range])
            guard !subString.isEmpty else {
                return false
            }
            let matches = regexDetector.matches(in: subString, range: NSRange(location: 0, length: 1))
            if matches.isEmpty {
                return false
            }
            return true
        }
        
        guard isFitRange(range) else {
            DocsLogger.error("getMaxRangeForSearcingUrl error changedRange range: \(range), fullRange: \(fullRange)")
            return NSRange(location: 0, length: 0)
        }
        
        do {
            let detect = try NSRegularExpression(pattern: lenReg, options: [])
            // 计算左边界
            left -= 1
            while left >= 0 {
                if isFitCharInLocation(left, fullString: plainString, regexDetector: detect) {
                    left -= 1
                } else {
                    left += 1
                    break
                }
            }
            left = max(0, left)
            // 计算右边界
            while right < fullRange.length {
                if isFitCharInLocation(right, fullString: plainString, regexDetector: detect) {
                    right += 1
                } else {
                    right -= 1
                    break
                }
            }
            right = min(right, fullRange.length - 1)
        } catch {
            DocsLogger.error("getMaxRangeForSearcingUrl error:\(error) regex: \(lenReg)")
            return NSRange(location: 0, length: 0)
        }
        let finalRange = NSRange(location: left, length: right - left + 1)
        guard isFitRange(finalRange) else {
            DocsLogger.error("getMaxRangeForSearcingUrl error finalRange range: \(finalRange), fullRange: \(fullRange)")
            return NSRange(location: 0, length: 0)
        }
        return finalRange
    }
}
