//
//  MFAAPI.swift
//  LarkAccount
//
//  Created by YuankaiZhu on 2023/8/23.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkContainer

class MFARequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {

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

class MFAAPI {
    static let logger = Logger.plog(MFAAPI.self, category: "LarkAccount.MFAAPI")
    let client: HTTPClient
    private let userResolver: UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.client = try userResolver.resolve(assert: HTTPClient.self)
    }

    func checkNewMFAStatus(
        token: String,
        scope: String
    ) -> Observable<V3.CommonResponse<MFANewCheckResponse>> {
        let params: [String: Any] = [
            "scope": scope,
            CommonConst.usePackageDomain: false
        ]
        let req: MFARequest<V3.CommonResponse<MFANewCheckResponse>> = createRequest(appId: .validateMFAToken, body: params)
        req.add(headers: [CommonConst.xMfaToken:token])
        return client.send(req)
    }

    func startNewMFA(
        scope: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let params: [String: Any] = [
            "scope": scope,
            CommonConst.usePackageDomain: false
        ]
        let req: MFARequest<V3.Step> = createRequest(appId: .applyMFAToken, body: params, uniContext: context)
        return client.send(req)
    }

    func startThirdPartyNewMFA(
        key: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let params: [String: Any] = [
            "mfa_key": key,
            CommonConst.usePackageDomain: false
        ]
        let req: MFARequest<V3.Step> = createRequest(appId: .applyMFAToken, body: params, uniContext: context)
        return client.send(req)
    }

    private func createRequest<T>(appId: APPID, body: [String: Any], uniContext: UniContextProtocol? = nil) -> MFARequest<T> {
        let req = MFARequest<T>(appId: appId, uniContext: uniContext)
        req.body = body
        req.domain = .passportAccounts()
        req.method = .post
        req.required(.fetchDeviceId)
        return req
    }
}
