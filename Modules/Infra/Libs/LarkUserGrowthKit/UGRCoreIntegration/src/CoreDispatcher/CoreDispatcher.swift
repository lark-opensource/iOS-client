//
//  CoreDispatcher.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/2.
//

import UIKit
import Foundation
import LarkContainer
import RxSwift
import LKCommonsLogging
import UGRule
import UGContainer
import ThreadSafeDataStructure
import SwiftProtobuf
import Homeric
import UGCoordinator
import LarkTraceId

private struct RuleCheckResult {
    let ruleID: Int64?
    let isSatisfied: Bool
}

private struct Validator: RespValidator {
    func isValid(response: GetUGScenarioResponse) -> Bool {
        return !response.scenarioContext.entities.isEmpty
    }
}

final class CoreDispatcher: ReachCoreService, UserResolverWrapper {
    private let reachAPI: UGReachAPI
    @ScopedInjectedLazy private var pluginContainerService: PluginContainerService?
    @ScopedInjectedLazy private var ruleService: UGRuleService?
    @ScopedInjectedLazy private var coordinator: UGCoordinatorService?

    private let lock = NSLock()
    private static let rootScenarioPath = ""
    private var configuration: SDKInnerConfiguration = .default()
    private var bufferedTasks: [DispatchWorkItem] = []
    private var reachPointGlobalInfos: SafeDictionary<String, ReachPointGlobalInfo> = [:] + .readWriteLock
    private var bizContextProviders: SafeDictionary<String, SafeDictionary<String, BizContextProvider>> = [:] + .readWriteLock
    private var rp2ScenarioMapping: SafeDictionary<String, String> = [:] + .readWriteLock
    private var requestDisposables: SafeDictionary<String, Disposable> = [:] + .readWriteLock
    private let tracer = Tracer()
    private var allowedEventList = [
        ReachPointEvent.Key.consume.rawValue,
        ReachPointEvent.Key.didShow.rawValue,
        ReachPointEvent.Key.didHide.rawValue,
        ReachPointEvent.Key.onClick.rawValue
    ]

    private lazy var serialQueue = {
        return DispatchQueue(label: "ug.reach.CoreDispatcher", qos: .userInitiated)
    }()
    private lazy var serialScheduler = SerialDispatchQueueScheduler(
        queue: serialQueue,
        internalSerialQueueName: serialQueue.label
    )

    private var sdkInitProcessing: Bool = false {
        didSet {
            if !self.sdkInitProcessing && !bufferedTasks.isEmpty {
                for task in bufferedTasks.reversed() {
                    serialQueue.async(execute: task)
                }
                bufferedTasks.removeAll()
            }
        }
    }

    private var whitelistForRP: [String] {
        guard let pluginContainerService else { return [] }
        return Array(pluginContainerService.reachPointsInfo.values).flatMap { $0 }
    }

    let userResolver: UserResolver
    init(userResolver: UserResolver, reachAPI: UGReachAPI) {
        self.reachAPI = reachAPI
        self.userResolver = userResolver
        setup()
    }

