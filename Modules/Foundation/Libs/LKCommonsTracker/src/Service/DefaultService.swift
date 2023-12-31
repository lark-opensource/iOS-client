//
//  DefaultService.swift
//  LKCommonsTracker
//
//  Created by 李晨 on 2019/3/25.
//

import Foundation

final class DefaultService: TrackerService {

    private var _cache: [Event] = []
    var cache: [Event] {
        pthread_rwlock_rdlock(&self.rwlock)
        defer {
            pthread_rwlock_unlock(&self.rwlock)
        }
        return _cache
    }
    var rwlock = pthread_rwlock_t()
    let platform: Platform

    init(platform: Platform) {
        self.platform = platform
        pthread_rwlock_init(&rwlock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&self.rwlock)
    }

    var serviceQueue: DispatchQueue = DispatchQueue(label: "lk.Tracker.default.service", qos: .utility)

    func post(event: Event) {
        pthread_rwlock_wrlock(&rwlock)
        defer {
            pthread_rwlock_unlock(&rwlock)
        }
        self._cache.append(event)
    }
}
