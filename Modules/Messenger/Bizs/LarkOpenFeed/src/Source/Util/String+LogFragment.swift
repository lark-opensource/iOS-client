//
//  String+LogFragment.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/18.
//

import Foundation

public extension String {
    // 将过长的日志字符串分片，防止被截断
    public func logFragment() -> [String] {
        let maxLength = 14_000 // 日志里的【字符串截断】 限制的最大长度
        let count = self.count
        let times: Int
        if count % maxLength == 0 {
            times = count / maxLength
        } else {
            times = count / maxLength + 1
        }
        var list: [String] = []
        for i in 0..<times {
            let start = i * maxLength
            var end = (i + 1) * maxLength
            if end > count {
                end = count
            }
            let str = self[start..<end]
            list.append(str)
        }
        return list
    }

    subscript (r: Range<Int>) -> String {
        let lowerBound = r.lowerBound
        let upperBound = r.upperBound
        let count = self.count
        guard lowerBound <= upperBound,
              lowerBound >= 0,
              upperBound >= 0,
              lowerBound <= count,
              upperBound <= count else { return "" }
        let start = index(startIndex, offsetBy: lowerBound)
        let end = index(startIndex, offsetBy: upperBound)
        return String(self[start..<end])
    }
}
