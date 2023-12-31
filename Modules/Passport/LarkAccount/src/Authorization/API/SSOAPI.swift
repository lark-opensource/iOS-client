//
//  SSOAPI.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2020/11/2.
//

import Foundation
import RxSwift
import LarkFoundation
import LarkAccountInterface
import LarkContainer

typealias V3UserConfirm = ThirdPartyAuthInfo
extension V3UserConfirm: ServerInfo {}

struct V3WebUrl: ServerInfo {
    var nextInString: String?
    var flowType: String?
    var usePackageDomain: Bool?

    let uri: String
    let mode: String

    enum CodingKeys: String, CodingKey {
        case uri
        case mode
    }
}

class SSORequest<Response: ResponseV3>: PassportRequest<Response> {
    convenience init(pathSuffix: String) {
        self.init(pathPrefix: CommonConst.authApiPath, pathSuffix: pathSuffix)
        self.middlewareTypes = [
            .requestCommonHeader,
            .toastMessage,
            .saveToken,
            .checkSession
        ]
        self.requiredHeader = [.suiteSessionKey, .sessionKeys, .flowKey, .passportToken]

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
    }
}

class SSOAPI: APIV3 {

    func oauth(body: OAuthRequestBody) -> Observable<V3.Step> {
        let request = SSORequest<V3.Step>(pathSuffix: "oauth2/sdk")
        request.body = body.getParams()
        request.method = .get
        request.required(.saveToken)
        request.domain = .passportAccounts()
        return client.send(request)
    }

    func confirm(scope: String, userID: String) -> Observable<V3.Step> {
        let request = SSORequest<V3.Step>(pathSuffix: "confirm")
        request.method = .post
        request.domain = .passportAccounts()
        request.body = ["scope": scope,
                        "user_id": userID]
        return client.send(request)
    }
}

// MARK: - Session OAuth

extension SSOAPI {
    func getAuthorizationCode(reqBody: AuthCodeReq) -> Observable<AuthCodeResp> {
        let req = SSORequest<V3.Step>(pathSuffix: "oauth2/sdk/")
        req.method = .get
        req.domain = .passportAccounts()
        let reqState = reqBody.state ?? UUID().uuidString
        let redirectUri = reqBody.redirectUri ?? SSOURL.appIdRedirectUrl(reqBody.appId)?.absoluteString
        let scope = reqBody.scope ?? ""
        let packageId = reqBody.packageId ?? Utils.appName

        req.body = [
            "app_id": reqBody.appId,
            "redirect_uri": redirectUri ?? "",
            "scope": scope,
            "package_id": packageId,
            "state": reqState,
            "source": "sso_ios",
            "response_type": "code"
        ]

        return client.send(req).map { (resp) -> AuthCodeResp in
            guard resp.stepData.nextStep == PassportStep.webUrl.rawValue,
                  let webUrl = PassportStep.webUrl.pageInfo(with: resp.stepData.stepInfo) as? V3WebUrl,
                  let url = URL(string: webUrl.uri) else {
                Self.logger.error("no web url data info")
                throw V3LoginError.badServerData
            }

            guard let resp = SuiteLoginUtil.jsonToObj(type: AuthCodeResp.self, json: url.queryParameters) else {
                Self.logger.error("web url param error")
                throw V3LoginError.badServerData
            }

            return resp
        }
    }
}

struct OAuthRequestBody: RequestBody {
    let appId: String
    let state: String
    // 其他全部参数，只取其中Native需要的，多余参数不能用，影响服务判断逻辑（例如 sso_sdk 这个参数是标识SDK请求用的）
    // 详细参数 https://bytedance.feishu.cn/docs/doccnOp4uv8AvhhFrCH6yKIVdgh#
    let otherParams: [String: String]

    func getParams() -> [String: Any] {
        var params = [
            "app_id": appId,
            "state": state,
            "source": "sso_ios" // rewrite web
        ]

        PassthroughKey.allCases.forEach { (key) in
            if let value = otherParams[key.rawValue] {
                params[key.rawValue] = value
            }
        }
        return params
    }

    // Native 不关心内容 但需要带上的参数
    enum PassthroughKey: String, CaseIterable {
        case codeChallenge = "code_challenge"
        case codeChallengeMethod = "code_challenge_method"
        case scope = "scope"
        case packageId = "package_id"
        case sdkVersion = "sdk_version"
        case redirectUri = "redirect_uri"
        case responseType = "response_type"
    }
}
