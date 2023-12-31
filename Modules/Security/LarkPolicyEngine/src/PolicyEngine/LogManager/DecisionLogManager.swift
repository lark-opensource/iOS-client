//
//  DecisionLogManager.swift
//  LarkPolicyEngine
//
//  Created by ByteDance on 2023/8/21.
//

import Foundation
import LarkSnCService

public struct EvaluateInfo: Codable, Equatable {
    
    public let evaluateUk: String
    let operateTime: String?
    let policySetKeys: [String]
    
    public init(evaluateUk: String, operateTime: String, policySetKeys: [String]) {
        self.evaluateUk = evaluateUk
        self.operateTime = operateTime
        self.policySetKeys = policySetKeys
    }
    
    public static func == (lhs: EvaluateInfo, rhs: EvaluateInfo) -> Bool {
        return lhs.evaluateUk == rhs.evaluateUk
    }
    
    public static func != (lhs: EvaluateInfo, rhs: EvaluateInfo) -> Bool {
        return !(lhs == rhs)
    }

}

struct EvaluateInfoResponse: Codable {
    let code: Int?
    let msg: String?
}

final class DecisionLogManager {
    
    private static let decisionLogCacheKey = "DecisionLogCacheKey"
    private static let decisionLogReportCount = 100
    private static let decisionLogDeleteCount = 25
    private static let retryCount = 2
    private static let retryDelay = 5
    private static let maxReportCount = 100
    private let service: SnCService
    private var decisionLogList: [EvaluateInfo] = []
    
    init(service: SnCService) {
        self.service = service
        decisionLogList = readFromCache() ?? []
    }
    
    func isEmpty() -> Bool {
        return decisionLogList.isEmpty
    }
    
    func getDecisionLogList() -> [EvaluateInfo] {
        decisionLogList
    }
        
    func addEvaluateInfo(evaluateInfoList: [EvaluateInfo]) {
        let combinedList = evaluateInfoList + decisionLogList
        decisionLogList = Array(combinedList.prefix(DecisionLogManager.maxReportCount))
        let deletedCount = combinedList.count - decisionLogList.count
        combinedList.suffix(deletedCount).forEach { evaluateInfo in
        self.service.logger?.info("DecisionLogManager remove evaluateInfo, " +
        "evaluateUk: \(evaluateInfo.evaluateUk), operateTime: \(evaluateInfo.operateTime ?? ""), policySetKeys: \(evaluateInfo.policySetKeys)")
        }
    }
    
    func removeEvaluateInfo(evaluateInfoList: [EvaluateInfo]) {
        decisionLogList = decisionLogList.filter {
            !evaluateInfoList.contains($0)
        }
    }

    func saveToCache() {
        do {
            try service.storage?.set(decisionLogList, forKey: Self.decisionLogCacheKey)
        } catch {
            service.logger?.error("fail to set decision log cache, error: \(error)")
        }
    }

    func removeCache() {
        do {
            _ = try service.storage?.remove(key: Self.decisionLogCacheKey) as [EvaluateInfo]?
        } catch {
            service.logger?.error("fail to remove decision log cache, error: \(error)")
        }
    }

    func readFromCache() -> [EvaluateInfo]? {
        do {
            guard let evaluateInfoList: [EvaluateInfo] = try service.storage?.get(key: DecisionLogManager.decisionLogCacheKey) else {
                service.logger?.info("decision log cache is empty.")
                return nil
            }
            return evaluateInfoList
        } catch {
            service.logger?.error("fail to get decision log cache, error: \(error)")
            return nil
        }
    }

    func reportRealLog() {
        let reportURL = "/lark/scs/guardian/policy_engine/evaluate_uk/report"
        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set domain before use policy engine.")
            assertionFailure("lost domain，please set domain.")
            return
        }
        
        let reportDecisionData = decisionLogList
        reportDecisionData.chunked(into: DecisionLogManager.decisionLogReportCount).forEach { evaluateInfoChunkedList in
            let requestData = evaluateInfoChunkedList.map {
                [
                    "evaluateUk": $0.evaluateUk,
                    "operateTime": $0.operateTime as Any,
                    "policySetKeys": $0.policySetKeys
                ]
            }
            
            self.service.logger?.info("reportRealLog reportDecisionData: \(requestData)")
            var request = HTTPRequest(domain, path: reportURL, method: .post)
            request.retryCount = DecisionLogManager.retryCount
            request.retryDelay = .seconds(DecisionLogManager.retryDelay)

            request.data = [
                "evaluateInfos": requestData as Any
            ]
            service.client?.request(request, dataType: ResponseModel<EvaluateInfoResponse>.self, completion: { [weak self] result in
                switch result {
                case .success(let response):
                    guard response.code.isZeroOrNil else {
                        self?.service.logger?.error("Failed to report decision log, error: \(response.msg ?? "")")
                        return
                    }
                    self?.service.logger?.info("Successfully reported decision log")
                    PolicyEngineQueue.async {
                        self?.removeEvaluateInfo(evaluateInfoList: evaluateInfoChunkedList)
                        self?.saveToCache()
                    }
                case .failure(let err):
                    self?.service.logger?.error("Failed to report decision log, error: \(err)")
                }
            })
        }
    }

    func reportRealLogInner(evaluateInfoList: [EvaluateInfo]) {
        PolicyEngineQueue.async { [weak self] in
            self?.addEvaluateInfo(evaluateInfoList: evaluateInfoList)
            self?.saveToCache()
            self?.reportRealLog()
        }
    }

    func deleteDecisionLogInner(evaluateInfoList: [EvaluateInfo]) {
        PolicyEngineQueue.async { [weak self] in
            self?.deleteDecisionLog(evaluateInfoList: evaluateInfoList)
        }
    }

    func deleteDecisionLog(evaluateInfoList: [EvaluateInfo]) {
        let deleteURL = "/lark/scs/guardian/policy_engine/evaluate_log/delete"
        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("lost domain, please set domain before use policy engine.")
            assertionFailure("lost domain，please set domain.")
            return
        }
        
        var request = HTTPRequest(domain, path: deleteURL, method: .post)
        request.retryCount = DecisionLogManager.retryCount
        request.retryDelay = .seconds(DecisionLogManager.retryDelay)
        
        evaluateInfoList.chunked(into: DecisionLogManager.decisionLogDeleteCount).forEach { evaluateInfoChunkedList in
            let requestData = evaluateInfoChunkedList.map {
                [
                    "evaluateUk": $0.evaluateUk,
                    "policySetKeys": $0.policySetKeys
                ]
            }

            request.data = [
                "evaluateInfos": requestData as Any
            ]
            self.service.logger?.info("deleteDecisionLogInner evaluateInfoChunkedList: \(requestData)")
            service.client?.request(request, completion: { [weak self] result in
                switch result {
                case .success:
                    self?.service.logger?.info("Successfully deleted decision log.")
                case .failure(let err):
                    self?.service.logger?.error("Failed to delete decision log, error: \(err)")
                }
            })
        }
    }
}

extension DecisionLogManager: EventDriver {
    func receivedEvent(event: InnerEvent) {
        switch event {
        case .timerEvent:
            if !isEmpty() {
                reportRealLog()
            }
        default:
            return
        }
    }
}
