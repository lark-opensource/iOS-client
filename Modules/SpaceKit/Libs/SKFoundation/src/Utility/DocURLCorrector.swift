//
//  DocURLCorrector.swift
//  SKFoundation
//
//  Created by huayufan on 2023/3/1.
//  


import UIKit

// 对正则匹配的URL做矫正
// https://bytedance.feishu.cn/docx/Q8F4d8QSaoyMMDxBjOMcQxvEnTh
public class DocURLCorrector {
    
    let brackets = ["[":"]", "(": ")", "<": ">", "{": "}"]
    let bracketsRevert = ["]": "[", ")": "(", ">": "<", "}": "{"]
    
    let blackSuffixList: [String] // [".", ",", "!", "?", "'", ":", ";", "#", "@"]

    enum Bracket: String {
        case parentheses = "("
        case square = "["
        case curly = "{"
        case angle = "<"
    }
    
    public init(blackList: [String]) {
        self.blackSuffixList = blackList
    }
    
    public func correctRange(urlRange: NSRange, urlStr: String, linkRegex: String) -> [NSRange] {
        var result: [NSRange] = []
        let range = checkBracket(urlRange: urlRange, urlStr: urlStr)
        result.append(range)
        
        let del = urlRange.length - range.length
        if del > 0 { // 后面有部分被切割掉了，需要看下后面部分是否能组成合法URL
           let leftRange = NSRange(location: range.location + range.length, length: del)
            if let strRange = Range(leftRange, in: urlStr) {
                let str = String(urlStr[strRange])
                var subRanges = str.docs.regularUrlRanges(pattern: linkRegex)
                subRanges = subRanges.map { NSRange(location: leftRange.location + $0.location, length: $0.length) }
                for subRange in subRanges {
                    result.append(contentsOf: self.correctRange(urlRange: subRange, urlStr: urlStr, linkRegex: linkRegex))
                }
            }
        }
        
        return result.map { checkLastBlackSuffix(urlRange: $0, urlStr: urlStr) }
    }

    func checkBracket(urlRange: NSRange, urlStr: String) -> NSRange {
        guard let strRange = Range(urlRange, in: urlStr) else { return urlRange }
        let str = String(urlStr[strRange])
        var recordList: [(Bracket, Int)] = []

        func findStackRange() -> NSRange {
            if let (_, preIdx) = recordList.first {
                return NSRange(location: urlRange.location, length: preIdx)
            } else {
                return urlRange
            }
        }
        
        for (idx, sub) in str.enumerated() {
            let subStr = String(sub)
            if let bracket = Bracket(rawValue: subStr) { // 匹配到了左边括号
                recordList.append((bracket, idx))
            } else if let res = bracketsRevert[subStr],
                      let bracket = Bracket(rawValue: res) { // 匹配到了右边括号
                if let (preBracket, _) = recordList.last {
                    if preBracket.rawValue != bracket.rawValue {
                        // 不需要匹配了，后面直接不符合预期
                        return findStackRange()
                    } else {
                        recordList.popLast()
                    }
                } else {
                    // 不需要匹配了，后面直接不符合预期
                    return NSRange(location: urlRange.location, length: idx)
                }
            } else {
                continue
            }
        }
        return findStackRange()
    }
    
    func checkLastBlackSuffix(urlRange: NSRange, urlStr: String) -> NSRange {
        guard let strRange = Range(urlRange, in: urlStr) else { return urlRange }
        var str = String(urlStr[strRange])

        var length = urlRange.length
        while !str.isEmpty,
              blackSuffixList.contains(String(str.suffix(1))) {
            str.removeLast()
            length -= 1
        }
        return NSRange(location: urlRange.location, length: length)
    }
    
}
