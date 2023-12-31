//
//  KaAPI.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/11.
//

import Foundation
import LKCommonsLogging
import LarkReleaseConfig

@available(*, deprecated, message: "Only KAR used before and now aligns with SaaS.")
class KaAPI: APIV3 {

    @available(*, deprecated, message: "Only KAR used before and now aligns with SaaS.")
    func settings(onSuccess: @escaping (KaSettings) -> Void, onFailure: @escaping OnFailureV3) {
        let req = PassportRequest<KaResponse>(pathPrefix: CommonConst.kaRIdpApiPath, pathSuffix: "settings")
        req.method = .get
        let params = [
            Const.channel: ReleaseConfig.releaseChannel
        ]
        req.required(.fetchDeviceId)
        req.body = params
        client.send(req, success: { (resp, _) in
            do {
                let data = try resp.data.asData()
                let kaSettings = try KaSettings.from(data)
                onSuccess(kaSettings)
            } catch {
                KaAPI.logger.error("parse kaSetting fail error: \(error)")
                onFailure(.badServerData)
            }
        }, failure: onFailure)
    }

    @available(*, deprecated, message: "Only KAR used before and now aligns with SaaS.")
    func authUrl(aliasCode: String, onSuccess: @escaping (KaAuthURL) -> Void, onFailure: @escaping OnFailureV3) {
        
        let req = PassportRequest<KaResponse>(pathPrefix: CommonConst.kaRIdpApiPath, pathSuffix: "v3/m/auth_url")
        let params: [String: Any] = [
            Const.aliasCode: aliasCode,
            CommonConst.appId: PassportConf.shared.appID
        ]
        req.method = .get
        req.body = params
        req.required(.captcha)
        client.send(req, success: { (resp, _) in
            do {
                let data = try resp.data.asData()
                let kaAuthURL = try KaAuthURL.from(data)
                onSuccess(kaAuthURL)
            } catch {
                KaAPI.logger.error("parse kaAuthURL fail error: \(error)")
                onFailure(.badServerData)
            }
        }, failure: onFailure)
    }
}

extension KaAPI {
    struct Const {
        static let terminalType: String = "terminal_type"
        static let channel: String = "channel"
        static let aliasCode: String = "alias_code"
    }
}
