//
//  String+LarkFoundation.swift
//  LarkFoundation
//
//  Created by ChalrieSu on 24/12/2017.
//  Copyright © 2017 com.bytedance.lark. All rights reserved.
//

import CryptoSwift
import Foundation
import LarkCompatible

public extension String {
    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ... end])
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ..< end])
    }
}

extension String: LarkFoundationExtensionCompatible {}

public extension LarkFoundationExtension where BaseType == String {
    func substring(to index: Int) -> String {
        if base.count > index {
            let endIndex = base.index(base.startIndex, offsetBy: index)
            let subString = base[..<endIndex]
            return String(subString)
        } else {
            return base
        }
    }

    private var md5Key: String {
        return base.md5().lf.substring(to: 8)
    }

    /// https://bytedance.feishu.cn/docs/doccnhivV4v5yDVm09zFdzt8TOh
    /// 按{Hash(8)}_{摘要Pattern} 拼接
    var dataMasking: String {
        var key = md5Key
        key.append("_" as Character)
        key.reserveCapacity(base.count * 3)
        for char in base {
            if char < "\u{80}" {
                switch char {
                case "a" ... "z":
                    key.append("a" as Character)
                case "A" ... "Z":
                    key.append("A" as Character)
                case "0" ... "9":
                    key.append("0" as Character)
                default:
                    if char.isWhitespace || char.isPunctuation {
                        key.append(char as Character)
                    } else {
                        key.append("x" as Character)
                    }
                }
            } else {
                switch char {
                case "\u{4E00}" ... "\u{9FFF}":
                    key.append("C" as Character)
                case "\u{3040}" ... "\u{30FF}":
                    key.append("J" as Character)
                case "\u{AC00}" ... "\u{D7A3}":
                    key.append("K" as Character)
                default:
                    if char.isPunctuation || char.isWhitespace {
                        key.append(char as Character)
                    } else {
                        key.append("X" as Character)
                    }
                }
            }
        }
        return key
    }

    func each() -> [NSRange] {
        let str = self.base
        var ranges: [NSRange] = []
        var index = 0
        while index < str.count {
            let range = rangeToNSRange(from:
                str.rangeOfComposedCharacterSequence(at:
                    str.index(str.startIndex, offsetBy: index)))
            index += 1
            ranges.append(range)
        }
        return ranges
    }

    class func decode(template: String, contents: [String: String]) -> String {
        var content = template
        for (key, value) in contents {
            content = content.replacingOccurrences(of: "{\(key)}", with: value)
        }

        return content
    }

    func transformToPinyin() -> String {
        if !self.isIncludeChinese {
            return self.base
        }

        let stringRef = NSMutableString(string: self.base) as CFMutableString
        // 转换为带音标的拼音
        CFStringTransform(stringRef, nil, kCFStringTransformToLatin, false)
        // 去掉音标
        CFStringTransform(stringRef, nil, kCFStringTransformStripCombiningMarks, false)
        let pinyin = stringRef as String

        // 去掉空格
        return pinyin.replacingOccurrences(of: " ", with: "")
    }

    var isIncludeChinese: Bool {
        base.unicodeScalars.contains(where: { 0x4E00 <= $0.value && $0.value >= 0x9FFF })
    }

    func htmlEscape() -> String {
        // NOTE：连续的空格转义后面一个，防止空格在链接结尾时造成干扰
        let escapeChars = [
            ("<", "&lt;"),
            (">", "&gt;"),
            ("  ", " &nbsp;"),
            ("\t", " &nbsp; &nbsp;")
        ]

        var res = self.base
        escapeChars.forEach { occurrence, target in
            res = res.replacingOccurrences(of: occurrence, with: target)
        }
        return res
    }

    // Range转换为NSRange
    func rangeToNSRange(from range: Range<String.Index>) -> NSRange {
        return NSRange(range, in: self.base)
    }

