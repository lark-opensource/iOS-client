//
//  PolicyEngine.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/28.
//

import Foundation
import LarkSnCService

protocol ProviderDelegate: AnyObject {
    func tenantHasDeployPolicy() -> Bool
    func postOuterEvent(event: Event)
    func postInnerEvent(event: InnerEvent)
}

public final class PolicyEngine {

    let service: SnCService
    let decisionLogManager: DecisionLogManager

    private let setting: Setting
    private var parameterMap: [String: Parameter] = [:]
    private let observerManager = WeakManager<Observer>()
    private let eventDriver = WeakManager<EventDriver>()
    private let localValidate: LocalValidate
    private let remoteValidate: RemoteValidate
    private let factorsController: FactorsController
    private let sessionInvalidObserver: SessionInvalidObserver
    private let cacheUpdateEvent: CacheUpdateEvent

    private let policyProvider: PolicyProvider
    private let pointCutProvider: PointCutProvider
    private let fastPassConfigProvider: FastPassInfoProvider
    private let subjectFactorProvider: SubjectFactorProvider
    private let ipFactorProvider: IPFactorProvider
    private let priorityProvider: PolicyPriorityProvider

    private var timer: Timer?

    deinit {
        timer?.invalidate()
        timer = nil
    }

    public init(service: SnCService) {
        self.service = service
        self.setting = Setting(service: service)
        policyProvider = PolicyProvider(service: service)
        pointCutProvider = PointCutProvider(service: service)
        fastPassConfigProvider = FastPassInfoProvider(service: service)
        subjectFactorProvider = SubjectFactorProvider(service: service)
        ipFactorProvider = IPFactorProvider(service: service)
        priorityProvider = PolicyPriorityProvider(policyProvider: policyProvider, factorProvider: subjectFactorProvider, service: service)
        localValidate = LocalValidate(service: service)
        remoteValidate = RemoteValidate(service: service)
        factorsController = FactorsController(service: service)
        sessionInvalidObserver = SessionInvalidObserver(service: service)
        decisionLogManager = DecisionLogManager(service: service)
        cacheUpdateEvent = CacheUpdateEvent(service: service)
        
        policyProvider.delegate = self
        subjectFactorProvider.delegate = self
        ipFactorProvider.delegate = self
        sessionInvalidObserver.delegate = self
        cacheUpdateEvent.delegate = self

        eventDriver.register(object: sessionInvalidObserver)
        eventDriver.register(object: policyProvider)
        eventDriver.register(object: pointCutProvider)
        eventDriver.register(object: fastPassConfigProvider)
        eventDriver.register(object: decisionLogManager)
        eventDriver.register(object: subjectFactorProvider)
        eventDriver.register(object: priorityProvider)
        eventDriver.register(object: ipFactorProvider)
        eventDriver.register(object: cacheUpdateEvent)
        let eventLogger = EventLogger(service: service)
        eventDriver.register(object: eventLogger)

        observerManager.register(object: eventLogger)
        setupTimer()
    }
}

extension PolicyEngine: PolicyEngineService {

    public func register(parameter: Parameter) {
        PolicyEngineQueue.sync {
            parameterMap[parameter.key] = parameter
        }
    }

    public func remove(parameter: Parameter) {
        _ = PolicyEngineQueue.sync {
            parameterMap.removeValue(forKey: parameter.key)
        }
    }

    public func register(observer: Observer) {
        PolicyEngineQueue.sync {
            observerManager.register(object: observer)
        }
    }

    public func remove(observer: Observer) {
        PolicyEngineQueue.sync {
            observerManager.remove(object: observer)
        }
    }

    public func postEvent(event: InnerEvent) {
        eventDriver.sendEvent(event: event)
    }

