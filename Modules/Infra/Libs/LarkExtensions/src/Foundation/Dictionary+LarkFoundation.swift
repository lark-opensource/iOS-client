//
//  Dictionary+Lark.swift
//  Lark
//
//  Created by Yuguo on 2017/9/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public extension Dictionary {
    /// Union of two dictionaries
    /// Note: The <key, value> in the argument will override
    /// the current dictionary's <key, value> if the keys match
    @inlinable func lf_update(_ dict: [Key: Value]) -> [Key: Value] {
        self.merging(dict, uniquingKeysWith: { $1 })
    }

    /// Returns a new dictionary that contains the combined key-value pairs of the two dictionaries,
    /// with duplicate keys removed and their corresponding values merged using the right-hand provided.
    /// - Parameters:
    ///   - lhs: The left-hand side dictionary to combine.
    ///   - rhs: The right-hand side dictionary to combine.
    /// - Returns: A new dictionary that contains the combined key-value pairs of the two dictionaries.
    @inlinable static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        lhs.merging(rhs, uniquingKeysWith: { $1 })
    }
}
