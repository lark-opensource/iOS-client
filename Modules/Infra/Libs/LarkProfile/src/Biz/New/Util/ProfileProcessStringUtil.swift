//
//  ProfileProcessStringUtil.swift
//  LarkProfile
//
//  Created by ByteDance on 2023/3/20.
//

import Foundation
import UIKit

struct ProfileProcessStringUtil {

    /// 按照特定字符计数规则，截取字符串
    /// - Parameter maxLength: 最大长度
    /// - Parameter forText: 文本内容
    /// - Parameter characterRatio: 中英文字符比
    /// - Returns: 处理结果
    static func getPrefix(_ maxLength: Int, forText text: String, characterRatio ratio: Int) -> String {
        guard maxLength >= 0 else { return "" }
        var currentLength: Int = 0
        var maxIndex: Int = 0
        for (index, char) in text.enumerated() {
            guard currentLength <= maxLength else { break }
            currentLength += min(char.utf8.count, ratio)
            maxIndex = index
        }
        return String(text.prefix(maxIndex))
    }

    /// 按照特定字符计数规则，获取字符串长度
    /// - Parameter forText: 文本内容
    /// - Parameter characterRatio: 中英文字符比
    /// - Returns: 处理结果
    static func getLength(forText text: String, characterRatio ratio: Int) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 ratio 个字符
            return res + min(char.utf8.count, ratio)
        }
    }
    
    /// 校验是否有特殊字符
    /// - Parameter string: 文本内容
    /// - Returns: 有-true，无-false
    static func hasSpecialCharacters(_ string: String) -> Bool {
        let characterSet = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|\\;:'\",.<>?/~`")
        return string.rangeOfCharacter(from: characterSet) != nil
    }

    /// 校验有多少个左括号(  右括号 )
    static func countBracketsInAttributedString(_ string: String) -> (left: Int, right: Int) {
        let leftBracketPattern = "\\("
        let rightBracketPattern = "\\)"
        
        let leftRegex = try? NSRegularExpression(pattern: leftBracketPattern, options: [])
        let rightRegex = try? NSRegularExpression(pattern: rightBracketPattern, options: [])
        
        let leftMatches = leftRegex?.matches(in: string, options: [], range: NSRange(location: 0, length: string.count)) ?? []
        let rightMatches = rightRegex?.matches(in: string, options: [], range: NSRange(location: 0, length: string.count)) ?? []
        
        return (left: leftMatches.count, right: rightMatches.count)
    }

    static func countBracketsMoreThanApair(_ string: String) -> Bool {
        let (left, right) = Self.countBracketsInAttributedString(string)
        if left == right, left > Cons.apairBrackets {
            return true
        }
        return false
    }

    /// 根据语言来判断是否是需要处理的语言
    public static func isToProcessLanguage() -> Bool {
        let language = BundleI18n.currentLanguage
        // 测试出以下语言需要处理添加margin
        return language == .en_US ||
        language == .id_ID ||
        language == .de_DE ||
        language == .es_ES ||
        language == .fr_FR ||
        language == .it_IT ||
        language == .pt_BR ||
        language == .ru_RU ||
        language == .th_TH ||
        language == .hi_IN ||
        language == .vi_VN
    }

    public static func isChinese() -> Bool {
        let language = BundleI18n.currentLanguage
        return language == .zh_CN
    }

    // nolint: magic_number - 工具方法
    public static func getSpecialTypeNameTagReplenishHMargin() -> CGFloat? {
        let hMarginMap = ["iPhone 14 Pro Max" : 30,
                          "iPhone SE" : 25,
                          "iPhone SE (2nd generation)" : 25,
                          "iPhone SE (3rd generation)" : 25]
        let currentDeviceName = UIDevice.current.lu.modelName()
        if let hMargin = hMarginMap[currentDeviceName] {
            return CGFloat(hMargin)
        }
        return nil
    }
}

extension ProfileProcessStringUtil {
    enum Cons {
        static var apairBrackets: Int { 1 }
    }
}
