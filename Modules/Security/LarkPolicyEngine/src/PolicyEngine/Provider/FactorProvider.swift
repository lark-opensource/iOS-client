//
//  FactorProvider.swift
//  LarkPolicyEngine
//
//  Created by ByteDance on 2023/9/11.
//

import Foundation
import LarkSnCService
import SwiftyJSON

final class SubjectFactorProvider {
    private static let querySubjectFactorURLPath = "/lark/scs/guardian/policy_engine/subject_factor/query"
    private static let subjectFactorInfoCacheKey = "SubjectFactorInfoCacheKey"

    private let service: SnCService
    private let setting: Setting
    private var subjectFactorInfo: SubjectFactorModel?
    weak var delegate: ProviderDelegate?

    init(service: SnCService) {
        self.service = service
        self.setting = Setting(service: service)
        self.subjectFactorInfo = readFromCache()
    }
    
    func getSubjectFactorDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict[FactorKey.userID.rawValue] = Int64(service.environment?.userId ?? "")
        dict[FactorKey.groupID.rawValue] = subjectFactorInfo?.groupIDList
        dict[FactorKey.deptIDPaths.rawValue] = subjectFactorInfo?.userDeptIDPaths
        dict[FactorKey.deptID.rawValue] = subjectFactorInfo?.userDeptIdsWithParent
        subjectFactorInfo?.commonFactorsMap?.forEach { (key, value) in
            do {
                dict[key] = try value.valueConvert()
            } catch {
                service.logger?.error(error.localizedDescription)
            }
        }
        return dict
    }

    func fetchSubjectFactor() {
        guard !setting.disableLocalValidate, setting.isEnablePolicyEngine else {
            service.logger?.info("disable fetch subject factor by disable local validate setting.")
            return
        }
        
        if let delegate = self.delegate, !delegate.tenantHasDeployPolicy() {
            service.logger?.info("tenantHasDeployPolicy validate, don't need to fetch subject factor info")
            return
        }

        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set http domain before fetch.")
            assertionFailure("lost domain, please set http domain before fetch.")
            return
        }

        var request = HTTPRequest(domain, path: Self.querySubjectFactorURLPath, method: .post)
        request.retryCount = 2
        request.retryDelay = .seconds(5)

        service.logger?.info("SubjectFactorProvider prepare to request subject factor.")

        service.client?.request(request, dataType: ResponseModel<SubjectFactorModel>.self, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard let subjectFactorResponse: SubjectFactorModel = response.data,
                      response.code.isZeroOrNil else {
                    let error = PolicyEngineError(error: .policyError(.subjectFactorFetchFailed),
                                                  message: "fail to request subject factor, code:\(response.code ?? -1), message:\(response.msg ?? "")")
                    error.report(monitor: self.service.monitor)
                    self.service.logger?.error(error.message)
                    break
                }
                self.service.logger?.info("SubjectFactorProvider success request subject factor.\(subjectFactorResponse).")
                PolicyEngineQueue.async {
                    if self.subjectFactorInfo != subjectFactorResponse {
                        self.saveToCache(subjectFactorInfo: subjectFactorResponse)
                        self.subjectFactorInfo = subjectFactorResponse
                        self.delegate?.postInnerEvent(event: .subjectFactorUpdate)
                    }
                }
            case .failure(let error):
                let error = PolicyEngineError(error: .policyError(.subjectFactorFetchFailed),
                                              message: "fail to request subject factor, error: \(error)")
                error.report(monitor: self.service.monitor)
                self.service.logger?.error(error.message)
            }
        })
    }

    private func saveToCache(subjectFactorInfo: SubjectFactorModel) {
        do {
            try service.storage?.set(subjectFactorInfo, forKey: Self.subjectFactorInfoCacheKey)
        } catch {
            service.logger?.error("fail to set subject factor cache, error: \(error)")
        }
    }

    private func readFromCache() -> SubjectFactorModel? {
        do {
            guard let subjectFactor: SubjectFactorModel = try service.storage?.get(key: Self.subjectFactorInfoCacheKey) else {
                service.logger?.info("subject factor cache is empty.")
                return nil
            }
            return subjectFactor
        } catch {
            service.logger?.error("fail to get subject factor cache, error: \(error)")
            return nil
        }
    }
}

