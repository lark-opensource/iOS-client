import ECOInfra
import Foundation
import LarkContainer
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkRustClient
import LKCommonsLogging
import OPSDK
import RustPB
import WebBrowser
import LarkSetting
import OPFoundation

let errorpageAPILogger = Logger.ecosystemWebLog(ErrorPagePlugin.self, category: "ErrorPagePlugin")
final class ErrorPagePlugin: OpenBasePlugin {
    var service: RustService?
    required init(resolver: UserResolver) {
        service = try? resolver.resolve(assert: RustService.self)
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "hostIsPrivate", pluginType: Self.self, paramsType: HostIsPrivateParams.self, resultType: HostIsPrivateResult.self) { (this, params, context, callback) in
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                context.apiTrace.error("gadgetContext is nil")
                callback(.failure(error: error))
                return
            }
            guard let browser = apiContext.controller as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("apiContext.controller is not WebBrowser")
                context.apiTrace.error("apiContext.controller is not WebBrowser")
                callback(.failure(error: error))
                return
            }
            guard browser.webview.url?.scheme == BrowserInternalScheme else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("browser.webview.url?.scheme == BrowserInternalScheme is false")
                context.apiTrace.error("browser.webview.url?.scheme == BrowserInternalScheme is false")
                callback(.failure(error: error))
                return
            }
            var publicReachable = true
            if FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.opt_vpn_recognition_enable")) {// user:global
                publicReachable = BDPNetworking.isNetworkConnected()
                errorpageAPILogger.info("hostIsPrivate publicReachable is \(publicReachable)")
            }
            if let settings = try? SettingManager.shared.setting(with: .make(userKeyLiteral: "openplatform_error_page_info")),// user:global
               let privateHost = settings["privateHost"] as? Array<String>,
               let url = URL(string: params.host) {
                let noScheme: Bool = (url.scheme == nil)
                var httpScheme: Bool = false
                if let scheme = url.scheme {
                    httpScheme = scheme.hasPrefix("http")
                }
                // 若scheme不存在或scheme为http/https
                if noScheme || httpScheme {
                    for host in privateHost {
                        if BDPIsEmptyString(host) {
                            continue
                        }
                        if this.checkPrivateURL(url, host: host) {
                            errorpageAPILogger.info("hostIsPrivate check white list \(params.host) is true")
                            callback(.success(data: HostIsPrivateResult(isPrivate: publicReachable)))
                            return
                        }
                    }
                }
            }
            // 调用RustSDK判定
            var request = Openplatform_V1_IsSiteLocalAddrRequest()
            request.host = params.host
            this.service?.async(RequestPacket(message: request)) { (responsePacket: ResponsePacket<RustPB.Openplatform_V1_IsSiteLocalAddrResponse>) -> Void in
                do {
                    let value = try responsePacket.result.get().isLocal
                    let isPrivate = value && publicReachable
                    errorpageAPILogger.info("Openplatform_V1_IsSiteLocalAddrRequest for \(params.host) is \(value)")
                    callback(.success(data: HostIsPrivateResult(isPrivate: isPrivate)))
                } catch {
                    errorpageAPILogger.error("Openplatform_V1_IsSiteLocalAddrRequest error", error: error)
                    let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("Openplatform_V1_IsSiteLocalAddrRequest error")
                        .setError(error)
                    context.apiTrace.error("Openplatform_V1_IsSiteLocalAddrRequest error", error: error)
                    callback(.failure(error: e))
                }
            }
        }
        registerAsyncHandler(for: "getErrorMetaInfo", resultType: GetErrorMetaInfoResult.self) { (params, context, callback) in
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                context.apiTrace.error("gadgetContext is nil")
                callback(.failure(error: error))
                return
            }
            guard let browser = apiContext.controller as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("apiContext.controller is not WebBrowser")
                context.apiTrace.error("apiContext.controller is not WebBrowser")
                callback(.failure(error: error))
                return
            }
            guard browser.webview.url?.scheme == BrowserInternalScheme else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("browser.webview.url?.scheme == BrowserInternalScheme is false")
                context.apiTrace.error("browser.webview.url?.scheme == BrowserInternalScheme is false")
                callback(.failure(error: error))
                return
            }
            let errorPageInfo = ECOConfig.service().getDictionaryValue(for: "openplatform_error_page_info")
            let vpnInfo = errorPageInfo?["vpnInfo"] as? [String: Any]
            let vpnConnectUrl = vpnInfo?["vpnConnectUrl"] as? String ?? ""
            let vpnAppUrl = vpnInfo?["vpnAppUrl"] as? String ?? ""
            errorpageAPILogger.info("getErrorMetaInfo: vpnConnectUrl:\(vpnConnectUrl), vpnAppUrl:\(vpnAppUrl)")
            callback(.success(data: GetErrorMetaInfoResult(vpnConnectUrl: vpnConnectUrl, vpnAppUrl: vpnAppUrl)))
        }
        
        registerInstanceAsyncHandler(for:"showWebCustomErrorPage", pluginType: Self.self, paramsType: CustomErrorPageParams.self) { (_, params, context, callback) in
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let errorMsg = "gadgetContext is nil"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(errorMsg)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                return
            }
            guard let browser = apiContext.controller as? WebBrowser else {
                let errorMsg = "apiContext.controller is not WebBrowser"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(errorMsg)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                return
            }
            if let browserNavigation = browser.resolve(ErrorPageExtensionItem.self)?.navigationDelegate as? ErrorPageWebBrowserNavigation {
                browserNavigation.handleWebCustomError(browser: browser, forCustom: params.customPageConfig)
                callback(.success(data: nil))
                return
            }
            let errorMsg = "browserNavigation is nil"
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                .setMonitorMessage(errorMsg)
            context.apiTrace.error(errorMsg)
            callback(.failure(error: error))
        }
    }
    
    private func checkPrivateURL(_ url: URL, host: String) -> Bool {
        guard !BDPIsEmptyString(host) else {
            return false
        }
        // 若为URL
        if url.scheme != nil, let anotherURL = URL(string: host), anotherURL.scheme != nil {
            guard let host1 = url.host, let host2 = anotherURL.host else {
                return false
            }
            // 完全匹配
            if host1 == host2 {
                return true
            }
            // 通配符需符合二级及以上域名
            if host2.components(separatedBy: ".").count < 2 {
                return false
            }
            return host1.hasSuffix("." + host2)
        }
        // 若为host
        // 完全匹配
        if url.absoluteString == host {
            return true
        }
        // 通配符需符合二级及以上域名
        if host.components(separatedBy: ".").count < 2 {
            return false
        }
        return url.absoluteString.hasSuffix("." + host)
    }
}
public final class HostIsPrivateParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "host")
    public var host: String
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_host]
    }
}
final class HostIsPrivateResult: OpenAPIBaseResult {
    public let isPrivate: Bool
    public init(isPrivate: Bool) {
        self.isPrivate = isPrivate
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        ["isPrivate": isPrivate]
    }
}
final class GetErrorMetaInfoResult: OpenAPIBaseResult {
    public let vpnConnectUrl: String
    public let vpnAppUrl: String
    public init(vpnConnectUrl: String, vpnAppUrl: String) {
        self.vpnConnectUrl = vpnConnectUrl
        self.vpnAppUrl = vpnAppUrl
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        [
            "vpnConnectUrl": vpnConnectUrl,
            "vpnAppUrl": vpnAppUrl
        ]
    }
}

public final class CustomErrorPageParams: OpenAPIBaseParams {
    @OpenAPIOptionalParam(jsonKey: "customPageConfig")
    public var customPageConfig: String?
    
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_customPageConfig]
    }
}

