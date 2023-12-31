// 该文件代码从WebBrowser+bridge.swift迁移出来，只做单纯的代码迁移，未修改任何业务逻辑，详情参考「code from」
import ECOInfra
import ECOProbe
import LarkFeatureGating
import LarkSetting
import LarkOPInterface
import LarkWebViewContainer
import LKCommonsLogging
import TTMicroApp
import WebBrowser
import LarkOpenAPIModel

final public class EcosystemAPIExtensionItem: WebBrowserExtensionItemProtocol {
    public var itemName: String? = "EcosystemAPI"
    public lazy var lifecycleDelegate: WebBrowserLifeCycleProtocol? = EcosystemAPIWebBrowserLifeCycle(item: self)
    public init() {}
    func setupOldBridge(browser: WebBrowser) {
        browser
            .webview
            .configuration
            .userContentController
            .add(
                EcosystemOldScriptMessageHandler(controller: browser),
                name: "invoke"
            )
    }
}

final public class EcosystemAPIWebBrowserLifeCycle: WebBrowserLifeCycleProtocol {
    private weak var item: EcosystemAPIExtensionItem?
    init(item: EcosystemAPIExtensionItem) {
        self.item = item
    }
    public func viewDidLoad(browser: WebBrowser) {
        item?.setupOldBridge(browser: browser)
    }
}
final public class EcosystemWebSingleExtensionItem: WebBrowserExtensionSingleItemProtocol {
    public init() {}
    public lazy var callAPIDelegate: WebBrowserCallAPIProtocol? = EcosystemWebCallAPIProtocol(item: self)
}
final public class EcosystemWebCallAPIProtocol: WebBrowserCallAPIProtocol {
    static let logger = Logger.ecosystemWebLog(EcosystemWebCallAPIProtocol.self, category: "WebAppExtensionItem")
    
    private weak var item: EcosystemWebSingleExtensionItem?
    
    private let innerDomainPrivateAPIList : Array<String>
    
