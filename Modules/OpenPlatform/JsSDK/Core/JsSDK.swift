//
//  JsSDK.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import Alamofire
import LKCommonsLogging
import RxSwift
import Swinject
import WebBrowser
import LarkOPInterface
import WebKit
import EcosystemWeb
import LarkSetting
import ECOInfra
import LarkContainer

let BizApiBlackListSettingsKey = "biz_api_blacklist"

//  仅挪动位置，未改变任何逻辑，code from 🍁
public struct APIConfig {
    public var name: String
    public init(name: String) {
        self.name = name
    }
}
public struct SDKConfig {
    public var apiConfigs: [String: APIConfig]

    public init(apiConfigs: [String: APIConfig]) {
        self.apiConfigs = apiConfigs
    }
}

/// 兼容新老协议的回调对象
public class WorkaroundAPICallBack {
    /// 是否使用新协议
    private let shouldUseNewBridgeProtocol: Bool
    /// 原先的字典
    private let oldArgs: [String: Any]
    /// 新老视图控制器满足的协议
    private weak var api: WebBrowser?
    /// 回调ID
    private var callbackID: String?
    init(shouldUseNewBridgeProtocol: Bool, api: WebBrowser?, oldArgs: [String: Any] = [String: Any](), callbackID: String?) {
        self.shouldUseNewBridgeProtocol = shouldUseNewBridgeProtocol
        self.api = api
        self.oldArgs = oldArgs
        self.callbackID = callbackID
    }
    /// 统一成功回调
    public func callbackSuccess(param: Any) {
        executeOnMainQueueAsync {
            if self.shouldUseNewBridgeProtocol {
                self.callback(with: param, type: "success")
            } else {
                if let onSuccess = self.oldArgs["onSuccess"] as? String {
                    self.api?.call(funcName: onSuccess, arguments: [param])
                } else {
                    JsSDKImpl.logger.error("js function has no onSuccess calback str")
                }
            }
        }
    }
    /// 统一失败回调
    public func callbackFailure(param: Any) {
        executeOnMainQueueAsync {
            if self.shouldUseNewBridgeProtocol {
                self.callback(with: param, type: "failure")
            } else {
                if let onFailed = self.oldArgs["onFailed"] as? String {
                    self.api?.call(funcName: onFailed, arguments: [param])
                } else {
                    JsSDKImpl.logger.error("js function has no onFailed calback str")
                }
            }
        }
    }

    /// 【兼容方法】老版本 JsSDK 方法回调 isWrappedParam 说明 param 是否被 [] 包裹
    public func callDeprecatedFunction(name: String, param: Any, isWrappedParam: Bool = false) {
        executeOnMainQueueAsync {
            if isWrappedParam, let wrappedParam = param as? [Any] {
                self.api?.call(funcName: name, arguments: wrappedParam)
            } else {
                self.api?.call(funcName: name, arguments: [param])
            }
        }
    }

    /// 持续“回调”
    func asyncNotify(event: String?, data: Any) {
        executeOnMainQueueAsync {
            if let event = event, !self.shouldUseNewBridgeProtocol {
                // 老协议
                self.api?.call(funcName: event, arguments: [data])
            } else {
                // 新协议
                self.callback(with: data, type: "continued")
            }
        }
    }
    /// 新协议回调统一方法
    private func callback(with params: Any, type: String) {
        let finalMap: [String: Any] = [
            "callbackID": callbackID,
            "data": params,
            "callbackType": type
        ]
        // 兜底处理params不合法的情况
        guard JSONSerialization.isValidJSONObject(finalMap) else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: finalMap) else { return }
        let str = String(data: data, encoding: .utf8) ?? ""
        let jsStr = "LarkWebViewJavaScriptBridge.nativeCallBack(\(str))"
        api?.webView.evaluateJavaScript(jsStr)
    }

    /// 安全的异步派发到主线程执行任务
    /// - Parameter block: 任务
    private func executeOnMainQueueAsync(_ block: @escaping os_block_t) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

public protocol JsAPIHandler: LarkWebJSAPIHandler {
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack)
}

public extension JsAPIHandler {
    func handle(args: [String: Any], api: WebBrowser, sdk: LarkWebJSSDK) {
        guard let jsSDK = sdk as? JsSDK else {
            return
        }
        //  callback使用同一对象，TODO，这里需要 LarkWebJSAPIHandler 支持shouldUseNewBridgeProtocol 和 callbackID(老协议没有callbackid，所以传入nil) TODO 需要该协议传入method上来
        let callback = WorkaroundAPICallBack(shouldUseNewBridgeProtocol: false, api: api, oldArgs: args, callbackID: nil)
        handle(args: args, api: api, sdk: jsSDK, callback: callback)
    }
}

public protocol JsSDK: LarkWebJSSDK {

    var resolver: UserResolver { get set }

    /// h5 JSAPI 需要发网络请求，统一使用这个sessionManager
    var sessionManager: Alamofire.SessionManager { get }

    /// 保存下载API接口所有的请求，以便随时取消
    var downloadRequests: [String: DownloadRequest] { get set }

