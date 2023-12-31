//
//  FlowController.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/2/28.
//

import Foundation
import ThreadSafeDataStructure

class FlowController {
    private(set) var bucket = SafeSet<String>([], synchronization: .readWriteLock)
    private let interval: CFTimeInterval
    private let qos: DispatchQoS

    init(interval: CFTimeInterval = 1.0, qos: DispatchQoS = .background) {
        self.interval = interval
        self.qos = qos
    }

    func execute(id: String, executor: () -> Void) {
        if bucket.contains(id) {
            return
        }

        bucket.update(with: id)
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval, qos: qos) {
                self.bucket.remove(id)
            }
        }

        executor()
    }
}
