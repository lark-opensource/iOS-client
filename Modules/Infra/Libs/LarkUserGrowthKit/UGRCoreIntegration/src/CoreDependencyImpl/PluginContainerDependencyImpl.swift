//
//  PluginContainerDependencyImpl.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/2.
//

import Foundation
import UGContainer

final class PluginContainerDependencyImpl: PluginContainerDependency {
    static private let splitChar = "&"
    private weak var coreService: ReachCoreService?

    init(coreService: ReachCoreService) {
        self.coreService = coreService
    }

    func reportEvent(event: ReachPointEvent) {
        let dispatcher = coreService as? CoreDispatcher
        let globalInfo = dispatcher?.getReachPointGlobalInfo(by: event.reachPointId)

        // 数据补偿，解耦 tryExpose 与 reachPoint 注册过程
        if event.eventName == ReachPointEvent.Key.onReady.rawValue {
            dispatcher?.tryReplay(with: event.reachPointId)
        }

        dispatcher?.uploadReachEvent(
            scenarioId: globalInfo?.meta.scenarioID,
            reachPointId: event.reachPointId,
            materialKey: event.materialKey,
            localRuleId: globalInfo?.localRuleId,
            eventName: event.eventName,
            consumeTypeValue: event.consumeTypeValue,
            uploadContext: event.extra
        )
    }
}
