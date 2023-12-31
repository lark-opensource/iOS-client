//
//  HelpDeskUtils.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/30.
//

import Foundation

/// 安全的异步派发到主线程执行任务
/// - Parameter block: 任务
public func executeOnMainQueueAsync(_ block: @escaping os_block_t) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

/// 安全的同步派发到主线程执行任务
/// - Parameter block: 任务
public func executeOnMainQueueSync(_ block: os_block_t) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync {
            block()
        }
    }
}