    func setup() {
        serialQueue.async {
            self.requestDisposables.values.forEach { (disposable) in
                disposable.dispose()
            }
            self.requestDisposables = [:] + .readWriteLock
            self.sdkInitProcessing = true

            let identifier = String(CACurrentMediaTime())
            self.tracer.traceMetric(
                eventKey: Homeric.UG_REACH_FETCH_SETTINGS,
                identifier: identifier,
                isEndPoint: false
            )
            // fetch sdk inner settings
            let disposable = self.reachAPI.fetchSDKSettings()
                .timeout(.milliseconds(5000), scheduler: self.serialScheduler)
                .subscribe { [weak self] (resp) in
                    self?.serialQueue.async {
                        self?.sdkInitProcessing = false
                    }
                    // update inner configurations
                    self?.configuration = SDKInnerConfiguration(
                        solveConflictUseGraph: resp.sdkStrategy.solveConflictUseGraph,
                        requestTimeoutDuration: resp.sdkStrategy.requestTimeoutDuration,
                        uploadStatusUseLoop: resp.sdkStrategy.uploadStatusUseLoop
                    )
                    self?.tracer.traceLog(msg: "update sdk innerConfiguration = \(resp.sdkStrategy)")

                    // update sdk allowed upload events
                    self?.lock.lock()
                    self?.allowedEventList = resp.eventNames
                    self?.lock.unlock()
                    self?.tracer.traceLog(msg: "update sdk allowed upload events = \(resp.eventNames)")

                    self?.tracer
                        .traceLog(msg: "fetchSDKSettings success")
                        .traceMetric(
                            eventKey: Homeric.UG_REACH_FETCH_SETTINGS,
                            identifier: identifier,
                            category: ["isSuccess": "true"],
                            isEndPoint: true
                        )
                } onError: { [weak self] (error) in
                    self?.serialQueue.async {
                        self?.sdkInitProcessing = false
                    }
                    self?.tracer
                        .traceLog(msg: "fetchSDKSettings failed, error = " + error.localizedDescription)
                        .traceMetric(
                            eventKey: Homeric.UG_REACH_FETCH_SETTINGS,
                            identifier: identifier,
                            category: ["isSuccess": "false"],
                            extra: ["errMsg": error.localizedDescription],
                            isEndPoint: true
                        )
                } onDisposed: { [weak self] in
                    self?.serialQueue.async {
                        self?.sdkInitProcessing = false
                    }
                }
            self.setRequestDisposable(identifier: ".setup_fetchSDKSettings", disposable: disposable)

            // observe coordinator pop result
            let observer = self.coordinator?.registerCoordinatorResult()
                .subscribeOn(scheduler: self.serialScheduler)
                .subscribe { [weak self] (result) in
                    for rp in result.rpEntitys {
                        switch result.rpState {
                        case .show:
                            self?.tracer.traceLog(msg: "receive coordinator show event, rpid = \(rp.reachPointID)")
                            if let reachMaterial = rp.material.first {
                                self?.pluginContainerService?.showReachPoint(
                                    reachPointId: rp.reachPointID,
                                    reachPointType: rp.type,
                                    data: reachMaterial.material
                                )
                            }
                        case .hide:
                            self?.tracer.traceLog(msg: "receive coordinator hide event, rpid = \(rp.reachPointID)")
                            self?.pluginContainerService?.hideReachPoint(
                                reachPointId: rp.reachPointID,
                                reachPointType: rp.type
                            )
                        }
                    }
                } onError: { [weak self] (error) in
                    self?.tracer.traceLog(msg: "coordinator pop error, errMsg = \(error.localizedDescription)")
                }

            self.setRequestDisposable(identifier: ".setup_observeCoordinator", disposable: observer)
        }
    }

    func register(with reachPointId: String, bizContextProvider: BizContextProvider) {
        tracer.traceLog(msg: "register bizContext with rpid = \(reachPointId)")
        if let currentBizContext = bizContextProviders[bizContextProvider.scenarioId] {
            currentBizContext[reachPointId] = bizContextProvider
        } else {
            bizContextProviders[bizContextProvider.scenarioId] = [reachPointId: bizContextProvider] + .readWriteLock
        }
        rp2ScenarioMapping[reachPointId] = bizContextProvider.scenarioId
    }

    func clearBizContext(with reachPointId: String) {
        tracer.traceLog(msg: "clear bizContext with rpid = \(reachPointId)")
        if let scenarioId = rp2ScenarioMapping[reachPointId] {
            bizContextProviders[scenarioId]?[reachPointId] = nil
        }
        rp2ScenarioMapping[reachPointId] = nil
    }

