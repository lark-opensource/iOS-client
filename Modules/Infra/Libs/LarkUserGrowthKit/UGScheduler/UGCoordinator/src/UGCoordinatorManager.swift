//
//  UGCoordinatorManager.swift
//  UGCoodinator
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import RxSwift
import RxRelay
import LarkContainer
import LKCommonsLogging
import RustPB

public protocol UGCoordinatorService {
    // 调度中心 -> CoordinatorResult, 外部注册模块调用
    func registerCoordinatorResult() -> Observable<CoordinatorResult>
    // 某个引导触达点位变化事件（展示、隐藏、消费）
    func onReachPointEvent(reachPointEvent: CoordinatorReachPointEvent)
    // 某个引导场景展示事件
    func onScenarioTrigger(scenarioContext: UGScenarioContext)
}

public final class UGCoordinatorManager {

    private static let log = Logger.log(UGCoordinatorManager.self, category: "LarkUGReach")
    private lazy var coordinator: UGCoordinator = {
        let coordinator = UGCoordinator(userResolver: userResolver)
        return coordinator
    }()

    let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
}

// MARK: - Service

extension UGCoordinatorManager: UGCoordinatorService {
    // 调度中心 -> CoordinatorResult, 外部注册模块调用
    public func registerCoordinatorResult() -> Observable<CoordinatorResult> {
        return self.coordinator.resultDriver.asObservable()
    }

    // 某个引导触达点位变化事件（展示、隐藏、消费）
    public func onReachPointEvent(reachPointEvent: CoordinatorReachPointEvent) {
        self.coordinator.onReachPointEvent(reachPointEvent: reachPointEvent)
        // 消费的时候需要获取结果
        if case .consume = reachPointEvent.action {
            self.coordinator.getDisplayResult()
        }
    }

    // 某个引导场景展示事件
    public func onScenarioTrigger(scenarioContext: UGScenarioContext) {
        self.coordinator.onScenarioTrigger(scenarioContext: scenarioContext)
        self.coordinator.getDisplayResult()
    }

    // 移除某个场景
    public func onScenarioLeave(scenarioContext: UGScenarioContext) {
        self.coordinator.onScenarioLeave(scenarioContext: scenarioContext)
        self.coordinator.getDisplayResult()
    }
}
