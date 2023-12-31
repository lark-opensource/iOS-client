//
//  LKBGTracker.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/19.
//

import Foundation

/// 打点上报
public protocol LKBGTracker {
    /// 后台刷新任务打点
    func refresh(metric: [String: Any], category: [String: Any], extra: [String: Any])
    /// 后台处理任务打点
    func processing(metric: [String: Any], category: [String: Any], extra: [String: Any])
}

extension LKBGTracker {
    func refresh(metric: [String: Any], category: [String: Any] = [:], extra: [String: Any] = [:]) {
        self.refresh(metric: metric, category: category, extra: extra)
    }

    func processing(metric: [String: Any], category: [String: Any] = [:], extra: [String: Any] = [:]) {
        self.processing(metric: metric, category: category, extra: extra)
    }
}