    func tryExpose(by scenarioId: String, actionRuleContext: UserActionRuleContext?, bizContextProvider: BizContextProvider?) {
        let traceId = TraceIdService.getTraceId()
        let task = DispatchWorkItem(flags: .inheritQoS) {
            TraceIdService.setTraceId(traceId)
            defer{
                TraceIdService.clearTraceId()
            }
            if let scenarioDict = self.bizContextProviders[scenarioId] {
                scenarioDict[CoreDispatcher.rootScenarioPath] = bizContextProvider
                self.bizContextProviders[scenarioId] = scenarioDict
            } else if let bizContextProvider = bizContextProvider {
                self.bizContextProviders[scenarioId] = [CoreDispatcher.rootScenarioPath: bizContextProvider] + .readWriteLock
            }

            let disposable = self.reachAPI
                .getLocalRule(scenarioId: scenarioId, via: .cache)
                .flatMap { [weak self] (localRule) -> Observable<RuleCheckResult> in
                    let invalidResult = RuleCheckResult(ruleID: nil, isSatisfied: false)
                    return (self?.checkLocalRuleStep(localRule: localRule, actionContext: actionRuleContext) ?? .just(invalidResult))
                }
                .filter { $0.isSatisfied }
                .flatMap({ [weak self] (context) -> Observable<Void> in
                    let exposeObservableProvider: ([String: String]?) -> Observable<Void> = { (bizContext) in
                        return self?.expose(
                            by: scenarioId,
                            ruleID: context.ruleID,
                            bizContext: bizContext
                        ) ?? .just(())
                    }
                    return self?.combinedBizContext(by: scenarioId)
                        .flatMap({ (bizContext) -> Observable<Void> in
                            return exposeObservableProvider(bizContext)
                        }) ?? exposeObservableProvider(nil)
                })
                .subscribe { [weak self] (_) in
                    self?.tracer.traceLog(msg: "tryExpose success")
                } onError: { [weak self] (error) in
                    self?.tracer.traceLog(
                        msg: "tryExpose process failed, error = " + error.localizedDescription
                    )
                }
            self.setRequestDisposable(identifier: ".tryExpose" + scenarioId, disposable: disposable)
        }

        if sdkInitProcessing {
            serialQueue.async {
                self.bufferedTasks.append(task)
            }
        } else {
            serialQueue.async(execute: task)
        }
    }