    private var privateAPIHHostConfig: [String: Any] {
        do {
            let config = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "op_private_api_host_config"))// user:global
            return config
        } catch {
            return [:]
        }
    }
    
    private var allAPIEscapeHostConfig: [String: Any] {
        do {
            let config = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "op_all_api_host_pre_config"))// user:global
            return config
        } catch {
            return [:]
        }
    }
    
    private var authOfflineAppWhiteList: [String] {
        do {
            let config = try SettingManager.shared.setting(with: Array<String>.self, key: UserSettingKey.make(userKeyLiteral: "WebAppApiAuthPassList"))// user:global
            return config
        } catch {
            return []
        }
    }
    
    // Api分级，目前先固定写死，后续等完整方案出来后再进行改造。
    private var onlyInnerDomainAPIList: [String] {
        return ["getInternalFeatureGating"]
    }
    
    private lazy var isOfflineWebAppConfigOptimize = {
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.offline.configoptimize"))// user:global
    }()
    
    init(item: EcosystemWebSingleExtensionItem) {
        self.item = item
        let defaultPath = BundleConfig.EcosystemWebBundle.path(forResource: "InnerDoaminPrivateAPIList", ofType: "plist")
        let privateAPIData = try! Data(contentsOf: URL(fileURLWithPath: defaultPath!))
        innerDomainPrivateAPIList = try! PropertyListSerialization.propertyList(from: privateAPIData, options: [], format: nil) as! Array<String>
        Self.logger.info("offline noauth app white list\(authOfflineAppWhiteList)")
    }
    
    /// 通过 fg 判断是否要关闭关于非鉴权 jssdk 的修复
    /// 默认为 false 长期灰度，只有发生故障才会打开降级为原逻辑
    /// 问题描述：https://bytedance.feishu.cn/docx/doxcnmqxSStTpkPT3uZ9F3Ck0Bg
    /// FG： https://lark-devops.bytedance.net/page/fg/edit?env=online&unit=cn&feature_key=openplatform.api.fix_nonauth_jssdk&tab=rule&app=Feishu
    private var isCloseNonAuthJSSDKFix: Bool {
        FeatureGatingManager.shared.featureGatingValue(with: "openplatform.api.fix_nonauth_jssdk")// user:global
    }
    
    private var isInnerDomainPrivateAPIInvokeEnable: Bool {
        FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.jsapi.private_api_enable")// user:global
    }
    
    private var isAllAPINoNeedAuthForHostEnable: Bool {
        FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.jsapi.all_web_api_host_config")// user:global
    }
    
    /*
     新框架入参
     biz系列
     {
         apiName:
         data: {
            业务数据
         }，
         callbackID:
     }
     tt系列
     {
         apiName:
         data: {
            业务数据，
            __v2__: true,
         }，
         callbackID:
     }
     */
    public func recieveAPICall(webBrowser: WebBrowser, message: APIMessage, callback: APICallbackProtocol) {
        //  下边等待套件统一API框架上线需要被替换
        //  对接人：lizhong.limboy
        // code from xiangyuanyuan
        if shouldInvokeAPIByTT(args: message.data, method: message.apiName) {
            // code from lixiaorui
            let webAppExtensionItem = webBrowser.resolve(WebAppExtensionItem.self)
            let webTrace = webAppExtensionItem?.trace
            
            webAppExtensionItem?.updateOfflineSessionIfNeeded()
            
            let inteceptorChain = webAppExtensionItem?.apiInvokeInterceptorChain
            let method = BDPJSBridgeMethod(name:message.apiName, params: message.data)
            let interceptorExtra = WebAppInvokeInterceptorExtra(callerID: message.extra?["callerID"] as? String)
            webTrace?.info("interceptorExtra: callerID\(interceptorExtra.callerID).")
            // 拦截器 用于在需要的时候修改 event 和 param
            do {
                try inteceptorChain?.preInvoke(method: method, extra: interceptorExtra)
            } catch {
                Self.logger.error("invokeInterceptorChain preInvoke method.name \(method.name) error: \(error)")
            }
            let originMessage = message
            let message = APIMessage(apiName: method.name,
                                     data: method.params as? [String : Any] ?? [:],
                                     callbackID: message.callbackID,
                                     extra: message.extra)
            webTrace?.info("originMessage (apiName: \(originMessage.apiName)), newMessage (apiName: \(message.apiName)).")
            
            // code from lixiaorui
            // 埋点 trace等后期jssdk透传
            let trace = OPTraceService.default().generateTrace(withParent: webBrowser.webview.trace, bizName: message.apiName)
            OPMonitor(name: WebBrowser.apiEventName,
                      code: WebBrowser.native_receive_invoke)
                .addMap(["app_id": webBrowser.appInfoForCurrentWebpage?.id ?? "",
                         "api_name": message.apiName,
                         "url": BDPLogHelper.safeURLString(webBrowser.webview.url?.absoluteString ?? "") ,
                         "callbackID": message.callbackID ?? "",
                         "app_type": "webApp"])
                .flushTo(trace)
            //  调用小程序的API
            let ttReqParams: [String: Any] = [
                "params": message.data,
                "callbackId": message.callbackID
            ]
        
            // code from yiying
            // 跳过鉴权调用tt js api， ka需要
            let newNoAuthJsSDK: WebAppApiNoAuthProtocol?
            // fix by wangfei.heart
            if isCloseNonAuthJSSDKFix {
                // 原逻辑
                newNoAuthJsSDK = ecosyetemWebDependency.getWebAppJsSDKWithoutAuthorization(apiHost: webBrowser)
            } else {
                // 修复逻辑
                newNoAuthJsSDK = webAppExtensionItem?.webAppJsSDKWithoutAuth
            }
            
            
            // openapi免鉴权列表
            if let noNeedAuth = newNoAuthJsSDK?.isAPINoNeedAuth(apiName: message.apiName), noNeedAuth {
                newNoAuthJsSDK?.invoke(method: message.apiName, args: ttReqParams, shouldUseNewBridgeProtocol: true, trace: trace, webTrace: webTrace)
                return
            }
            
            // 公司级别内域名白名单api调用
            if isInnerDomainPrivateAPIInvokeEnable , isInnerDomainPrivateAPIInvokeNoAuthRequired(apiName: message.apiName, webBrowser: webBrowser) {
                var invokeResult = (newNoAuthJsSDK?.invoke(method: message.apiName, args: ttReqParams, shouldUseNewBridgeProtocol: true, trace: trace, webTrace: webTrace))!
                Self.logger.info("api auth check inner domain for url:\(webBrowser.browserURL?.safeURLString), api:\(message.apiName), result:\(invokeResult ? "success" : "fail")")
                OPMonitor(name: "op_web_private_api_report", code: WebBrowser.private_api_invoke_result)
                    .addCategoryValue("name", message.apiName)
                    .addCategoryValue("url", webBrowser.browserURL?.safeURLString)
                    .addCategoryValue("result", invokeResult ? Int(1) : Int(0))
                    .flush()
                return
            }
            
            // 公司级别内域名白名单未通过， 且该api仅公司内服务可调用，直接报错
            if onlyInnerDomainAPIList.contains(message.apiName) {
                callback.callbackFailure(param: [
                    "errCode": 103,
                    "errMsg": "feature not support"
                ], extra: nil, error: nil)
                return
            }
            
            // 域名级别的OpenAPI免鉴权调用
            if isAllAPINoNeedAuthForHostEnable , canEscapeAllAPIInvokeAuth(webBrowser: webBrowser) {
                var invokeResult = (newNoAuthJsSDK?.invoke(method: message.apiName, args: ttReqParams, shouldUseNewBridgeProtocol: true, trace: trace, webTrace: webTrace))!
                Self.logger.info("api auth check escape all api for url:\(webBrowser.browserURL?.safeURLString), api:\(message.apiName), result:\(invokeResult ? "success" : "fail")")
                return
            }
            
            let webappAuth = webAppExtensionItem?.webAppJsSDKWithAuth
            // JSAPI调用前检查鉴权状态 埋点
            let webAppAuthMonitor = OPMonitor(name: WebBrowser.webEventName, code: EPMClientOpenPlatformWebWebappAuthCode.op_webapp_auth_strategy_status_before_use_jsapi)
                .addCategoryValue("appId", webBrowser.appInfoForCurrentWebpage?.id ?? "")
                .addCategoryValue("authStrategy", webBrowser.webAppAuthStrategy?.rawValue ?? "")
                .addCategoryValue("apiAuthenStatus", webBrowser.appInfoForCurrentWebpage?.apiAuthenStatus.rawValue ?? "")
                .addCategoryValue("url",  webBrowser.webview.url?.safeURLString)
            
            if webappAuth == nil {
                webAppAuthMonitor.addCategoryValue("hasPermission", false)
                    .addCategoryValue("extraMsg", "Request api \(message.apiName) does not have permission")
            } else {
                webAppAuthMonitor.addCategoryValue("hasPermission", true)
            }
            webAppAuthMonitor.tracing(webBrowser.getTrace())
                .flush();
            
            // code from lixiaorui
            guard let auth = webappAuth else {
                OPMonitor(name: WebBrowser.apiEventName,
                          code: WebBrowser.native_callback_invoke)
                    .setResultTypeFail()
                    .addMap(["app_type": "webApp",
                             "app_id": webBrowser.appInfoForCurrentWebpage?.id ?? "",
                             "errMsg": "no auth permisson，please call config",
                             "errCode": OpenAPICommonErrorCode.authenFail.rawValue,
                             "innerMsg":"no auth permisson，please call config"])
                    .flushTo(trace)
                trace.finish()
                //  之前和鉴权owner进行了开会，结论如下：
                //  当前webpage还没调用config，提醒开发者调用config
                callback.callbackFailure(param: [
                    "errMsg": "no auth permisson，please call config"
                ], extra: nil, error: nil)
                return
            }
            // 离线应用，appid级别白名单
            var offlineAppID = webBrowser.appInfoForCurrentWebpage?.id
            var whiltelists = self.authOfflineAppWhiteList
//            print("输出当前appid:\(appid),输出个白名单\(whiltelists)")
            
            if let offlineAppID = offlineAppID,
               !offlineAppID.isEmpty,
               self.authOfflineAppWhiteList.count > 0,
               isWebBrowserInOfflineMode(browser: webBrowser),
               self.authOfflineAppWhiteList.contains(offlineAppID) {
                   Self.logger.info("api auth check for offline app,name:\(message.apiName)")
                   auth.invoke(method: message.apiName, args: ttReqParams, shouldUseNewBridgeProtocol: true, trace: trace, webTrace: webTrace)
                   return
            }
            if isWebBrowserInOfflineMode(browser: webBrowser), let webAppExtensionItem = webAppExtensionItem, isOfflineWebAppConfigOptimize, webAppExtensionItem.offlineJSSDKSession == nil {
                // 离线应用检查是否已经拿到了jssdk_session,如果没有就请求一次
                // 请求失败也不做兜底的处理,这个逻辑是为了解决离线场景下非常小概率的调用API(API内部依赖jssdksession)发生在自动鉴权完成之前的badcase。
                Self.logger.info("fetch offline jssdk session for backup, name:\(message.apiName)")
                webAppExtensionItem.fetchOfflineWebappJSSDKSession { result in
                    Self.logger.info("fetch offline jssdk session for backup finish, name:\(message.apiName)")
                    auth.invoke(method: message.apiName, args: ttReqParams, shouldUseNewBridgeProtocol: true, trace: trace, webTrace: webTrace)
                }
            } else {
                auth.invoke(method: message.apiName, args: ttReqParams, shouldUseNewBridgeProtocol: true, trace: trace, webTrace: webTrace)
            }
        } else {
            //  调用biz.系列的API
            webBrowser.jsSDK?.invoke(apiName: message.apiName, data: message.data, callbackID: message.callbackID)
        }
    }
    
    
    private func canEscapeAllAPIInvokeAuth(webBrowser: WebBrowser) -> Bool {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.jsapi.all_web_api_host_with_path")) {
            return canEscapeAllAPIAuthIfMatchHostAndPath(webBrowser: webBrowser)
        } else {
            return canEscapeAllAPIAuthIfOnlyMatchHost(webBrowser: webBrowser)
        }
    }
    private func canEscapeAllAPIAuthIfOnlyMatchHost(webBrowser: WebBrowser) -> Bool {
        var canEscape = false
        if let hostConfig = (allAPIEscapeHostConfig["allWebApiPreConfigParams"] as? Dictionary<String, Any>), let allowList = hostConfig["allow_list"] as? Array<String>, let host = webBrowser.browserURL?.host, let path = webBrowser.browserURL?.path {
            var hitHost = hithostInWhiteList(currentHost: host, allowList: allowList)
            if let key = hitHost, !key.isEmpty {
                if let denyConfig = hostConfig["deny_list"] as? Dictionary<String, Any>, let denyPathList = denyConfig[key] as? Array<String> {
                    var isInDenyList = isPathInDenyList(currentPath: path, denyList: denyPathList)
                    if isInDenyList {
                        // host在白名单，配置了黑名单，且path在黑名单，仍然是需要鉴权
                        canEscape = false
                    } else {
                        // host在白名单，配置了黑名单，且path不在黑名单， 放行
                        canEscape = true
                    }
                } else {
                    // host在白名单， 且未配置黑名单， 放行
                    canEscape = true
                }
            }
        }
        return canEscape
    }
    
    private func canEscapeAllAPIAuthIfMatchHostAndPath(webBrowser: WebBrowser) -> Bool {
        var canEscape = false
        if let hostConfig = (allAPIEscapeHostConfig["allWebApiPreConfigParams"] as? Dictionary<String, Any>), let allowList = hostConfig["allow_list"] as? Array<String>, let host = webBrowser.browserURL?.host, let path = webBrowser.browserURL?.path {
            canEscape = hitHostAndPathInWhiteList(host: host, path: path, allowList: allowList)
        }
        return canEscape
    }
    
    private func isInnerDomainPrivateAPIInvokeNoAuthRequired(apiName: String , webBrowser: WebBrowser) -> Bool {
        if innerDomainPrivateAPIList.contains(apiName) {
            if let hostConfig = (privateAPIHHostConfig[apiName] as? Dictionary<String, Any>), let allowList = hostConfig["allow_list"] as? Array<String>, let url = webBrowser.browserURL {
                if let denyList = hostConfig["deny_list"] as? [String: Any], isUrlDeny(url, denyList: denyList) {
                    Self.logger.info("deny by isUrlDeny")
                    return false
                }
                if isUrlEqualsIgnoreQueryItem(url, allowList: allowList) {
                    Self.logger.info("pass by isUrlEqualsIgnoreQueryItem")
                    return true
                }
                if isHostAllow(url, allowList: allowList) {
                    Self.logger.info("pass by isHostAllow")
                    return true
                }
            }
        }
        return false
    }
    
    private func isUrlDeny(_ url: URL, denyList: [String: Any]) -> Bool {
        let urlStr = url.absoluteString
        guard !BDPIsEmptyString(urlStr) else {
            return false
        }
        // 默认为http/https url, 使用host
        var queryStr: String? = url.host
        // 若scheme存在且不为http前缀, 则为uri
        if let scheme = url.scheme, !scheme.hasPrefix("http") {
            queryStr = urlStr
        }
        if let key = queryStr, let denyPathList = denyList[key] as? [String] {
            return isPathInDenyList(currentPath: url.path, denyList: denyPathList)
        }
        return false
    }
    
    private func isUrlEqualsIgnoreQueryItem(_ url: URL, allowList: [String]) -> Bool {
        let urlStr = url.absoluteString
        guard !BDPIsEmptyString(urlStr) else {
            return false
        }
        return allowList.contains(urlStr)
    }
    
    private func isHostAllow(_ url: URL, allowList: [String]) -> Bool {
        let urlStr = url.absoluteString
        guard !BDPIsEmptyString(urlStr) else {
            return false
        }
        guard let host = url.host else {
            return false
        }
        if let hitHost = hithostInWhiteList(currentHost: host, allowList: allowList), !BDPIsEmptyString(hitHost) {
            return true
        }
        return false
    }
    
    /// 判断域名是否在白名单中
    /// - Parameters:
    ///   - currentHost: 当前页面域名
    ///   - allowList: 配置的域名白名单
    /// - Returns: 命中的域名白名单host,如果没有命中返回空
    func hithostInWhiteList(currentHost:String, allowList: Array<String>)->String? {
        var hitHost : String?
        for configHost in allowList {
            if configHost.split(separator: ".").count < 2 {
                continue
            }
            var dotConfigHost = configHost
            if !configHost.starts(with: ".") {
                dotConfigHost = "." + configHost
            }
            if currentHost.hasSuffix(dotConfigHost) || currentHost == configHost{
                hitHost = configHost
                break
            }
        }
        return hitHost
    }
    
    /// 判断 域名和Path 是否在白名单中
    /// - Parameters:
    ///   - host: 当前页面的host
    ///   - path: 当前页面的path
    ///   - allowList: 配置的域名Path白名单
    /// - Returns: 命中白名单返回true，否则返回false
    private func hitHostAndPathInWhiteList(host: String, path: String, allowList: Array<String>) -> Bool {
        var enable = false
        for pattern in allowList {
            //检测配置的是否是顶级域名 (不支持顶级域名)
            if pattern.split(separator: ".").count < 2 {
                continue
            }
            //情况一：若配置了Path, 则需要检测Host和Path
            if let index = pattern.firstIndex(of: "/") {
                let hostPattern = pattern.prefix(upTo: index)
                let pathPattern = pattern.suffix(from: index)
                if checkHostIsMatch(host: host, pattern: String(hostPattern)) && path.hasPrefix(pathPattern) {
                    enable = true
                    break
                }
            } else {//情况二：若没有配置Path, 只需检测Host
                let hostPattern = pattern
                if checkHostIsMatch(host: host, pattern: hostPattern) {
                    enable = true
                    break
                }
            }
        }
        return enable
    }

    private func checkHostIsMatch(host: String, pattern: String) -> Bool {
        if pattern.hasPrefix(".") {
            return host.hasSuffix(pattern)
        } else {
            return host == pattern
        }
    }
    
    func isPathInDenyList(currentPath:String, denyList: Array<String>) -> Bool {
        var isInDenyList : Bool = false
        for configPath in denyList {
            if currentPath.contains(configPath) {
                isInDenyList = true
                break
            }
        }
        return isInDenyList
    }
    
    func isWebBrowserInOfflineMode(browser : WebBrowser) -> Bool {
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.offline.v2")) {// user:global
            if browser.resolve(OfflineResourceExtensionItem.self) != nil {
                return true
            }
        }
        if browser.resolve(WebOfflineExtensionItem.self) != nil {
            return true
        }
        if browser.resolve(FallbackExtensionItem.self) != nil {
            return true
        }
        if browser.configuration.resourceInterceptConfiguration != nil {
            return true
        }
        if browser.configuration.offline {
            return true
        }
        return false
    }
}
// code from xiangyuanyuan
// 用于判断是否走tt系接口
func shouldInvokeAPIByTT(args: [String: Any], method: String) -> Bool{
    if((args["__v2__"] as? Bool ?? false ) || (method == "config")){
        return true
    }
    return false
}
/*
 老框架入参
 biz系列
 {
     method: ,
     args: {
        方法名:
        业务数据
     }
 }
 tt系列
 {
     method: ,
     args: {
         __v2__: true,
         callbackId: ，
         params: {
            业务数据
         },
     }
 }
 */
