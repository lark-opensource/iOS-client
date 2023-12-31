//
//  String.swift
//  Minutes_iOS
//
//  Created by panzaofeng on 2021/2/28.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation

extension String {
    public func ranges(of searchString: String) -> [NSRange] {
        let string = self as NSString

        var ranges = [NSRange]()
        var searchRange = NSRange()
        var range: NSRange = string.range(of: searchString)
        while range.location != NSNotFound {
            ranges.append(range)
            searchRange = NSRange(location: NSMaxRange(range), length: string.length - NSMaxRange(range))
            range = string.range(of: searchString, options: [], range: searchRange)
        }
        return ranges
    }
}

extension String {
    public func convertToTimeInterval() -> TimeInterval? {
        guard !self.isEmpty else {
            return nil
        }

        var interval: TimeInterval = 0

        let parts = self.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            if let value = Double(part) {
                interval += value * pow(Double(60), Double(index))
            } else {
                return nil
            }
        }

        return interval
    }
}

extension Substring {
    public func covertTime() -> (TimeInterval, TimeInterval)? {
        guard !self.isEmpty else {
            return nil
        }

        let parts = self.components(separatedBy: "-->")
        guard parts.count == 2 else { return nil }

        guard let startTime = parts.first?.convertToTimeInterval() else {
            return nil
        }

        guard let endString = parts.last?.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).first,
              let endTime = endString.convertToTimeInterval() else {
            return nil
        }

        return (startTime, endTime)
    }
}

extension RangeReplaceableCollection where Self: StringProtocol {
    public mutating func removeAllAt() {
        removeAll { $0 == "@" }
    }
}