    func tryExpose(by scenarioId: String, specifiedReachPointIds: [String]) {
        let traceId = TraceIdService.getTraceId()
        let task = DispatchWorkItem(flags: .inheritQoS) {
            TraceIdService.setTraceId(traceId)
            defer{
                TraceIdService.clearTraceId()
            }
            let disposable = self.combinedBizContext(by: scenarioId, specifiedReachPointIds: specifiedReachPointIds)
                .flatMap({ (bizContext) -> Observable<Void> in
                    return self.expose(
                        by: scenarioId,
                        specifiedReachPointIds: specifiedReachPointIds,
                        bizContext: bizContext
                    )
                })
                .subscribe { [weak self] (_) in
                    self?.tracer.traceLog(msg: "tryExpose success \(scenarioId)")
                } onError: { [weak self] (error) in
                    self?.tracer.traceLog(
                        msg: "tryExpose process failed \(scenarioId), error = " + error.localizedDescription
                    )
                }
            self.setRequestDisposable(
                identifier: ".tryExpose" + scenarioId + specifiedReachPointIds.joined(separator: ","),
                disposable: disposable
            )
        }

        if sdkInitProcessing {
            serialQueue.async {
                self.bufferedTasks.append(task)
            }
        } else {
            serialQueue.async(execute: task)
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
    ) {
        let task = DispatchWorkItem(flags: .inheritQoS) { [weak self] in
            guard let self else { return }
            let traceContext = "sid=\(scenarioId ?? "")&rpid=\(reachPointId ?? "")&mkey=\(materialKey ?? "")&event=\(eventName)"
            self.tracer.traceLog(msg: "receive container report event, context = \(traceContext)")
            // notify coodinator first
            if let event = UGContainer.ReachPointEvent.Key(rawValue: eventName) {
                var state: ActionEvent?
                switch event {
                case .didShow:
                    state = .show
                case .didHide:
                    state = .hide
                case .consume:
                    state = .consume
                case .onRemove:
                    state = .remove
                default: break
                }
                if let state = state, let reachPointId = reachPointId {
                    let coodinatorEvent = UGCoordinator.CoordinatorReachPointEvent(
                        action: state,
                        reachPointIDs: [reachPointId]
                    )
                    self.tracer.traceLog(msg: "send event to coordinator when upload, rpid = \(reachPointId), state = \(state)")
                    self.coordinator?.onReachPointEvent(reachPointEvent: coodinatorEvent)
                }
            }
            // block if not in allowed events
            self.lock.lock()
            guard self.allowedEventList.contains(eventName) else {
                self.lock.unlock()
                return
            }
            self.lock.unlock()
            // then upload server
            let identifier = String(CACurrentMediaTime())
            self.tracer.traceMetric(
                eventKey: Homeric.UG_REACH_UPLOAD_EVENT,
                identifier: identifier,
                isEndPoint: false
            )
            let uploadReqIdentifier = ".uploadReachEvent_\(traceContext)"
            let disposable = self.reachAPI.uploadReachEvent(
                scenarioId: scenarioId,
                reachPointId: reachPointId,
                materialKey: materialKey,
                localRuleId: localRuleId,
                eventName: eventName,
                consumeTypeValue: consumeTypeValue,
                uploadContext: uploadContext
            )
            .flatMap({ [weak self] (_) -> Observable<Void> in
                if eventName == ReachPointEvent.Key.consume.rawValue, let reachPointId = reachPointId {
                    return self?.reachAPI.deleteReachPointCache(reachPointIds: [reachPointId]) ?? .just(())
                }
                return .just(())
            })
            .subscribe { [weak self] (_) in
                self?.tracer
                    .traceLog(msg: "uploadReachEvent success, context = \(traceContext)")
                    .traceMetric(
                        eventKey: Homeric.UG_REACH_UPLOAD_EVENT,
                        identifier: identifier,
                        category: ["isSuccess": "true"],
                        isEndPoint: true
                    )
            } onError: { [weak self] (error) in
                self?.tracer
                    .traceLog(msg: "uploadReachEvent failed, error = \(error.localizedDescription), context = \(traceContext)")
                    .traceMetric(
                        eventKey: Homeric.UG_REACH_UPLOAD_EVENT,
                        identifier: identifier,
                        category: ["isSuccess": "true",
                                   "errorCode": error.reachErrorCode()],
                        extra: ["errMsg": error.localizedDescription],
                        isEndPoint: true
                    )
            }
            self.setRequestDisposable(identifier: uploadReqIdentifier, disposable: disposable)
        }

        if sdkInitProcessing {
            serialQueue.async {
                self.bufferedTasks.append(task)
            }
        } else {
            serialQueue.async(execute: task)
        }
    }

    func tryReplay(with reachPointId: String) {
        let task = DispatchWorkItem(flags: .inheritQoS) {
            self.tracer.traceLog(msg: "try replay with rpid = \(reachPointId)")
            let disposable = self.reachAPI.getUGValue(by: reachPointId)
                .flatMap({ [weak self] (val) -> Observable<UGValue?> in
                    if val != nil {
                        return self?.reachAPI.deleteUGValue(by: [reachPointId])
                            .flatMap { (_) -> Observable<UGValue?> in
                                return .just(val)
                            } ?? .just(nil)
                    }
                    return .just(nil)
                })
                .filter { $0 != nil }
                .subscribe { [weak self] (val) in
                    guard let val = val else {
                        return
                    }
                    if case .byteValue(let stashData) = val,
                       let context = try? ScenarioContext(serializedData: stashData),
                       let entity = context.entities.first,
                       entity.material.first?.hasMaterial ?? false {
                        self?.tracer.traceLog(msg: "send scenario context to coordinator when replay, sid = \(context.scenarioID), rpid = \(entity.reachPointID)")
                        self?.coordinator?.onScenarioTrigger(scenarioContext: context)
                    }
                    self?.tracer.traceLog(msg: "replay success, reachPointId = \(reachPointId)")
                } onError: { [weak self] (error) in
                    self?.tracer.traceLog(
                        msg: "replay failed, reachPointId = \(reachPointId), error = \(error.localizedDescription)"
                    )
                }
            self.setRequestDisposable(identifier: ".tryReplay" + reachPointId, disposable: disposable)
        }

        if sdkInitProcessing {
            serialQueue.async {
                self.bufferedTasks.append(task)
            }
        } else {
            serialQueue.async(execute: task)
        }
    }

    func isAnyExclusiveReachPoint(only scenarioId: String?) -> Bool {
        // 二期可扩展的能力
        // 基于业务可能会有自己的业务触点，所以这个接口也是有必要开放给外部使用的
        // 暂时不读取冲突协调模块的顶点状态
        return false
    }

    func getReachPointGlobalInfo(by reachPointId: String) -> ReachPointGlobalInfo? {
        return reachPointGlobalInfos[reachPointId]
    }
}

/// Core Scheduling Step
private extension CoreDispatcher {
    func checkLocalRuleStep(localRule: LocalRule?, actionContext: UserActionRuleContext?) -> Observable<RuleCheckResult> {
        tracer.traceLog(msg: "enter check local rule step")
        guard let localRule = localRule else {
            tracer.traceLog(msg: "can not find localRule, pass directly")
            let passport = RuleCheckResult(
                ruleID: nil,
                isSatisfied: true
            )
            return .just(passport)
        }
        guard let actionContext = actionContext else {
            tracer.traceLog(msg: "user action context did not provide, ruleID = \(localRule.ruleID)")
            let blockResult = RuleCheckResult(
                ruleID: localRule.ruleID,
                isSatisfied: false
            )
            return .just(blockResult)
        }
        guard let ruleAction = RuleAction(rawValue: actionContext.ruleActionKey) ?? RuleAction(rawValue: actionContext.metaRule) else {
            tracer.traceLog(msg: "user action context is invalid, context = \(actionContext), ruleID = \(localRule.ruleID)")
            let blockResult = RuleCheckResult(
                ruleID: localRule.ruleID,
                isSatisfied: false
            )
            return .just(blockResult)
        }
        tracer.traceLog(msg: "localRule context matched, ruleAction = \(ruleAction.description), ruleID = \(localRule.ruleID)")
        let actionInfo = RuleActionInfo(
            ruleAction: ruleAction,
            actionValue: actionContext.ruleActionValue
        )
        return ruleService?.handleRuleEvent(ruleInfoPB: localRule, actionInfo: actionInfo)
            .map { (isSatisfied) -> RuleCheckResult in
                return RuleCheckResult(
                    ruleID: localRule.ruleID,
                    isSatisfied: isSatisfied
                )
            }
            .do { [weak self] (result) in
                self?.tracer.traceLog(msg: "localRule check result = \(String(describing: result)), ruleID = \(localRule.ruleID)")
            } onError: { [weak self] (error) in
                self?.tracer.traceLog(
                    msg: "localRule check abnormal, errorMsg = \(error.localizedDescription), ruleID = \(localRule.ruleID)"
                )
            } ?? .empty()
    }

