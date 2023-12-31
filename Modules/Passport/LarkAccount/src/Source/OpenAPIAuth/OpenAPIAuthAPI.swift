//
//  OpenAPIAuthAPI.swift
//  LarkAccount
//
//  Created by au on 2023/6/6.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import RxSwift

final class OpenAPIAuthRequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {

    required init(pathPrefix: String, pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        super.init(pathPrefix: pathPrefix, pathSuffix: pathSuffix, uniContext: uniContext)
        self.middlewareTypes = [.fetchDeviceId, .requestCommonHeader, .saveToken]
        self.requiredHeader = [.authFlowKey]

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
    }

    convenience init(pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        self.init(pathPrefix: CommonConst.authenPathPrefix, pathSuffix: pathSuffix, uniContext: uniContext)
    }

    convenience init(appID: APPID, uniContext: UniContextProtocol? = nil) {
        self.init(pathSuffix: appID.apiIdentify(), uniContext: uniContext)
        self.appId = appID
    }
}

final class OpenAPIAuthAPI: APIV3 {

    func getAuthInfoInner(params: OpenAPIAuthParams) -> Observable<V3.SimpleResponse> {
        let request = OpenAPIAuthRequest<V3.SimpleResponse>(appID: APPID.authenGetAuthInfo)
        request.domain = .open
        request.body = params.getParams()
        request.method = .post
        return client.send(request)
    }

    func confirmInner(appID: String) -> Observable<V3.SimpleResponse> {
        let request = OpenAPIAuthRequest<V3.SimpleResponse>(appID: APPID.authenConfirm)
        let params: [String: Any] = ["app_id": appID]
        request.domain = .open
        request.body = params
        request.method = .post
        return client.send(request)
    }

}

struct OpenAPIAuthConfirmInfo: Codable {

    let code: String
    let state: String?
    let autoConfirm: Bool
    let extra: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case code, state
        case autoConfirm = "auto_confirm"
        case extra
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try? container.decode([String:Any].self, forKey: .extra)
        self.extra = data
        self.code = try container.decode(String.self, forKey: .code)
        self.state = try? container.decode(String.self, forKey: .state)
        self.autoConfirm = try container.decode(Bool.self, forKey: .autoConfirm)
    }

    internal func encode(to encoder: Encoder) throws { }
}

struct OpenAPIAuthGetAuthInfo: Codable {

    let appInfo: AppInfo?
    let suiteInfo: SuiteInfo?
    let currentUser: CurrentUser?
    let code: String?
    let state: String?
    let autoConfirm: Bool
    let extra: [String: Any]?
    let i18nAgreement: I18nAgreement?

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try? container.decode([String:Any].self, forKey: .extra)
        self.extra = data
        self.appInfo = try? container.decode(AppInfo.self, forKey: .appInfo)
        self.suiteInfo = try? container.decode(SuiteInfo.self, forKey: .suiteInfo)
        self.currentUser = try? container.decode(CurrentUser.self, forKey: .currentUser)
        self.code = try? container.decode(String.self, forKey: .code)
        self.state = try? container.decode(String.self, forKey: .state)
        self.autoConfirm = try container.decode(Bool.self, forKey: .autoConfirm)
        self.i18nAgreement = try? container.decode(I18nAgreement.self, forKey: .i18nAgreement)
    }

    internal func encode(to encoder: Encoder) throws { }

    enum CodingKeys: String, CodingKey {
        case appInfo = "app_info"
        case suiteInfo = "suite_info"
        case currentUser = "current_user"
        case code
        case state
        case autoConfirm = "auto_confirm"
        case extra
        case i18nAgreement = "i18n_agreement"
    }

    // MARK: AppInfo
    struct AppInfo: Codable {
        let appIconURL: String?
        let appID: String
        let appName: String

        enum CodingKeys: String, CodingKey {
            case appIconURL = "app_icon_url"
            case appID = "app_id"
            case appName = "app_name"
        }
    }

    // MARK: CurrentUser
    struct CurrentUser: Codable {
        let tenantIconURL: String?
        let tenantID: String
        let tenantName: String
        let userID: String
        let userName: String
        let scopeList: [ScopeList]

        enum CodingKeys: String, CodingKey {
            case tenantIconURL = "tenant_icon_url"
            case tenantID = "tenant_id"
            case tenantName = "tenant_name"
            case userID = "user_id"
            case userName = "user_name"
            case scopeList = "scope_list"
        }
    }

    // MARK: ScopeList
    struct ScopeList: Codable {
        let name: String?
        let desc: String?
        let required: Bool

        enum CodingKeys: String, CodingKey {
            case name, desc, required
        }
    }

    // MARK: SuiteInfo
    struct SuiteInfo: Codable {
        let suiteIconURL: String?
        let suiteName: String

        enum CodingKeys: String, CodingKey {
            case suiteIconURL = "suite_icon_url"
            case suiteName = "suite_name"
        }
    }
}

extension OpenAPIAuthParams: RequestBody {
    func getParams() -> [String: Any] {
        var params: [String: Any] = ["app_id": appID]
        if let state = self.state {
            params["state"] = state
        }
        if let scope = self.scope {
            params["scope"] = scope
        }
        if let redirectUri = self.redirectUri {
            params["redirect_uri"] = redirectUri
        }
        if let openAppType = self.openAppType {
            params["open_app_type"] = openAppType
        }
        return params
    }
}
