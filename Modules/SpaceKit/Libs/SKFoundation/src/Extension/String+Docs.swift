//
//  String+Docs.swift
//  DocsCommon
//
//  Created by weidong fu on 29/11/2017.
//
// swiftlint:disable line_length

import UIKit

extension String: DocsExtensionCompatible {}

public extension DocsExtension where BaseType == String {

    var urlRanges: [NSRange] {
        let baseStr = self.base
        var ranges = Set<NSRange>()
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            var detectRanges = [NSRange]()
            /// 首先肯定要检测全文的
            let fullRange = NSRange(baseStr.startIndex..<baseStr.endIndex, in: baseStr)
            detectRanges.append(fullRange)
            /// 但是如果只检测全文的话，对于“@google.com”这种@前无文字的情况就检测不出来，所以需要单独处理
            /// 将字符串中所有@的位置找出来，把@后的子串范围添加到detectRanges
            if var ind = baseStr.firstIndex(of: "@") {
                while ind < baseStr.index(before: baseStr.endIndex) {
                    let subrange = baseStr.index(after: ind)..<baseStr.endIndex
                    let subNSRange = NSRange(subrange, in: baseStr)
                    detectRanges.append(subNSRange)
                    if let nextInd = baseStr[subrange].firstIndex(of: "@") {
                        ind = nextInd
                    } else { break }
                }
            }
            /// 对detectRanges里面的所有范围都做一次检测，将检测出的URL范围添加到ranges集合里
            for range in detectRanges {
                detector.enumerateMatches(in: baseStr, options: [], range: range) { (result, _, _) in
                    if let res = result, res.url != nil {
                        ranges.insert(res.range)
                    }
                }
            }
            /// 将集合转成列表然后返回
            return ranges.sorted(by: { $0.location < $1.location })
        } catch {
            return []
        }
    }
    
    var newRegularUrlRanges: [NSRange] {
        do {
            let detect = try NSRegularExpression(pattern: LinkRegex.LINK_REG, options: [.caseInsensitive, .useUnicodeWordBoundaries])
            let matches = detect.matches(in: base, range: NSRange(location: 0, length: base.utf16.count))
            return matches.map { $0.range }
        } catch {
            DocsLogger.error("regularUrlRanges error:\(error)")
            return []
        }
    }
    
    var regularUrlRanges: [NSRange] {
        let hostReg = "localhost:[0-9]{2,5}"
        let ipReg = "(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}(2[0-4][0-9]|25[0-5]|1[0-9]{2}|[1-9][0-9]|[0-9])(:[0-9]{2,5})?"
        /// 匹配IP地址
        let noDomainReg = "(https?|http|ftp):\\/\\/((" + hostReg
            + ")|( " + ipReg + "))(\\/[-a-zA-Z0-9@:%_+.~#?&//=]*)?"
        /// 匹配域名地址
        let domainReg = "((https?|http|ftp):\\/\\/)?[-a-zA-Z0-9:%._+~#=]{2,256}\\.(com|org|net|edu|gov|aero|app|biz|cat|coop|info|int|jobs|mobi|museum|name|pro|travel|arpa|asia|xxx|google|[a-z][a-z])\\b([-a-zA-Z0-9@:%_+.~#?&//=;()$,!]*)"
        let lenReg = "^(?!data:)(?:mailto:)?[\\w.!#$%&'*+-/=?^_`{|}~]{1,2000}@[A-Za-z0-9.-]+\\.(com|org|net|edu|gov|aero|app|biz|cat|coop|info|int|jobs|mobi|museum|name|pro|travel|arpa|asia|xxx|[a-z][a-z])"
        let linkReg = "(" + noDomainReg + ")|(" + domainReg + ")|(" + lenReg + ")"
        return regularUrlRanges(pattern: linkReg)
    }

    static var regularExpressions: [String: NSRegularExpression] = [:]
    
    func regularUrlRanges(pattern: String) -> [NSRange] {
        do {
            if UserScopeNoChangeFG.HYF.asideCommentHeightOptimize,
               let detect = Self.regularExpressions[pattern] {
                let matches = detect.matches(in: base, range: NSRange(location: 0, length: base.utf16.count))
                return matches.map { $0.range }
            } else {
                let detect = try NSRegularExpression(pattern: pattern, options: [])
                let matches = detect.matches(in: base, range: NSRange(location: 0, length: base.utf16.count))
                if UserScopeNoChangeFG.HYF.asideCommentHeightOptimize {
                    Self.regularExpressions[pattern] = detect
                }
                return matches.map { $0.range }
            }
        } catch {
            DocsLogger.error("regularUrlRanges error:\(error)")
            return []
        }
    }

    func escapeSingleQuote() -> String {
        return base.replacingOccurrences(of: #"'"#, with: #"\'"#)
    }
}


