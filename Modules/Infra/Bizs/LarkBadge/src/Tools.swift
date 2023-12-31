//
//  Tools.swift
//  Kingfisher
//
//  Created by KT on 2019/4/26.
//

import Foundation

extension DispatchQueue {

    /// 主线程安全
    ///
    /// - Parameter block: 回调
    public func mainSafe(_ block: @escaping () -> Void) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
}
