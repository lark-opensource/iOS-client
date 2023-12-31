//
//  WebAppApiAuthService.swift
//  LarkOpenPlatform
//
//  Created by lixiaorui on 2020/12/7.
//

import Foundation
import EEMicroAppSDK
import Swinject
import LarkAppConfig
import Alamofire
import LarkRustHTTP
import LKCommonsLogging
import LarkOPInterface
import LarkFeatureGating
import WebBrowser
import TTMicroApp
import OPFoundation

func webAuthStorageEnable() -> Bool {
    let storageFGValue = !LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.larkwebview.userauthstorage.disable")// user:global
    return storageFGValue
}

public final class WebAppAuthModel: NSObject, BDPMetaWithAuthProtocol {

    public private(set) var appId: String = ""

    public private(set) var uniqueID: BDPUniqueID

    public var type: BDPType {
        return .webApp
    }

    //  BDPMetaWithAuthProtocol要求，外边没地方传入，一直是空字符串，这里没有修改任何逻辑
    public private(set) var name: String = ""
    public private(set) var icon: String = ""

    public private(set) var version: String = ""

    // 网页应用都应该是线上
    public private(set) var versionType: OPAppVersionType = .current

    public private(set) var version_code: Int64 = 0

    // 网页应用目前没有
    public var domainsAuthMap: [String: [String]] {
        return [:]
    }

    // 网页应用目前没有
    public var whiteAuthList: [String] {
        return []
    }

    // 网页应用目前没有
    public var blackAuthList: [String] {
        return []
    }

    public private(set) var authPass: Int = 0

    public private(set) var orgAuthMap: [AnyHashable: Any] = [:]

    public fileprivate(set) var userAuthMap: [AnyHashable: Any] = [:]

    // 用户&组织两种类型权限的持久化类
    private var sandbox: BDPSandboxProtocol?

    init(appId: String) {
        self.appId = appId
        self.uniqueID = OPAppUniqueID(appID: appId, identifier: nil, versionType: versionType, appType: .webApp)
        if webAuthStorageEnable() {
            self.sandbox = (BDPModuleManager(of: self.uniqueID.appType)
                .resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?
                .createSandbox(with: self.uniqueID, pkgName: "")
            let orgAuthMap = EMAOrgAuthorization.mapForOrgAuthToInvokeName()
            for key in Set(orgAuthMap.values) {
                if let value = self.sandbox?.privateStorage.object(forKey: key) {
                    self.orgAuthMap[key] = value
                }
            }
        }
    }

    fileprivate func updateAuth(with extra: [String: Any]) {
        self.authPass = extra["auth_pass"] as? Int ?? 0
        let orgAuth = extra["orgAuthScope"] as? [String: Any] ?? [:]
        self.setOrgAuthData(orgAuth)
        var userAuth = extra["userAuthScope"] as? [String: Any] ?? [:]
        if BDPAuthorization.authorizationFree() {
            userAuth = extra["userAuthScopeList"] as? [String: Any] ?? [:]
        }
        userAuth.forEach { (key, value) in
            let keys = BDPAuthorization.mapForStorageKeyToScopeKey()
            var scopeKey = "scope.\(key)"
            // 这边灰度阶段使用olineScopeKey转换成scopeKey.待全量后删除原先onlineScopeKey拼接scope.的方式;
            if (EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyNewScopeMapRule)) {
                scopeKey = EMAUserAuthorizationSynchronizer.transformOnlineScope(toScope: key)
            }
            let authKey = EMAUserAuthorizationSynchronizer.transformScopeKey(toStorageKey: scopeKey,
                                                                             mapForStorageKeyToScopeKey: keys)
            if (!authKey.isEmpty) {
                self.setUserAuthData(value, forKey: authKey)
            }
        }
    }

    private func setOrgAuthData(_ data: [String: Any]) {
        self.orgAuthMap = data
        if webAuthStorageEnable() {
            // 删除上次本地组织授权信息
            let orgAuthMap = EMAOrgAuthorization.mapForOrgAuthToInvokeName()
            for key in Set(orgAuthMap.values) {
                if let value = self.sandbox?.privateStorage.object(forKey: key) {
                    self.sandbox?.privateStorage.removeObject(forKey: key)
                }
            }
            // 重设当次本地组织授权信息
            data.forEach { (key, value) in
                if !key.isEmpty {
                    self.sandbox?.privateStorage.setObject(value, forKey: key)
                }
            }
        }
    }