    func loadCombineDataSourceStep(
        by scenarioId: String,
        localRuleId: Int64? = nil,
        specifiedReachPointIds: [String]? = nil,
        bizContext: [String: String]? = nil
    ) -> Observable<GetUGScenarioResponse> {
        tracer.traceLog(msg: "enter load combine datasource step \(scenarioId)")
        return Observable<GetUGScenarioResponse>.smartCombine(
            localReq: loadCacheDataSource(by: scenarioId) as Observable<GetUGScenarioResponse>,
            remoteReq: loadRemoteDataSource(
                by: scenarioId,
                specifiedReachPointIds: specifiedReachPointIds,
                bizContext: bizContext
            ) as Observable<GetUGScenarioResponse>,
            validator: Validator()
        )
        .do(onNext: { [weak self] (resp) in
            let whitelist = self?.whitelistForRP ?? []
            for entity in resp.scenarioContext.entities {
                if !whitelist.contains(entity.reachPointID), let data = entity.material.first, data.hasMaterial {
                    var stash = resp
                    stash.scenarioContext.entities = [entity]
                    if let stashData = try? stash.serializedData() {
                        _ = self?.reachAPI.updateUGValue(by: entity.reachPointID, value: .byteValue(stashData)).subscribe()
                    }
                }
            }
        })
        .map({ [weak self] (resp) -> GetUGScenarioResponse in
            let whitelist = self?.whitelistForRP ?? []
            var validResp = resp
            validResp.scenarioContext.entities = resp.scenarioContext.entities.filter({ (entity) -> Bool in
                return whitelist.contains(entity.reachPointID)
            })
            return validResp
        })
        .do { [weak self] (resp) in
            resp.scenarioContext.entities.forEach { (entity) in
                let globalInfo = ReachPointGlobalInfo(
                    meta: entity,
                    localRuleId: localRuleId
                )
                self?.reachPointGlobalInfos[entity.reachPointID] = globalInfo
            }
            self?.tracer.traceLog(msg: "loadUnionDataSource success \(scenarioId), filtered rps = \(resp.scenarioContext.entities.map { $0.reachPointID })")
        } onError: { [weak self] (error) in
            self?.tracer.traceLog(
                msg: "loadUnionDataSource failed \(scenarioId), error = " + error.localizedDescription
            )
        }
    }

