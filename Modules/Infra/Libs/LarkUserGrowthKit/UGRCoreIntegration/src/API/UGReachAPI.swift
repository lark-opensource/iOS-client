//
//  UGReachAPI.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/2.
//

import Foundation
import RxSwift

enum DataFetchStrategy {
    case remote
    case cache
}

protocol UGReachAPI {
    func fetchSDKSettings() -> Observable<GetUGSDKSettingsResponse>

    func fetchScenario(
        via strategy: DataFetchStrategy,
        scenarioId: String,
        specifiedReachPointIds: [String]?,
        bizContext: [String: String]?
    ) -> Observable<GetUGScenarioResponse>

    func uploadReachEvent(
        scenarioId: String?,
        reachPointId: String?,
        materialKey: String?,
        localRuleId: Int64?,
        eventName: String,
        consumeTypeValue: Int,
        uploadContext: [String: String]?
    ) -> Observable<Void>

    func getLocalRule(
        scenarioId: String,
        via strategy: DataFetchStrategy
    ) -> Observable<LocalRule?>

    func deleteReachPointCache(reachPointIds: [String]) -> Observable<Void>

    func getUGValue(by key: String) -> Observable<UGValue?>

    func updateUGValue(by key: String, value: UGValue?) -> Observable<Void>

    func deleteUGValue(by keys: [String]) -> Observable<Void>

    func getNTPTime() -> Int64
}
