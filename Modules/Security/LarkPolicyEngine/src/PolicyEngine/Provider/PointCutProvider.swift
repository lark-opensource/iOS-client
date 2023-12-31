//
//  PointCutProvider.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/29.
//

import Foundation
import LarkSnCService
import ThreadSafeDataStructure

final class PointCutProvider {
    private static let pointCutFetchURL = "/lark/scs/guardian/policy_engine/pointcut/query"
    private static let cacheKey = "PointCutInfoCacheKey"
    private var isFirstRequest: Bool = true

    private let service: SnCService
    private let setting: Setting
    private var safeConfigs: SafeAtomic<[String: PointCutModel]?> = nil + .readWriteLock
    private var configs: [String: PointCutModel]? {
        get { safeConfigs.value }
        set { safeConfigs.value = newValue }
    }
    private var isRetrying = false

    init(service: SnCService) {
        self.service = service
        self.setting = Setting(service: service)
        self.configs = readFromCache()
    }

    func selectPointcutInfo(by request: ValidateRequest) -> PointCutModel? {
        var pointcut: PointCutModel?
        pointcut = configs?[request.pointKey]
        if configs == nil {
            let error = PolicyEngineError(error: .policyError(.queryPointcutFailed), message: "fail to query point cut, point key:\(request.pointKey), has data:\(configs != nil)")
            error.report(monitor: self.service.monitor)
            self.service.logger?.error(error.message)
            PolicyEngineQueue.async {
                self.fetchConfig()
            }
        }
        return pointcut
    }

    func selectDowngradeDecision(by request: ValidateRequest) throws -> ValidateResponse {

        if let pointcut = selectPointcutInfo(by: request) {
            let actions = try pointcut.fallbackActions?.compactMap { actionName in
                return try ActionResolver.resolve(action: actionName, request: request)
            }
            return ValidateResponse(effect: pointcut.fallbackStrategy == 1 ? .permit : .deny, actions: actions ?? [], uuid: request.uuid, type: .downgrade)
        }
        let error = PolicyEngineError(error: .policyError(.queryDowngradeDecisionFailed),
                                      message: "Fail to select downgrade decision, pointKey:\(request.pointKey)，has data:\(configs != nil)")
        error.report(monitor: service.monitor)
        service.logger?.error(error.message)
        throw error
    }

    func fetchConfig() {
        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set request domain at first.")
            assertionFailure("lost domain, please set request domain at first.")
            return
        }
        guard setting.isEnablePolicyEngine else {
            service.logger?.info("disable fetch pointcut info by disable policy engine.")
            return
        }
        guard !isRetrying else {
            service.logger?.info("is retrying, drop this request for point cut.")
            return
        }
        service.logger?.info("begin request point cut.")
        var request = HTTPRequest(domain, path: PointCutProvider.pointCutFetchURL, method: .post)
        request.retryCount = 2
        request.retryDelay = .seconds(5)
        self.isRetrying = true
        service.client?.request(request, dataType: ResponseModel<PointcutQueryDataModel>.self, completion: { [weak self] result in
            switch result {
            case .success(let response):
                if let pointcuts = response.data?.pointcuts, response.code.isZeroOrNil {
                    // 处理成key:value的形式
                    var configs = [String: PointCutModel]()
                    for config in pointcuts {
                        configs[config.identifier] = config
                    }
                    PolicyEngineQueue.async {
                        self?.configs = configs
                        self?.writeToCache(configs: configs)
                    }
                    self?.service.logger?.info("success request point cut.")
                } else {
                    let error = PolicyEngineError(error: .policyError(.pointcutFetchFailed), message: "fail to request point cut, code:\(response.code ?? -1), message:\(response.msg ?? "")")
                    error.report(monitor: self?.service.monitor)
                    self?.service.logger?.error(error.message)
                }
            case .failure(let err):
                let firstRequest = self?.isFirstRequest ?? true
                let error = PolicyEngineError(error: .policyError(.pointcutFetchFailed), message: "fail to request point cut, isFirstRequest: \(firstRequest), error:\(err)")
                error.report(monitor: self?.service.monitor)
                self?.service.logger?.error(error.message)
            }
            self?.isFirstRequest = false
            PolicyEngineQueue.asyncAfter(deadline: .now() + .seconds(self?.setting.pointcutRetryDelay ?? 5)) {
                self?.isRetrying = false
            }
        })
    }

    private func writeToCache(configs: [String: PointCutModel]) {
        do {
            try service.storage?.set(configs, forKey: Self.cacheKey, space: .global)
        } catch {
            service.logger?.error("fail to set point cut cache, error:\(error)")
        }
    }

    private func readFromCache() -> [String: PointCutModel]? {
        do {
            guard let configs: [String: PointCutModel] = try service.storage?.get(key: Self.cacheKey, space: .global) else {
                service.logger?.info("point cut cache is empty.")
                return nil
            }
            return configs
        } catch {
            service.logger?.error("fail to get point cut cache, error:\(error)")
            return nil
        }
    }
}

extension PointCutProvider: EventDriver {
    func receivedEvent(event: InnerEvent) {
        switch event {
        case .initCompletion:
            fetchConfig()
        case .timerEvent:
            if configs == nil {  fetchConfig() }
        default:
            return
        }
    }
}