    func replaceFirstOccurrence(_ target: String, with newStr: String) -> String {
        var str = self.base
        if let range = self.base.range(of: target, options: [.literal], range: nil, locale: nil) {
            str.replaceSubrange(range, with: newStr)
            return str
        }
        return str
    }

    enum TrimPostion {
        case lead
        case tail
        case both
    }

    func trimCharacters(in set: CharacterSet, postion: TrimPostion = .both) -> String {
        var result: String = self.base
        func trimLeadCharacters() {
            if var scalar = result.unicodeScalars.first {
                while set.contains(scalar) {
                    result = String(result[result.index(after: result.startIndex)...])
                    if let firstScalar = result.unicodeScalars.first {
                        scalar = firstScalar
                    } else {
                        break
                    }
                }
            }
        }
        func trimTailCharacters() {
            if var scalar = result.unicodeScalars.last {
                while set.contains(scalar) {
                    result = String(result[..<result.index(before: result.endIndex)])
                    if let lastScalar = result.unicodeScalars.last {
                        scalar = lastScalar
                    } else {
                        break
                    }
                }
            }
        }
        switch postion {
        case .lead:
            trimLeadCharacters()
        case .tail:
            trimTailCharacters()
        default:
            result = result.trimmingCharacters(in: set)
        }
        return result
    }

    func trimString(target targetStrings: [String], postion: TrimPostion = .both) -> String {
        var result: String = self.base
        func trimLeadString() {
            var findTarget = false
            for targetString in targetStrings {
                var prefix = ""
                var tryPrefix = targetString
                while result.hasPrefix(tryPrefix) {
                    tryPrefix += targetString
                    prefix += targetString
                    findTarget = true
                }
                result = String(result[result.index(result.startIndex, offsetBy: prefix.count)...])
            }
            if !findTarget {
                return
            }
            trimLeadString()
        }
        func trimTailString() {
            var findTarget = false
            for targetString in targetStrings {
                var suffix = ""
                var trySuffix = targetString
                while result.hasSuffix(trySuffix) {
                    trySuffix += targetString
                    suffix += targetString
                    findTarget = true
                }
                result = String(result[..<result.index(result.endIndex, offsetBy: -suffix.count)])
            }
            if !findTarget {
                return
            }
            trimTailString()
        }
        switch postion {
        case .lead:
            trimLeadString()
        case .tail:
            trimTailString()
        default:
            trimLeadString()
            trimTailString()
        }
        return result
    }

    func index(of string: String) -> String.Index? {
        return self.base.range(of: string)?.lowerBound
    }

    func endIndex(of string: String) -> String.Index? {
        return self.base.range(of: string)?.upperBound
    }

    func indexes(of string: String) -> [String.Index] {
        return ranges(of: string).map({ range -> String.Index in
            range.upperBound
        })
    }

    func ranges(of string: String) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []

        var start = self.base.startIndex
        let end = self.base.endIndex
        while let range = self.base.range(of: string, range: start ..< end) {
            result.append(range)
            start = range.upperBound
        }

        return result
    }

    func split(_ str: String) -> [String] {
        if self.base.isEmpty {
            return []
        }
        return self.base.components(separatedBy: str)
    }

    func nsranges(of substr: String) -> [NSRange] {
        if let res = try? NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: substr), options: []) {
            return res.matches(
                in: self.base,
                options: [],
                range: NSRange(location: 0, length: (self.base as NSString).length)).map { $0.range }
        }
        return []
    }

    /// 按照总字节长度截断指定字符串，长度大于3的按照2计算
    func subString(maxByteLength: Int) -> String {
        var chCount = 0
        var bytesCount = 0
        for char in self.base {
            let chBytes = "\(char)".lengthOfBytes(using: String.Encoding.utf8) >= 3 ? 2 : 1
            if bytesCount + chBytes > maxByteLength { break }

            chCount += 1
            bytesCount += chBytes
        }
        return String(self.base[..<self.base.index(self.base.startIndex, offsetBy: chCount)])
    }
}
