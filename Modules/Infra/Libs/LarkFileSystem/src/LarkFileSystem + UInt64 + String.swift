//
//  LarkFileSystem + UInt64 + String.swift
//  DateToolsSwift
//
//  Created by PGB on 2020/3/16.
//

import Foundation

extension UInt64 {
    var megaByteFormat: Double {
        return Double(self) / 1024.0 / 1024.0
    }

    var formattedSize: String {
        return String(format: "%.4fMB", megaByteFormat)
    }
}

extension String {
    func exactlyMatches(_ regexPattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: .caseInsensitive) else { return false }
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))

        return matches.first?.range.length == self.count
    }

    func appendingPathComponent(_ str: String) -> String {
        return NSString(string: self).appendingPathComponent(str)
    }

    var level: Int {
        return self.split(separator: "/").count
    }
}
