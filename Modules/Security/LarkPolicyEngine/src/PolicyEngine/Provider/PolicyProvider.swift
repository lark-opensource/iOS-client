//
//  PolicyProvider.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/8/16.
//

import Foundation
import LarkSnCService

final class PolicyProvider {
    private static let queryPolicyPairURLPath = "/lark/scs/guardian/policy_engine/client_policy_pair/query"
    private static let queryPolicyEntityURLPath = "/lark/scs/guardian/policy_engine/client_policy_entity/query"
    private static let policyEntityInfoCacheKey = "PolicyEntityCacheKey"
    private static let lastRequestDateCacheKey = "LastRequestDateCacheKey"
    private var isFirstPolicyPairRequest: Bool = true
    private var isFirstPolicyEntityRequest: Bool = true

    private let service: SnCService
    private let setting: Setting
    private var policyInfo: PolicyEntityModel?
    private var policyPairs: [String: String]? {
        policyInfo?.policies?.mapValues {
            $0.version
        }
    }
    weak var delegate: ProviderDelegate?

    init(service: SnCService) {
        self.service = service
        self.setting = Setting(service: service)
        policyInfo = readFromCache()
    }

    func selectPolicy(by type: PolicyType) -> [PolicyID: Policy] {
        var policies: [PolicyID: Policy]?
        PolicyEngineQueue.sync {
            policies = policyInfo?.policies?.filter { $0.value.type == type }
        }
        guard let policies = policies else {
            service.logger?.warn("select policy empty by type: \(type)")
            return [:]
        }
        return policies
    }

    func selectAllPolicy() -> [String: Policy]? {
        policyInfo?.policies
    }

    func selectPolicyCombineAlgorithm(by type: PolicyType) throws -> CombineAlgorithm {
        var combineAlgorithmRawStr: String?
        PolicyEngineQueue.sync {
            combineAlgorithmRawStr = policyInfo?.policyType2combineAlgorithm?[type.rawValue]
        }
        guard let combineAlgorithmRawStr = combineAlgorithmRawStr else {
            throw PolicyEngineError(error: .policyError(.queryCombineAlgorithmFailed),
                                    message: "fail to select policy combine algorithm by type: \(type)")
        }
        if let combineAlgorithm = CombineAlgorithm(rawValue: combineAlgorithmRawStr) {
            return combineAlgorithm
        }
        throw PolicyEngineError(error: .policyError(.queryCombineAlgorithmFailed),
                                message: "Found unknow combine algorithm: \(combineAlgorithmRawStr), has data:\(policyInfo != nil)")
    }
    
    func updatePolicyInfo() {
        fetchPolicyPairs { policyPairs, error in
            if let error = error {
                error.report(monitor: self.service.monitor)
                self.service.logger?.error(error.message)
                return
            }
            let combine = policyPairs?.policyType2CombineAlgorithmMap ?? [:]
            if policyPairs?.policyPairs?.count ?? 0 > self.setting.policyEngineFetchPolicyNum {
                self.service.logger?.info("PolicyProvider fetched policies more than 20, clear local policy data")
                self.updatePolicyEntity(update: [:], combine: combine)
                return
            }
            PolicyEngineQueue.async { [weak self] in
                guard let self = self else { return }
                let compare = self.comparePairs(policyPairsInfo: policyPairs)
                let reservePairs = Array(compare.reserve.keys)
                var reserve: [String: Policy] = [:]
                if let policies = self.policyInfo?.policies {
                    reserve = Dictionary(reservePairs.compactMap { ($0, policies[$0]) }) { _, new in new }.compactMapValues { $0 }
                }
                guard !compare.new.isEmpty || !compare.reserve.isEmpty else {
                    self.service.logger?.info("PolicyProvider don't need to update cache, policyPairs is empty")
                    self.updatePolicyEntity(update: [:], combine: combine)
                    return
                }

                var policyPairs: [PolicyPair] = []
                compare.new.forEach { pair in
                    policyPairs.append(PolicyPair(id: pair.key, version: pair.value))
                }

                if policyPairs.isEmpty {
                    self.service.logger?.info("PolicyProvider don't need to request policy entity")
                    self.updatePolicyEntity(update: reserve, combine: combine)
                } else {
                    self.requestPolicyEntity(policyPairs: policyPairs) { policyInfo, error in
                        if let error = error {
                            error.report(monitor: self.service.monitor)
                            self.service.logger?.error(error.message)
                            return
                        }
                        reserve.merge(policyInfo ?? [:]) { _, new in new }
                        self.updatePolicyEntity(update: reserve, combine: combine)
                    }
                }
            }
        }
    }