extension SubjectFactorProvider: EventDriver {
    func receivedEvent(event: InnerEvent) {
        if [.initCompletion, .timerEvent].contains(event) {
            fetchSubjectFactor()
        }
    }
}

final class IPFactorProvider {
    private static let queryIPFactorURLPath = "/lark/scs/guardian/policy_engine/ip/query"
    private static let ipFactorInfoCacheKey = "IPFactorInfoCacheKey"

    private let service: SnCService
    private let setting: Setting
    private var ipFactorInfo: IPFactorModel?
    weak var delegate: ProviderDelegate?

    init(service: SnCService) {
        self.service = service
        self.setting = Setting(service: service)
        self.saveToCache(ipFactorInfo: self.ipFactorInfo)
    }

    func getIPFactorDict() -> [String: Any] {
        guard let info = ipFactorInfo else {
            return [:]
        }
        return [
            FactorKey.sourceIP.rawValue: info.sourceIP,
            FactorKey.sourceIPV4.rawValue: info.sourceIPV4
        ]
    }

    func fetchIPFactor() {
        guard !setting.disableLocalValidate, setting.isEnablePolicyEngine else {
            service.logger?.info("disable fetch ip factor by disable local validate setting.")
            return
        }

        if let delegate = self.delegate, !delegate.tenantHasDeployPolicy() {
            service.logger?.info("tenantHasDeployPolicy validate, don't need fetch ip factor info")
            return
        }

        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set http domain before fetch.")
            assertionFailure("lost domain, please set http domain before fetch.")
            return
        }

        var request = HTTPRequest(domain, path: Self.queryIPFactorURLPath, method: .post)
        request.retryCount = 2
        request.retryDelay = .seconds(5)

        service.logger?.info("IPFactorProvider prepare to request ip factor.")

        service.client?.request(request, dataType: ResponseModel<IPFactorModel>.self, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                guard let ipFactorModel = response.data,
                      response.code.isZeroOrNil else {
                    PolicyEngineQueue.async {
                        self.ipFactorInfo = nil
                        self.delegate?.postOuterEvent(event: .ipFactorChanged)
                        self.saveToCache(ipFactorInfo: self.ipFactorInfo)
                    }
                    let error = PolicyEngineError(error: .policyError(.ipFactorFetchFailed),
                                                  message: "fail to request ip factor, code:\(response.code ?? -1), message:\(response.msg ?? "")")
                    error.report(monitor: self.service.monitor)
                    self.service.logger?.error(error.message)
                    break
                }
                self.service.logger?.info("IPFactorProvider success request ip factor")
                PolicyEngineQueue.async {
                    if ipFactorModel != self.ipFactorInfo {
                        self.ipFactorInfo = ipFactorModel
                        self.delegate?.postOuterEvent(event: .ipFactorChanged)
                        self.saveToCache(ipFactorInfo: self.ipFactorInfo)
                    }
                }
            case .failure(let error):
                PolicyEngineQueue.async {
                    self.ipFactorInfo = nil
                    self.delegate?.postOuterEvent(event: .ipFactorChanged)
                    self.saveToCache(ipFactorInfo: self.ipFactorInfo)
                }
                let error = PolicyEngineError(error: .policyError(.ipFactorFetchFailed),
                                              message: "fail to request ip factor, error: \(error)")
                error.report(monitor: self.service.monitor)
                self.service.logger?.error(error.message)
            }
        })
    }

    private func saveToCache(ipFactorInfo: IPFactorModel?) {
        do {
            try service.storage?.set(ipFactorInfo, forKey: Self.ipFactorInfoCacheKey)
        } catch {
            service.logger?.error("fail to set ip factor cache, error: \(error)")
        }
    }
}

extension IPFactorProvider: EventDriver {
    func receivedEvent(event: InnerEvent) {
        if [.initCompletion, .becomeActive, .networkChanged].contains(event) {
            fetchIPFactor()
        }
    }
}
