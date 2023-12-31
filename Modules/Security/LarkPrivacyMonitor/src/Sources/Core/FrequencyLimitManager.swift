//
//  FrequencyLimitManager.swift
//  LarkPrivacyMonitor
//
//  Created by huanzhengjie on 2023/4/28.
//

import LarkSnCService

/// 高频降级逻辑
/// 单位时间内某个API 调用次数超过一定阈值则触发降级逻辑
private final class RateLimiter {
    // 时间阈值，单位秒
    private let timeThreshold: Int
    // 调用次数阈值
    private let countThreshold: Int
    // 当前调用次数
    private var count: Int = 0
    // 上次调用时间
    private var lastCallTime: Int64 = 0

    init(timeThreshold: Int, countThreshold: Int) {
        self.timeThreshold = timeThreshold
        self.countThreshold = countThreshold
    }

    func limited() -> Bool {
        let now = Int64(CFAbsoluteTimeGetCurrent() * 1000)
        if now - lastCallTime > timeThreshold * 1000 {
            count = 0
            lastCallTime = now
        }
        count += 1
        return count > countThreshold
    }
}

/// 高频检测降级逻辑，性能优化
/// 用于高频调用或者循环调用时的容错降级
final class FrequencyLimitManager {
    public static let shared = FrequencyLimitManager()
    private var countThreshold = 10
    private var timeThreshold = 1
    private lazy var apiRateLimiters = [String: RateLimiter]()
    private let lock = NSLock()
    private init() {}

    /// 检测某个API调用是否触发了限频逻辑
    func limited(of apiMethod: String) -> Bool {
        // 存在多线程环境，加锁保护
        lock.lock()
        defer {
            lock.unlock()
        }
        var limiter = apiRateLimiters[apiMethod]
        if nil == limiter {
            limiter = RateLimiter(timeThreshold: timeThreshold, countThreshold: countThreshold)
            apiRateLimiters[apiMethod] = limiter
        }
        return (limiter?.limited()).or(false)
    }

    /// 更新频次和时间判断的阈值（只有在启动阶段配置使用）
    func updateThreshold(timeThreshold: Int, countThreshold: Int) {
        self.timeThreshold = timeThreshold
        self.countThreshold = countThreshold
    }

}
