//
//  PermissionManager+Form.swift
//  SKCommon
//
//  Created by guoqp on 2021/7/19.
//

import Foundation
import SwiftyJSON
import HandyJSON
import ThreadSafeDataStructure
import SKFoundation
import SKInfra
import SpaceInterface

///表单相关协议
extension PermissionManager {

    ///获取bitable高级权限规则
    public func fetchBitablePermissionRules(token: String, bridgeData: BitableBridgeData, complete: ((BitablePermissionRules?, Error?) -> Void)? = nil) -> DocsRequest<JSON> {

        let path = OpenAPI.APIPath.getBitablePermissonRule(token)
        let request = DocsRequest<JSON>(path: path, params: nil)
            .set(method: .GET)
            .set(timeout: 20)
            .set(needVerifyData: false)
        request.start(callbackQueue: callbackQueue, result: { (json, error) in
            guard error == nil else {
                DispatchQueue.main.async { complete?(nil, error) }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }
            guard DocsNetworkError.isSuccess(code) else {
                DispatchQueue.main.async { complete?(nil, DocsNetworkError.invalidData) }
                return
            }
            let data: JSON = json["data"]
            let rules = BitablePermissionRuleParser.parsePermissionRules(data, bridgeData: bridgeData)
            DispatchQueue.main.async { complete?(rules, nil) }
        })
        return request
    }


    /// 更新bitable高级权限
    public func updateBitablePermissionRules(
        token: String,
        roleID: String,
        collaborators: [Collaborator],
        notify: Bool,
        complete: @escaping (JSON?, Error?) -> Void)
    -> DocsRequest<JSON> {
        var dictionary = [[String: Any]]()
        dictionary = collaborators.map {
            return ["memberId": $0.userID,
                    "memberType": $0.rawValue]
        }
        let parameters: [String: Any] = [
            "baseRole": ["members": dictionary,
                         "roleId": roleID],
            "needAddCollaborators": true
        ]

        let path = OpenAPI.APIPath.updateBitablePermissonRule(token)
        return DocsRequest<JSON>(path: path, params: parameters)
            .set(needVerifyData: false)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(timeout: 20)
            .start(result: { (json, error) in
                guard error == nil else {
                    DocsLogger.error("update bitable permission rules failed!", extraInfo: nil, error: error, component: nil)
                    DispatchQueue.main.async {
                        complete(nil, CollaboratorsError.networkError)
                    }
                    return
                }
                guard let json = json, let code = json["code"].int else {
                    DispatchQueue.main.async {
                        complete(nil, CollaboratorsError.parseError)
                    }
                    return
                }
                if let err = DocsNetworkError(code) {
                    DispatchQueue.main.async {
                        complete(json, err)
                    }
                    return
                }
                DispatchQueue.main.async {
                    complete(json, nil)
                }
            })
    }


}

extension PermissionManager {
    /// 获取 bitable 高级权限规则
    func fetchBitableRulesInfo(
        token: String,
        bridgeData: BitableBridgeData,
        completion: @escaping (Result<BitablePermissionRules, Error>) -> Void
    ) -> DocsRequest<JSON> {
        let path = OpenAPI.APIPath.getBitablePermissonRule(token)
        let request = DocsRequest<JSON>(path: path, params: nil)
            .set(method: .GET)
            .set(timeout: 20)
            .set(needVerifyData: true)
        request.start(callbackQueue: callbackQueue, result: { (json, error) in
            if let err = error {
                DocsLogger.error("[BAP] fetchBitableRulesInfo server failed!", error: err, component: LogComponents.permission)
                DispatchQueue.main.async {
                    completion(.failure(err))
                }
                return
            }
            guard let json = json else {
                DocsLogger.error("[BAP] fetchBitableRulesInfo data null!", component: LogComponents.permission)
                DispatchQueue.main.async {
                    completion(.failure(DocsNetworkError.invalidData))
                }
                return
            }
            DocsLogger.info("[BAP] fetchBitableRulesInfo success!", component: LogComponents.permission)
            let data: JSON = json["data"]
            let rules = BitablePermissionRuleParser.parsePermissionRules(data, bridgeData: bridgeData)
            DispatchQueue.main.async {
                completion(.success(rules))
            }
        })
        return request
    }
    