    func pushToCoodinatorStep(scenarioContext: ScenarioContext) -> Observable<Void> {
        tracer.traceLog(msg: "enter push to coodinator step \(scenarioContext.scenarioID)")
        var willDisplayReachPoints = [ReachPointEntity]()
        var willHideReachPoints = [ReachPointEntity]()

        scenarioContext.entities.forEach { (rp) in
            if rp.material.isEmpty {
                willHideReachPoints.append(rp)
            } else {
                willDisplayReachPoints.append(rp)
            }
        }

        if !willDisplayReachPoints.isEmpty {
            var pushScenarioContext = scenarioContext
            pushScenarioContext.entities = willDisplayReachPoints
            let rpIds = willDisplayReachPoints.map { $0.reachPointID }
            tracer.traceLog(msg: "send scenario context to coordinator when expose, sid = \(pushScenarioContext.scenarioID), rpids = \(rpIds)")
            coordinator?.onScenarioTrigger(scenarioContext: pushScenarioContext)
        }

        if !willHideReachPoints.isEmpty {
            let rpIds = willHideReachPoints.map { $0.reachPointID }
            tracer.traceLog(msg: "send remove event to coordinator when expose, rpids = \(rpIds)")
            let event = UGCoordinator.CoordinatorReachPointEvent(
                action: .remove,
                reachPointIDs: rpIds
            )
            coordinator?.onReachPointEvent(reachPointEvent: event)
        }

        return .just(())
    }
}

private extension CoreDispatcher {
    func expose(
        by scenarioId: String,
        specifiedReachPointIds: [String]? = nil,
        ruleID: Int64? = nil,
        bizContext: [String: String]? = nil
    ) -> Observable<Void> {
        return Observable.just(())
            .flatMap { [weak self] (_) -> Observable<GetUGScenarioResponse> in
                return self?.loadCombineDataSourceStep(
                    by: scenarioId,
                    localRuleId: ruleID,
                    specifiedReachPointIds: specifiedReachPointIds,
                    bizContext: bizContext
                ) ?? .just(GetUGScenarioResponse())
            }
            .filter { !$0.scenarioContext.entities.isEmpty }
            .flatMap { (dataSource) -> Observable<GetUGScenarioResponse> in
                return .just(dataSource)
            }
            .flatMap({ [weak self] (dataSource) -> Observable<Void> in
                return (self?.pushToCoodinatorStep(scenarioContext: dataSource.scenarioContext) ?? .just(()))
            })
    }

