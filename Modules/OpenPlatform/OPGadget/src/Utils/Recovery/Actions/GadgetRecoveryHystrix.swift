//
//  GadgetRecoveryHystrix.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import OPFoundation

/// 熔断默认的间隔，每次只统计这个时间段内的错误次数
private let DefaultHystrixClearInterval: TimeInterval = 5 * 60

/// 熔断类型
enum GadgetRecoveryHystrixType {
    /// 不触发熔断
    case none
    /// 触发初级熔断
    case primary
    /// 触发终极熔断
    case final
}

/// 熔断配置
struct GadgetRecoveryHystrixConfig {
    /// 默认值
    static let `default` = GadgetRecoveryHystrixConfig(
        primarySingle: 2,
        primaryGlobal: 4,
        finalSingle: 3,
        finalGlobal: 6
    )

    /// 单应用错误发生次数超过这个值就进入primary熔断
    let primarySingle: Int

    /// 全应用错误发生次数超过这个值就进入primary熔断
    let primaryGlobal: Int

    /// 单应用错误发生次数超过这个值就进入final熔断
    let finalSingle: Int

    /// 全应用错误发生次数超过这个值就进入final熔断
    let finalGlobal: Int
}


/// 熔断中心
class GadgetRecoveryHystrixCenter {
    /// 单例
    static let current: GadgetRecoveryHystrixCenter = GadgetRecoveryHystrixCenter()

    private init() {}

    private var globalFailedPoints: [Date] = []

    private var singleFailedPoints: [OPAppUniqueID: [Date]] = [:]

    /// 加锁
    private var semaphore = DispatchSemaphore(value: 1)

    /// 通知熔断中心发生了一次错误恢复
    func triggerRecovery(with uniqueID: OPAppUniqueID) {
        semaphore.wait()
        defer { semaphore.signal() }

        // 记录全局触发错误重试的次数，以AppType为维度分隔开
        globalFailedPoints.append(Date())

        // 记录单应用容器触发错误重试的次数
        if var currentSinglePoints = singleFailedPoints[uniqueID] {
            currentSinglePoints.append(Date())
            singleFailedPoints[uniqueID] = currentSinglePoints
        } else {
            singleFailedPoints[uniqueID] = [Date()]
        }
    }

    /// 获取此次错误恢复当前是否触发熔断以及熔断类型
    func currentHystrixType(with uniqueID: OPAppUniqueID) -> GadgetRecoveryHystrixType {
        // 获取熔断在线配置
        let hystrixConfig = GadgetRecoveryConfigProvider.gadgetRecoveryHystrixConfig
        // 下方要开始集中对类中的一些数据进行修改，加锁保护
        semaphore.wait()
        defer { semaphore.signal() }
        // 删除globalFailedPoints中defaultHystrixClearInterval之前的节点
        globalFailedPoints.removeAll { date -> Bool in
            (date+DefaultHystrixClearInterval).isInPast
        }
        // 删除currentSinglePoints中defaultHystrixClearInterval之前的节点
        var currentSinglePoints = singleFailedPoints[uniqueID] ?? []
        currentSinglePoints.removeAll { date -> Bool in
            (date+DefaultHystrixClearInterval).isInPast
        }
        singleFailedPoints[uniqueID] = currentSinglePoints
        // 分别拿出当前的全局触发次数与单应用容器触发的次数
        let currentGlobalCount = globalFailedPoints.count
        let currentSingleCount = currentSinglePoints.count

        // 判断是否触发熔断，如果触发了熔断就对当前记录的触发次数进行清零
        if currentSingleCount < hystrixConfig.primarySingle && currentGlobalCount < hystrixConfig.primaryGlobal {
            return .none
        } else if currentSingleCount > hystrixConfig.finalSingle || currentGlobalCount > hystrixConfig.finalGlobal {
            clearStateWithNoLock()
            return .final
        } else {
            clearStateWithNoLock()
            return .primary
        }
    }

    private func clearStateWithNoLock() {
        globalFailedPoints = []
        singleFailedPoints.removeAll()
    }
}