    func update(url: URL, config: SDKConfig)

    func disableJsAuthrized() -> Bool

    // 原始LarkWebJSSDK存了 authSession, 但实际没有跟appId关联起来，config接口是由业务方自己调用的，所以可能出现业务方调用传入的appId和真正的appId并不一致
    func updateSession(webAppInfo: WebAppInfo, url: URL?, session: String, webpage: WKBackForwardListItem?)
}

extension JsSDKImpl: JsSDK { }

public class JsSDKImpl: LarkWebJSSDK {

    public var methodList: [String] {
        let oldapipList = methodsDict.map { k, _ -> String in
            k
        }
        let list = oldapipList + ttapiList
        return list
    }

    let ttapiList = [
        "onUserCaptureScreen",
        "offUserCaptureScreen",
        "getSystemInfo",
        "setClipboardData",
        "getClipboardData",
        "mailto",
        "startDeviceCredential",
        "startPasswordVerify",
        "checkWatermark",
        "hasWatermark",
        "onWatermarkChange",
        "offWatermarkChange",
        "startFaceVerify",
        "openSchema",
        "docsPicker",
        "showModal",
        "showToast",
        "hideToast",
        "showPrompt",
        "getUserInfo",
        "showActionSheet",
        "setNavigationBarTitle",
        "setNavigationBarColor",
        "getLocation",
        "openDocument",
        "removeSavedFile",
        "downloadFile",
        "monitorReport",
        "createDownloadTask"
    ]

    public var resolver: UserResolver

    weak var api: WebBrowser?

    static let logger = Logger.log(JsSDKImpl.self, category: "Module.JSSDK")

    fileprivate(set) var methodsDict: [String: () -> LarkWebJSAPIHandler] = [:]

    var configs: [String: SDKConfig] = [:]
    /// jsAPI鉴权用的token
    public var authSession: String?

