//
//  RustUGReachAPI.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/2.
//

import Foundation
import RustPB
import RustSDK
import ServerPB
import LarkRustClient
import RxSwift
import LarkTraceId

final class RustUGReachAPI: UGReachAPI {
    let client: RustService
    let scheduler: ImmediateSchedulerType?

    init(client: RustService, scheduler: ImmediateSchedulerType? = nil) {
        self.client = client
        self.scheduler = scheduler
    }
}

extension ObservableType {
    func subscribeOn(_ scheduler: ImmediateSchedulerType? = nil) -> Observable<Self.Element> {
        if let scheduler = scheduler {
            return self.subscribeOn(scheduler: scheduler)
        }
        return self.asObservable()
    }
}

extension RustUGReachAPI {
    func fetchSDKSettings() -> Observable<GetUGSDKSettingsResponse> {
        let request = GetUGSDKSettingsRequest()
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func fetchScenario(
        via strategy: DataFetchStrategy,
        scenarioId: String,
        specifiedReachPointIds: [String]?,
        bizContext: [String: String]?
    ) -> Observable<GetUGScenarioResponse> {
        switch strategy {
        case .remote:
            var request = GetUGScenarioRequest()
            request.scenarioID = scenarioId
            if let specifiedReachPointIds = specifiedReachPointIds {
                request.specifiedReachPointIds = specifiedReachPointIds
            }
            if let bizContext = bizContext {
                request.bizContext = bizContext
            }
            return client.sendAsyncRequest(request).subscribeOn(scheduler)
        case .cache:
            var request = GetUGScenarioCacheRequest()
            request.scenarioID = scenarioId
            return client.sendAsyncRequest(request).map({ [weak self] (resp: GetUGScenarioCacheResponse) -> GetUGScenarioResponse in
                let ntpTime = self?.getNTPTime() ?? Int64.max
                var meta = resp.scenarioCache.meta
                let rpId2rp: [String: ReachPointEntity] =
                    Dictionary(meta.entities.map { ($0.reachPointID, $0) }, uniquingKeysWith: { _, last in last })
                // filter valid reach points
                var validReachPoints: [ReachPointEntity] = []
                for (rpId, updateTime) in resp.scenarioCache.rpid2UpdateTime {
                    if let rp = rpId2rp[rpId], ntpTime - updateTime < rp.config.cachePeriod {
                        validReachPoints.append(rp)
                    }
                }
                meta.entities = validReachPoints
                var finalResp = GetUGScenarioResponse()
                finalResp.scenarioID = meta.scenarioID
                finalResp.scenarioContext = meta
                return finalResp
            }).subscribeOn(scheduler)
        }
    }

    func uploadReachEvent(
        scenarioId: String?,
        reachPointId: String?,
        materialKey: String?,
        localRuleId: Int64?,
        eventName: String,
        consumeTypeValue: Int,
        uploadContext: [String: String]?
    ) -> Observable<Void> {
        var request = ServerPB.ServerPB_Ug_reach_ReportUGEventRequest()
        if let scenarioId = scenarioId {
            request.scenarioID = scenarioId
        }
        if let reachPointId = reachPointId {
            request.reachPointID = reachPointId
        }
        if let materialKey = materialKey {
            request.materialKey = materialKey
        }
        if let localRuleId = localRuleId {
            request.localRuleID = localRuleId
        }
        if let uploadContext = uploadContext {
            request.uploadContext = uploadContext
        }
        request.consumeType = (consumeTypeValue == ServerPB_Ug_reach_material_ConsumeType.all.rawValue ? .all : .unknown)
        request.eventName = eventName
        return client.sendPassThroughAsyncRequest(request, serCommand: .reportUgEvent).subscribeOn(scheduler)
    }

    func getLocalRule(
        scenarioId: String,
        via strategy: DataFetchStrategy
    ) -> Observable<LocalRule?> {
        var request = GetUGLocalRuleRequest()
        request.scenarioID = scenarioId
        return client.sendAsyncRequest(request)
            .map { (resp: Ugreach_V1_GetUGLocalRuleResponse) -> LocalRule? in
                return resp.hasLocalRule ? resp.localRule : nil
            }
            .subscribeOn(scheduler)
    }

    func deleteReachPointCache(reachPointIds: [String]) -> Observable<Void> {
        var request = DeleteUGReachPointCacheRequest()
        request.reachPointIds = reachPointIds
        return client.sendAsyncRequest(request)
            .flatMap({ (_) -> Observable<Void> in
                return .just(())
            })
            .subscribeOn(scheduler)
    }

    func getUGValue(by key: String) -> Observable<UGValue?> {
        var request = GetUGValueByKeyRequest()
        request.key = key
        return client.sendAsyncRequest(request)
            .map({ (resp: GetUGValueByKeyResponse) -> UGValue? in
                return resp.value.value
            })
            .subscribeOn(scheduler)
    }

    func updateUGValue(by key: String, value: UGValue?) -> Observable<Void> {
        var request = UpdateUGValueByKeyRequest()
        request.key = key
        var wrapValue = UGWrapValue()
        wrapValue.value = value
        request.value = wrapValue
        return client.sendAsyncRequest(request)
            .flatMap({ (_) -> Observable<Void> in
                return .just(())
            })
            .subscribeOn(scheduler)
    }

    func deleteUGValue(by keys: [String]) -> Observable<Void> {
        var request = DeleteUGValueByKeyRequest()
        request.keys = keys
        return client.sendAsyncRequest(request)
            .flatMap({ (_) -> Observable<Void> in
                return .just(())
            })
            .subscribeOn(scheduler)
    }

    func getNTPTime() -> Int64 {
        return get_ntp_time()
    }
}
