//
//  NSAttributedString+LarkFoundation.swift
//  LarkFoundation
//
//  Created by qihongye on 2018/3/27.
//  Copyright © 2018年 com.bytedance.lark. All rights reserved.
//

import UIKit
import Foundation
import LarkCompatible
import UniverseDesignColor
import UniverseDesignTheme

public struct TrimPosition: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let lead = TrimPosition(rawValue: 1)
    public static let trail = TrimPosition(rawValue: 1 << 1)
    public static let both = TrimPosition(rawValue: 3)
}

extension NSAttributedString: LarkFoundationExtensionCompatible {}

public extension LarkFoundationExtension where BaseType == NSAttributedString {
    func trimmedAttributedString(set: CharacterSet, position: TrimPosition = .both) -> NSAttributedString {
        let invertedSet = set.inverted
        let modifyAttributeText = NSMutableAttributedString(attributedString: self.base)
        var range = NSRange(location: 0, length: 0)
        if position.contains(.lead) {
            range = (self.base.string as NSString).rangeOfCharacter(from: invertedSet)
        }
        let location = range.length > 0 ? range.location : 0
        range.length = 0

        if position.contains(.trail) {
            range = (self.base.string as NSString).rangeOfCharacter(from: invertedSet, options: .backwards)
        }
        let length = (range.length > 0 ? NSMaxRange(range) : modifyAttributeText.string.count) - location

        let newText = modifyAttributeText.attributedSubstring(from: NSRange(location: location, length: length))
        return newText
    }

    /// Returns the special chracter ranges like 1⃣️.
    /// - Returns: ranges
    func attributedStringUnicodeScalarRanges() -> [NSRange] {
        if base.string.isEmpty {
            return []
        }
        var ranges: [NSRange] = []
        var prevEncodeOffset = 0
        var unicodeLength = 0
        let string = base.string
        for index in string.indices {
            let encodeOffset = index.utf16Offset(in: string)
            unicodeLength = encodeOffset - prevEncodeOffset
            if unicodeLength > 1 {
                ranges.append(NSRange(location: prevEncodeOffset, length: unicodeLength))
            }
            prevEncodeOffset = encodeOffset
        }

        unicodeLength = base.length - prevEncodeOffset
        if unicodeLength > 1 {
            ranges.append(NSRange(location: prevEncodeOffset, length: unicodeLength))
        }

        return ranges
    }

    /// cutting the center of emoji in attributedString will crash in iOS 13.1.2, so provide a safe cut method
    /// - Parameter from: subRange
    /// - Returns: Substring result
    func safeAttributedSubstring(from: NSRange) -> NSAttributedString {
        var from = from
        let ranges = self.attributedStringUnicodeScalarRanges()

        var isFixLocation = false
        var isFixUpper = false
        for range in ranges {
            if isFixLocation, range.location >= from.upperBound {
                break
            }
            let isLocationInRange = from.location > range.location && from.location <= range.upperBound
            // judge location is need to fix
            // for example, attr: "121⃣️345"
            // subrange: "{3, 2}"
            // fix range to {4, 1}
            if isLocationInRange {
                let leftDistance = from.location - range.location
                let rightDistance = range.upperBound - from.location
                let distance = leftDistance <= rightDistance ? leftDistance : -rightDistance
                let location = leftDistance <= rightDistance ? range.location : range.upperBound
                from.location = location
                from.length += distance
                isFixLocation = true
            }
            let isUpperInRange = from.upperBound > range.location && from.upperBound < range.upperBound
            // judge upper is need to fix
            // for example, attr: "121⃣️345"
            // subrange: "{0, 3}"
            // fix range to {0, 2}
            if isUpperInRange {
                let leftDistance = from.upperBound - range.location
                let rightDistance = range.upperBound - from.location
                let distance = leftDistance <= rightDistance ? -leftDistance : rightDistance
                from.length += distance
                isFixUpper = true
            }
            if isFixLocation && isFixUpper {
                break
            }
        }
        from.length = min(from.length, base.length)
        return base.attributedSubstring(from: from)
    }

    /// Parameters:
    /// matches: 目标匹配字符串
    /// color: 高亮颜色，nil时使用默认高亮颜色
    /// matchLimit: 最大匹配次数，超出时即便匹配也不高亮，nil时不做限制
    func setHighlight(
        matches: [String],
        color: UIColor = UIColor.ud.colorfulBlue,
        matchLimit: UInt? = 10
    ) -> NSAttributedString {
        guard !matches.isEmpty else {
            return self.base
        }
        let text = self.base.string
        let muAttributedString = NSMutableAttributedString(attributedString: self.base)
        matches.forEach { match in
            var searchRange = NSRange(location: 0, length: text.count)
            var foundRange = (text as NSString).range(of: match, options: [.caseInsensitive], range: searchRange)
            var matchTime = 0
            while searchRange.location < text.count, foundRange.location != NSNotFound {
                if let matchLimit = matchLimit {
                    if matchTime < matchLimit {
                        matchTime += 1
                    } else {
                        break
                    }
                }
                muAttributedString.addAttribute(.foregroundColor,
                                                value: color,
                                                range: foundRange)
                searchRange.location = foundRange.location + foundRange.length
                searchRange.length = text.count - searchRange.location
                foundRange = (text as NSString).range(of: match, options: [.caseInsensitive], range: searchRange)
            }
        }
        return NSAttributedString(attributedString: muAttributedString)
    }

    /// Parameters:
    /// regex: 传入目标匹配字符串正则表达式
    /// color: 高亮颜色，nil时使用默认高亮颜色
    /// matchLimit: 最大匹配次数，超出时即便匹配也不高亮，nil时不做限制
    func setHighlight(
        regex: String,
        color: UIColor = UIColor.ud.colorfulBlue,
        matchLimit: UInt? = 10
    ) -> NSAttributedString {
        let text = self.base.string
        let muAttributedString = NSMutableAttributedString(attributedString: self.base)
        guard let regular = try? NSRegularExpression(pattern: regex, options: [.caseInsensitive]) else {
            return self.base
        }
        let range = NSRange(location: 0, length: text.count)
        var matchTime = 0
        let matches = regular.matches(in: text, options: [.reportCompletion], range: range)
        for match in matches {
            if let matchLimit = matchLimit {
                if matchTime < matchLimit {
                    matchTime += 1
                } else {
                    break
                }
            }
            muAttributedString.addAttribute(.foregroundColor,
                                            value: color,
                                            range: match.range)
        }
        return NSAttributedString(attributedString: muAttributedString)
    }
}

// swiftlint:disable identifier_name
public func + (_ l: NSAttributedString, _ r: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(l)
    result.append(r)
    return result
}

public func + (_ l: NSMutableAttributedString, _ r: NSMutableAttributedString) -> NSMutableAttributedString {
    let result = NSMutableAttributedString()
    result.append(l)
    result.append(r)
    return result
}

// swiftlint:enable identifier_name
