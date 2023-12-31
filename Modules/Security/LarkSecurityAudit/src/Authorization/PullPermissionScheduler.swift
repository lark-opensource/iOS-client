//
//  PullPermissionScheduler.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/12/25.
//

import Foundation

final class PullPermissionScheduler {

    /// 一个 上传时间周期 内发送请求数
    private var reqCntInTimeInterval: Int = 0
    /// 一个 上传时间周期 内的最大请求数
    private let maxReqCntInTimeInterval: Int = Const.maxPullPermissionReqCntInTimeInterval
    /// 前一次请求时间
    private var previousReqTimestamp: CFAbsoluteTime = 0
    /// 上传时间周期
    private var scheduleTimeInerval: TimeInterval = TimeInterval(Const.batchTimerInterval)

    init() {}

    func shouldUpload() -> Bool {
        let current = CFAbsoluteTimeGetCurrent()
        if current - self.previousReqTimestamp > self.scheduleTimeInerval {
            self.reqCntInTimeInterval = 0
            self.previousReqTimestamp = current
        }
        if self.reqCntInTimeInterval >= self.maxReqCntInTimeInterval {
            return false
        }
        self.reqCntInTimeInterval += 1
        return true

    }
}