    fileprivate func getUserAuthData(forKey key: String) -> Any? {
        guard let userAuthMap = self.userAuthMap[key] else {
            if webAuthStorageEnable() {
                return self.sandbox?.privateStorage.object(forKey: key)
            }
            return nil
        }
        return userAuthMap
    }

    fileprivate func setUserAuthData(_ object: Any, forKey key: String) {
        self.userAuthMap[key] = object
        if webAuthStorageEnable() {
            self.sandbox?.privateStorage.setObject(object, forKey: key)
        }
    }

    fileprivate func removeUserAuthData(forKey key: String) -> Bool {
        self.userAuthMap.removeValue(forKey: key)
        if webAuthStorageEnable() {
            self.sandbox?.privateStorage.removeObject(forKey: key)
        }
        return true
    }
}

private enum WebAppAuthStatus {
    case unfetched
    case fetching
    case fetchSuccess
    case fetchFail
}

public final class WebAppApiAuthJsSDK: NSObject, WebAppApiAuthJsSDKProtocol {
    private static let logger = Logger.oplog(WebAppApiAuthJsSDK.self, category: "OPWeb.Auth")

    public let model: WebAppAuthModel

    private let jssdk: WebAppJsSDK
    private let resolver: Resolver
    // 此处逻辑与jssdkImpl里保持一致
    private var sessionManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        /// 要注意，rust经常容易出问题，后期加上fg控制这一行代码
        configuration.protocolClasses = [RustHttpURLProtocol.self]
        return Alamofire.SessionManager(configuration: configuration)
    }()

    public var currentURL: URL? {
        didSet {
            if let old = oldValue, old.withoutQueryAndFragment != currentURL?.withoutQueryAndFragment {
                resetSesion(url: old)
            }
        }
    }

    private var monitorURLInfo: String {
        return "url: host = \(currentURL?.host ?? "") path = \(currentURL?.path ?? "")"
    }

    public var currentSession: String? {
        guard let url = currentURL else {
            WebAppApiAuthJsSDK.logger.warn("auth service has nil url, appId=\(self.model.appId)")
            return nil
        }
        return sessionDic[url.withoutQueryAndFragment]
    }

    private var needAuth: Bool {
        let minaNeedAuth = EMAAppEngine.current()?.onlineConfig?.shouldAuthForWebApp(with: self.model.uniqueID) ?? true
        let fgNeedAuth = !LarkFeatureGating.shared.getFeatureBoolValue(for: "lark.webapp.disable.checkttpermission")// user:global
        return minaNeedAuth && fgNeedAuth
    }
    
    /// API 是否可以免鉴权 ( 要求本地 API 实现已经支持免鉴权 )
    /// - Parameter apiName: api 名字
    /// - Returns: 是否可以免鉴权
    private func isAPINoNeedAuth(apiName: String) -> Bool {
        
        if WebNoAuthApi(rawValue: apiName) != nil {
            return true
        }
        
        // 默认不开启免鉴权
        return false
    }

    // 每个页面都需要经过config接口鉴权，config接口appId, url都是业务方自己填的，所以这里要记录拿回来的数据对应的session
    private var sessionDic: [String: String] = [:]// [url: session]

    private var getAuthDataStatus: WebAppAuthStatus = .unfetched // 标记拉取授权信息状态，生命周期内（vc）只成功拉取一次

    public init(appID: String,
         apiHost: WebBrowser,
         resolver: Resolver) {
        self.resolver = resolver
        self.model = WebAppAuthModel(appId: appID)
        self.jssdk = WebAppJsSDK(api: apiHost)
        super.init()
        self.jssdk.authService = self
    }

    public func updateSession(session: String, url: URL) {
        sessionDic[url.withoutQueryAndFragment] = session
        fetchAuthIfNeeded()
    }

    private func fetchAuthIfNeeded() {
        WebAppApiAuthJsSDK.logger.info("try fetch auth data, appId=\(model.appId) hasSession=\(currentSession != nil) needAuth=\(needAuth) authStatus=\(getAuthDataStatus) urlInfo=\(monitorURLInfo)")
        guard currentSession != nil && needAuth else {
            return
        }
        switch getAuthDataStatus {
        case .fetchFail, .unfetched:
            getAuthDataStatus = .fetching
            getAuthData()
        default:
            break
        }
    }

    public func resetSesion(url: URL) {
        sessionDic.removeValue(forKey: url.withoutQueryAndFragment)
    }

    private func getAuthData() {
        WebAppApiAuthJsSDK.logger.info("start fetch auth data for appId=\(model.appId) urlInfo=\(monitorURLInfo)")
        guard let configuration = try? resolver.resolve(assert: AppConfiguration.self) else {
            OPError.error(monitorCode: OWMonitorCodeApiAuth.internal_error, message: "fetch auth data but has no configuration, appId=\(model.appId) urlInfo=\(monitorURLInfo)")
            return
        }
        guard var url = configuration.settings[DomainSettings.open]?.first else {
            OPError.error(monitorCode: OWMonitorCodeApiAuth.internal_error, message: "fetch auth data but has no auth url, appId=\(model.appId) settingsCount=\(configuration.settings.count) urlInfo=\(monitorURLInfo)")
            return
        }
        let ttCode = BDPMetaTTCode()
        url = "https://\(url)/open-apis/mina/getScopesBySession"
        var params: [String: Any] = [:]
        params["appID"] = self.model.appId
        params["ttcode"] = ttCode.ttcode
        params["h5Session"] = currentSession ?? ""

        sessionManager.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil).responseJSON { [weak self](response) in
            guard let self = self else {
                OPError.error(monitorCode: OWMonitorCodeApiAuth.internal_error, message: "request auth data internal error, auth service released")
                return
            }
            switch response.result {
            case .success(let value):
                let result = value as? Dictionary ?? [:]
                let code = result["code"] as? Int
                guard code == 0 else {
                    self.getAuthDataStatus = .fetchFail
                    OPError.error(monitorCode: OWMonitorCodeApiAuth.request_result_biz_fail, message: "request auth data biz error, appId=\(self.model.appId) code=\(code) urlInfo=\(self.monitorURLInfo)")
                    return
                }
                guard let data = result["data"] as? [String: Any],
                    let scopeInfo = data["scopeInfo"] as? String else {
                    self.getAuthDataStatus = .fetchFail
                    OPError.error(monitorCode: OWMonitorCodeApiAuth.request_result_data_invalid, message: "request auth data response invalid data, appId=\(self.model.appId) result=\(result) urlInfo=\(self.monitorURLInfo)")
                    return
                }
                guard let scopes = (((scopeInfo as NSString).tma_aesDecrypt(ttCode.aesKeyA, iv: ttCode.aesKeyB) ?? Data()) as NSData).jsonValue() as? [String: Any] else {
                    self.getAuthDataStatus = .fetchFail
                    OPError.error(monitorCode: OWMonitorCodeApiAuth.request_result_decrypt_error, message: "request auth data response valid, but auth decrypt fail, appId=\(self.model.appId) urlInfo=\(self.monitorURLInfo)")
                    return
                }
                WebAppApiAuthJsSDK.logger.info("fetch auth data success, appId=\(self.model.appId)")
                OPMonitor(name: OPMonitor.event_h5_api_auth,
                          code: OWMonitorCodeApiAuth.request_success)
                    .setResultTypeSuccess()
                    .addMap(["urlInfo":"\(self.monitorURLInfo)"])
                    .setAppID(self.model.appId).flush()
                self.model.updateAuth(with: scopes)
                self.getAuthDataStatus = .fetchSuccess
            case .failure(let error):
                OPError.error(monitorCode: OWMonitorCodeApiAuth.request_network_error, message: "request auth data network error, appId=\(self.model.appId) error=\(error) urlInfo=\(self.monitorURLInfo)")
                self.getAuthDataStatus = .fetchFail
            }
        }
    }

    //  args必须是这样的
    /*
    {
     "params": {
        业务数据
     },
     "callbackId": ""
    }
    */
    @discardableResult
    public func invoke(method: String, args: [String: Any], shouldUseNewBridgeProtocol: Bool, trace: OPTrace, webTrace: OPTrace?) -> Bool {
        // 如有必要，尝试拉取，方便下次使用
        WebAppApiAuthJsSDK.logger.info("invoke tt mehtod=\(method) appId=\(self.model.appId) needAuth=\(needAuth) urlInfo=\(monitorURLInfo)")
        fetchAuthIfNeeded()
        
        // 部分API为免授权API，允许非应用形态未授权渠道调用（后续做API分级方案记得把这里的逻辑一起迁移过去）
        var apiNeedAuth = needAuth
        if isAPINoNeedAuth(apiName: method) {
            apiNeedAuth = false
        }
        
        return jssdk.invoke(method: method, args: args, needAuth: apiNeedAuth, shouldUseNewBridgeProtocol: shouldUseNewBridgeProtocol, trace: trace, webTrace: webTrace)
    }
}

