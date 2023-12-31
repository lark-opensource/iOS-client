//
//  V3APIHelper.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/25.
//

import Foundation
import LarkLocalizations
import LarkFoundation
import Homeric
import LKCommonsLogging
import RxSwift
import LarkReleaseConfig
import LKCommonsTracker
import LarkAccountInterface
import LarkContainer
import LarkEnv

class V3APIHelper {

    private let enableCaptchaTokenFetcher: () -> Bool
    private let disposeBag: DisposeBag = DisposeBag()
    // injected params send to server when login/register
    var injectParams: InjectParams = InjectParams()
    /// 外部（H5）设置的Header，一次性使用避免后续对Header的污染
    var oneTimeHeader: [String: String]? {
        didSet {
            if let header = oneTimeHeader {
                // 更新 Token 如果包含了
                self.tokenManager.updateTokenIfHas(header)
            }
        }
    }

    @Provider var deviceService: InternalDeviceServiceProtocol
    @Provider var envManager: EnvironmentInterface
    @Provider var captchaAPI: CaptchaAPI // user:checked (global-resolve)
    @Provider var tokenManager: PassportTokenManager
    @Provider var userManager: UserManager

    init(
        enableCaptchaTokenFetcher: @escaping () -> Bool
    ) {
        self.enableCaptchaTokenFetcher = enableCaptchaTokenFetcher
    }

    fileprivate static let logger = Logger.plog(V3APIHelper.self, category: "SuiteLogin.V3APIHelper")

    var enableCaptchaToken: Bool {
        return self.enableCaptchaTokenFetcher()
    }

    var suiteSessionKey: String? {
        userManager.foregroundUser?.suiteSessionKey // user:current
    }

    var passportUnit: String { envManager.env.unit }

    // MARK: Domain

    func fetchDomain(_ type: Request.Domain) -> String {
        switch type {
        case .api(let usingPackageDomain):
            if usingPackageDomain {
                if let url = PassportConf.shared.serverInfoProvider.getUrl(.apiUsingPackageDomain).value {
                    return url
                } else {
                    Self.logger.errorWithAssertion("n_action_domain_PackageDomain(.api)_was_not_found")
                    return ""
                }
            } else {
                if let url = PassportConf.shared.serverInfoProvider.getUrl(.api).value {
                    return url
                } else {
                    Self.logger.errorWithAssertion("n_action_domain_EnvDomain(.api)_was_not_found")
                    return ""
                }
            }
        case .passportAccounts(let usingPackageDomain):
            if usingPackageDomain {
                if let url = PassportConf.shared.serverInfoProvider.getUrl(.passportAccountsUsingPackageDomain).value {
                    return url
                } else {
                    Self.logger.errorWithAssertion("n_action_domain_PackageDomain(.passportAccounts)_was_not_found")
                    return ""
                }
            } else {
                if let url = PassportConf.shared.serverInfoProvider.getUrl(.passportAccounts).value {
                    return url
                } else {
                    Self.logger.errorWithAssertion("n_action_domain_EnvDomain(.passportAccounts)_was_not_found")
                    return ""
                }
            }
        case .open:
            if let url = PassportConf.shared.serverInfoProvider.getUrl(.open).value {
                return url
            }
            Self.logger.errorWithAssertion("n_action_domain_(.open)_was_not_found")
            return ""
        case .custom(let domain):
            var url = domain
            if !url.hasPrefix(CommonConst.prefixHTTPS) {
                url = CommonConst.prefixHTTPS + url
            }

            if !url.hasSuffix(CommonConst.slant) {
                url = url + CommonConst.slant
            }
            return url
        }
    }

    // MARK: Captcha

    func captchaToken(method: String, body: String, result: @escaping (Result<String, V3LoginError>) -> Void) {
        captchaAPI.captchaToken(method: method, body: body) { (rs) in
            switch rs {
            case .success(let token):
                result(.success(token))
            case .failure(let error):
                V3APIHelper.logger.error("captchaToken method:\(method) appVersion:\(CommonConst.apiVersionValue) error:\(error.localizedDescription)")
                result(.failure(error))
            }
        }
    }

