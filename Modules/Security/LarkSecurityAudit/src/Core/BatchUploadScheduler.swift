//
//  BatchUploadScheduler.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//

import Foundation

final class BatchUploadScheduler {

    /// 一个 上传时间周期 内发送请求数
    private var reqCntInTimeInterval: Int = 0
    /// 一个 上传时间周期 内的最大请求数
    private var maxReqCntInTimeInterval: Int = Const.maxReqCntInTimeInterval
    /// 前一次请求时间
    private var previousReqTimestamp: CFAbsoluteTime = 0
    /// 上传时间周期
    private var scheduleTimeInerval: TimeInterval = TimeInterval(Const.batchTimerInterval)
    /// 上传成功次数
    private var reqSuccessCnt: Int = 0

    init() {

    }

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

    func record(_ result: Result<Void, Error>) {
        switch result {
        case .success:
            ascend()
        case .failure(let error):
            if let err = error as? SecurityAuditError {
                switch err {
                case .badBizCode:
                    break
                case .badHTTPStatusCode:
                    desend()
                case .badServerData:
                    break
                case .mergeDataFail, .serializeDataFail, .unknown:
                    break
                }
            }
        }
    }

    private func desend() {
        self.reqSuccessCnt = 0
        self.maxReqCntInTimeInterval = 1
        self.scheduleTimeInerval = min(TimeInterval(Const.maxBatchTimerInterval), self.scheduleTimeInerval * 2)
    }

    private func ascend() {
        // 未降级，或已恢复无需处理
        if self.maxReqCntInTimeInterval >= Const.maxReqCntInTimeInterval {
            return
        }

        if self.reqSuccessCnt >= Const.recoveryThreshold {
            self.reqSuccessCnt = 0
            // 恢复 上传时间周期
            self.scheduleTimeInerval /= 2
            if self.scheduleTimeInerval < TimeInterval(Const.batchTimerInterval) {
                self.scheduleTimeInerval = TimeInterval(Const.batchTimerInterval)
                // 恢复 周期内 上传次数
                self.maxReqCntInTimeInterval += 1
            }
        }
        self.reqSuccessCnt += 1
    }
}
