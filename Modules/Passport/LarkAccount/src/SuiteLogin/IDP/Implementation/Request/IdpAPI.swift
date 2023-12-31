//
//  IdpAPI.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/1/13.
//

import Foundation
import LKCommonsLogging
import LarkReleaseConfig
import RxSwift

class IdpRequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {
    convenience init(pathSuffix: String) {
        self.init(pathPrefix: CommonConst.authenticationIdpApiPath, pathSuffix: pathSuffix)
        self.middlewareTypes = [
            .captcha,
            .requestCommonHeader,
            .saveToken,
            .saveEnv,
            .crossUnit,
            .checkSession
        ]
        self.requiredHeader = [.suiteSessionKey, .sessionKeys, .flowKey, .passportToken, .proxyUnit]

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
    }

    convenience init(appId: APPID) {
        self.init(pathSuffix: appId.apiIdentify())
        self.appId = appId
    }
}

class IdpAPI: APIV3 {

    func fetchDefaultIDP(onSuccess: @escaping (IDPDefaultSettingModel) -> Void, onFailure: @escaping OnFailureV3) {
        let req = PassportRequest<IDPResponse>(
            pathPrefix: CommonConst.authenticationIdpApiPath,
            pathSuffix: "settings"
        )
        req.method = .get
        req.domain = .passportAccounts()
        req.body = [
            CommonConst.channel: ReleaseConfig.releaseChannel
        ]
        client.send(req, success: { (resp, _) in
            do {
                let data = try resp.data.asData()
                let IDPSettings = try IDPDefaultSettingModel.from(data)
                onSuccess(IDPSettings)
            } catch {
                IdpAPI.logger.error("parse IDPDefaultSetting fail error: \(error)")
                onFailure(.badServerData)
            }
        }, failure: onFailure)
    }

    func fetchConfigForIDP(
        _ body: SSOUrlReqBody
    ) -> Observable<V3.Step> {
        let request = IdpRequest<V3.Step>(appId: .v3IdpAuthUrl)
        // 使用包域名
        body.usePackageDomain = true
        request.body = body
        // need session key when execute after login
        request.required(.fetchDeviceId).required(.suiteSessionKey).required(.injectParams)
        request.method = .get
        request.sceneInfo = body.sceneInfo
        request.domain = .passportAccounts(usingPackageDomain: true)
        return client.send(request)
    }

    func uploadIdpToken(token: String, extraInfo: [String: Any]?, sceneInfo: [String: String], success: @escaping OnStepSuccessV3, failure: @escaping OnFailureV3) {
        var params: [String: Any] = [
            CommonConst.idToken: token,
            CommonConst.appId: PassportConf.shared.appID
        ]
        if let extraInfo = extraInfo {
            params = params.merging(extraInfo) { (current, _) in
                IdpAPI.logger.error("merge uploadIdpToken extraInfo conflict key: \(current) use current value.")
                return current
            }
        }
        let req = IdpRequest<V3.Step>(appId: .v3IdpVerifyToken)
        req.body = params
        req.domain = .passportAccounts(usingPackageDomain: true)
        req.sceneInfo = sceneInfo
        req.required(.suiteSessionKey)
        client.send(req, success: success, failure: failure)
    }

    func fetchNext(state: String) -> Observable<V3.Step> {
        let params: [String: Any] = [
            "state": state
        ]
        let req = IdpRequest<V3.Step>(appId: .v3ClientDispatch)
        req.method = .post
        req.body = params
        // 使用包域名
        req.domain = .passportAccounts(usingPackageDomain: true)
        return client.send(req)
    }
}