    public func asyncValidate(requestMap: [String: ValidateRequest],
                              callback: (([String: ValidateResponse]) -> Void)?) {
        let startTime = CFAbsoluteTimeGetCurrent()
        PolicyEngineQueue.async { [weak self] in
            self?.validate(requestMap: requestMap) { responseMap, localDuration, remoteDuration in

                DispatchQueue.main.async {
                    callback?(responseMap)
                }

                self?.trackCombineValidateCost(
                    localDuration: localDuration,
                    remoteDuration: remoteDuration,
                    totalDuration: Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000_000),
                    count: responseMap.count
                )
                self?.trackCombineResult(responseMap: responseMap)

                responseMap.forEach { taskID, response in
                    guard let request = requestMap[taskID] else { return }
                    response.trackTaskPerf(request: request, monitor: self?.service.monitor)
                    response.trackResult(request: request, tracker: self?.service.tracker)
                }
            }
        }
    }

    public func downgradeDecision(request: ValidateRequest) -> ValidateResponse {
        if enableFastPass(request: request) {
            return ValidateResponse(effect: .permit, actions: [], uuid: request.uuid, type: .fastPass)
        }
        let response: ValidateResponse
        do {
            response = try self.pointCutProvider.selectDowngradeDecision(by: request)
        } catch let err as PolicyEngineError {
            response = ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .downgrade, errorMsg: err.message)
            err.report(monitor: service.monitor)
        } catch {
            response = ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .downgrade, errorMsg: "Unknow error: \(error)")
            assertionFailure("Unknow error: \(error)")
        }
        service.logger?.info("uuid:\(request.uuid), downgrade validate, request:\(request)")
        return response
    }

    public func enableFastPass(request: ValidateRequest) -> Bool {
        guard setting.isEnablePolicyEngine else {
            service.logger?.info("uuid:\(request.uuid), fast pass true by disable policy engine.")
            return true
        }
        guard let pointcut = pointCutProvider.selectPointcutInfo(by: request), !pointcut.appliedPolicyTypes.isEmpty else {
            service.logger?.info("uuid:\(request.uuid), fast pass false. select pointcut failed or has empty policy types. pointkey:\(request.pointKey)")
            return false
        }

        var hasCheck = false

        if let tenantIDKeyPath = pointcut.contextDerivation["TENANT_ID"] {
            guard let tenantID = (request.entityJSONObject as NSDictionary).value(forKeyPath: tenantIDKeyPath) as? Int64 else {
                let error = PolicyEngineError(error: .policyError(.queryFastPassConfigFailed),
                                              message: "fail to query fast info, can't get TENANT_ID, point key:\(request.pointKey)")
                error.report(monitor: self.service.monitor)
                self.service.logger?.error("uuid:\(request.uuid), " + error.message)
                assertionFailure("lack of \(tenantIDKeyPath)")
                return false
            }
            // swiftlint:disable reduce_boolean
            let result = pointcut.appliedPolicyTypes.reduce(true) { partialResult, policyType in
                return partialResult && isEnableFastPass(tenantID: tenantID, policyType: policyType)
            }
            // swiftlint:enable reduce_boolean
            hasCheck = true
            guard result else {
                service.logger?.info("uuid:\(request.uuid), pointkey:\(request.pointKey) fast pass result: false.")
                return false
            }
        }

        if let objectTenantIDKeyPath = pointcut.contextDerivation["OBJECT_TENANT_ID"] {
            guard let objectTenantID = (request.entityJSONObject as NSDictionary).value(forKeyPath: objectTenantIDKeyPath) as? Int64 else {
                let error = PolicyEngineError(error: .policyError(.queryFastPassConfigFailed),
                                              message: "fail to query fast info, can't get OBJECT_TENANT_ID, point key:\(request.pointKey)")
                error.report(monitor: self.service.monitor)
                self.service.logger?.error("uuid:\(request.uuid), " + error.message)
                assertionFailure("lack of \(objectTenantIDKeyPath)")
                return false
            }
            // swiftlint:disable reduce_boolean
            let result = pointcut.appliedPolicyTypes.reduce(true) { partialResult, policyType in
                return partialResult && isEnableFastPass(tenantID: objectTenantID, policyType: policyType)
            }
            // swiftlint:enable reduce_boolean
            hasCheck = true
            guard result else {
                service.logger?.info("uuid:\(request.uuid), pointkey:\(request.pointKey) fast pass result: false.")
                return false
            }
        }
        service.logger?.info("uuid:\(request.uuid), pointkey:\(request.pointKey) fast pass result: \(hasCheck).")
        return hasCheck
    }

    public func checkPointcutIsControlledByFactors(requestMap: [String: CheckPointcutRequest],
                                                   callback: ((_ retMap: [String: Bool]) -> Void)?) {
        var responseMap = [String: Bool]()
        let requestMap = requestMap.filter { element in
            if enableFastPass(request: element.value) {
                responseMap[element.key] = false
                return false
            }
            return true
        }

        guard !requestMap.isEmpty else {
            DispatchQueue.main.async {
                callback?(responseMap)
            }
            return
        }
        factorsController.checkPointcutIsControlledByFactors(requestMap: requestMap) { retMap in
            DispatchQueue.main.async {
                callback?(responseMap.merging(retMap, uniquingKeysWith: { $0 && $1 }))
            }
        }
    }

    public func enableFetchPolicy(tenantId: String?) -> Bool {
        // 本地决策禁止和策略引擎总开关禁止时,不需要拉取策略信息
        guard !setting.disableLocalValidate, setting.isEnablePolicyEngine else {
            service.logger?.info("tenantHasDeployPolicy validate, disable fetch policy by disable local validate setting.")
            return false
        }
        return fastPassConfigProvider.tenantHasDeployPolicyInner(tenantId: tenantId)
    }

    public func reportRealLog(evaluateInfoList: [EvaluateInfo]) {
        decisionLogManager.reportRealLogInner(evaluateInfoList: evaluateInfoList)
    }

    public func deleteDecisionLog(evaluateInfoList: [EvaluateInfo]) {
        decisionLogManager.deleteDecisionLogInner(evaluateInfoList: evaluateInfoList)
    }
    
}