    func updateBitableFallbackRoleConfig(
        token: String,
        config: BitablePermissionRules.AccessConfig.Config,
        completion: @escaping (Error?) -> Void
    ) {
        let path = OpenAPI.APIPath.updateBitablePermRoleFallbackConfig(token)
        var dataDict: [String: Any] = [:]
        dataDict["accessStrategy"] = config.accessStrategy.rawValue
        dataDict["roleId"] = config.roleId
        let param = ["defaultAccessConfig": dataDict]
        let request = DocsRequest<JSON>(path: path, params: param)
            .set(method: .POST)
            .set(timeout: 10)
            .set(needVerifyData: true)
            .set(encodeType: .jsonEncodeDefault)
        request.start(callbackQueue: callbackQueue, result: { [weak request] (_, error) in
            if let err = error {
                DocsLogger.error("[BAP] updateBitableFallbackRoleConfig failed", error: err, component: LogComponents.permission)
                DispatchQueue.main.async {
                    completion(err)
                    request?.makeSelfUnReferfenced()
                }
                return
            }
            DocsLogger.info("[BAP] updateBitableFallbackRoleConfig success", component: LogComponents.permission)
            DispatchQueue.main.async {
                completion(nil)
                request?.makeSelfUnReferfenced()
            }
        })
        request.makeSelfReferenced()
    }
    
