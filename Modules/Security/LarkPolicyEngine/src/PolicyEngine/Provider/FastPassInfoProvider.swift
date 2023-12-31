//
//  FastPassInfoProvider.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/2/15.
//

import Foundation
import LarkSnCService
import ThreadSafeDataStructure

private typealias FastPassConfig = [String: [String]]

private struct PolicyTypeTenantsResponse: Codable {
    let policyTypeTenants: FastPassConfig?
}

final class FastPassInfoProvider {

    private static let queryConfigURLPath = "/lark/scs/guardian/policy_engine/policy_type_tenants/query"
    private static let fastPassConfigCacheKey = "FastPassConfigCacheKey"
    private var isFirstRequest: Bool = true

    private let service: SnCService
    private let setting: Setting
    private var safeFastPassConfig: SafeAtomic<FastPassConfig?> = nil + .readWriteLock
    private var fastPassConfig: FastPassConfig? {
        get { safeFastPassConfig.value }
        set { safeFastPassConfig.value = newValue }
    }

    init(service: SnCService) {
        self.service = service
        self.setting = Setting(service: service)
        fastPassConfig = readFromCache()
    }

    func checkTenantHasPolicy(tenantID: String, policyType: PolicyType) throws -> Bool {
        if let id = Int64(tenantID), id <= 0 {
            return false
        }
        guard let fastPassConfig = fastPassConfig else {
            throw PolicyEngineError(error: .policyError(.queryFastPassConfigFailed),
                                          message: "fail to query fast pass config, config not exist, policy type:\(policyType)")
            
        }
        guard let tenants = fastPassConfig[policyType.rawValue] else {
            throw PolicyEngineError(error: .policyError(.queryFastPassConfigFailed),
                                          message: "fail to query fast pass config, policy type:\(policyType)")
        }
        return tenants.contains(tenantID)
    }

    func fetchConfig() {
        guard setting.isEnablePolicyEngine else {
            service.logger?.info("disable fetch fast pass config by disable policy engine.")
            return
        }
        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set http domain before fetch.")
            assertionFailure("lost domain, please set http domain before fetch.")
            return
        }
        service.logger?.info("FastPassInfo isFirstRequest:\(isFirstRequest)")

        var request = HTTPRequest(domain, path: Self.queryConfigURLPath, method: .post)
        request.retryCount = 2
        request.retryDelay = .seconds(5)
        service.logger?.info("prepare to request fast pass config.")

        service.client?.request(request, dataType: ResponseModel<PolicyTypeTenantsResponse>.self, completion: { [weak self] result in
            switch result {
            case .success(let response):
                guard let fastPassConfig = response.data?.policyTypeTenants,
                      response.code.isZeroOrNil else {
                    let error = PolicyEngineError(error: .policyError(.fetchFastPassConfigFailed),
                                                  message: "fail to request fast pass config, code:\(response.code ?? -1), message:\(response.msg ?? "")")
                    error.report(monitor: self?.service.monitor)
                    self?.service.logger?.error(error.message)
                    break
                }
                self?.service.logger?.info("success request fast pass config, config:\(fastPassConfig)")
                PolicyEngineQueue.sync {
                    self?.fastPassConfig = fastPassConfig
                    self?.saveToCache(fastPassConfig: fastPassConfig)
                }
            case .failure(let error):
                let firstRequest = self?.isFirstRequest ?? true
                let error = PolicyEngineError(error: .policyError(.fetchFastPassConfigFailed),
                                              message: "fail to request fast pass config, isFirstRequest: \(firstRequest), error: \(error)")
                error.report(monitor: self?.service.monitor)
                self?.service.logger?.error(error.message)
            }
            self?.isFirstRequest = false
        })
    }

    private func saveToCache(fastPassConfig: FastPassConfig) {
        do {
            try service.storage?.set(fastPassConfig, forKey: Self.fastPassConfigCacheKey, space: .global)
        } catch {
            service.logger?.error("fail to set policy cache, error: \(error)")
        }
    }

    private func readFromCache() -> FastPassConfig? {
        do {
            guard let fastPassConfig: FastPassConfig = try service.storage?.get(key: Self.fastPassConfigCacheKey, space: .global) else {
                service.logger?.info("policy cache is empty.")
                return nil
            }
            return fastPassConfig
        } catch {
            service.logger?.error("fail to get policy cache, error: \(error)")
            return nil
        }
    }

    public func tenantHasDeployPolicyInner(tenantId: String?) -> Bool {
        service.logger?.info("tenantHasDeployPolicy validate, tenantID:\(tenantId ?? "-1") tenantIdList:\(fastPassConfig ?? [:])")

        // 当前用户所在租户信息获取失败,需要拉取策略信息
        guard let tenantId = tenantId else {
            service.logger?.error("tenantHasDeployPolicy validate, tenantID nil")
            return true
        }
        // 租户列表拉取失败,需要拉取策略信息;这里要区分拉取为空值,空值并非nil,空值则表示不需要拉取
        guard let tenantIdList = fastPassConfig else {
            service.logger?.error("tenantHasDeployPolicy validate, tenantIdList nil")
            return true
        }

        // 当前用户所在信息获取异常,需要拉取策略信息
        if Int(tenantId) ?? 0 <= 0 {
            service.logger?.error("tenantHasDeployPolicy validate, tenantId validate error")
            return true
        }

        // 租户列表包含当前用户所在租户,需要拉取策略信息
        return tenantIdList.contains(where: {
            let result = $0.value.contains(tenantId)
            if result {
                service.logger?.info("tenantHasDeployPolicy validate, tenantIdList contains tenantId")
            }
            return result
        })
    }
}

extension FastPassInfoProvider: EventDriver {
    func receivedEvent(event: InnerEvent) {
        switch event {
        case .initCompletion, .timerEvent:
            fetchConfig()
        default:
            return
        }
    }
}
