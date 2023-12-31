//
//  NSRegularExpression+LarkFoundation.swift
//  LarkExtensions
//
//  Created by liuwanlin on 2019/4/23.
//

import Foundation

public extension NSRegularExpression {
    func matches(_ string: String) -> [String] {
        let input = string as NSString
        let range = NSRange(location: 0, length: input.length)
        let results = self.matches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)

        return results.map { result -> String in
            input.substring(with: result.range)
        }
    }
}