    func loadCacheDataSource(by scenarioId: String) -> Observable<GetUGScenarioResponse> {
        let identifier = String(CACurrentMediaTime())
        tracer.traceMetric(
            eventKey: Homeric.UG_REACH_FETCH_SENARIO_INFO,
            identifier: identifier,
            isEndPoint: false
        )
        return reachAPI.fetchScenario(
            via: .cache,
            scenarioId: scenarioId,
            specifiedReachPointIds: nil,
            bizContext: nil
        ).do { [weak self] (resp) in
            self?.tracer
                .traceLog(msg: "load cache dataSource success, resp = \(resp)")
                .traceMetric(
                    eventKey: Homeric.UG_REACH_FETCH_SENARIO_INFO,
                    identifier: identifier,
                    category: ["isSuccess": "true",
                               "source": "local"],
                    isEndPoint: true
                )
        } onError: { [weak self] (error) in
            self?.tracer
                .traceLog(msg: "load cache dataSource failed, error = \(error.localizedDescription)")
                .traceMetric(
                    eventKey: Homeric.UG_REACH_FETCH_SENARIO_INFO,
                    identifier: identifier,
                    category: ["isSuccess": "false",
                               "errorCode": error.reachErrorCode(),
                               "source": "local"],
                    extra: ["errMsg": error.localizedDescription],
                    isEndPoint: true
                )
        }
    }

    func loadRemoteDataSource(
        by scenarioId: String,
        specifiedReachPointIds: [String]? = nil,
        bizContext: [String: String]? = nil
    ) -> Observable<GetUGScenarioResponse> {
        let identifier = String(CACurrentMediaTime())
        tracer.traceMetric(
            eventKey: Homeric.UG_REACH_FETCH_SENARIO_INFO,
            identifier: identifier,
            isEndPoint: false
        )
        return reachAPI.fetchScenario(
            via: .remote,
            scenarioId: scenarioId,
            specifiedReachPointIds: specifiedReachPointIds,
            bizContext: bizContext
        )
        .timeout(.milliseconds(Int(configuration.requestTimeoutDuration * 1000)), scheduler: serialScheduler)
        .do { [weak self] (resp) in
            self?.tracer
                .traceLog(msg: "load remote dataSource success, resp = \(resp)")
                .traceMetric(
                    eventKey: Homeric.UG_REACH_FETCH_SENARIO_INFO,
                    identifier: identifier,
                    category: ["isSuccess": "true",
                               "source": "remote"],
                    isEndPoint: true
                )
        } onError: { [weak self] (error) in
            self?.tracer
                .traceLog(msg: "load remote dataSource failed, error = \(error.localizedDescription)")
                .traceMetric(
                    eventKey: Homeric.UG_REACH_FETCH_SENARIO_INFO,
                    identifier: identifier,
                    category: ["isSuccess": "false",
                               "errorCode": error.reachErrorCode(),
                               "source": "remote"],
                    extra: ["errMsg": error.localizedDescription],
                    isEndPoint: true
                )
        }
    }

    func setRequestDisposable(identifier: String, disposable: Disposable?) {
        if let disposable = requestDisposables[identifier] {
            disposable.dispose()
        }
        requestDisposables[identifier] = disposable
    }

    func combinedBizContext(
        by scenarioId: String,
        specifiedReachPointIds: [String]? = nil
    ) -> Observable<[String: String]> {
        let scenarioDict = bizContextProviders[scenarioId] ?? [:] + .readWriteLock
        let providers = scenarioDict.compactMap { (element) -> BizContextProvider? in
            if (specifiedReachPointIds?.contains(element.key) ?? true) || element.key == CoreDispatcher.rootScenarioPath {
                return element.value
            }
            return nil
        }

        return Observable.zip(providers.map { $0.contextProvider() })
            .map { (bizContexts) -> [String: String] in
                let tuples = bizContexts.flatMap { $0 }
                return Dictionary(tuples, uniquingKeysWith: +)
            }
    }
}
