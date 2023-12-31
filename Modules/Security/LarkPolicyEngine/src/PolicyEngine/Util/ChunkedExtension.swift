//
//  ChunkedExtension.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/2/9.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Dictionary {
    func chunked(into size: Int) -> [Self] {
        return Array(self).chunked(into: size).map { Dictionary(uniqueKeysWithValues: $0) }
    }
}
