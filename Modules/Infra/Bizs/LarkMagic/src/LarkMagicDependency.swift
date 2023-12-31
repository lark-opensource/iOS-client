//
//  LarkMagicDependency.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/9.
//

import Foundation

public protocol LarkMagicDependency {
    /// 检查冲突
    ///
    /// - returns:
    ///   - isConflict: 是否冲突
    ///   - extra: 冲突描述，用于 log
    func checkConflict() -> (isConflict: Bool, extra: [String: String])
}
