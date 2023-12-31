//
//  StringMatcher.swift
//  Lark
//
//  Created by 刘晚林 on 2017/5/17.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public protocol StringMatcher {
    static func match(in text: String, of input: String, extra: NSDictionary) -> (String, Range<String.Index>)?
    static func fullMatch(in text: String, of input: String, extra: NSDictionary) -> [(String, Range<String.Index>)]
}

open class SimpleMatcher: StringMatcher {
    public class func match(in text: String, of input: String, extra: NSDictionary = [:])
        -> (String, Range<String.Index>)? {
        let lowercasedInput = input.lowercased()

        if let range = text.lowercased().range(of: lowercasedInput) {
            return (String(text[range]), range)
        }

        return nil
    }

    public class func fullMatch(in text: String, of input: String, extra: NSDictionary)
        -> [(String, Range<String.Index>)] {
        if let res = match(in: text, of: input, extra: extra) {
            return [res]
        }
        return []
    }
}

open class PinYinMatcher: StringMatcher {
    public class func fullMatch(in text: String, of input: String, extra: NSDictionary)
        -> [(String, Range<String.Index>)] {
        let inputs = input.components(separatedBy: " ").filter { !$0.isEmpty }

        var results: [(String, Range<String.Index>)] = []
        for input in inputs {
            if let res = match(in: text, of: input, extra: extra) {
                results.append(res)
            }
        }

        return results
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    public class func match(
        in text: String,
        of input: String,
        extra: NSDictionary = [:]) -> (String, Range<String.Index>)? {
        let lowercasedInput = input.lowercased()

        if let range = text.lowercased().range(of: lowercasedInput) {
            return (String(text[range]), range)
        }
        if lowercasedInput.lf.isIncludeChinese,
           let nameCN = extra["name"] as? String,
           let range = nameCN.range(of: lowercasedInput) {
            return (String(nameCN[range]), range)
        }

        let pinyin = extra["pinyin"] as? String ?? ""

        if pinyin.lowercased().contains(lowercasedInput) {
            let result = self.parse(text: text)

            var startIndex: String.Index?
            var endIndex: String.Index?

            for (index, (key, range)) in result.enumerated() {
                if key.hasPrefix(lowercasedInput) {
                    startIndex = range.lowerBound
                    endIndex = range.upperBound
                    break
                }

                if lowercasedInput.hasPrefix(key) && index < result.count - 1 {
                    var newIndex = index
                    var prefix = key
                    var matchRange = range
                    while newIndex < result.count - 1 {
                        newIndex += 1
                        prefix += result[newIndex].0
                        matchRange = matchRange.lowerBound ..< result[newIndex].1.upperBound
                        if prefix.hasPrefix(lowercasedInput) {
                            startIndex = matchRange.lowerBound
                            endIndex = matchRange.upperBound
                            break
                        }
                        if !lowercasedInput.hasPrefix(prefix) {
                            continue
                        }
                    }
                }
            }

            if let startIndex = startIndex, let endIndex = endIndex {
                let range = Range(uncheckedBounds: (lower: startIndex, upper: endIndex))
                return (String(text[range]), range)
            } else {
                return (lowercasedInput,
                        Range(uncheckedBounds: (lower: lowercasedInput.startIndex, upper: lowercasedInput.startIndex)))
            }
        }

        if !lowercasedInput.lf.isIncludeChinese {
            // 判断是否可以匹配字头
            let result = self.parse(text: text)
            var headString = ""
            result.forEach { str, _ in
                if !str.isEmpty {
                    headString += String(str[..<str.index(str.startIndex, offsetBy: 1)])
                }
            }
            let matchHeadRange = (headString as NSString).range(of: lowercasedInput)
            if matchHeadRange.location != NSNotFound {
                let matchHeads = result[matchHeadRange.location ..< (matchHeadRange.location + matchHeadRange.length)]

                if !matchHeads.isEmpty {
                    var startIndex: String.Index?
                    var endIndex: String.Index?
                    matchHeads.forEach({ _, range in
                        if startIndex == nil || range.lowerBound <= startIndex! {
                            startIndex = range.lowerBound
                        }
                        if endIndex == nil || range.upperBound >= endIndex! {
                            endIndex = range.upperBound
                        }
                    })
                    if let startIndex = startIndex, let endIndex = endIndex {
                        let range = Range(uncheckedBounds: (lower: startIndex, upper: endIndex))
                        return (String(text[range]), range)
                    }
                }
            }
        }

        return nil
    }

    // swiftlint:enable cyclomatic_complexity function_body_length

    public class func parse(text: String) -> [(String, Range<String.Index>)] {
        var result: [(String, Range<String.Index>)] = []
        var offset = 0
        for char in text {
            let str = String(char)
            if str.lf.isIncludeChinese {
                let cRange = text.index(text.startIndex, offsetBy: offset) ..< text.index(text.startIndex,
                                                                                          offsetBy: offset + 1)
                result.append((str.lf.transformToPinyin().lowercased(), cRange))
            }
            offset += 1
        }
        return result
    }
}
