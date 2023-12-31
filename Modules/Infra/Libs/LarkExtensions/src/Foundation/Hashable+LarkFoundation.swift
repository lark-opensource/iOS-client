//
//  Hashable+Lark.swift
//  Lark
//
//  Created by qihongye on 2018/1/15.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation

public extension Hashable {
    static func lf_iterator() -> AnyIterator<Self> {
        var index = 0
        return AnyIterator {
            let next = withUnsafeBytes(of: &index) { $0.load(as: Self.self) }
            if next.hashValue != index { return nil }
            index += 1
            return next
        }
    }
}
