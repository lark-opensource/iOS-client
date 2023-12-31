//
//  OPBlockLock.swift
//  OPBlock
//
//  Created by 王飞 on 2021/11/23.
//

class BlockLock {
    let semaphore: DispatchSemaphore

    init() {
        semaphore = DispatchSemaphore(value: 1)
    }

    func lock() {
        semaphore.wait()
    }

    func unlock() {
        semaphore.signal()
    }
}
