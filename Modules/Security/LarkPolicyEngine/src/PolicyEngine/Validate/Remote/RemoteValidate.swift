//
//  RemoteValidate.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/30.
//

import Foundation
import LarkSnCService
import ByteDanceKit

final class RemoteValidate {

    private let service: SnCService

    struct RemoteValidateDataModel: Codable {
        let resultMap: [String: EnforceResult]?
    }

    struct EnforceResult: Codable {
        let effect: Effect
        let actions: [String]?
        let errorCode: Int?
        let appliedPolicySetResults: [PolicySetResult]?
    }
    
    struct PolicySetResult: Codable {
        let policySetKey: String?
        private(set) var isEvaluated: Bool = false
    }

    let remoteValidatePath = "/lark/scs/guardian/enforce"

    init(service: SnCService) {
        self.service = service
    }

    func validate(requestMap: [String: ValidateRequest], completion: (([String: ValidateResponse]) -> Void)?) {
        let requestMapList = requestMap.chunked(into: PolicyRemoteCheckMaxRequestCount)
        var resultMap = [String: ValidateResponse]()
        let group = DispatchGroup()
        requestMapList.forEach { request in
            group.enter()
            fetchValidateResult(requestMap: request) { response in
                resultMap.merge(response) { first, _ in return first }
                group.leave()
            }
        }
        group.notify(queue: PolicyEngineQueue.queue) {
            completion?(resultMap)
        }
    }

    private func fetchValidateResult(
        requestMap: [String: ValidateRequest],
        completion: (([String: ValidateResponse]) -> Void)?
    ) {
        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set domain before use policy engine.")
            assertionFailure("lost domain，please set domain")
            completion?(requestMap.mapValues({ request in
                return ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .local, errorMsg: "Request failed, lost domain.")
            }))
            return
        }
        service.monitor?.info(service: "remote_validate_stat", category: nil, metric: [
            "task_count": requestMap.count
        ])
        var request = HTTPRequest(domain, path: remoteValidatePath, method: .post)
        request.retryCount = 2
        request.retryDelay = .seconds(5)
        let requestMapDict = requestMap.mapValues({ request in
            let jsonData = (try? JSONSerialization.data(withJSONObject: request.entityJSONObject)) ?? Data()
            let jsonStr = String(data: jsonData, encoding: .utf8)
            return [
                "pointcutKey": request.pointKey,
                "enforceContext": jsonStr,
                "enforcementID": request.uuid
            ]
        })
        request.data = ["params": requestMapDict]

        service.logger?.info("Begin remote validate request, params:\(request.data ?? [:])")
        service.client?.request(request, dataType: ResponseModel<RemoteValidateDataModel>.self, completion: { [weak self] result in
            switch result {
            case .success(let response):
                guard let responseMap = response.data?.resultMap,
                      response.code.isZeroOrNil else {
                    let policyEngineError = PolicyEngineError(
                        error: .policyError(.remoteValidateRequestFailed),
                        message: "Request remote validate failed, code:\(response.code ?? -1), message:\(response.msg ?? ""), response count:\(response.data?.resultMap?.count ?? 0)")
                    policyEngineError.report(monitor: self?.service.monitor)
                    completion?(requestMap.mapValues({ request in
                        return ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .remote, errorMsg: policyEngineError.message)
                    }))
                    self?.service.logger?.error("Request remote validate failed, code:\(response.code ?? -1), message:\(response.msg ?? "")")
                    break
                }
                var resultMap = [String: ValidateResponse]()
                responseMap.forEach { taskID, result in
                    guard let request = requestMap[taskID] else {
                        self?.service.logger?.warn("found unknow task id: \(taskID)")
                        return
                    }
                    let actions: [Action] = (result.actions ?? []).compactMap { actionJson in
                        guard let actionDict = (actionJson as NSString).btd_jsonDictionary() else {
                            return nil
                        }
                        guard let name = actionDict["name"] as? String else {
                            return nil
                        }
                        let params = actionDict["params"] as? [String: Any]
                        return Action(name: name, params: params ?? [:])
                    }
                    // 存在错误
                    if let errorCode = result.errorCode, errorCode != 0 {
                        resultMap[taskID] = ValidateResponse(effect: result.effect,
                                                             actions: actions,
                                                             uuid: request.uuid,
                                                             type: .remote,
                                                             errorMsg: "uuid:\(request.uuid), taskid:\(taskID), remote error, code: \(result.errorCode ?? -1)")
                        let policyEngineError = PolicyEngineError(
                            error: .policyError(.remoteValidateFailed),
                            message: "uuid:\(request.uuid), taskid:\(taskID), Remote validate failed, error code:\(result.errorCode ?? -1)")
                        policyEngineError.report(monitor: self?.service.monitor)
                        // swiftlint:disable:next line_length
                        self?.service.logger?.error("uuid:\(request.uuid), taskid:\(taskID), Request remote validate failed, errorCode:\(result.errorCode ?? -1), policyEngineErrorCode:\(policyEngineError.error.code)")
                    } else {
                        let policySetKeys = result.appliedPolicySetResults?
                            .filter { $0.isEvaluated && $0.policySetKey != nil }
                            .compactMap { $0.policySetKey } ?? []
                        let checkType: ResponseType = ((result.appliedPolicySetResults?.isEmpty ?? true) || !policySetKeys.isEmpty) ? .remote : .fastPass
                        resultMap[taskID] = ValidateResponse(effect: result.effect, actions: actions, uuid: request.uuid, type: checkType, policySetKeys: policySetKeys)
                    }
                }
                let lostMap = requestMap.filter { resultMap[$0.key] == nil }
                lostMap.forEach { taskID, request in
                    self?.service.logger?.error("lost validate taskID: \(taskID) by remote.")
                    resultMap[taskID] = ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .local, errorMsg: "Lost validate by remote.")
                }
                completion?(resultMap)
                self?.service.logger?.info("Success remote validate request, params:\(request.data ?? [:])")

            case .failure(let error):
                let policyEngineError = PolicyEngineError(error: .policyError(.remoteValidateRequestFailed), message: "Request remote validate failed, error:\(error)")
                policyEngineError.report(monitor: self?.service.monitor)
                completion?(requestMap.mapValues({ request in
                    return ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .local, errorMsg: policyEngineError.message)
                }))
                self?.service.logger?.error("Fail remote validate request, params:\(request.data ?? [:]), error: \(error)")
            }
        })
    }

}