    // MARK: Header

    func getHeader(captchaToken: String? = nil, passportToken: String?, pwdToken: String?, suiteSessionKey: String?, verifyToken: String?, flowKey: String?, proxyUnit: String?, authFlowKey: String?, sessionKeys: [String]?) -> [String: String] {
        struct Const {
            // key
            static let contentType: String = CommonConst.contentType
            static let locale: String = "X-Locale"
            static let terminalType: String = "X-Terminal-Type"
            static let deviceInfo: String = "X-Device-Info"
            static let deviceIDs: String = "X-Passport-Device-IDs"
            static let passportUnit: String = CommonConst.passportUnit
            static let apiVersion: String = "X-Api-Version"
            static let appID: String = "X-App-Id"
            // value
            static let applicationJson: String = CommonConst.applicationJson
            static let apiVersionValue: String = CommonConst.apiVersionValue
        }

        var header = [
            CommonConst.requestId: UUID().uuidString,
            Const.locale: LanguageManager.currentLanguage.localeIdentifier,
            Const.contentType: Const.applicationJson,
            Const.terminalType: getXTerminalType(),
            Const.deviceInfo: getXDeviceInfo(),
            Const.deviceIDs: getXDeviceIDs(),
            Const.apiVersion: Const.apiVersionValue,
            Const.appID: getXAppID() // TODO: jinjian
        ]
        if let sessionKey = suiteSessionKey {
            header[CommonConst.suiteSessionKey] = sessionKey
        }
        if let token = passportToken, !token.isEmpty {
            header[CommonConst.passportToken] = token
        }
        if let token = pwdToken, !token.isEmpty {
            header[CommonConst.passportPWDToken] = token
        }
        if let token = verifyToken, !token.isEmpty {
            header[CommonConst.verifyToken] = token
        }
        if let flowKey = flowKey, !flowKey.isEmpty {
            header[CommonConst.flowKey] = flowKey
        }
        if let proxyUnit = proxyUnit, !proxyUnit.isEmpty {
            header[CommonConst.proxyUnit] = proxyUnit
        }
        if let authFlowKey = authFlowKey, !authFlowKey.isEmpty {
            header[CommonConst.authFlowKey] = authFlowKey
        }
        if let sessionKeys = sessionKeys, !sessionKeys.isEmpty {
            header[CommonConst.sessionKeys] = sessionKeys.joined(separator: ",")
        }
        if !ReleaseConfig.isPrivateKA {
            header[Const.passportUnit] = passportUnit
        }

        // KA-R use
        if let token = captchaToken {
            header[CommonConst.captchaToken] = token
        }

        if let fid = PassportConf.shared.stagingFeatureId {
            header[CommonConst.featureIdHeaderKey] = fid
        }
        //frontUserUUID
        if PassportSwitch.shared.enableUUIDAndNewStoreReset {
            //为了避免加锁导致死锁等问题，frontUUID使用保证在主线程调用的方式，解决同步问题
            //等如果是主线程直接调用
            if Thread.isMainThread {
                header[CommonConst.frontUserUUID] = PassportStore.shared.frontUUID
            } else {
                //非主线程，sync到主线程调用, frontUUID 是一个简单的生成uuid的逻辑
                var frontUUID: String = ""
                DispatchQueue.main.sync {
                    frontUUID = PassportStore.shared.frontUUID
                }
                header[CommonConst.frontUserUUID] = frontUUID
            }

        }
        
        //统一did
        if let uniDid = deviceService.universalDeviceID() {
            header[CommonConst.universalDeviceId] = uniDid
        }
        
        // 最后执行
        if let tmpHeader = oneTimeHeader {
            header.merge(tmpHeader, uniquingKeysWith: { $1 })
            oneTimeHeader = nil
        }
        return header
    }

