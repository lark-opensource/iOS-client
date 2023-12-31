//
//  VerifyAPI.swift
//  LarkAccount
//
//  Created by zhaoKejie on 2023/8/9.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkContainer

class VerifyRequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {

    convenience init(pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix, uniContext: uniContext)
    }

    required init(pathPrefix: String, pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        super.init(pathPrefix: pathPrefix, pathSuffix: pathSuffix, uniContext: uniContext)
        self.middlewareTypes = [
            .captcha,
            .requestCommonHeader,
            .saveToken,
            .costTimeRecord,
            .toastMessage,
            .checkSession
        ]
        self.requiredHeader = [.passportToken, .proxyUnit]
        // 端内登录逻辑中，需要在用户列表中过滤已登录的用户，需要告知后端所有 session
        self.required(.sessionKeys)

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
    }

    convenience init(appId: APPID, uniContext: UniContextProtocol? = nil) {
        self.init(pathSuffix: appId.apiIdentify(), uniContext: uniContext)
        self.appId = appId
    }
}

class VerifyAPI {

    static let logger = Logger.plog(VerifyAPI.self, category: "LarkAccount.VerifyAPI")

    @Provider var client: HTTPClient

    func verifyCode(
        serverInfo: ServerInfo,
        code: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {

        var params: [String: String] = [CommonConst.code: code]
        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }

        let req = VerifyRequest<V3.Step>(appId: .v4VerifyCode, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)

        return client.send(req)
    }

    func retrieveGuideWay(
        serverInfo: ServerInfo,
        action: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {

        let req = VerifyRequest<V3.Step>(appId: .v4RetrieveGuideWay, uniContext: context)
        var body: [String: Any] = [
            CommonConst.action: action
        ]
        if let flowType = serverInfo.flowType {
            body[CommonConst.flowType] = flowType
        }
        req.configDomain(serverInfo: serverInfo)
        req.body = body
        req.required(.flowKey)
        req.required(.suiteSessionKey)
        return client.send(req)
    }

    func applyCode(
        serverInfo: ServerInfo,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: String] = [:]
        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }
        let req = VerifyRequest<V3.Step>(appId: .v4ApplyCode, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
    }

    func verifyPwd(
        serverInfo: ServerInfo,
        password: String,
        rsaInfo: RSAInfo?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let appID: APPID = .v4VerifyPwd
        let req = VerifyRequest<V3.Step>(appId: appID, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        let flowType = serverInfo.flowType ?? ""
        req.setPwdReqBody(PwdRequestBody(
            pwd: password,
            rsaInfo: rsaInfo,
            sourceType: nil,
            logId: appID.apiIdentify(),
            flowType: flowType
        ))
        req.requiredHeader.insert(.flowKey)
        return client
            .send(req)
    }

    func verifyOtp(
        serverInfo: ServerInfo,
        code: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: String] = [CommonConst.code: code]
        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }
        let req = VerifyRequest<V3.Step>(appId: .v4VerifyOtp, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.verifyOtp, context: context)
    }

    func verifyMo(serverInfo: ServerInfo,
                  context: UniContextProtocol
    ) -> RxSwift.Observable<V3.Step> {
        let request = VerifyRequest<V3.Step>(appId: .verifyMo, uniContext: context)
        var params: [String: String] = [:]
        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }
        request.body = params
        request.configDomain(serverInfo: serverInfo)
        request.requiredHeader.insert(.flowKey)
        return client.send(request)

    }
}