// H5目前无存储，此处适配小程序权限相关storage接口，目前小程序权限相关storage都是扁平化铺开存储的
// 小程序存储：location: {"default_json_key": true}
// locationModifyTime: {"default_json_key": XXXXXX}
// 实际后端请求回来的权限数据格式：
// {
//    "userAuthScope": {
//        "scopeName1": {
//            "auth": bool,
//            "modifyTime": int64
//        },
//        "scopeName2": {
//            "auth": bool,
//            "modifyTime": int64
//        }
//    },
//    "orgAuthScope": {
//        "clientApi1": {
//            "auth": true,
//            "modifyTime": int64
//        },
//        "clientApi2": {
//            "auth": true,
//            "modifyTime": int64
//        }
//    }
//}
// failedAuthScopeKey 是针对小程序上报失败了之后，重新上报等相关逻辑，H5目前没有
extension WebAppApiAuthJsSDK: BDPAuthStorage {

    public func setObject(_ object: Any!, forKey key: String!) -> Bool {
        guard key != String.failedAuthScopeKey else {
            WebAppApiAuthJsSDK.logger.info("WebAppAuthStorage don't need handle set failed scoped, appId=\(self.model.appId)")
            return false
        }
        let keyInfo = key.storageKeyInfo
        guard let authScope = keyInfo.first else {
            WebAppApiAuthJsSDK.logger.warn("WebAppAuthStorage set object error, appId=\(self.model.appId) key=(\(String(describing: key))")
            return false
        }
        var scopeDic = self.model.getUserAuthData(forKey: authScope) as? [String: Any] ?? [String: Any]()
        if keyInfo.count == 2 && keyInfo[1].isEmpty {
            scopeDic[String.modTypeKey] = object
        } else if keyInfo.count == 2 {
            scopeDic[String.modifyTypeKey] = object
        } else {
            scopeDic[String.authKey] = object
        }
        self.model.setUserAuthData(scopeDic, forKey: authScope)
        return true
    }

