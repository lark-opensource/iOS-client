//
//  Lock.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/21.
//

import Foundation

/// 封装的读写锁
final class RWLock {
    private var rwlock = pthread_rwlock_t()

    init() {
        pthread_rwlock_init(&self.rwlock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&self.rwlock)
    }

    func rdSync<T>(action: () -> T) -> T {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return action()
    }

    func wrSync<T>(action: () -> T) -> T {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return action()
    }
}
