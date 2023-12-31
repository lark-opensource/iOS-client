import Foundation
import LKCommonsLogging
import LarkFeatureGating
import LarkOPInterface
import EEMicroAppSDK
import TTMicroApp
import WebBrowser
import ECOProbe
import JsSDK
import OPPluginManagerAdapter

// 调用到小程序的API需要传入的依赖对象，code from yinhao@bytedance.com
class WebAppJsSDK {
    static let logger = Logger.log(WebAppJsSDK.self)
    private static let webEventName = "op_webapp_auth_strategy"
    private weak var api: WebBrowser?
    weak var authService: WebAppApiAuthJsSDK?
    var appId: String {
        return authService?.model.appId ?? ""
    }
    var url: String {
        return authService?.currentURL?.absoluteString ?? ""
    }
    init(api: WebBrowser) {
        self.api = api
    }
    deinit {
        Self.logger.info("Web: WebAppJsSDK deinit")
    }
    @discardableResult
    func invoke(method: String, args: [String: Any], needAuth: Bool, shouldUseNewBridgeProtocol: Bool, trace: OPTrace, webTrace: OPTrace?) -> Bool {
        let errEvent = OPMonitor(OPMonitor.event_h5_api_error)
            .setMonitorCode(OWMonitorCodeApi.fail)
            .setResultTypeFail()
            .setAppID(appId)
            .setMethod(method)
        guard let api = api else {
            errEvent.setErrorMessage("WebAppJsSDK: invoke has no api")
                .flush()
            OPMonitor("op_api_invoke")
                .setMonitorCode(APIMonitorCodeCommon.native_callback_invoke)
                .setResultTypeFail()
                .setAppID(appId)
                .setErrorMessage("WebAppJsSDK: invoke has no webbroser").flushTo(trace)
            trace.finish()
            Self.logger.error("Web: get web container error")
            return false
        }
        EERoute.shared().invokeWebMethod(method, params: args, engine: self, controller: api, needAuth: needAuth, shouldUseNewbridgeProtocol: shouldUseNewBridgeProtocol, trace: trace, webTrace: webTrace)
        return true
    }

    func evaluateJavaScript(script: String, completion: ((Any?, Error?) -> Void)?) {
        api?.webView.evaluateJavaScript(script, completionHandler: { [weak self, weak api](res, error) in
            if let err = error {
                OPMonitor(OPMonitor.event_h5_webview_error)
                    .setMonitorCode(OWMonitorCodeWebview.evaluate_js_error)
                    .setResultTypeFail()
                    .setAppID(self?.appId ?? "")
                    .setErrorMessage("WebAppJsSDK: evaluateJavaScript failed with \(api?.webView.url?.withoutQueryAndFragment ?? ""), error: \(err)")
                    .setError(err)
                    .flush()
                WebAppJsSDK.logger.error("WebAppJsSDK: evaluateJavaScript failed", error: err)
            }
            completion?(res, error)
        })
    }
    
    func callbackConfig(response: [AnyHashable: Any], webTrace: OPTrace) {
        
        let currentURL = response["currentURL"] as? URL
        let sdk = api?.jsSDK as? JsSDKImpl
        var data = (response["data"] as? [AnyHashable: Any])
        data = (data?["data"] as? [AnyHashable: Any])
        if let authSession = data?["jssdk_session"] as? String {
            let webpageForConfig = api?.currentWebPage
            sdk?.authSession = authSession
            let webAppInfo = WebAppInfo(id: response["appId"] as? String ?? "", name: data?["app_name"] as? String ?? "", iconURL: data?["app_icon"] as? String, status: AppStatus.runtime.rawValue, apiAuthenStatus: .authened)
            sdk?.updateSession(webAppInfo: webAppInfo, url: currentURL, session: authSession, webpage: webpageForConfig)
        } else{
            WebAppJsSDK.logger.warn("config api returns abnormal data, jssdk_session is null")
        }
        
        if let jsApiList = response["jsApiList"] as? Array<String> {
            let configs = jsApiList
                .map { APIConfig(name: $0) }
                .lf_toDictionary { $0.name }
            if let currentURL = currentURL {
                sdk?.update(url: currentURL, config: SDKConfig(apiConfigs: configs))
            } else{
                WebAppJsSDK.logger.warn("config api returns abnormal data, currentURL is null")
            }
        } else{
            WebAppJsSDK.logger.warn("config api returns abnormal data, jsApiList exception")
        }
        
        // config后，鉴权策略状态记录 埋点
        OPMonitor(name: WebAppJsSDK.webEventName, code: EPMClientOpenPlatformWebWebappAuthCode.op_webapp_auth_strategy_status_after_config)
            .addMap(["appId": api?.appInfoForCurrentWebpage?.id ?? "",
                     "authStrategy": api?.webAppAuthStrategy?.rawValue ?? "",
                     /*
                     "url": api?.url.safeURLString,
                      */
                     // url目前是optional，没修改任何逻辑，如果有疑问请咨询原作者xiangyuanyuan
                     "url": api?.browserURL?.safeURLString,
                     "count": api?.countOfAuthRecords ?? 0])
            .tracing(webTrace)
            .flush()
    }
    
}
extension WebAppJsSDK: OPJsSDKImplProtocol {

    var authSession: String {
        return authService?.currentSession ?? ""
    }

    var authModel: AnyObject? {
        return authService?.model
    }

    var authStorage: AnyObject? {
        return authService
    }
}