    public func object(forKey key: String!) -> Any! {
        guard key != String.failedAuthScopeKey else {
            WebAppApiAuthJsSDK.logger.info("WebAppAuthStorage don't need handle get failed scoped, appId=\(self.model.appId)")
            return nil
        }
        let keyInfo = key.storageKeyInfo
        guard let authScope = keyInfo.first else {
            WebAppApiAuthJsSDK.logger.warn("WebAppAuthStorage get object error, appId=\(self.model.appId) key=(\(String(describing: key))")
            return nil
        }
        let scopeDic = self.model.getUserAuthData(forKey: authScope) as? [String: Any]
        if keyInfo.count == 2 && keyInfo[1].isEmpty {
            return scopeDic?[String.modTypeKey]
        } else if keyInfo.count == 2 {
            return scopeDic?[String.modifyTypeKey]
        } else {
            return scopeDic?[String.authKey]
        }
    }

    public func removeObject(forKey key: String!) -> Bool {
        guard key != String.failedAuthScopeKey else {
            WebAppApiAuthJsSDK.logger.info("WebAppAuthStorage don't need remove failed scoped, appId=\(self.model.appId)")
            return false
        }
        return self.model.removeUserAuthData(forKey: key)
    }

}

fileprivate extension String {
    static let modifyTypeKey = "modifyTime"
    static let modTypeKey = "mod"
    static let authKey = "auth"
    static let failedAuthScopeKey = "bdp_auth_fail_scope"
    static let storageModTypeSubfix = "Mod"
    // 对auth模块数据进行转换，auth模块传过来的key分为 ${scope} / ${scope}ModifyTime / ${scope}Mod
    var storageKeyInfo: [String] {
        return self.components(separatedBy: String.storageModTypeSubfix)
    }
}
