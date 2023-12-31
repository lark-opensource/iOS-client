//
//  LarkInterface+TourFlow.swift
//  LarkTour
//
//  Created by Meng on 2020/6/11.
//

import Foundation
import RxSwift
import RustPB

public enum AbnormalExitReason: Int {
    case others = -1
    case stepDataNotFound = 1
    case slotCount = 2
    case slotElement = 3
    case unkownStep = 4
}

public typealias DynamicFlowSuiteId = Int64

/// 动态步骤插槽配置
public struct DynamicSlotConfig {
    /// 是否支持隐藏
    public var enableHidden: Bool

    public init(enableHidden: Bool) {
        self.enableHidden = enableHidden
    }
}

/// 用于步骤Slot Key定义的协议
public protocol DynamicSlotKeys: RawRepresentable, CaseIterable, Hashable where RawValue == String {
    static var slotConfigs: [Self: DynamicSlotConfig] { get }
}

/// 动态流程定义
public protocol DynamicFlow: RawRepresentable, CaseIterable, Hashable where RawValue == String {
    static var suiteId: Int64 { get }
}

/// 动态步骤缓存策略
public enum DynamicCacheStrategy {
    // Default
    case always
    // 只会缓存一次，get Step时清理步骤，步骤全部清理完后清理flow
    case once
}

/// 动态流程调度服务，主要用于**多步**的流程调度，内部封装了`DynamicFlowService`的调用逻辑
///
/// 使用场景：Onboarding流程
/// 使用方式：
/// 1. 通过`fetchDynamicFlow`拉取流程数据，`DynamicProcessService`会帮你处理好数据缓存工作
/// 2. 通过`startFlow`开始一个流程
/// 3. 继承`DynamicStepTemplate`实现你的流程步骤，`DynamicProcessService`会帮你调度
/// 4. 你的流程步骤需要进行下一步时，调用`goNextStep`
/// 5. 你的流程步骤完成时，调用`finishFlow`
/// 6. 流程步骤中途异常使用`abnormalExitFlow`结束流程，使用`isRootStep`查询是否起始步骤
///
public protocol DynamicProcessService {
    /// 注册动态流程
    /// - Parameters:
    ///   - suiteId: suiteId
    ///   - strategy: cache 策略
    ///   - fetchedHandler: 拉取回调, 以及FlowContext
    func fetchDynamicFlow(
        suiteId: DynamicFlowSuiteId,
        strategy: DynamicCacheStrategy,
        fetchedHandler: (([String: String]) -> Void)?
    )

    /// 开始动态步骤流程
    /// - Parameter suiteId: suiteId
    func startFlow(for suiteId: DynamicFlowSuiteId) -> Bool

    /// 开始下个步骤
    func goNextStep<SlotKeys>(
        for suiteId: DynamicFlowSuiteId,
        stepId: String,
        slotKey: SlotKeys
    ) where SlotKeys: DynamicSlotKeys

    /// 异常情况退出/清理流程
    func abnormalExitFlow(for suiteId: DynamicFlowSuiteId,
                          exitReason: AbnormalExitReason,
                          stepId: String?,
                          errorMsg: String?)

    /// 完动态步骤流程
    /// - Parameter suiteId: suiteId
    func finishFlow(for suiteId: DynamicFlowSuiteId)

    /// 是否是起始步骤
    func isRootStep(for suiteId: DynamicFlowSuiteId, stepId: String) -> Bool

    /// 开始动态步骤
    /// - Parameter suiteId: suiteId
    func startStep(for suiteId: DynamicFlowSuiteId, stepId: String)
}

extension DynamicProcessService {
    public func fetchDynamicFlow(
        suiteId: DynamicFlowSuiteId,
        strategy: DynamicCacheStrategy,
        fetchedHandler: (([String: String]) -> Void)? = nil
    ) {
        fetchDynamicFlow(
            suiteId: suiteId,
            strategy: strategy,
            fetchedHandler: fetchedHandler
        )
    }
}
