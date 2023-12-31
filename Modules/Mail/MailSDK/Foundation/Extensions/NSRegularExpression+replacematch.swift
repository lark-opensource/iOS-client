//
//  NSRegularExpression+replacematch.swift
//  MailSDK
//
//  Created by 谭志远 on 2019/7/23.
//

import Foundation

extension NSRegularExpression {
    typealias NSRegularBlock = (_ result: NSTextCheckingResult) -> String
    func replaceMatchesInString(string: NSMutableString, matchIndex: Int = 0, block: NSRegularBlock) {
        let matches = self.matches(in: (string as String), options: .reportCompletion, range: NSRange(location: 0, length: string.length))
        for match in matches.reversed() where match.numberOfRanges > matchIndex {
            string.replaceCharacters(in: match.range(at: matchIndex), with: block(match))
        }
    }

    func replaceMatchesInString(string: NSMutableString, matchIndex: Int = 0, with replacement: String) {
        replaceMatchesInString(string: string, matchIndex: matchIndex) { (_) in
            return replacement
        }
    }
}

extension String {
    // convert NSRange to Range<String.Index>
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location + nsRange.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
        else { return nil }
        return from ..< to
    }

    func indicesOf(string: String) -> [Int] {
        // Converting to an array of utf8 characters makes indicing and comparing a lot easier
        let search = self.utf8.map { $0 }
        let word = string.utf8.map { $0 }

        var indices = [Int]()

        // m - the beginning of the current match in the search string
        // i - the position of the current character in the string we're trying to match
        var m = 0, i = 0
        while m + i < search.count {
            if word[i] == search[m + i] {
                if i == word.count - 1 {
                    indices.append(m)
                    m += i + 1
                    i = 0
                } else {
                    i += 1
                }
            } else {
                m += 1
                i = 0
            }
        }

        return indices
    }
}