//  走到这里的都是引入了老版本JSSDK的
class EcosystemOldScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private static let logger = Logger.ecosystemWebLog(EcosystemOldScriptMessageHandler.self)
    weak private var controller: WebBrowser?
    init(controller: WebBrowser?) {
        self.controller = controller
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let params = message.body as? [String: Any] else { return }
        guard let controller = controller else {
            //  如果没有controller，调用也就没有意义了，而且现在的代码是不会调用这里的
            let msg = "has no controller and should not log this"
            assertionFailure(msg)
            Self.logger.error(msg)
            return
        }
        guard let method = params["method"] as? String else {
            Self.logger.error("Web: get invoke, no method")
            return
        }
        OPMonitor("web_old_protocol_invoke")
            .addCategoryValue("api_name", method)
            .addCategoryValue("url", controller.webview.url?.host)
            .flush()
        guard let args = params["args"] as? [String: Any] else {
            EcosystemOldScriptMessageHandler.logger.error("Web: get invoke, no args")
            return
        }
        let block = {
            // code from xiangyuanyuan
            //  JSSDK要求加了这个v2就是走tt系列API; 仅在新版jssdk启用tt版本的config
            if let v2 = args["__v2__"] as? Bool, v2 {
                // code from lixiaorui
                // 埋点, trace等后期jssdk透传
                let trace = OPTraceService.default().generateTrace(withParent: controller.webview.trace, bizName: method)
                let webTrace = controller.resolve(WebAppExtensionItem.self)?.trace
                // code from lixiaorui
                OPMonitor(name: WebBrowser.apiEventName,
                          code: WebBrowser.native_receive_invoke)
                    // code from changrong
                    .addMap(["app_id": controller.appInfoForCurrentWebpage?.id ?? "",
                             "api_name": method,
                             "url": BDPLogHelper.safeURLString(controller.webview.url?.absoluteString ?? "") ,
                             "app_type": "webApp"])
                    .flushTo(trace)
                // code from yiying
                //  调用小程序API
                EcosystemOldScriptMessageHandler.logger.info("Web: call engine api, \(method)")
                // code from yiying
                // 跳过鉴权调用tt js api， ka需要
                let newNoAuthJsSDK = ecosyetemWebDependency.getWebAppJsSDKWithoutAuthorization(apiHost: controller)
                if let noNeedAuth = newNoAuthJsSDK?.isAPINoNeedAuth(apiName: method), noNeedAuth {
                    newNoAuthJsSDK?.invoke(method: method, args: args, shouldUseNewBridgeProtocol: false, trace: trace, webTrace: webTrace)
                    return
                }
                // code from lixiaorui
                guard let auth = controller.resolve(WebAppExtensionItem.self)?.webAppJsSDKWithAuth else {
                    OPMonitor(name: WebBrowser.apiEventName,
                              code: WebBrowser.native_callback_invoke)
                        .setResultTypeFail()
                        .addMap(["app_type": "webApp",
                                 "app_id": controller.appInfoForCurrentWebpage?.id ?? "",
                                 "errMsg": "no auth permisson，please call config",
                                 "errCode": OpenAPICommonErrorCode.authenFail.rawValue,
                                 "innerMsg": "no auth permisson，please call config"])
                        .flushTo(trace)
                    trace.finish()

                    //  和鉴权owner进行了开会，结论如下：
                    //  当前webpage还没调用config，提醒开发者调用config
                    //  这里比较恶心，需要调用和BDPWebAppEngine一样的代码，还不可以依赖TTMicroApp
                    //  code from yinhao

                    //  兼容无callbackID的历史问题，否则前端会出现SyntaxError
                    var callbackID = args["callbackId"] as? String ?? String(NSNotFound)
                    if callbackID.isEmpty {
                        callbackID = String(NSNotFound)
                    }
                    let jsstr = """
                        ttJSBridge.invokeHandler(\(callbackID), {
                            "errMsg": "no auth permisson，please call config"
                        })
                    """
                    controller.webview.evaluateJavaScript(jsstr)
                    Self.logger.error("has not call config and want to call ttapi")
                    return
                }
                auth.invoke(method: method, args: args, shouldUseNewBridgeProtocol: false, trace: trace, webTrace: webTrace)
            } else {
                //  调用biz.系列的API
                EcosystemOldScriptMessageHandler.logger.info("Web: call lark api, \(method)")
                self.controller?.jsSDK?.invoke(method: method, args: args)
            }
        }
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
// code from lixiaorui
// API流程埋点, 目前仅针对tt系列Api
extension WebBrowser {
    fileprivate static let native_receive_invoke = OPMonitorCode(domain: "client.open_platform.api.common", code: 10002, level: OPMonitorLevelNormal, message: "native_receive_invoke")
    fileprivate static let native_callback_invoke = OPMonitorCode(domain: "client.open_platform.api.common", code: 10003, level: OPMonitorLevelNormal, message: "native_callback_invoke")
    fileprivate static let apiEventName = "op_api_invoke"
    
    // 域名级别私有api调用监控
    fileprivate static let private_api_invoke_result = OPMonitorCode(domain: "client.open_platform.api.private.invoke", code: 10000, level: OPMonitorLevelNormal, message: "private_api_invoke_result")
}