    private func getXTerminalType() -> String {
        return "\(PassportConf.terminalType)"
    }

    private func getXDeviceInfo() -> String {
        struct Const {
            static let deviceID: String = "device_id"
            static let deviceName: String = "device_name"
            static let deviceOS: String = "device_os"
            static let deviceModel: String = "device_model"
            static let larkVersion: String = "lark_version"
            static let rustVersion: String = "rust_version"
            static let packageName: String = "package_name"
            static let channel: String = "channel"
            static let afID: String = "af_id"
            static let ttAppID: String = "tt_app_id"
            static let packageBrand: String = "package_brand"
        }

        var deviceInfo = [
            Const.packageName: Utils.appName,
            Const.deviceID: deviceService.deviceId,
            Const.deviceName: (PassportConf.deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? PassportConf.deviceModel : PassportConf.deviceName),
            Const.deviceOS: PassportConf.deviceOS,
            Const.deviceModel: PassportConf.deviceModel,
            Const.larkVersion: Utils.appVersion,
            Const.channel: ReleaseConfig.appBrandName,
            Const.ttAppID: ReleaseConfig.appId,
            Const.packageBrand: ReleaseConfig.isLark ? "lark" : "feishu"
        ]

        #if LarkAccount_RUST
        deviceInfo[Const.rustVersion] = RustStaticInfo.sdkVersion
        #endif

        #if DEBUG || BETA || ALPHA
        deviceInfo[Const.packageName] = ReleaseConfig.isLark ? "com.larksuite.lark" : "com.bytedance.ee.lark"
        #endif
        if let uid = PassportConf.shared.appsFlyerUID {
            deviceInfo[Const.afID] = uid
        }

        return deviceInfo.reduce("") { (res, kv) -> String in
            let (key, value) = kv
            return res + "\(key)=\(value.deviceInfoEncode);"
        }
    }

    private func getXDeviceIDs() -> String {
        guard let map = deviceService.fetchDeviceIDMap() else {
            Self.logger.error("Header get x-device-ids empty.", method: .local)
            return ""
        }

        // example: "boecn:123456,boeva:654321"
        let result: String

        #if DEBUG || BETA || ALPHA
        // 调试与内测期间，避免不同环境获取的 did 混在一起
        switch envManager.env.type {
        case .staging:
            result = map
                .map { "\($0.key):\($0.value)" }
                .filter { $0.contains("boe") }
                .joined(separator: ",")
        case .preRelease:
            result = map
                .map { "\($0.key):\($0.value)" }
                .filter { !$0.contains("boe") }
                .joined(separator: ",")
        case .release:
            result = map
                .map { "\($0.key):\($0.value)" }
                .filter { !$0.contains("boe") }
                .joined(separator: ",")
        }
        #else
        result = map
            .map { "\($0.key):\($0.value)" }
            .joined(separator: ",")
        #endif

        return result
    }

    ///
    private func getXAppID() -> String {
        return "1"
    }

    func appendInjectParamsFor(_ params: [String: Any]) -> [String: Any] {
        V3APIHelper.logger.info("inject additional info to params", method: .local)
        return injectParams.addTo(params: params)
    }

    func cleanCache() {
        Self.logger.info("n_net_helper_clear_data")
        tokenManager.passportToken = nil
        tokenManager.pwdToken = nil
        tokenManager.verifyToken = nil
        tokenManager.flowKey = nil
        tokenManager.proxyUnit = nil
        tokenManager.authFlowKey = nil
        injectParams.reset()
    }
}

extension String {
    var urlEncode: String {
        self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
    var deviceInfoEncode: String {
        let charSet = CharacterSet.urlQueryAllowed as NSCharacterSet
        let mutiSet = charSet.mutableCopy() as! NSMutableCharacterSet
        mutiSet.removeCharacters(in: "&;")
        return self.addingPercentEncoding(withAllowedCharacters: mutiSet as CharacterSet) ?? ""
    }
}
