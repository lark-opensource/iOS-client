//
//  UGReachSDKPresenter.swift
//  UGReachSDK
//
//  Created by shizhengyu on 2021/3/15.
//

import Foundation
import UGContainer
import UGRCoreIntegration
import LarkContainer
import LKCommonsLogging
import RxSwift
import LarkTraceId

final class UGReachSDKPresenter: UGReachSDKService, UserResolverWrapper {

    private static let logger = Logger.log(UGReachSDKPresenter.self, category: "ug.reach.sdk.presenter")

    @ScopedInjectedLazy private var pluginContainerService: PluginContainerService?
    @ScopedInjectedLazy private var coreDispatchService: ReachCoreService?

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func obtainReachPoint<T: ReachPoint>(reachPointId: String, bizContextProvider: BizContextProvider?) -> T? {
        UGReachSDKPresenter.logger.info("[UGReachSDK] presenter.obtainReachPoint, rpid = \(reachPointId)")
        if let bizContextProvider = bizContextProvider {
            coreDispatchService?.register(with: reachPointId, bizContextProvider: bizContextProvider)
        }
        return pluginContainerService?.obtainReachPoint(reachPointId: reachPointId)
    }

    func recycleReachPoint(reachPointId: String, reachPointType: String) {
        UGReachSDKPresenter.logger.info("[UGReachSDK] presenter.recycleReachPoint, rpid = \(reachPointId), type = \(reachPointType)")
        coreDispatchService?.clearBizContext(with: reachPointId)
        pluginContainerService?.recycleReachPoint(reachPointId: reachPointId, reachPointType: reachPointType)
    }

    func register(with reachPointId: String, bizContextProvider: BizContextProvider) {
        UGReachSDKPresenter.logger.info("[UGReachSDK] presenter.register, sid = \(bizContextProvider.scenarioId), rpid = \(reachPointId)")
        coreDispatchService?.register(with: reachPointId, bizContextProvider: bizContextProvider)
    }

    func clearBizContext(with scenarioId: String) {
        UGReachSDKPresenter.logger.info("[UGReachSDK] presenter.clearBizContext")
        coreDispatchService?.clearBizContext(with: scenarioId)
    }

    func setup() {
        UGReachSDKPresenter.logger.info("[UGReachSDK] presenter.setup")
        coreDispatchService?.setup()
    }

    func tryExpose(
        by scenarioId: String,
        actionRuleContext: UserActionRuleContext?,
        bizContextProvider: BizContextProvider?
    ) {
        TraceIdService.start(eventName: "UGGuide try expose \(scenarioId)!", moduleName: .ugGuide) {
            UGReachSDKPresenter.logger.info("[UGReachSDK] presenter.tryExpose, sid = \(scenarioId)")
            coreDispatchService?.tryExpose(by: scenarioId, actionRuleContext: actionRuleContext, bizContextProvider: bizContextProvider)
        }
    }

    func tryExpose(by scenarioId: String, specifiedReachPointIds: [String]) {
        TraceIdService.start(eventName: "UGGuide try expose \(scenarioId)!", moduleName: .ugGuide) {
            UGReachSDKPresenter.logger.info(
                "[UGReachSDK] presenter.tryExposeWithSpecifiedReachPoints, sid = \(scenarioId), rpids = \(specifiedReachPointIds)"
            )
            coreDispatchService?.tryExpose(by: scenarioId, specifiedReachPointIds: specifiedReachPointIds)
        }
    }
}
