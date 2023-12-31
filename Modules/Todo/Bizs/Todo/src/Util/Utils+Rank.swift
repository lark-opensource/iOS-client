//
//  Utils+Rank.swift
//  Todo
//
//  Created by baiyantao on 2022/9/4.
//

import Foundation

// https://bytedance.feishu.cn/docx/BRXwdrSEaoKZnJxU35PcIGSYnSf
extension Utils {
    struct Rank { }
}

extension Utils.Rank {
    /// 默认最大的rank, 放到最后的
    static let defaultRank = "iiiiii"
    static let defaultRankLen = 6
    /// 与server约定的最小值，server拿到这个值后会重新修正
    static let defaultMinRank = "000000"
    /// 客户端用的Rank
    static let defaultClientRank = "kkkkkk"

    static func next(of rankStr: String) -> String {
        var rank = Array(rankStr)
        var replaceRank = [Character]()

        for char in rank.reversed() {
            let nextChar = nextChar(of: char)
            if nextChar != invalidChar {
                replaceRank.append(nextChar)
                break
            }
            replaceRank.append(min)
        }

        if replaceRank.count >= rank.count {
            return rankStr + stepStr
        } else {
            rank.replaceSubrange((rank.count - replaceRank.count)...(rank.count - 1), with: replaceRank.reversed())
            return String(rank)
        }
    }

    static func pre(of rankStr: String) -> String {
        var rank = Array(rankStr)
        var replaceRank = [Character]()

        for char in rank.reversed() {
            let preChar = preChar(of: char)
            if preChar != invalidChar {
                replaceRank.append(preChar)
                break
            }
            replaceRank.append(max)
        }

        if replaceRank.count >= rank.count {
            assertionFailure()
            return defaultRank
        } else {
            rank.replaceSubrange((rank.count - replaceRank.count)...(rank.count - 1), with: replaceRank.reversed())
            return String(rank)
        }
    }

    static func middle(of preStr: String, and nextStr: String) -> String {
        if preStr == nextStr {
            return preStr
        }
        let isExchenge = preStr > nextStr
        let preRank = isExchenge ? Array(nextStr) : Array(preStr)
        let nextRank = isExchenge ? Array(preStr) : Array(nextStr)
        var resRank = [Character]()

        var index = 0
        var isBorrow = false
        var loopCount = 0
        while true {
            if loopCount >= 1_000 {
                V3Home.logger.error("rank middle dead loop, pre: \(preStr), next: \(nextStr)")
                assertionFailure()
                return defaultRank
            }
            loopCount += 1

            let preChar = index < preRank.count ? preRank[index] : min
            let nextChar = (isBorrow || index >= nextRank.count) ? max : nextRank[index]
            let middleChar = middleChar(between: preChar, and: nextChar)

            resRank.append(middleChar)
            index += 1

            if preChar < middleChar && middleChar < nextChar {
                break
            }

            if nextChar > preChar {
                isBorrow = true
            }
        }

        // 得到的结果如果比 preRank 还短，需要用 preRank 多出的后缀来补齐
        if resRank.count < preRank.count {
            resRank.append(contentsOf: preRank[resRank.count...])
        }

        // 补齐后的结果如果仍旧比最低位数少，再补一些值
        if resRank.count < defaultRankLen {
            let char = Character("1")
            resRank.append(contentsOf: Array(repeating: char, count: defaultRankLen - resRank.count))
        }

        return String(resRank)
    }

    static func index(of char: Character) -> Int {
        let asciiOf0: UInt8 = 48
        let asciiOf9: UInt8 = 57
        let asciiOfa: UInt8 = 97
        let asciiOfz: UInt8 = 122

        guard let ascii = char.asciiValue, ascii >= asciiOf0, ascii <= asciiOfz else {
            assertionFailure()
            return 0
        }
        if ascii >= asciiOf0 && ascii <= asciiOf9 {
            return Int(ascii - asciiOf0)
        }
        if ascii >= asciiOfa && ascii <= asciiOfz {
            return Int(ascii - asciiOfa + 10)
        }
        assertionFailure()
        return 0
    }
}

// private
extension Utils.Rank {
    private static let chars: [Character] = Array("0123456789abcdefghijklmnopqrstuvwxyz") // 0 一般不出现
    private static let min: Character = "1"
    private static let max: Character = "z"
    private static let step = 8
    private static let stepStr = "8"
    private static let invalidChar: Character = "0"

    private static func nextChar(of char: Character) -> Character {
        let nextIndex = index(of: char) + step
        guard nextIndex > 0 && nextIndex < chars.count else {
            return invalidChar
        }
        return chars[nextIndex]
    }

    private static func preChar(of char: Character) -> Character {
        let preIndex = index(of: char) - step
        guard preIndex > 0 && preIndex < chars.count else {
            return invalidChar
        }
        return chars[preIndex]
    }

    private static func middleChar(between lhs: Character, and rhs: Character) -> Character {
        let middleIndex = (index(of: lhs) + index(of: rhs)) / 2
        guard middleIndex > 0 && middleIndex < chars.count else {
            return invalidChar
        }
        return chars[middleIndex]
    }
}
