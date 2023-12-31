//
//  MutexLock.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/18.
//

final class MutexLock {

    let semaphore: DispatchSemaphore

    init() {
        semaphore = DispatchSemaphore(value: 0)
        semaphore.signal() // 保证 V 操作次数 >= P
    }

    func lock() {
        semaphore.wait()
    }

    func unlock() {
        semaphore.signal()
    }
}
