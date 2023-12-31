//
//  AuthModel.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/3/2.
//

import Foundation
import LarkAccountInterface
import LKCommonsLogging

enum AuthTrack {
    static let pageTypeKey = "page_type"
    static let suiteValue = "suite"
    static let authValue = "auth"
    static let sdkAuthValue = "sso_sdk_auth"
}

enum SSOJump {
    case none(needDismiss: Bool)
    case bundleId(_ bundleId: String)
    case scheme(_ url: String)
}

struct SSOURL {

    static let logger = Logger.plog(SSOURL.self, category: "LarkAccount.Authorization")

    enum Const {
        static let host: String = "oauth"
        static let failurePath: String = "/failure"
        static let cancelPath: String = "/cancel"

//        static let sdkOAuth: String = "/suite/passport/sdk/oauth"
        static let sdkOAuth: String = "/accounts/auth_login/oauth2/sdk"
    }

    enum ParamKey {
        static let url: String = "url"
        // app_id 或 client_id 服务都支持（默认使用appId），但小程序拦截了app_id的请求影响老版本web降级，这里使用client_id
        static let clientId: String = "client_id"
        static let state: String = "state"
        static let code: String = "code"
        static let errCode: String = "err_code"
        static let redirectUri: String = "redirect_uri"
    }

    static func appIdRedirectUrl(_ appId: String) -> URL? {
        return URL(string: "\(appId)://\(Const.host)")
    }

    static func failureUrl(with redirectUrl: URL, errorCode: Int, state: String) -> URL? {
        guard let url = URL(string: Const.failurePath, relativeTo: redirectUrl) else {
            Self.logger.errorWithAssertion(
                "create failure url failed",
                additionalData: ["redirectUrl": redirectUrl.absoluteString]
            )
            return nil
        }

        return url.resolvingBaseAppendParams( [
            ParamKey.code: "0",
            ParamKey.errCode: "\(errorCode)",
            ParamKey.state: state
        ])
    }

    static func cancelUrl(with redirectUrl: URL, state: String) -> URL? {
        guard let url = URL(string: Const.cancelPath, relativeTo: redirectUrl) else {
            Self.logger.errorWithAssertion(
                "create cancel url failed",
                additionalData: ["redirectUrl": redirectUrl.absoluteString]
            )
            return nil
        }

        return url.resolvingBaseAppendParams([
            ParamKey.code: "0",
            ParamKey.state: state
        ])
    }
}

extension URL {
    fileprivate func resolvingBaseAppendParams(_ params: [String: String], forceNew: Bool = true) -> URL? {
        // resolvingAgainstBaseURL == true 因为 url 是可以是根据 relativeUrl生成的
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)

        var finalParams: [String: String] = [:]
        components?.queryItems?.forEach({ (item) in
            finalParams[item.name] = item.value ?? ""
        })

        finalParams.merge(params) { (old, new) -> String in
            forceNew ? new : old
        }

        var items: [URLQueryItem] = []
        finalParams.forEach { (info) in
            items.append(URLQueryItem(name: info.key, value: info.value))
        }
        components?.queryItems = items
        return components?.url
    }
}
