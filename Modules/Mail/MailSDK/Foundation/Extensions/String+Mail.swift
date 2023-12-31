//
//  String+Docs.swift
//  DocsCommon
//
//  Created by weidong fu on 29/11/2017.
//

import UIKit

// Taken from http://www.w3.org/TR/xhtml1/dtds.html#a_dtd_Special_characters
// Ordered by uchar lowest to highest for bsearching
// disable-lint: magic_number -- ascii 编码字典
let asciiHTMLEscapeDict: [UInt32: String] = [34: "&quot;",
                                             38: "&amp;",
                                             60: "&lt;",
                                             62: "&gt;",
                                             // Latin Extended-A
                                             338: "&OElig;",
                                             339: "&oelig;",
                                             352: "&Scaron;",
                                             353: "&scaron;",
                                             376: "&Yuml;",
                                             // Spacing Modifier Letters
                                             710: "&circ;",
                                             732: "&tilde;",
                                             // General Punctuation
                                             8194: "&ensp;",
                                             8195: "&emsp;",
                                             8201: "&thinsp;",
                                             8204: "&zwnj;",
                                             8205: "&zwj;",
                                             8206: "&lrm;",
                                             8207: "&rlm;",
                                             8211: "&ndash;",
                                             8212: "&mdash;",
                                             8216: "&lsquo;",
                                             8217: "&rsquo;",
                                             8218: "&sbquo;",
                                             8220: "&ldquo;",
                                             8221: "&rdquo;",
                                             8222: "&bdquo;",
                                             8224: "&dagger;",
                                             8225: "&Dagger;",
                                             8240: "&permil;",
                                             8249: "&lsaquo;",
                                             8250: "&rsaquo;",
                                             8364: "&euro;"]
// enable-lint: magic_number

// MARK: - encoded & decoded
extension String {
    var htmlEncoded: String {
        var arr: [String] = []
        for code in self.unicodeScalars {
            let number = code.value
            if let value = asciiHTMLEscapeDict[number] {
                arr.append(String(value))
            } else {
                arr.append(String(code))
            }
        }

        return arr.joined(separator: "") as String
    }
    var escapeString: String {
        return self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: "'", with: "\\'")
    }

    static func random(len: Int) -> String {
        let characters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var randomStr = ""
        for _ in 0...len {
            let index = Int(arc4random_uniform(UInt32(characters.count)))
            randomStr.append(characters[characters.index(characters.startIndex, offsetBy: index)])
        }
        return randomStr
    }

    func appendingPathComponent(_ path: String) -> String {
        let result = URL(fileURLWithPath: self).appendingPathComponent(path)
        return result.path
    }

//    // url decode
//    func urlDecoded() -> String {
//        return removingPercentEncoding ?? ""
//    }

    func matches(of regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range) }
        } catch {
            return []
        }
    }

    /// match signature
    func matcheSignatureImgsSrc() -> [String] {
        let regex = "(\\ssrc=\"http.*?signature=true.*?\")"
        return matches(of: regex)
    }

    func substring(from index: Int) -> String {
        if self.count > index {
            let startIndex = self.index(self.startIndex, offsetBy: index)
            let subString = self[startIndex..<self.endIndex]

            return String(subString)
        } else {
            return ""
        }
    }

    var removeAllSpaceAndNewlines: String {
        return self.replacingOccurrences(of: " ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 埋点的通用加密逻辑：https://bytedance.feishu.cn/wiki/wikcnkpRkznYcOUYekHTZ9zATwg
    func encriptUtils() -> String {
        let saltA = "08a441"
        let saltB = "42b91e"
        return (saltA + (self + saltB).md5()).sha1()
    }
}

extension String: MailExtensionCompatible {}
extension MailExtension where BaseType == String {
    var isGif: Bool {
        return self.base.lowercased().hasSuffix(".gif")
    }
}