    func fetchPolicyPairs(callback: ((_ policyPairs: PolicyPairsModel?, _ error: PolicyEngineError?) -> Void)?) {
        guard !setting.disableLocalValidate, setting.isEnablePolicyEngine else {
            service.logger?.info("disable fetch policy pairs by disable local validate setting.")
            return
        }

        if let delegate = self.delegate, !delegate.tenantHasDeployPolicy() {
            service.logger?.info("tenantHasDeployPolicy validate, not need fetch policy pairs info")
            return
        }

        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set http domain before fetch.")
            assertionFailure("lost domain, please set http domain before fetch.")
            return
        }

        var request = HTTPRequest(domain, path: Self.queryPolicyPairURLPath, method: .post)
        request.retryCount = 2
        request.retryDelay = .seconds(5)

        request.data = [
            "version": LarkPolicyEngineVersion
        ]

        service.logger?.info("PolicyProvider prepare to request policy pairs, request data:\(String(describing: request.data))")

        service.client?.request(request, dataType: ResponseModel<PolicyPairsModel>.self, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard let policyPairsInfo = response.data,
                      response.code.isZeroOrNil else {
                    let error = PolicyEngineError(error: .policyError(.policyFetchFailed),
                                                  message: "fail to request policy pairs, code:\(response.code ?? -1), message:\(response.msg ?? "")")
                    callback?(nil, error)
                    break
                }
                self.service.logger?.info("PolicyProvider success request policy pairs, ids:\([policyPairsInfo.policyPairs?.map { ["id": $0.id, "version": $0.version] }])")
                callback?(policyPairsInfo, nil)
            case .failure(let error):
                let firstRequest = self.isFirstPolicyPairRequest
                let error = PolicyEngineError(error: .policyError(.policyFetchFailed),
                                              message: "fail to request policy pairs, isFirstRequest: \(firstRequest), error: \(error)")
                callback?(nil, error)
            }
            self.isFirstPolicyPairRequest = false
        })
    }

    private func comparePairs(policyPairsInfo: PolicyPairsModel?) -> PolicyUpdateResult {
        var curPolicyPairs: [String: String] = [:]
        for pair in policyPairsInfo?.policyPairs ?? [] {
            curPolicyPairs[pair.id] = pair.version
        }
        let policyPairs = self.policyPairs ?? [:]
        if isFirstRequestPolicyInfo() {
            return PolicyUpdateResult(reserve: [:], new: curPolicyPairs)
        } else {
            let reservePairs = policyPairs.filter {
                return curPolicyPairs[$0.key] == $0.value
            }
            let newPairs = curPolicyPairs.filter {
                return policyPairs[$0.key] != $0.value
            }
            return PolicyUpdateResult(reserve: reservePairs, new: newPairs)
        }
    }

    private func saveToCache(policyInfo: PolicyEntityModel?) {
        do {
            try service.storage?.set(policyInfo, forKey: Self.policyEntityInfoCacheKey)
        } catch {
            service.logger?.error("fail to set policy cache, error: \(error)")
        }
    }

    private func readFromCache() -> PolicyEntityModel? {
        do {
            guard let policyEntity: PolicyEntityModel = try service.storage?.get(key: Self.policyEntityInfoCacheKey) else {
                service.logger?.info("policy cache is empty.")
                return nil
            }
            return policyEntity
        } catch {
            service.logger?.error("fail to get policy cache, error: \(error)")
            return nil
        }
    }
    
    private func requestPolicyEntity(policyPairs: [PolicyPair], callback: ((_ policyInfo: [String: Policy]?, _ error: PolicyEngineError?) -> Void)?) {
        guard !setting.disableLocalValidate, setting.isEnablePolicyEngine else {
            service.logger?.info("disable fetch policy entity by disable local validate setting.")
            return
        }

        if let delegate = self.delegate, !delegate.tenantHasDeployPolicy() {
            service.logger?.info("tenantHasDeployPolicy validate, not need fetch policy entity")
            return
        }
        
        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set http domain before fetch.")
            assertionFailure("lost domain, please set http domain before fetch.")
            return
        }
        
        let curRequestPolicyPairs = Array(policyPairs.prefix(20))
        let nextRequestPolicyPairs = Array(policyPairs.dropFirst(20))
        
        guard !curRequestPolicyPairs.isEmpty else {
            service.logger?.info("PolicyProvider request data is empty.")
            callback?(nil, nil)
            return
        }
        
        var request = HTTPRequest(domain, path: Self.queryPolicyEntityURLPath, method: .post)
        request.retryCount = 2
        request.retryDelay = .seconds(5)
        let requestData = curRequestPolicyPairs.map {
            [
                "id": $0.id,
                "version": $0.version
            ]
        }

        request.data = [
            "policyPairs": requestData
        ]

        service.logger?.info("PolicyProvider prepare to request policy entity, request data:\(requestData)")

        service.client?.request(request, dataType: ResponseModel<PolicyEntityResponse>.self, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard let policyEntityInfo = response.data,
                      response.code.isZeroOrNil else {
                    let error = PolicyEngineError(error: .policyError(.policyFetchFailed),
                                                  message: "fail to request policy entity, code:\(response.code ?? -1), message:\(response.msg ?? "")")
                    callback?(nil, error)
                    break
                }
                self.service.logger?.info("PolicyProvider success request policy entity, ids:\(policyEntityInfo.policies?.map { ["id": $0.id, "version": $0.version] } ?? [])")
                if policyEntityInfo.policies?.count != curRequestPolicyPairs.count {
                    let error = PolicyEngineError(error: .policyError(.policyFetchFailed),
                                                  message: "Inconsistent quantity of request pairs, code:\(response.code ?? -1), message:\(response.msg ?? "")")
                    callback?(nil, error)
                    break
                }
                PolicyEngineQueue.async { [weak self] in
                    guard let self = self else { return }
                    self.requestPolicyEntity(policyPairs: nextRequestPolicyPairs) { policyInfo, error in
                        if let error = error {
                            callback?(nil, error)
                            return
                        }
                        var policies = Dictionary((policyEntityInfo.policies ?? []).map { ($0.id, $0) }) { _, new in new }
                        policies.merge(policyInfo ?? [:]) { _, new in new }
                        callback?(policies, nil)
                    }
                }
            case .failure(let error):
                let firstRequest = self.isFirstPolicyEntityRequest
                let error = PolicyEngineError(error: .policyError(.policyFetchFailed),
                                              message: "fail to request policy entity, isFirstRequest: \(firstRequest), error: \(error)")
                callback?(nil, error)
            }
            self.isFirstPolicyEntityRequest = false
        })
    }

    private func isFirstRequestPolicyInfo() -> Bool {
        var lastRequestDate: Date?
        
        do {
            if let data: Date = try service.storage?.get(key: Self.lastRequestDateCacheKey) {
                lastRequestDate = data
            }
        } catch {
            service.logger?.error("PolicyProvider fail to get date cache, error: \(error)")
            return true
        }
        
        let currentDate = Date()
        if let lastDate = lastRequestDate,
           Calendar.current.isDate(lastDate, inSameDayAs: currentDate) {
            return false
        }
        
        do {
            try service.storage?.set(currentDate, forKey: Self.lastRequestDateCacheKey)
        } catch {
            service.logger?.error("fail to set date cache, error: \(error)")
        }
        return true
    }

    private func updatePolicyEntity(update: [String: Policy], combine: [String: String]) {
        self.policyInfo = PolicyEntityModel(policies: update, policyType2combineAlgorithm: combine)
        self.saveToCache(policyInfo: self.policyInfo)
        self.delegate?.postInnerEvent(event: .policyUpdate)
    }
}

extension PolicyProvider: EventDriver {
    func receivedEvent(event: InnerEvent) {
        switch event {
        case .initCompletion, .timerEvent:
            updatePolicyInfo()
        default:
            return
        }
    }
}