    /// h5 JSAPI 需要发网络请求，统一使用这个sessionManager
    public var sessionManager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        return Alamofire.SessionManager(configuration: configuration)
    }()

    /// 保存下载API接口所有的请求，以便随时取消
    public var downloadRequests =  [String: DownloadRequest]()

    public init(api: WebBrowser, r: UserResolver) {
        self.api = api
        self.resolver = r
    }

    public func update(url: URL, config: SDKConfig) {
        let key = self.key(from: url)
        self.configs[key] = config
    }

    public func regist(method: String, apiGetter: @escaping () -> LarkWebJSAPIHandler) {
        guard methodsDict[method] == nil else {
            JsSDKImpl.logger.error("函数重复注册", additionalData: ["method": method])
            return
        }

        methodsDict[method] = apiGetter
    }
    //  新协议调用biz系列API
    public func invoke(apiName: String, data: [String: Any], callbackID: String?) -> Bool {
        OPMonitor("web_biz_api_invoke")
            .addCategoryValue("api_name", apiName)
            .addCategoryValue("url", api?.webView.url?.host)
            .flush()
        JsSDKImpl.logger.info("recieve js api message, method: \(apiName)")
        
        guard let api = api else { return false }
        let callback = WorkaroundAPICallBack(shouldUseNewBridgeProtocol: true, api: self.api, oldArgs: data, callbackID: callbackID)
        let fallbackEnabled = !resolver.fg.dynamicFeatureGatingValue(with: "openplatform.web.api.biz.failcallback.disable")
        
        guard let getAPI = methodsDict[apiName] else {
            JsSDKImpl.logger.error("未找到对应handler，无法调用", additionalData: ["method": apiName])
            if fallbackEnabled {
                callback.callbackFailure(param: NewJsSDKErrorAPI.Auth.apiFindNoHandler.description())
            }
            return false
        }
        
        guard let url = self.api?.webView.url else {
            JsSDKImpl.logger.error("get current url failed", additionalData: ["method": apiName])
            if fallbackEnabled {
                callback.callbackFailure(param: NewJsSDKErrorAPI.Auth.webviewURLEmpty.description())
            }
            return false
        }
        guard let apiHanlder = getAPI() as? JsAPIHandler else {
            JsSDKImpl.logger.error("not JsAPIHandler", additionalData: ["method": apiName])
            if fallbackEnabled {
                callback.callbackFailure(param: NewJsSDKErrorAPI.Auth.apiHandlerTypeInvalid.description())
            }
            return false
        }
        
        // 判断是否命中黑名单, 处于安全需求 biz api 会逐步加进黑名单后下线
        // https://bytedance.feishu.cn/docx/doxcnYMZ3Qla1VVZSj6xNOrqVdb
        if let blackList = ECOConfig.service().getArrayValue(for: BizApiBlackListSettingsKey) as? [String],
           blackList.contains(apiName) {
            JsSDKImpl.logger.error("api in black list", additionalData: ["method": apiName])
            OPMonitor("web_biz_api_deprecated")
                .addCategoryValue("api_name", apiName)
                .addCategoryValue("url", url.host)
                .flush()
            callback.callbackFailure(param: NewJsSDKErrorAPI.Auth.apiDeprecated(apiName: apiName).description())
            return false
        }
        
        if hasPermission(jsHanlder: apiHanlder, url: url, method: apiName) {
            apiHanlder.handle(args: data, api: api, sdk: self, callback: callback)
            return true
        } else {
            /// 鉴权失败, 按照情况回调错误
            JsSDKImpl.logger.error("h5 api auth failed")
            if configs[self.key(from: url)] != nil {
                callback.callbackFailure(param: NewJsSDKErrorAPI.Auth.apiNotInAuthrizedAPIList.description())
            } else {
                callback.callbackFailure(param: NewJsSDKErrorAPI.Auth.apiNotInAuthrizedAPIList.description())
            }
        }
        return false
    }

    ///  VC调过来第一个函数就是这里
    @discardableResult
    public func invoke(method: String, args: [String: Any]) -> Bool {
        OPMonitor("web_biz_api_invoke")
            .addCategoryValue("api_name", method)
            .addCategoryValue("url", api?.webView.url?.host)
            .flush()
        JsSDKImpl.logger.info("recieve js api message, method: \(method)")
        guard let getAPI = methodsDict[method] else {
            JsSDKImpl.logger.error("未找到对应handler，无法调用", additionalData: ["method": method])
            return false
        }

        guard let url = self.api?.webView.url else {
            JsSDKImpl.logger.error("get current url failed", additionalData: ["method": method])
            return false
        }
        guard let api = api else { return false }
        let apiHanlder = getAPI()
        
        // 判断是否命中黑名单, 处于安全需求 biz api 会逐步加进黑名单后下线
        // https://bytedance.feishu.cn/docx/doxcnYMZ3Qla1VVZSj6xNOrqVdb
        if let blackList = ECOConfig.service().getArrayValue(for: BizApiBlackListSettingsKey) as? [String],
           blackList.contains(method) {
            JsSDKImpl.logger.error("api in black list", additionalData: ["method": method])
            OPMonitor("web_biz_api_deprecated")
                .addCategoryValue("api_name", method)
                .addCategoryValue("url", url.host)
                .flush()
            apiHanlder.callbackWith(
                api: self.api,
                funcName: args["onFailed"] as? String,
                arguments: [NewJsSDKErrorAPI.Auth.apiDeprecated(apiName: method).description()]
            )
            return false
        }
        
        if hasPermission(jsHanlder: apiHanlder, url: url, method: method) {
            apiHanlder.handle(args: args, api: api, sdk: self)
            return true
        } else {
            /// 鉴权失败, 按照情况回调错误
            JsSDKImpl.logger.error("h5 api auth failed")
            let onFailed = args["onFailed"] as? String
            if configs[self.key(from: url)] != nil {
                apiHanlder.callbackWith(
                    api: self.api,
                    funcName: onFailed,
                    arguments: [NewJsSDKErrorAPI.Auth.apiNotInAuthrizedAPIList.description()]
                )
            } else {
                apiHanlder.callbackWith(
                    api: self.api,
                    funcName: onFailed,
                    arguments: [NewJsSDKErrorAPI.Auth.notAuthrized.description()]
                )
            }
        }
        return false
    }

    private func key(from url: URL) -> String {
        return "\(url.scheme ?? "")://\(url.host ?? "")\(url.path)"
    }

    private func hasPermission(jsHanlder: LarkWebJSAPIHandler, url: URL, method: String) -> Bool {
        guard jsHanlder.needAuthrized else {
            return true
        }
        /// 当拉取到 key = "lark.h5api.verify" 的fg的时候，认为后台屏蔽接口鉴权
        if disableJsAuthrized() {
            return true
        }
        let key = self.key(from: url)
        if !(configs[key]?.apiConfigs.keys.contains(method) ?? false) {
            JsSDKImpl.logger.error("鉴权失败，无法调用", additionalData: ["method": method])
            return false
        }
        return true
    }

    public func disableJsAuthrized() -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: FGKey.h5sdkDisableVerify.rawValue))
    }

    public func updateSession(webAppInfo: WebAppInfo, url: URL?, session: String, webpage: WKBackForwardListItem?) {
        api?.resolve(WebAppExtensionItem.self)?.updateSession(webAppInfo: webAppInfo, url: url, session: session, webpage: webpage)
    }
}

enum FGKey: String {
    /// h5sdk 屏蔽鉴权
    case h5sdkDisableVerify = "lark.h5api.verify"
}

//code from lilun.ios
func possibleURL(urlStr: String) -> URL? {
    if let url = URL(string: urlStr) {
        return url
    }
    if let urlEncode = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        return URL(string: urlEncode)
    }
    return nil
}

class JsSDKDependencyImpl {
    var secLinkWhitelist: [String] { (rawSetting?["sec_link_whitelist"] as? [String]) ?? [] }

    @ProviderRawSetting(key: UserSettingKey.make(userKeyLiteral: "domain_manage_policy")) var rawSetting: [String: Any]?
}
