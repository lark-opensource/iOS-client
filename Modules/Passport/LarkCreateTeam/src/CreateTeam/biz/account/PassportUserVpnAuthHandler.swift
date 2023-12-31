//
//  PassportUserVpnAuthHandler.swift
//  LarkCreateTeam
//
//  Created by bytedance on 2021/9/8.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import LarkAccountInterface
import LarkContainer
import JsSDK
import LKJsApiExternal

private enum PassportUserVpnAuthError: Int {

    case unauthorized = -90_000
    case noUserNameOrPassword = -90_001
    case clientLogicFailed = -90_002

    func description() -> String {
        switch self {
        case .unauthorized:
            return "vpn_bridge unauthorized!"
        case .noUserNameOrPassword:
            return "username and password must not be null!"
        case .clientLogicFailed:
            return "client logic issue, contact the developer!"
        }
    }
}

class PassportUserVpnAuthHandler: JsAPIHandler {

    @Provider var idpController: PassportWebViewDependency

    static let logger = Logger.log(PassportUserVpnAuthHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        idpController.monitorSensitiveJsApi(apiName: "biz.account.vpn_auth_user", sourceUrl: api.browserURL, from: "LarkCreateTeam")

        guard let authConfig = idpController.getIDPAuthConfig(),
              let idpUrlStr = authConfig["url"] as? String,
              let idpURL = URL(string: idpUrlStr) else {

            callback.callbackSuccess(param: ["succ": false,
                                             "code": PassportUserVpnAuthError.unauthorized.rawValue,
                                             "msg": PassportUserVpnAuthError.unauthorized.description()])
            PassportUserVpnAuthHandler.logger.error("auth data nil")
            return
        }

        guard let oriTopDomain = getTopLevelDomain(url: idpURL),
              /*
              let currentTopDomain = getTopLevelDomain(url: api.url),
               */
        // 只是因为URL改成了optional，没有修改任何逻辑，详情请咨询caiweiwei
        let url = api.browserURL, let currentTopDomain = getTopLevelDomain(url: url),
              oriTopDomain == currentTopDomain else {

            callback.callbackSuccess(param: ["succ": false,
                                             "code": PassportUserVpnAuthError.unauthorized.rawValue,
                                             "msg": PassportUserVpnAuthError.unauthorized.description()])
            PassportUserVpnAuthHandler.logger.info("vpn_bridge unauthorized!")
            return
        }
        guard let userName = args["userName"] as? String,
              let password = args["password"] as? String,
              !userName.isEmpty,
              !password.isEmpty
              else {
            callback.callbackSuccess(param: ["succ": false,
                                             "code": PassportUserVpnAuthError.noUserNameOrPassword.rawValue,
                                             "msg": PassportUserVpnAuthError.noUserNameOrPassword.description()])
            PassportUserVpnAuthHandler.logger.error("username and password must not be null!")
            return
        }
        PassportUserVpnAuthHandler.logger.info("begin login")
        guard let delegate = KANativeAppAPIExternal.shared.delegate else {
            PassportUserVpnAuthHandler.logger.error("KANativeAppAPIExternal delegate must not be null!")
            callback.callbackSuccess(param: ["succ": false,
                                             "code": PassportUserVpnAuthError.clientLogicFailed.rawValue,
                                             "msg": PassportUserVpnAuthError.clientLogicFailed.description()])
            return
        }
        guard delegate.getPluginApiNames().contains("vpn_login") else {
            PassportUserVpnAuthHandler.logger.error("delegate dosen't apply vpn_login!")
            callback.callbackSuccess(param: ["succ": false,
                                             "code": PassportUserVpnAuthError.clientLogicFailed.rawValue,
                                             "msg": PassportUserVpnAuthError.clientLogicFailed.description()])
            return
        }
        let event = KANativeAppAPIEvent()
        event.name = "vpn_login"
        event.params = [
            "username": userName,
            "password": password
        ]
        delegate.handle(event: event) { success, result in
            guard var params = result else {
                PassportUserVpnAuthHandler.logger.error("vpn login is \(success), result is nil")
                callback.callbackSuccess(param: ["succ": false,
                                                 "code": PassportUserVpnAuthError.clientLogicFailed.rawValue,
                                                 "msg": PassportUserVpnAuthError.clientLogicFailed.description()])
                return
            }
            PassportUserVpnAuthHandler.logger.info("vpn login is \(success), result is \(result?.description ?? "")")
            params["succ"] = success
            callback.callbackSuccess(param: params)
        }
    }
    func getTopLevelDomain(url: URL) -> String? {
        guard let hostName = url.host else { return nil }
        let components = hostName.components(separatedBy: ".")
        if components.count > 2 {
            return components.suffix(2).joined(separator: ".")
        } else {
            return hostName
        }
    }
}
