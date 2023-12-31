//
//  MutexLock.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/15.
//

import Foundation
final class MutexLock {

    let semaphore: DispatchSemaphore

    init() {
        semaphore = DispatchSemaphore(value: 0)
        semaphore.signal() // 保证V操作次数>=P
    }

    func lock() {
        semaphore.wait()
    }

    func unlock() {
        semaphore.signal()
    }
}