extension String {
    //将原始的url编码为合法的url
    public func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return encodeUrlString ?? ""
    }

    //将编码后的url转换回原始的url
    public func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }

    public func appendingPathComponent(_ path: String) -> String {
        let fileURL = URL(fileURLWithPath: self)
        let result = fileURL.appendingPathComponent(path)

        return result.path
    }
    //         描述      实体名称
    //         空格      &nbsp;
    //    &    和号      &amp;
    //    <    小于号    &lt;
    //    >    大于号    &gt;
    //    '    单引号    &#x27;
    //    "    双引号    &quot;

    //    前端特殊字符
    //    /
    public func parseHTMLConvertChar() -> String {
        return parseHTMLConvertCharNoTrimming().trimmingCharacters(in: .newlines)
    }
    
    public func parseHTMLConvertCharNoTrimming() -> String {
        return self.replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#x27;", with: "\'")
            .replacingOccurrences(of: "&#x2F;", with: "/")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}

extension String {
    public static func randomStr(len: Int) -> String {
        let randomCharacters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var randomStr = ""
        for _ in 0...len {
            let index = Int.random(in: 0..<randomCharacters.count)
            randomStr.append(randomCharacters[randomCharacters.index(randomCharacters.startIndex, offsetBy: index)])
        }
        return randomStr
    }

    public var reversedStr: String {
        return String(self.reversed())
    }
}

extension Locale {
    public var isChinese: Bool {
        return identifier.contains("zh")
    }
}

// MARK: 判断字符串的语言
extension String {
    public var containsChineseCharacters: Bool {
        return self.range(of: "\\p{Han}", options: .regularExpression) != nil
    }

    public var isAllChineseCharacters: Bool {
        var isAll = false
        if let chineseRangeIdx = self.range(of: "\\p{Han}+", options: .regularExpression) {
            let chineseSubStr = self[chineseRangeIdx]
            if chineseSubStr == self {
                isAll = true
            }
        }
        return isAll
    }

    public var isAllLetters: Bool {
        var isAll = true
        for eachChar in self {
            if !(
                ((eachChar >= "A") && (eachChar <= "Z")) ||
                    ((eachChar >= "a") && (eachChar <= "z"))
                ) {
                isAll = false
                break
            }
        }
        return isAll
    }

    public var isAllDigits: Bool {
        var isAll = true
        for eachChar in self {
            if !((eachChar >= "1") && (eachChar <= "9")) {
                isAll = false
                break
            }
        }
        return isAll
    }
}

// MARK: - regex
extension String {
    
    
    /// 将所有匹配到正则的文字替换为 template
    public func replace(with template: String, for regex: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            return self.replace(with: template, regex: regex)
        } catch {
            return self
        }
    }
    
    public func replace(with template: String, regex: NSRegularExpression) -> String {
        let nsString = self as NSString
        let nsRange = NSRange(location: 0, length: nsString.length)
        return regex.stringByReplacingMatches(in: self, options: [], range: nsRange, withTemplate: template)
    }
    
    public func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            return self.matches(regex: regex)
        } catch {
            return []
        }
    }
    
    public func matches(regex: NSRegularExpression) -> [String] {
        let nsString = self as NSString
        let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
        return results.map { nsString.substring(with: $0.range) }
    }
    
    /// 根据正则表达式，返回匹配到的第一个Capture Group
    ///
    /// - Parameter pattern: 需要匹配的字符串
    /// - Returns: 匹配到的第一处字符串中的第一个Capture Groups
    public func firstMatchedCaptureGroup(for pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.first.map {
                let range = ($0.numberOfRanges > 1) ? $0.range(at: 1) : $0.range
                return nsString.substring(with: range)
            }
        } catch {
            return nil
        }
    }
    
    public func isMatch(for pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = self as NSString
            let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: nsString.length))
            return match != nil
        } catch {
            return false
        }
    }

    public var isDoubleFormat: Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "^(\\-|\\+)?\\d+(\\.\\d+)?$")
        return predicate.evaluate(with: self)
    }
}

