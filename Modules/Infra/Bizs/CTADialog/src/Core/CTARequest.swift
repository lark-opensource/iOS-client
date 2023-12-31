//
//  CTARequest.swift
//  CTADialog
//
//  Created by aslan on 2023/10/11.
//

import Foundation
import RxSwift
import RustPB
import LarkRustClient
import LarkContainer
import LarkAccountInterface
import LarkEnv
import LKCommonsLogging
import LarkLocalizations
import LarkStorage

typealias SendHttpRequest = RustPB.Basic_V1_SendHttpRequest
typealias SendHttpResponse = RustPB.Basic_V1_SendHttpResponse

enum CTARequestError: Error {
    case objectBeReleased
    case getClientFail
    case getDomainFail
    case JSONFormatFail
    case responseFormatFail
    case serviceFail
}

class CTARequest: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    let logger = Logger.log(CTARequest.self, category: "CTADialog.CTARequest")

    @ScopedProvider private var client: RustService?
    @ScopedProvider private var passport: PassportUserService?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func sendAsync(featureKey: String,
                   scene: String,
                   checkpointTenantId: String,
                   checkpointUserId: String? = nil) -> Observable<(CTAModel?, Error?)> {
        guard let client = client else {
            self.logger.error("RustService client is nil")
            return Observable.error(CTARequestError.getClientFail)
        }

        guard let domain = CTADomain.getDomain(userResolver: self.userResolver),
              !domain.isEmpty else {
            self.logger.error("get domain fail!")
            return Observable.error(CTARequestError.getDomainFail)
        }

        var req = SendHttpRequest()
        req.url = "https://\(domain)\(CTADialogDefine.Request.path)"
        req.method = .post

        /// header
        var header: [String: String] = [:]
        let sessionStr = "session=" + (passport?.user.sessionKey ?? "")
        header[CTADialogDefine.Request.cookieKey] = sessionStr
        header[CTADialogDefine.Request.locale] = LanguageManager.currentLanguage.localeIdentifier
        header[CTADialogDefine.Request.deviceType] = "IOS"

        if EnvManager.env.type == .staging {
            if let boeFeatureEnv = KVPublic.Common.ttenv.value(), boeFeatureEnv.isEmpty == false {
                header["x-tt-env"] = boeFeatureEnv
            }
        }
        req.headers = header

        /// body
        var json: [String: Any] = [:]
        json["feature_key"] = featureKey
        if !scene.isEmpty {
            json["scene"] = scene
        }
        json["checkpoint_tenant_id"] = checkpointTenantId
        json["checkpoint_user_id"] = checkpointUserId ?? "0"
        json["template_version"] = "1.0"
        guard let body = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            self.logger.error("json transform fail")
            return Observable.error(CTARequestError.JSONFormatFail)
        }
        req.body = body

        return client.sendAsyncRequest(req) { [weak self] (resp: SendHttpResponse) -> (CTAModel?, Error?) in
            guard let `self` = self else { return (nil, CTARequestError.objectBeReleased) }
            guard resp.httpStatusCode == CTADialogDefine.Request.responseSuccessCode else {
                self.logger.error("server error! \(resp.httpStatusCode)")
                return (nil, CTARequestError.serviceFail)
            }
            guard let response = try? JSONDecoder().decode(CTAResponse.self, from: resp.body) else {
                self.logger.error("resp decode error!")
                return (nil, CTARequestError.responseFormatFail)
            }
            guard response.code == 0 else {
                self.logger.error("resp server error")
                return (nil, CTARequestError.serviceFail)
            }
            return (response.data, nil)
        }
    }
}
