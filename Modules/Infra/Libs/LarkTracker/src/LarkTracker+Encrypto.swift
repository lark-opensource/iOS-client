//
//  LarkTracker+Encrypto.swift
//  LarkTracker
//
//  Created by 李晨 on 2019/12/5.
//

import Foundation
import CryptoSwift

public struct Encrypto {
    public static func encryptoId(_ id: String) -> String {
        if id.isEmpty {
            return ""
        }
        let encryptoId = prefixToken() + (id + suffixToken()).md5()
        return encryptoId.sha1()
    }

    static func prefixToken() -> String {
        let prefix = "ee".md5()
        if prefix.count > 6 {
            return prefix[0..<6]
        }
        return prefix
    }

    static func suffixToken() -> String {
        let prefix = "ee".md5()
        if prefix.count > 6 {
            return prefix[(prefix.count - 6)..<prefix.count]
        }
        return prefix
    }
}

extension String {
    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}
