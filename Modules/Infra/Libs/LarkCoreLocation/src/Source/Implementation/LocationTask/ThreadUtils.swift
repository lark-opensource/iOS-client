//
//  ThreadUtils.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 5/1/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
/// 按需切换到主线程执行逻辑
/// - Parameters:
///   - block: 需要执行的逻辑
func executeOnMainThread(block: @escaping os_block_t) {
    if !Thread.isMainThread {
        // 非主线程 执行main queue 同步操作 不会死锁
        DispatchQueue.main.sync {
            block()
        }
    } else {
        block()
    }
}
