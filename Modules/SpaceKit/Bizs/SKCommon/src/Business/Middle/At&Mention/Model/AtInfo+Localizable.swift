//
//  AtInfo+Localizable.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/2/21.
//  

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SpaceInterface
/// ReadMe
/// AtInfo 处理了 HTML 里 不带多语言的解析
/// 这个分类主要用来解决带多语言的（即 < ... en_name='' name=''> ）
extension AtInfo {
    public var localizableEncodeString: String {
        let external = isExternal ? "1" : "0"
        if type == .user || type == .group {
            return "<at category=\"at-user-block\" type=\"\(type.rawValue)\" href=\"\" is_external=\"\(external)\" token=\"\(token)\" name=\"\(name ?? "")\" en_name=\"\(enName ?? "")\">@\(at)</at>"
        } else if type == .group {
            return "<at type=\"\(type.rawValue)\" href=\"\" is_external=\"\(external)\" token=\"\(token)\">@\(at)</at>"
        } else if let iconInfo = self.iconInfo {
            let icon = "{\"type\":\(iconInfo.typeValue),\"key\":\"\(iconInfo.key)\",\"fs_unit\":\"\(iconInfo.fsunit)\"}"
            return "<at type=\"\(type.rawValue)\" href=\"\(href)\" is_external=\"\(external)\" token=\"\(token)\" icon='\(icon)'>\(at)</at>"
        } else {
            return "<at type=\"\(type.rawValue)\" href=\"\(href)\" is_external=\"\(external)\" token=\"\(token)\">\(at)</at>"
        }
    }

    /*
    // 将 String 中的 <at></at> 转换成对应的富文本格式
    public static func translateAtFormat(from text: String,
                                         font: CGFloat,
                                         lineBreakMode: NSLineBreakMode = .byWordWrapping) -> NSMutableAttributedString {
        return translateAtFormat(from: text,
                                 attributes: AtInfo.TextFormat.defaultAttributes(fontSize: font),
                                 lineBreakMode: lineBreakMode,
                                 makeInfo: AtInfo.makeInfoForLocalizable)
    }

    private static func translateAtFormat(from text: String,
                                          attributes: [NSAttributedString.Key: Any],
                                          lineBreakMode: NSLineBreakMode = .byWordWrapping,
                                          makeInfo: ((NSTextCheckingResult, NSString) -> AtInfo?)) -> NSMutableAttributedString {
        guard let pattern = AtInfo.murkyRegularExpression else {
            DocsLogger.info("At 获取正则错误")
            return NSMutableAttributedString(string: text)
        }
        let atInfoResult = parseMessageContent(in: text, pattern: pattern, makeInfo: makeInfo)
        let mutaAttrString = NSMutableAttributedString(string: "")
        atInfoResult.forEach { (result) in
            var attrString: NSAttributedString
            switch result {
            case .string(let str):
                attrString = NSAttributedString(string: str, attributes: attributes)
            case .atInfo(let atInfo):
                attrString = atInfo.attributedString(attributes: attributes, lineBreakMode: lineBreakMode)
            }
            mutaAttrString.append(attrString)
        }
        return mutaAttrString
    }
     */

    /// 模糊匹配
    static var murkyRegularExpression: NSRegularExpression? = {
        let pattern = "<at(\n|.)*?>(\n|.)*?</at>"
        let regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            return nil
        }
        return regex
    }()
    /// 精准匹配多语言
    static var localizableRegularExpression: NSRegularExpression? = {
        let pattern = "<at category=\"at-user-block\" type=\"([\\s\\S]*?)\" href=\"([\\x00-\\xFF]*?)\" token=\"([A-Za-z0-9]+?)\" name=\"([\\s\\S]*?)\" en_name=\"([\\s\\S]*?)\">([\\s\\S]*?)</at>"
        let regex: NSRegularExpression?
        do {
            regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            return nil
        }
        return regex
    }()
}

