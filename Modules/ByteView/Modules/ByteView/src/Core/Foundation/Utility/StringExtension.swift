//
//  StringExtension.swift
//  ByteView
//
//  Created by chentao on 2020/9/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

extension VCExtension where BaseType == String {
    func substring(from index: Int) -> String {
        if base.count > index {
            let startIndex = base.index(base.startIndex, offsetBy: index)
            let subString = base[startIndex..<base.endIndex]

            return String(subString)
        } else {
            return base
        }
    }

    func substring(to index: Int) -> String {
        if base.count > index {
            let endIndex = base.index(base.startIndex, offsetBy: index)
            let subString = base[..<endIndex]
            return String(subString)
        } else {
            return base
        }
    }

    func substring(from: Int, length: Int) -> String {
        guard length > 0 else { return "" }
        guard from < base.count else { return "" }
        let left = base.index(base.startIndex, offsetBy: from)
        if (from + length) < base.count {
            return String(base[left..<base.index(left, offsetBy: length)])
        } else {
            return String(base[left..<base.endIndex])
        }
    }

    /// 去除URL的参数，返回“?”前的部分
    func removeParams() -> String {
        return base.components(separatedBy: "?")[0]
    }
}

extension String {
    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

extension NSRegularExpression {
    func matches(_ string: String) -> [String] {
        let input = string as NSString
        let range = NSRange(location: 0, length: input.length)
        let results = self.matches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)

        return results.map { result -> String in
            return input.substring(with: result.range)
        }
    }
}

final class StringUtil {
    /// 在文案的可点击区域前后手动添加换行符，以保证可点击区域是独立一行
    static func handleTextWithLineBreak(_ text: String, font: UIFont, maxWidth: CGFloat) -> (String, NSRange)? {
        var content = text
        let array = content.components(separatedBy: "@@")
        var range: NSRange?
        if array.count >= 3 {
            content = content.replacingOccurrences(of: "@@\(array[1])@@", with: array[1])
            range = NSRange(location: array[0].count, length: array[1].count)
        }

        if var range = range {
            let textWidth = text.vc.boundingWidth(height: ceil(font.lineHeight), font: font)
            let canFitSingleLine: Bool = textWidth <= maxWidth
            if !canFitSingleLine {
                // 如果文案整体不能放在一行，则@@中间的部分需要独立为一行，因此需要手动在前后加换行符
                if range.location > 0 {
                    content.insert("\n", at: content.index(content.startIndex, offsetBy: range.location))
                    range.location += 1
                }
                if range.upperBound < content.count {
                    content.insert("\n", at: content.index(content.startIndex, offsetBy: range.upperBound))
                }
            }
            return (content, range)
        }
        return nil
    }
}
