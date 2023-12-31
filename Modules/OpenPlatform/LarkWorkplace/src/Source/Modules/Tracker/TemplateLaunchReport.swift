//
//  TemplateLaunchReport.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/11/18.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import ECOInfra

/// 收敛模板化工作台加载性能参数
final class TemplateLaunchReport {
    static let logger = Logger.log(TemplateLaunchReport.self)

    private let trace: OPTrace
    /// 是否出现加载阶段失败（只能置位true）
    var isStepFailed: Bool = false

    /// 是否使用缓存（0 网络，1缓存）
    private var useCache: Int = 1

    /// 各个阶段的启动时间点
    private var startTimeStamp: [String: Date] = [:]
    /// 各个阶段的结束时间点
    private var endTimeStamp: [String: Date] = [:]

    /// 首屏正在渲染的Block(id)
    private var renderBlock: [String] = []

    init(trace: OPTrace) {
        self.trace = trace
    }

    /// 获取基础环境初始化耗时(ms)
    private func getInitEnvTime() -> Int {
        if let startTime = startTimeStamp[TmplPerformanceKey.initEnv.rawValue],
           let endTime = endTimeStamp[TmplPerformanceKey.initEnv.rawValue] {
            return Int(endTime.timeIntervalSince(startTime) * 1_000)
        } else {
            return 0
        }
    }

    /// 工作台业务数据获取完成耗时(ms)
    private func getRequestDataTime() -> Int {
        if let startTime = startTimeStamp[TmplPerformanceKey.requestData.rawValue],
           let endTime = endTimeStamp[TmplPerformanceKey.requestData.rawValue] {
            return Int(endTime.timeIntervalSince(startTime) * 1_000)
        } else {
            return 0
        }
    }

    /// 首屏Block加载完成耗时(ms)
    private func getFirstFrameBlockShow() -> Int {
        if let startTime = startTimeStamp[TmplPerformanceKey.firstFrameBlockShow.rawValue],
           let endTime = endTimeStamp[TmplPerformanceKey.firstFrameBlockShow.rawValue] {
            return Int(endTime.timeIntervalSince(startTime) * 1_000)
        } else {
            return 0
        }
    }

    /// 记录是否有缓存启动
    func recordLaunch(withCache: Bool) {
        useCache = withCache ? 1 : 0
    }
    /// 记录基础环境初始化启动
    func recordInitEnvStart() {
        assert(Thread.isMainThread, "launch report date array only editor on MainThread")
        startTimeStamp[TmplPerformanceKey.initEnv.rawValue] = Date()
    }
    /// 记录基础环境初始化结束
    func recordInitEnvEnd() {
        assert(Thread.isMainThread, "launch report date array only editor on MainThread")
        endTimeStamp[TmplPerformanceKey.initEnv.rawValue] = Date()
    }

    /// 记录业务数据请求启动
    func recordRequestStart() {
        assert(Thread.isMainThread, "launch report date array only editor on MainThread")
        if startTimeStamp[TmplPerformanceKey.requestData.rawValue] == nil {
            endTimeStamp[TmplPerformanceKey.initEnv.rawValue] = Date()
            startTimeStamp[TmplPerformanceKey.requestData.rawValue] = Date()
        }
    }

    /// 记录业务数据请求结束
    func recordRequestEnd() {
        assert(Thread.isMainThread, "launch report date array only editor on MainThread")
        if endTimeStamp[TmplPerformanceKey.requestData.rawValue] == nil {
            endTimeStamp[TmplPerformanceKey.requestData.rawValue] = Date()
        }
    }

    /// 记录block开始渲染
    func recordBlockStart(id: String?) {
        assert(Thread.isMainThread, "launch report date array only editor on MainThread")
        guard let id = id else {
            Self.logger.info("miss block id, not record")
            return
        }
        if startTimeStamp[TmplPerformanceKey.firstFrameBlockShow.rawValue] == nil {
            startTimeStamp[TmplPerformanceKey.firstFrameBlockShow.rawValue] = Date()
        }
        renderBlock.append(id)
    }

    /// 记录block结束渲染
    func recordBlockEnd(id: String?, success: Bool) {
        assert(Thread.isMainThread, "launch report date array only editor on MainThread")
        guard let id = id else {
            Self.logger.info("miss block id, not record")
            return
        }
        if success {
            endTimeStamp[TmplPerformanceKey.firstFrameBlockShow.rawValue] = Date()
        }
        renderBlock.removeAll { $0 == id }
        if renderBlock.isEmpty {
            /// 所有block结束加载
            post()
        }
    }

    /// 上报加载性能，如有失败，则不上报
    func post() {
        if !isStepFailed, endTimeStamp[TmplPerformanceKey.firstFrameBlockShow.rawValue] != nil {
            let initEnvTime = getInitEnvTime()
            let requestDataTime = getRequestDataTime()
            let firstFrameBlockShowTime = getFirstFrameBlockShow()
            let total = initEnvTime + requestDataTime + firstFrameBlockShowTime
            WPMonitor().setCode(WPMCode.workplace_startup)
                .setTrace(trace)
                .setInfo([
                    TmplPerformanceKey.useCache.rawValue: useCache,
                    TmplPerformanceKey.initEnv.rawValue: initEnvTime,
                    TmplPerformanceKey.requestData.rawValue: requestDataTime,
                    TmplPerformanceKey.firstFrameBlockShow.rawValue: firstFrameBlockShowTime
                ])
                .setMetrics("duration", total)
                .flush()
            isStepFailed = true // 上报过，不再上报
        }
    }
}