extension PolicyEngine: ProviderDelegate {
    func postInnerEvent(event: InnerEvent) {
        postEvent(event: event)
    }

    func postOuterEvent(event: Event) {
        observerManager.sendEvent(event: event)
    }

    func tenantHasDeployPolicy() -> Bool {
        return fastPassConfigProvider.tenantHasDeployPolicyInner(tenantId: service.environment?.tenantId)
    }
}

extension PolicyEngine: SessionInvalidObserverDelegate {
    func sessionInvalidAction() {
        self.timer?.invalidate()
        service.logger?.info("PolicyEngine Timer Stop")
    }
}

extension PolicyEngine {
    func setupTimer() {
        self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(setting.fetchPolicyInterval), repeats: true, block: { [weak self] _ in
            self?.postEvent(event: .timerEvent)
        })
    }

    func validate(requestMap: [String: ValidateRequest],
                  callback: ((_ responseMap: [String: ValidateResponse], _ localDuration: Int, _ remoteDuration: Int) -> Void)?) {
        let localStartTime = CFAbsoluteTimeGetCurrent()
        let localDuration: () -> Int = {
            return Int((CFAbsoluteTimeGetCurrent() - localStartTime) * 1_000_000)
        }

        var resultMap = [String: ValidateResponse]()
        let enablePolicyEngine = setting.isEnablePolicyEngine
        service.logger?.info("start async validate, engine seitch:\(enablePolicyEngine)")
        // first pass
        let requestMap = requestMap.filter { element in
            if enableFastPass(request: element.value) {
                resultMap[element.key] = ValidateResponse(effect: .permit, actions: [], uuid: element.value.uuid, type: .fastPass)
                return false
            }
            return true
        }

        // 全部快速通过了
        guard !requestMap.isEmpty else {
            callback?(resultMap, localDuration(), 0)
            service.logger?.info("fast pass, request list:\(requestMap)")
            return
        }
        let subjectFactors = subjectFactorProvider.getSubjectFactorDict()
        let ipFactors = ipFactorProvider.getIPFactorDict()
        let factors = subjectFactors.merging(ipFactors) { f, _ in f }
        let context = ValidateContext(policyProvider: policyProvider, pointCutProvider: pointCutProvider, priorityProvider: priorityProvider, factors: factors, baseParam: parameterMap)
        var remoteCheckMap = [String: ValidateRequest]()
        var localCheckMap = [String: ValidateRequest]()
        let disableLocalDecisionPointcutList = setting.disableLocalDecisionPointcutList
        requestMap.forEach { element in
            if pointCutProvider.selectPointcutInfo(by: element.value) == nil || disableLocalDecisionPointcutList.map({ $0 }).contains(element.value.pointKey) {
                remoteCheckMap[element.key] = element.value
            } else {
                localCheckMap[element.key] = element.value
            }
        }

        var localResultMap = [String: ValidateResponse]()
        if !setting.disableLocalValidate && localCheckMap.count < setting.localValidateLimitCount {
            localResultMap = localValidate.validate(requestMap: localCheckMap, context: context)
            // 过滤通过的和出错的
            localResultMap.forEach { key, value in
                if value.effect != .deny || value.errorMsg != nil {
                    remoteCheckMap[key] = localCheckMap[key]
                } else {
                    resultMap[key] = value
                }
            }
        } else {
            remoteCheckMap = requestMap
        }
        guard !remoteCheckMap.isEmpty else {
            // 快速拒绝
            service.logger?.info("Fast blocked all request")
            callback?(resultMap, localDuration(), 0)
            return
        }
        let remoteStartTime = CFAbsoluteTimeGetCurrent()
        remoteValidate.validate(requestMap: remoteCheckMap) { [weak self] remoteResultMap in
            remoteResultMap.forEach { key, response in
                var response = response
                if response.errorMsg != nil {
                    // downgrade
                    guard let request = remoteCheckMap[key] else {
                        resultMap[key] = .init(
                            effect: .indeterminate,
                            actions: [],
                            uuid: "0",
                            type: .downgrade,
                            errorMsg: "Failed to select downgrade decision result, because unknown key:\(key) for request.")
                        return
                    }
                    guard var downgrade = self?.downgradeDecision(request: request) else {
                        resultMap[key] = .init(
                            effect: .indeterminate,
                            actions: [],
                            uuid: "0",
                            type: .downgrade,
                            errorMsg: "Failed to select downgrade decision result, request info: \(request)")
                        return
                    }
                    downgrade.logInfo = localResultMap[key]?.logInfo ?? LocalValidateLogInfo.default
                    resultMap[key] = downgrade
                } else {
                    response.logInfo = localResultMap[key]?.logInfo ?? LocalValidateLogInfo.default
                    resultMap[key] = response
                }
            }
            // 判断是否存在遗漏
            let uncheckedMap = requestMap.filter { resultMap[$0.key] == nil }
            if !uncheckedMap.isEmpty {
                self?.service.logger?.error("Found uncheck request: \(uncheckedMap)")
                let uncheckedDowngradeMap = uncheckedMap.mapValues { request in
                    guard let downgrade = self?.downgradeDecision(request: request) else {
                        return ValidateResponse(effect: .indeterminate,
                                                actions: [],
                                                uuid: "0",
                                                type: .downgrade,
                                                errorMsg: "Failed to select downgrade decision result, request info: \(request)")
                    }
                    return downgrade
                }
                resultMap.merge(uncheckedDowngradeMap) { first, _ in return first }
            }
            callback?(resultMap, Int((remoteStartTime - localStartTime) * 1_000_000), Int((CFAbsoluteTimeGetCurrent() - remoteStartTime) * 1_000_000))
        }
    }

    /// 是否允许快速通过
    /// 传递了租户id的情况下，查询租户id是否配置策略
    private func isEnableFastPass(tenantID: Int64, policyType: PolicyType) -> Bool {
        guard setting.isEnablePolicyEngine else {
            service.logger?.info("Fast pass with disable policy enable, tenant id: \(tenantID)")
            return true
        }
        do {
            let hasConfigPolicy = try self.fastPassConfigProvider.checkTenantHasPolicy(tenantID: String(tenantID), policyType: policyType)
            return !hasConfigPolicy
        } catch let err as PolicyEngineError {
            err.report(monitor: service.monitor)
            self.service.logger?.error(err.message)
        } catch {
            let engineError = PolicyEngineError(error: .policyError(.unknow), message: error.localizedDescription)
            engineError.report(monitor: service.monitor)
            self.service.logger?.error(engineError.message)
        }
        return false
    }
}
