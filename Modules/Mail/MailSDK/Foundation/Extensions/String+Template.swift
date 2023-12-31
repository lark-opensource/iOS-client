//
//  String+Template.swift
//  MessageListDemo
//
//  Created by 谭志远 on 2019/6/10.
//

import Foundation

extension String {
    func getTemplateSectionWithName(_ sectionName: String) -> String? {
        if self.isEmpty {
            return nil
        }
        let sectionBegin = "<!\(sectionName)!>"
        let sectionEnd = "<!/\(sectionName)!>"

        var start = NSNotFound
        if let range = self.nsRange(of: sectionBegin) {
            start = range.location
        }
        var end = NSNotFound
        if let range = self.nsRange(of: sectionEnd) {
            end = range.location
        }

        if start != NSNotFound && end != NSNotFound {
            return (self as NSString).substring(with: NSRange(location: start + sectionBegin.count, length: end - start - sectionBegin.count)) as String
        } else {
            MailLogger.info("Mail template section \"\(sectionName)\" is empty, consider remove it")
            return nil
        }
    }

    func getTemplateItemMatches() -> [(String, Range<String.Index>)] {
        var matches = [(String, Range<String.Index>)]()
        if let regex = MailMessageListTemplateRender.templateRegex {
            let results = regex.matches(in: self, range: NSRange(location: 0, length: utf16.count))
            for result in results {
                if let range = Range<String.Index>(result.range, in: self) {
                    let keyword = String(self[self.index(range.lowerBound, offsetBy: 1)..<self.index(range.upperBound, offsetBy: -1)])
                    matches.append((keyword, range))
                }
            }
        }
        return matches
    }

    func cleanEscapeCharacter() -> String {
        return self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    // JSON 字符串内 " 需要两次转义
    // 因为JSON格式中有 \" 包含key和value，值内实际内容需要转义为 \\\"
    // https://www.freeformatter.com/json-escape.html
    func doubleEscapeForJson() -> String {
        return self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\u{8}", with: "\\b")
            .replacingOccurrences(of: "\u{000C}", with: "\\f")
    }
    func addresIsMe() -> Bool {
        if (Store.settingData.getCachedCurrentAccount()?.mailSetting.emailAlias.allAddresses ?? [])
                    .map({ $0.address.lowercased() }).contains(self.lowercased()) {
                    return true
                }
        return false
    }
}

extension NSMutableString {
    func replace(templateStr: String, separator: String, value: String) -> NSMutableString {
        var range = NSRange(location: 0, length: self.length)
        while self.range(of: "\(separator)\(templateStr)\(separator)", options: .literal, range: range).location != NSNotFound {
            range = self.range(of: "\(separator)\(templateStr)\(separator)", options: .literal, range: range)
            self.replaceCharacters(in: range, with: value)
            range.location = range.location + value.count
            range.length = self.length - range.location
        }

        return self
    }

    func replace(templateStr: String, value: String?) -> NSMutableString {
        var string = value
        if value == nil {
            string = ""
        }

        return self.replace(templateStr: templateStr, separator: "$", value: string!)
    }

    func replace(dictionary: [String: String]) -> NSMutableString {
        for key in dictionary.keys {
            self.replace(templateStr: key, value: dictionary[key])
        }

        return self
    }

    func replaceOnce(templateStr: String, separator: String, value: String) -> NSMutableString {
        let range = self.range(of: "\(separator)\(templateStr)\(separator)")
        if range.location != NSNotFound {
            self.replaceCharacters(in: range, with: value)
        }

        return self
    }

    func replaceOnce(templateStr: String, value: String?) -> NSMutableString {
        var string = value
        if value == nil {
            string = ""
        }

        return self.replaceOnce(templateStr: templateStr, separator: "$", value: string!)
    }

    func replaceOnce(dictionary: [String: String]) -> NSMutableString {
        for key in dictionary.keys {
            self.replaceOnce(templateStr: key, value: dictionary[key])
        }

        return self
    }
}

extension StringProtocol {
    func nsRange(of string: Self, options: String.CompareOptions = [], range: Range<Index>? = nil, locale: Locale? = nil) -> NSRange? {
        var start = range?.lowerBound ?? startIndex
        let end = range?.upperBound ?? endIndex
        if start < startIndex || end > endIndex {
            return nil
        }
        guard let range = self.range(of: string, options: options, range: range ?? start..<end, locale: locale ?? .current) else { return nil }
        return .init(range, in: self)
    }
}
