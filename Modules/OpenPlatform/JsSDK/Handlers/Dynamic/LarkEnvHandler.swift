//
//  LarkEnvHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import WebBrowser
import LKCommonsLogging
import LarkAppConfig
import LarkReleaseConfig
import RustPB
import Swinject
import ECOProbe
import LarkReleaseConfig
import LarkAccountInterface
import LarkEnv
import LarkContainer

class LarkEnvHandlerMonitorCode: OPMonitorCode {
    /// 分享各个入口触发点
    static let handle_invoke = LarkEnvHandlerMonitorCode(code: 10000, message: "handle_invoke")
    
    private init(code: Int, level: OPMonitorLevel = OPMonitorLevelNormal, message: String) {
        super.init(domain: LarkEnvHandlerMonitorCode.domain, code: code, level: level, message: message)
    }

    static let domain = "client.JsSDK.LarkEnvHandler"
}

class LarkEnvHandler: JsAPIHandler {

    enum LoginEnvType: Int {
        case feishu = 0
        case lark = 1
        case KA = 2
    }

    enum PkgEnvType: Int {
        case feishuRelease = 0
        case feishuInhouse = 1
        case larkRelease = 2
        case larkInhouse = 3
    }

    enum DeployEnvType: Int {
        case release = 0
        case staging = 1
        case preRelease = 2
    }
    
    @Provider private var passportService: PassportService // Global

    private static let logger = Logger.log(LarkEnvHandler.self, category: "LarkEnvHandler")
    private let resolver: Resolver
    typealias EnvTypes = (login: LoginEnvType, pkg: PkgEnvType, deploy: DeployEnvType)

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        LarkEnvHandler.logger.debug("handle args = \(args))")

        let types: EnvTypes = getEnvTypes()
        let loginEnv: LoginEnvType = types.login
        let pkgEnv: PkgEnvType = types.pkg
        let deployEnv: DeployEnvType = types.deploy

        LarkEnvHandler.logger.debug("getEnvTypes loginEnv = \(loginEnv), pkgEnv = \(pkgEnv), deployEnv = \(deployEnv)")
        
        OPMonitor(LarkEnvHandlerMonitorCode.handle_invoke)
            .tracing(api.webview.trace)
            .addCategoryValue("url", api.webview.url?.safeURLString)
            .addCategoryValue("browserURL", api.browserURL?.safeURLString)
            .addCategoryValue("loginEnv", loginEnv.rawValue)
            .addCategoryValue("pkgEnv", loginEnv.rawValue)
            .addCategoryValue("deployEnv", deployEnv.rawValue)
            .flush()

        if let onSuccess = args["onSuccess"] as? String {
            let arguments = [["loginEnv": loginEnv.rawValue, "pkgEnv": pkgEnv.rawValue, "deployEnv": deployEnv.rawValue]] as [[String: Any]]
            callbackWith(api: api, funcName: onSuccess, arguments: arguments)
            LarkEnvHandler.logger.debug("LarkEnvHandler success, loginEnv = \(loginEnv), pkgEnv = \(pkgEnv), deployEnv = \(deployEnv)")
        } else {
            if let onFailed = args["onFailed"] as? String {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
        }
    }

    private func getEnvTypes() -> EnvTypes {
        let loginEnv: LoginEnvType = ReleaseConfig.isKA ? .KA : (passportService.isFeishuBrand ? .lark : .feishu)
        
        let pkgEnv: PkgEnvType = (ReleaseConfig.isLark) ? .larkRelease : .feishuRelease
        
        var deployEnv: DeployEnvType
        switch EnvManager.env.type {
        case .release:
            deployEnv = .release
        case .staging:
            deployEnv = .staging
        case .preRelease:
            deployEnv = .preRelease
        @unknown default:
            deployEnv = .release
        }
        
        let envs: EnvTypes = EnvTypes(login: loginEnv, pkg: pkgEnv, deploy: deployEnv)
        return envs
    }

}