public extension AtInfo {
//    private static func makeInfoForLocalizable(_ result: NSTextCheckingResult,
//                                               _ text: NSString) -> AtInfo? {
//        let matchType = "(?<=type=\")([\\s\\S]*?)(?=\")"
//        let matchToken = "(?<=token=\")([A-Za-z0-9]+?)(?=\")"
//        let matchHref = "(?<=href=\")([\\x00-\\xFF]*?)(?=\")"
//        let matchAt = "(?<=>)([\\s\\S]*?)(?=</at>)"
//        let matchEnName = "(?<=en_name=\")([\\s\\S]*?)(?=\")"
//        let matchName = "(?<=name=\")([\\s\\S]*?)(?=\")"
//        let matchIcon = "(?<=icon=\')([\\s\\S]*?)(?=\')"
//        func match(_ str: String, regular: String) -> String? {
//            let result = str.matches(for: regular)
//            return result.count > 0 ? result[0] : nil
//        }
//        let str = text.substring(with: result.range)
//        if let type = match(str, regular: matchType),
//           let token = match(str, regular: matchToken),
//           var at = match(str, regular: matchAt) {
//            let href = str.matches(for: matchHref)[0]
//            if let first = at.first, first == "@" { at = at[1..<at.count] }
//            if let intType = Int(type) {
//                let t = AtType(rawValue: intType) ?? .unknown
//                let info = AtInfo(type: t, href: href, token: token, at: at)
//                if let enName = match(str, regular: matchEnName) { info.enName = enName }
//                if let name = match(str, regular: matchName) { info.name = name }
//                info.iconInfo = Self.makeIconInfo(with: match(str, regular: matchIcon))
//                return info
//            }
//        }
//        return nil
//    }

    static func makeIconInfo(with jsonStr: String?) -> RecommendData.IconInfo? {
        guard let jsonStr = jsonStr else { return nil }
        let iconJson = JSON(parseJSON: jsonStr)
        if let iconTypeRaw = iconJson["type"].int,
           let iconType = SpaceEntry.IconType(rawValue: iconTypeRaw),
           let iconKey = iconJson["key"].string,
           let iconFSUnit = iconJson["fs_unit"].string {
            return RecommendData.IconInfo(type: iconType, key: iconKey, fsunit: iconFSUnit)
        } else {
            return nil
        }
    }
    
    /// 根据用户名返回Mention内容
    static func mentionString(userName: String) -> NSAttributedString? {
        var text = BundleI18n.SKResource.Doc_Doc_FeedItemAtMsg(userName)
        
        // 匹配出html标签
        let pattern = "(<[a-zA-Z]+.*?>)|(</[a-zA-Z]*?>)"
        let regularExpression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = regularExpression?.matches(in: text, options: .reportCompletion, range: NSRange(location: 0, length: text.count)) ?? []
        let mentionFont = UIFont(name: "Helvetica Neue", size: 16) ?? UIFont.systemFont(ofSize: 16)
        guard matches.count == 2 else {
            // 印地语正则匹配失败，使用降级方案
            return defaultMentionString(text: text, mentionFont: mentionFont)
        }
        
        // 移除标签
        text = text.replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: nil)
        
        // 对部分文字高亮处理
        let res = NSMutableAttributedString(string: text, attributes: [.font: mentionFont])
        let len = matches[1].range.location - (matches[0].range.location) - matches[0].range.length
        let nRange = NSRange(location: matches[0].range.location, length: len)
        // 预防越界
        if nRange.location + nRange.length <= res.length {
            res.addAttributes([.foregroundColor: UIColor.ud.rgb(0x3686FF)], range: nRange)
        }
        return res
    }
    
    private static func defaultMentionString(text: String, mentionFont: UIFont) -> NSAttributedString {
        var template = text
        template = template.replacingOccurrences(of: "(<[a-zA-Z]+.*?>)|(</[a-zA-Z]*?>)", with: "", options: .regularExpression, range: nil)
        return NSAttributedString(string: template, attributes: [.font: mentionFont])
    }
}
