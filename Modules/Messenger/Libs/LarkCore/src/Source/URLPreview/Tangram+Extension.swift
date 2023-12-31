//
//  LarkModel+Tangram.swift
//  LarkCore
//
//  Created by 袁平 on 2021/6/10.
//

import RustPB

public extension Basic_V1_URL {
    var tcURL: String? {
        if !ios.isEmpty {
            return ios
        }
        if !url.isEmpty {
            return url
        }
        return nil
    }
}

extension String {
    func indexUTF8(from: Int) -> Index {
        return utf8.index(utf8.startIndex, offsetBy: from)
    }

    mutating func removeUTF8(from: Int, length: Int) -> String? {
        guard from < utf8.count, from + length <= utf8.count else { return nil }
        let start = self.indexUTF8(from: from)
        let end = self.indexUTF8(from: from + length)
        let subStr = utf8[start..<end]
        self.removeSubrange(start..<end)
        return String(subStr)
    }

    func substringOfUTF8(from: Int, length: Int) -> String? {
        guard from < utf8.count, from + length <= utf8.count else { return nil }
        let start = self.indexUTF8(from: from)
        let end = self.indexUTF8(from: from + length)
        let subStr = utf8[start..<end]
        return String(subStr)
    }
}
