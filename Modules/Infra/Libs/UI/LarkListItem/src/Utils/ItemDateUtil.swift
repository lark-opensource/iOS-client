//
//  ItemDateUtil.swift
//  CryptoSwift
//
//  Created by Yuri on 2023/5/31.
//

import Foundation
#if canImport(LarkExtensions)
import LarkExtensions

class ItemDateUtil {
    static func dataString(_ interval: Int64) -> String {
        return Date.lf.getNiceDateString(TimeInterval(interval))
    }
}
#else
class ItemDataUtil {
    static func dataString(_ interval: Int64) -> String {
        return "Yesterday"
    }
}
#endif
