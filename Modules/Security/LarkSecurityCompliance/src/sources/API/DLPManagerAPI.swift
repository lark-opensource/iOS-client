//
//  DLPManagerAPI.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface
import RxSwift
import LarkPolicyEngine
import LarkSetting
import SwiftyJSON
import RxCocoa

struct DLPManagerApi {
    var client: HTTPClient
    let userResolver: UserResolver
    
    private var domain: String? {
        DomainSettingManager.shared.currentSetting[.securityData]?.first
    }
    
    init(resolver: UserResolver) throws {
        userResolver = resolver
        client = try resolver.resolve(type: HTTPClient.self)
    }
    
    func getDlpStatus(policyModels: [PolicyModel]) -> Observable<Bool> {
        guard let domain else {
            return Observable.error(LSCError.domainInvalid)
        }
        guard let first = policyModels.first, let token = first.getToken() else {
            return Observable.error(DLPError.paramsDeficiency)
        }
        let query = ["token": token, "entityType": first.entity.entityType.rawValue, "policyType": "DLP"]
        let requst = HTTPRequest(path: "/intercept/ccm/policystatus/", query: query, domain: domain)
        return client.request(requst)
            .map {
                let json = try JSON(data: $0)
                return json["data"]["policy"]["res"].bool ?? true
            }
    }
    
    func getDlpResult(_ policyModels: [PolicyModel], downgrade: ValidateResponse) -> Observable<[String: ValidateResponse]> {
        // 1.初始化用降级结果填充
        var results: [String: ValidateResponse] = policyModels.reduce([String: ValidateResponse]()) { partialResult, element in
            var tempMap = partialResult
            tempMap.updateValue(downgrade, forKey: element.taskID)
            return tempMap
        }
        
        // 2.向服务端获取真实结果
        return getDlpResponse(policyModels: policyModels)
            .observeOn(MainScheduler.instance)
            .map({ response in
                policyModels.forEach { policyModel in
                    // 3.对服务端返回的结果进行转换，由DlpResponse转化为ValidateResponse
                    guard let result = matchResult(policyModel: policyModel, dlpResponse: response.data) else {
                        SCLogger.info("get dlp result failed for operate: \(policyModel.entity.entityOperate)")
                        return
                    }
                    // 4.用服务端返回的真实结果覆盖初始化的结果
                    results[policyModel.taskID] = transformResult(result: result)
                }
                return results
            })
            .catchError({ error in
                SCLogger.error("get dlp result error", additionalData: ["error": "\(error)"])
                return .just(results)
            })
    }
    
    private func getDlpResponse(policyModels: [PolicyModel]) -> Observable<BaseResponse<DlpResponse>> {
        guard let domain else {
            return Observable.error(LSCError.domainInvalid)
        }
        let operationLists = getOperateList(policyModels: policyModels)
        // 这里同时校验的只能是同一篇文档，所以这里只取了第一个，调用处有保证token一致
        guard let first = policyModels.first,
                let token = first.getToken(), !operationLists.isEmpty else {
            return Observable.error(DLPError.paramsDeficiency)
        }
        let params: [String: Any] = ["token": token, "entityType": first.entity.entityType.rawValue, "entityOperateList": operationLists, "isPreEvaluate": true]
        let requst = HTTPRequest(path: "/intercept/ccm/result", method: .post, params: params, domain: domain)
        return client.request(requst).retry(2)
    }
    
    private func matchResult(policyModel: PolicyModel, dlpResponse: DlpResponse) -> DlpResult? {
        let result = dlpResponse.resultMap?.first(where: { (operate, _) in
            guard let operate = EntityOperate(rawValue: operate) else { return false }
            return operate.rawValue == getOperateList(policyModels: [policyModel]).first
        })?.value
        return result
    }
    
    private func transformResult(result: DlpResult) -> ValidateResponse {
        let uuid = result.enforcementID ?? UUID().uuidString
        let effect = result.isAllow ? Effect.permit : Effect.deny
        var actions: [Action] = []
        if var name = result.bizAction {
            // 异化逻辑：TT特化之前业务方实现的时候是按照文件策略管理实现的，所以此处返回了FILE_BLOCK_COMMON，需要更新为TT_BLOCK，但由于本期服务端不介入，所以由端上写死
            if name == "FILE_BLOCK_COMMON" {
                name = "TT_BLOCK"
            }
            actions = [Action(name: name)]
        }
        let policySetKeys = result.appliedPolicySetResultList?.compactMap({ policySetResult -> String? in
            guard policySetResult.isEvaluated else {
                return nil
            }
            return policySetResult.policySetKey
        })
        let type = result.isFallback.isTrue ? ResponseType.downgrade : ResponseType.remote
        return ValidateResponse(effect: effect, actions: actions, uuid: uuid, type: type, policySetKeys: policySetKeys)
    }
    
    private func getOperateList(policyModels: [PolicyModel]) -> [String] {
        let operateList: [String] = policyModels.compactMap({ policyModel in
            guard policyModel.entity.entityOperate.isDlpPoint else {
                return nil
            }
            let fileExportOperates = [EntityOperate.ccmFileDownload, EntityOperate.ccmExport]
            if fileExportOperates.contains(policyModel.entity.entityOperate) {
                return EntityOperate.ccmExport.rawValue
            }
            return policyModel.entity.entityOperate.rawValue
        })
        return Array(Set(operateList))
    }
}

struct DlpResponse: Codable {
    let resultMap: [String: DlpResult]?
    let timeout: TimeInterval?
}

struct AppliedPolicySetResult: Codable {
    let policySetKey: String
    let isEvaluated: Bool
}

struct DlpResult: Codable {
    let isAllow: Bool
    let bizAction: String?
    let isFallback: Bool?
    let enforcementID: String?
    let appliedPolicySetResultList: [AppliedPolicySetResult]?
}

enum DLPError: Error {
    case paramsDeficiency
}

extension PolicyModel {
    func getToken() -> String? {
        if let entity = self.entity as? CCMEntity, let token = entity.token {
            return token
        } else if let entity = self.entity as? CalendarEntity, let token = entity.token {
            return token
        }
        return nil
    }
}

extension EntityOperate {
    var isDlpPoint: Bool {
        let dlpOperations = [
            EntityOperate.ccmCopy,
            EntityOperate.ccmFileDownload,
            EntityOperate.ccmExport,
            EntityOperate.ccmAttachmentDownload,
            EntityOperate.ccmCreateCopy,
            EntityOperate.openExternalAccess
        ]
        if dlpOperations.contains(self) {
            return true
        }
        return false
    }
}
