//
//  GadgetRecoveryMonitor.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/24.
//

import Foundation
import ECOProbe
import OPSDK
import TTMicroApp

class GadgetRecoveryMonitor {

    static let current = GadgetRecoveryMonitor()

    private var gadgetsRecoveryState: [OPAppUniqueID: GadgetRecoveryState] = [:]

    private let semaphore = DispatchSemaphore(value: 1)

    /// 通知小程序自动恢复框架捕捉到错误
    func notifyGadgetRecoveryErrorCatched(recoveryContext: RecoveryContext, currentHystrixType: GadgetRecoveryHystrixType) {
        guard let uniqueID = recoveryContext.uniqueID else {
            GadgetRecoveryLogger.logger.error("GadgetRecoveryMonitor.notifyGadgetRecoveryErrorCatched: can not get uniqueID from recoveryContext")
            return
        }

        // 自动恢复框架捕获到错误发生，埋点上报
        OPMonitor(GDMonitorCode.recovery_error_catch)
            .addCategoryValue("recoveryScene", recoveryContext.recoveryScene?.value)
            .addCategoryValue("hystrixType", "\(currentHystrixType)")
            .setError(recoveryContext.recoveryError)
            .setUniqueID(uniqueID)
            .flush()

        // 下方要操作gadgetsRecoveryState字典，先加锁
        semaphore.wait()
        defer { semaphore.signal() }
        // 变更当前小程序的恢复状态
        var recoveryState = gadgetsRecoveryState[uniqueID] ?? .idle
        switch recoveryState {
        case .idle:
            recoveryState = .errorCatched
        case .errorRecoverying, .errorCatched:
            break
        }
        gadgetsRecoveryState[uniqueID] = recoveryState
    }

    /// 通知小程序正在执行恢复重试相关的操作
    func notifyGadgetRecoveryRecoverying(uniqueID: OPAppUniqueID) {
        // 埋点上报
        OPMonitor(GDMonitorCode.recovery_error_retry)
            .setUniqueID(uniqueID)
            .flush()

        // 下方要操作gadgetsRecoveryState字典，先加锁
        semaphore.wait()
        defer { semaphore.signal() }
        // 变更当前小程序的恢复状态
        var recoveryState = gadgetsRecoveryState[uniqueID] ?? .idle
        switch recoveryState {
        case .idle, .errorRecoverying:
            break
        case .errorCatched:
            recoveryState = .errorRecoverying
        }
        gadgetsRecoveryState[uniqueID] = recoveryState
    }

    /// 通知小程序加载成功
    func notifyGadgetRecoveryLoadSuccess(uniqueID: OPAppUniqueID) {
        // 下方要操作gadgetsRecoveryState字典，先加锁
        semaphore.wait()
        defer { semaphore.signal() }
        // 变更当前小程序的恢复状态
        let recoveryState = gadgetsRecoveryState[uniqueID] ?? .idle
        switch recoveryState {
        case .idle, .errorCatched:
            break
        case .errorRecoverying:
            // 成功将小程序从错误中恢复，埋点上报
            OPMonitor(GDMonitorCode.recovery_success)
                .setUniqueID(uniqueID)
                .flush()
        }
        gadgetsRecoveryState[uniqueID] = .idle
    }


    /// 小程序当前所处的自动恢复的状态
    private enum GadgetRecoveryState {
        /// 正常运行状态
        case idle
        /// 被捕获到错误
        case errorCatched
        /// 自动恢复框架正在尝试将小程序从错误中恢复回来
        case errorRecoverying
    }
}
