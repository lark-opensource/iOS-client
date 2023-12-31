//
//  InputParseUtils.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LKCommonsLogging

public final class InputParseUtils {

    public static let prefix = "\u{14}\u{15}"
    public static let suffix = "\u{15}\u{14}"

    public static let trimCharacterSet = { () -> CharacterSet in
        var cs = CharacterSet()
        cs.insert("\u{1}")
        cs.insert("\u{2}")
        cs.insert("\u{3}")
        cs.insert("\u{4}")
        cs.insert("\u{5}")
        cs.insert("\u{6}")
        cs.insert("\u{7}")
        cs.insert("\u{8}")
        cs.insert("\u{9}")
        cs.insert("\u{10}")
        cs.insert("\u{11}")
        cs.insert("\u{12}")
        cs.insert("\u{13}")
        cs.insert("\u{14}")
        cs.insert("\u{15}")
        return cs
    }()

    public static let logger = Logger.log(InputParseUtils.self, category: "Utils.InputParseUtils")

    public static func baseParse(in text: String, pattern: String, formReplaceResult: ([String], NSTextCheckingResult) -> String) -> String {
        let input: NSString = text as NSString
        var output = input
        var count = 0
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            regex.enumerateMatches(in: input as String, range: NSRange(location: 0, length: input.length), using: { (match, _, _) in
                guard let match = match else {
                    return
                }

                let range = match.range
                let numberOfRanges = match.numberOfRanges

                let matchStr = input.substring(with: range) as NSString
                var matchParts: [String] = []
                for idx in 0...numberOfRanges - 1 {
                    matchParts.append(input.substring(with: match.range(at: idx)))
                }

                let newStr = formReplaceResult(matchParts, match) as NSString
                let newRange = NSRange(location: range.location + count, length: range.length)

                output = output.replacingCharacters(in: newRange, with: newStr as String) as NSString

                count += (newStr.length - matchStr.length)
            })
        } catch {
            InputParseUtils.logger.error(
                "Regular expression initialize failed.",
                additionalData: ["Pattern": pattern],
                error: error)
        }
        return output as String
    }

    public static func numberStringToInvisibleString(_ numberStr: String) -> String {
        var parsedStr: String = ""

        for char in numberStr {
            switch char {
            case "0": parsedStr += "\u{12}"
            case "1": parsedStr += "\u{1}"
            case "2": parsedStr += "\u{2}"
            case "3": parsedStr += "\u{3}"
            case "4": parsedStr += "\u{4}"
            case "5": parsedStr += "\u{5}"
            case "6": parsedStr += "\u{6}"
            case "7": parsedStr += "\u{7}"
            case "8": parsedStr += "\u{8}"
            case "9": parsedStr += "\u{10}"
            default: break
            }
        }
        return parsedStr
    }

    public static func invisibleStringToNumberString(_ invisibleString: String) -> String {
        var parsedStr: String = ""

        for char in invisibleString {
            switch char {
            case "\u{12}": parsedStr += "0"
            case "\u{1}": parsedStr += "1"
            case "\u{2}": parsedStr += "2"
            case "\u{3}": parsedStr += "3"
            case "\u{4}": parsedStr += "4"
            case "\u{5}": parsedStr += "5"
            case "\u{6}": parsedStr += "6"
            case "\u{7}": parsedStr += "7"
            case "\u{8}": parsedStr += "8"
            case "\u{10}": parsedStr += "9"
            default: break
            }
        }
        return parsedStr
    }
}
// MARK: - NSAttributedString
extension InputParseUtils {

    public static func baseAttributedParse(in text: NSAttributedString, pattern: String, formReplaceResult: ([String]) -> NSAttributedString) -> NSAttributedString {
        let input: NSString = text.string as NSString
        let output = NSMutableAttributedString(attributedString: text)
        self.baseAttributedParse(input: input, output: output, pattern: pattern, formReplaceResult: formReplaceResult)
        return output
    }

    fileprivate static func baseAttributedParse(input: NSString, output: NSMutableAttributedString, pattern: String, formReplaceResult: ([String]) -> NSAttributedString) {
        var count = 0
        autoreleasepool {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                regex.enumerateMatches(in: input as String, range: NSRange(location: 0, length: input.length), using: { (match, _, _) in
                    guard let match = match else {
                        return
                    }

                    let range = match.range
                    let numberOfRanges = match.numberOfRanges

                    let matchStr = input.substring(with: range) as NSString
                    var matchParts: [String] = []
                    for idx in 0...numberOfRanges - 1 {
                        matchParts.append(input.substring(with: match.range(at: idx)))
                    }

                    let newStr = formReplaceResult(matchParts) as NSAttributedString
                    let newRange = NSRange(location: range.location + count, length: range.length)
                    output.replaceCharacters(in: newRange, with: newStr)
                    count += (newStr.length - matchStr.length)
                })
            } catch {
                InputParseUtils.logger.error(
                    "Regular expression initialize failed.",
                    additionalData: ["Pattern": pattern],
                    error: error)
            }
        }
    }
}
