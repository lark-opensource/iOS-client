//
//  SSOUrlReqBody.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/5/15.
//

import Foundation

class SSOUrlReqBody: RequestBody {

    let idpName: String?
    let userId: String?
    let targetSessionKey: String?
    let authenticationChannel: LoginCredentialIdpChannel?
    let sourceType: Int
    let queryScope: String
    let sceneInfo: [String: String]?
    /// 服务端 getauthurl 返回的原始键值内容
    let rawStepInfo: [String: Any]?
    let context: UniContextProtocol
    
    var usePackageDomain = false
    //服务端控制走哪个流程；ug，lark global等
    let action: RegisterActionType

    init(
        idpName: String? = nil,
        userId: String? = nil,
        targetSessionKey: String? = nil,
        authChannel: LoginCredentialIdpChannel? = nil,
        sourceType: Int = 1,
        queryScope: String = CommonConst.queryScopeAll,
        sceneInfo: [String: String]? = nil,
        rawStepInfo: [String: Any]? = nil,
        action: RegisterActionType = .passport,
        context: UniContextProtocol
    ) {
        self.idpName = idpName
        self.userId = userId
        self.targetSessionKey = targetSessionKey
        self.sourceType = sourceType
        self.queryScope = queryScope
        self.authenticationChannel = authChannel
        self.sceneInfo = sceneInfo
        self.rawStepInfo = rawStepInfo
        self.action = action
        self.context = context
    }

    func getParams() -> [String: Any] {
        if let info = rawStepInfo, !info.isEmpty {
            return info
        }
        var params: [String: Any] = [
            CommonConst.appId: PassportConf.shared.appID,
            CommonConst.sourceType: sourceType,
            CommonConst.queryScope: queryScope,
            CommonConst.action: action.rawValue
        ]
        if let idpName = idpName {
            params[CommonConst.idpDomain] = idpName
        }
        if let userId = userId {
            params[CommonConst.userId] = userId
        }
        if let targetSessionKey = targetSessionKey {
            params[CommonConst.targetSessionKey] = targetSessionKey
        }
        if let authenticationChannel = authenticationChannel {
            params[CommonConst.authenticationChannel] = authenticationChannel.rawValue
        }
        if usePackageDomain {
            params[CommonConst.usePackageDomain] = true
        }
        return params
    }

}
