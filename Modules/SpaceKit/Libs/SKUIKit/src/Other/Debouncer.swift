//
//  Debouncer.swift
//  SpaceKit
//
//  Created by Webster on 2020/5/12.
//

import SKFoundation

public final class SKThrottle {
    private let delayInterval: DispatchTimeInterval
    private let delayFloat: Double
    private lazy var queue: DispatchQueue = {
        let label = "com.bytedance.ee.docs.debouncer." + UUID().uuidString
        let q = DispatchQueue(label: label, qos: .userInteractive)
        return q
    }()

    private let itemsMap = ThreadSafeDictionary<String, DispatchWorkItem>()
    private let timeMap = ThreadSafeDictionary<String, TimeInterval>()

    public init(interval: Double) {
        delayFloat = interval
        delayInterval = .milliseconds(Int(interval * 1000))
    }

    //设置成第一次肯定会触发
    public func schedule(_ job: @escaping (() -> Void), jobId: String) {
        //没有分发过、或者节流时间到了
        if canFireJob(jobId) {
            itemsMap.value(ofKey: jobId)?.cancel()
            itemsMap.removeValue(forKey: jobId)
            timeMap.updateValue(NSDate().timeIntervalSince1970, forKey: jobId)
            DispatchQueue.main.async { job() }
        } else {
            /*
            itemsMap.value(ofKey: jobId)?.cancel()
            itemsMap.removeValue(forKey: jobId)
            let newWorkItem = DispatchWorkItem { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.canFireJob(jobId) {
                    DispatchQueue.main.async {
                        strongSelf.timeMap.updateValue(NSDate().timeIntervalSince1970, forKey: jobId)
                        job()
                    }
                }
            }
            itemsMap.updateValue(newWorkItem, forKey: jobId)
            queue.asyncAfter(deadline: .now() + delayInterval, execute: newWorkItem)
            */
        }

    }

    private func canFireJob(_ jobId: String) -> Bool {
        if let lastFireTime = timeMap.value(ofKey: jobId) {
            let interval = NSDate().timeIntervalSince1970 - lastFireTime
            return interval > delayFloat
        } else {
            return true
        }
    }

}
