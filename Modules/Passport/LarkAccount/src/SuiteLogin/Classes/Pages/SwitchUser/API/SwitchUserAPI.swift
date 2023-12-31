//
//  SwitchUserAPI.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/5/12.
//

import Foundation
import RxSwift
import LarkContainer

class SwitchRequest<ResponseData: ResponseV3>: AfterLoginRequest<ResponseData> {
    convenience init(pathSuffix: String) {
        self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix)
        self.required(.saveToken)
        self.required(.pwdToken)
        self.required(.suiteSessionKey)
        self.required(.sessionKeys)

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
     }


}

class SwitchUserAPI: APIV3, VerifyAPIProtocol {

    

    @Provider private var loginAPI: LoginAPI

    struct Const {
        static let sourceType: String = "source_type"
        static let flowType: String = "flow_type"
        static let contactType: String = "contact_type"
        static let code: String = "code"
        static let switchType: String = "switch_type"
    }

    // 这里所有的参数都是目标切换用户的内容，非当前用户
    // 追加 switchType 参数 https://bytedance.feishu.cn/docx/doxcn8HoM3ipM3jfYJdJ04Wr6Ce?hash=9856644a0723b93a6dc7a59245d6d629
    func switchIdentity(to userID: String, credentialID: String, sessionKey: String?, switchType: CommonConst.SwitchType) -> Observable<V3.Step> {
        var params: [String: Any] = [
            CommonConst.userId: userID,
            CommonConst.credentialId: credentialID,
            Const.switchType: switchType.rawValue
        ]
        if let sessionKey = sessionKey {
            params[CommonConst.sessionKey] = sessionKey
        }

        let suffix = "switch_identity"
        let req = SwitchRequest<V3.Step>(pathSuffix: suffix)
        req.body = params
        req.method = .post
        req.domain = .passportAccounts()
        return client.send(req)
    }

    func applyCode(
        sourceType: Int?,
        contactType: Int?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [:]
        if let contactType = contactType {
            params[Const.contactType] = contactType
        }
        if let sourceType = sourceType {
            params[Const.sourceType] = sourceType
        }
        let suffix = "apply_code/switch"
        let req = SwitchRequest<V3.Step>(pathSuffix: suffix)
        req.body = params
        return client.send(req)
    }

    // TODO: fix apply
    func applyCode(
        serverInfo: ServerInfo,
        flowType: String?,
        contactType: Int?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let suffix = "apply_code/switch"
        let req = SwitchRequest<V3.Step>(pathSuffix: suffix)
        return client.send(req)
    }
    
    func v3Verify(
          sourceType: Int?,
          code: String,
          contactType: Int?,
          sceneInfo: [String: String]?,
          context: UniContextProtocol
    ) -> Observable<V3.Step> {
        return loginAPI.v3Verify(sourceType: sourceType, code: code, contactType: contactType, sceneInfo: sceneInfo, context: context)
    }

    func verify(
        serverInfo: ServerInfo,
        flowType: String?,
        code: String,
        contactType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            Const.code: code
        ]
        if let contactType = contactType {
            params[Const.contactType] = contactType
        }
        if let flowType = flowType {
            params[Const.flowType] = flowType
        }
        let suffix = "verify_code/switch"
        let req = SwitchRequest<V3.Step>(pathSuffix: suffix)
        req.body = params
        return client.send(req)
    }

    func verify(
        serverInfo: ServerInfo,
        flowType: String?,
        password: String,
        rsaInfo: RSAInfo?,
        contactType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let suffix = "verify_pwd/switch"
        let req = SwitchRequest<V3.Step>(pathSuffix: suffix)
        req.setPwdReqBody(PwdRequestBody(
            pwd: password,
            rsaInfo: rsaInfo,
            sourceType: nil,
            logId: suffix,
            contactType: contactType
        ))
        return client.send(req)
    }

    func verifyOtp(
        sourceType: Int?,
        code: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            Const.code: code
        ]
        if let sourceType = sourceType {
            params[Const.sourceType] = sourceType
        }
        let suffix = "verify_otp/switch"
        let req = SwitchRequest<V3.Step>(pathSuffix: suffix)
        req.body = params
        return client.send(req)
    }
    
    func v4VerifyOtp(
        serverInfo: ServerInfo,
        flowType: String?,
        code: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step>{
        return loginAPI.v4VerifyOtp(serverInfo: serverInfo, flowType: flowType, code: code, context: context)
    }

    func recoverType(
        sourceType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        return loginAPI.recoverType(sourceType: sourceType, context: context)
    }
    
    func retrieveGuideWay(serverInfo: ServerInfo, flowType: String?, action: Int, context: UniContextProtocol) -> Observable<V3.Step> {
        return loginAPI.retrieveGuideWay(serverInfo: serverInfo, flowType: flowType, action: action, context: context)
    }
    
    func verifyMo(serverInfo: ServerInfo, flowType: String?, context: UniContextProtocol) -> RxSwift.Observable<V3.Step> {
        return loginAPI.verifyMo(serverInfo: serverInfo, flowType: flowType, context: context)
    }
}