    /// 获取当前用户 bitable 付费功能的权限情况
    func fetchBitableCostInfo(
        token: String,
        completion: @escaping (Result<BitablePermissionCostInfo, Error>) -> Void
    ) -> DocsRequest<JSON> {
        let path = OpenAPI.APIPath.getBitablePermissonCostInfo(token)
        let request = DocsRequest<JSON>(path: path, params: nil)
            .set(method: .GET)
            .set(timeout: 20)
            .set(needVerifyData: false)
        request.start(callbackQueue: callbackQueue, result: { (json, error) in
            if let err = error {
                DocsLogger.error("[BAP] fetchBitableCostInfo server failed!", error: error, component: LogComponents.permission)
                DispatchQueue.main.async {
                    completion(.failure(err))
                }
                return
            }
            guard let json = json, let code = json["code"].int, DocsNetworkError.isSuccess(code) else {
                DocsLogger.error("[BAP] fetchBitableCostInfo server failed, code:\(json?["code"].int ?? -1)", component: LogComponents.permission)
                DispatchQueue.main.async {
                    completion(.failure(DocsNetworkError.invalidData))
                }
                return
            }
            do {
                let info = try JSONDecoder().decode(BitablePermissionCostInfo.self, from: json["data"].rawData())
                DocsLogger.info("[BAP] fetchBitableCostInfo success!", component: LogComponents.permission)
                DispatchQueue.main.async {
                    completion(.success(info))
                }
            } catch let error {
                DocsLogger.error("[BAP] fetchBitableCostInfo decode failed!", error: error, component: LogComponents.permission)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        })
        return request
    }
    
    
    /// 获取 bitable 的管理员（FA）信息
    func fetchAllBitableCollaborators(token: String, completion: @escaping (Result<[Collaborator], Error>) -> Void) {
        let src: CollaboratorSource = .defaultType
        fetchCollaborators(
            token: token,
            type: ShareDocsType.bitable.rawValue,
            shouldFetchNextPage: true,
            clearAllBeforeFetch: true,
            collaboratorSource: src
        ) { (_, error) in
            if let error = error {
                DocsLogger.error("[BAP] fetchAllBitableCollaborators failed", error: error, component: LogComponents.permission)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            let collaborators = self.getCollaborators(for: token, collaboratorSource: src) ?? []
            DocsLogger.info("[BAP] fetchAllBitableCollaborators success, \(collaborators.count)", component: LogComponents.permission)
            DispatchQueue.main.async {
                completion(.success(collaborators))
            }
        }
    }
    
    /// 清除 Bitable 高级权限的所有角色
    func clearBitableAdPermMembers(token: String, completion: @escaping (Error?) -> Void) -> DocsRequest<JSON> {
        let path = OpenAPI.APIPath.clearBitableAdPermMembers(token)
        let request = DocsRequest<JSON>(path: path, params: nil)
            .set(method: .POST)
            .set(timeout: 10)
            .set(needVerifyData: true)
        request.start(callbackQueue: callbackQueue, result: { (_, error) in
            if let err = error {
                DocsLogger.error("[BAP] clearBitableAdPermMembers failed", error: err, component: LogComponents.permission)
                DispatchQueue.main.async {
                    completion(err)
                }
                return
            }
            DocsLogger.info("[BAP] clearBitableAdPermMembers success", component: LogComponents.permission)
            DispatchQueue.main.async {
                completion(nil)
            }
        })
        return request
    }
}

enum BitableAdPermApplyError {
    case unknown
    case containSensitiveWords
    case alreadyHavePerm
}

enum BitableAdPermApplyStatus: Int {
    case allow = 0
    case deny = 1
}


extension PermissionManager {
    func applyBitableAdPerm(token: String, message: String, completion: @escaping (BitableAdPermApplyError?) -> Void) -> DocsRequest<JSON> {
        DocsLogger.info("[BAP] applyBitableAdPerm start!")
        let params: [String: Any] = [
            "message": message
        ]
        let path = OpenAPI.APIPath.applyBitableAdPerm(token)
        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .POST)
            .set(timeout: 20)
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        request.start(result: { object, error in
            if let error = error {
                DocsLogger.error("[BAP] apply | applyBitableAdPerm failed", error: error, component: LogComponents.permission)
                completion(.unknown)
                return
            }
            guard object?["code"] == 0 else {
                DocsLogger.error("[BAP] apply | applyBitableAdPerm failed, error code: \(object?["code"])!")
                if object?["code"] == 800_004_106 {
                    completion(.containSensitiveWords)
                } else if object?["code"] == 800_004_106 {
                    completion(.alreadyHavePerm)
                } else {
                    completion(.unknown)
                }
                return
            }
            DocsLogger.info("[BAP] apply | applyBitableAdPerm success!")
            completion(nil)
        })
        return request
    }
    
    func getBitableAdPermApplyStatus(token: String, completion: @escaping (BitableAdPermApplyStatus) -> Void) -> DocsRequest<JSON> {
        DocsLogger.info("[BAP] getBitableAdPermApplyStatus start!")
        let params: [String: Any] = [
            "uid": User.current.basicInfo?.userID ?? ""
        ]
        let path = OpenAPI.APIPath.applyBitableAdPermCode(token)
        let request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
            .set(needVerifyData: false)
        request.start(result: { object, error in
            guard error == nil, let code = object?["code"].int, code == 0, let raw = object?["data"]["applyPermissionCode"].int, let status = BitableAdPermApplyStatus(rawValue: raw) else {
                DocsLogger.error("[BAP] apply | getBitableAdPermApplyStatus failed: \(String(describing: object))", error: error, component: LogComponents.permission)
                // 如果请求或解析失败，默认允许，后端做兜底拦截
                completion(.allow)
                return
            }
            DocsLogger.info("[BAP] apply | getBitableAdPermApplyStatus success: \(raw)!")
            completion(status)
        })
        return request
    }
    
}

extension PermissionManager {
    /// 判断一份 Bitable 的「高级权限设置页」是否对当前用户可见
    /// - Parameters:
    ///   - docsInfo: bitable 的 docsInfo
    ///   - isPro: bitable 是否开启了高级权限功能
    /// - Returns: 可见性
    @available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK")
    public static func getUserAdPermVisibility(for docsInfo: DocsInfo, isPro: Bool, userPermissions: UserPermissionAbility? = nil) -> Bool {
        var permissions = userPermissions
        
        if permissions == nil {
            let mgr = DocsContainer.shared.resolve(PermissionManager.self)!
            permissions = mgr.getUserPermissions(for: docsInfo.objToken)
        }
        
        guard permissions?.canPreview() == true else {
            DocsLogger.error("[BAP] not available due to can not preview")
            return false
        }
        
        if docsInfo.templateType?.isTemplate == true {
            // 模板情况下，始终展示入口
            return true
        } else {
            // 非模板情况下，FA 展示，!FA 不展示
            DocsLogger.error("[BAP] ad perm visibility: \(permissions?.isFA ?? false)")
            return permissions?.isFA == true
        }
    }

    public static func getUseradPermVisibility(permissionService: UserPermissionService, isTemplate: Bool, isPro: Bool) -> Bool {
        guard permissionService.validate(operation: .preview).allow else {
            DocsLogger.error("[BAP] not available due to can not preview")
            return false
        }
        if isTemplate {
            return true
        } else {
            let isFullAccess = permissionService.validate(operation: .isFullAccess).allow
            DocsLogger.error("[BAP] ad perm visibility: \(isFullAccess)")
            return isFullAccess
        }
    }
}