//extension String {
//    /// Calculate the estimated width of a single-line UILabel with the specified text and font.
//    ///
//    /// - Parameters:
//    ///   - font: The text's font. This parameter must not be `nil`.
//    /// - Returns: The estimated width of the single-line UILabel
//    public func estimatedSingleLineUILabelWidth(in font: UIFont!) -> CGFloat {
//        let test = UILabel()
//        test.text = self
//        test.font = font
//        test.numberOfLines = 1
//        test.frame.size = CGSize(width: 400, height: 400)
//        test.sizeToFit()
//        return test.frame.width
//    }
//    /// Apply the string with specified attributes and bound its width within the max width.
//    /// - Parameters:
//    ///   - attr: The attributes of the desired attributed string.
//    ///   - maxWidth: The maximum width of the attributed string.
//    ///   - minPercent: The minimum percentage that the last line of the UILabel should fill. Pass `nil` if you don't need this constraint.
//    /// - Returns: The attributed string and its actual size.
//    public func attrString(withAttributes attr: [NSAttributedString.Key: Any], boundedBy maxWidth: CGFloat,
//                    expectLastLineFillPercentageAtLeast minPercent: CGFloat?) -> (NSAttributedString, CGSize) {
//        let attributedString = NSAttributedString(string: self, attributes: attr)
//        let neededWidthIfInSingleLine = attributedString.estimatedSingleLineUILabelWidth
//        var realSize: CGSize = .zero
//        if neededWidthIfInSingleLine <= maxWidth {
//            let font = attr[.font] as? UIFont
//            let fontSize = font?.pointSize ?? UIFont.systemFontSize
//            let paraStyle = attr[.paragraphStyle] as? NSParagraphStyle
//            let lineSpacing = paraStyle?.lineSpacing ?? 0.0
//            realSize = CGSize(width: neededWidthIfInSingleLine, height: fontSize + lineSpacing)
//        } else {
//            realSize = attributedString.estimatedMultilineUILabelSize(maxWidth: maxWidth,
//                                                                      expectLastLineFillPercentageAtLeast: minPercent)
//        }
//        return (attributedString, realSize)
//    }
//}

extension String {
    public func mySubString(to index: Int) -> String {
        return String(self[..<self.index(self.startIndex, offsetBy: index)])
    }

    public func mySubString(from index: Int) -> String {
        return String(self[self.index(self.startIndex, offsetBy: index)...])
    }
    
    public func mySubString(begin: Int, end: Int) -> String {
        let beginIndex = self.index(self.startIndex, offsetBy: begin)
        let endIndex = self.index(self.startIndex, offsetBy: end)
        return String(self[beginIndex..<endIndex])
    }
}

extension String {
    public func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}



extension String {
    
    public var encryptToken: String {
        return DocsTracker.encrypt(id: self)
    }
    /// 用于对含有 token 的文本进行加密，会保留 token 的前几位，然后中间的位数进行加密，替换为 *****。
    public var encryptToShort: String {
        SecurityInfoChecker.shared.encryptToShort(text: self)
    }
}

public extension String {
    //range转换为NSRange
    func toNSRange(_ range: Range<String.Index>) -> NSRange {
        guard let from = range.lowerBound.samePosition(in: utf16), let to = range.upperBound.samePosition(in: utf16) else {
            return NSRange(location: 0, length: 0)
        }
        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from), length: utf16.distance(from: from, to: to))
    }
}

//https://bytedance.feishu.cn/docx/O65PdIqe4o7SRsxBponcWbj1nHb#Zl97d9w8loBKbyxM15ScM9WIn2e
//正则检查字符串是否符合 Email 格式
public extension String {
    func isValidEmail() -> Bool {
        //去掉前后空格、换行符号进行检查
        let whitespacesTrimmingResult = self.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailRegEx = "^[-!#$%&'*+/0-9=?A-Z^_a-z`{|}~](\\.?[-!#$%&'*+/0-9=?A-Z^_a-z`{|}~])*@[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+$"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: whitespacesTrimmingResult)
    }
}
