//
//  ConfigHandler.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/24.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//
// swiftlint:disable all
import Alamofire
import LarkRustHTTP
import LKCommonsLogging
import RxSwift
import WebBrowser
import LarkOPInterface
import LarkAccountInterface
import WebKit
import LarkContainer

class ConfigHandler: JsAPIHandler, UserResolverWrapper {
    static let logger = Logger.oplog(ConfigHandler.self, category: "Module.JSSDK")

    let disposeBag = DisposeBag()

    private let apiBizCode: UInt = 33
    
    @ScopedProvider private var userService: PassportUserService?
    
    let userResolver: UserResolver
        
    init(resolver: UserResolver) {
        userResolver = resolver
    }
    
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        guard let appId = args["appId"] as? String,
            let timestamp = args["timestamp"] as? TimeInterval,
            let nonceStr = args["nonceStr"] as? String,
            let signature = args["signature"] as? String,
            let jsApiList = args["jsApiList"] as? [String] else {
            // 日志里不要裸打args，里面可能包含了用户传过来的signature等信息
            ConfigHandler.logger.error("SDK config invalid params", additionalData: ["args": "\(args.keys)"])
            callback.callbackFailure(param: NewJsSDKErrorAPI.badArgumentType(extraMsg: "鉴权参数类型错误").description())
                return
        }
        
        guard let userService else {
            Self.logger.error("resolve PassportUserService failed")
            callback.callbackFailure(param: NewJsSDKErrorAPI.resolveServiceError.description())
            return
        }

        let currentURL = api.webView.url
        // 此处与安卓/PC对齐，真正去鉴权的URL是去掉fragment的（微信和钉钉也是如此）
        let configURL = currentURL?.removeFragment()
        ConfigHandler.logger.info("SDK configURL is nil? \(configURL == nil)")

        let parameters: [String: Any] = [
            "tenant_id": userService.userTenant.tenantID,   //  如果这里不修改，可能存在隐藏的bug，原来是对象生成的时候传入，如果切换了租户或者身份变化就错了。为了避免这个假设导致问题，改为用的时候获取
            "app_id": appId,
            "url": configURL?.absoluteString ?? "",
            "timestamp": timestamp,
            "nonce_str": nonceStr,
            "signature": signature,
            "js_api_list": jsApiList
        ]
        let headers: HTTPHeaders = ["X-Session-ID": userService.user.sessionKey ?? ""]    //  如果这里不修改，可能存在隐藏的bug，原来是对象生成的时候传入，如果切换了租户或者身份变化就错了。为了避免这个假设导致问题，改为用的时候获取

        let url = OpenPlatformNetworkAPI(resolver: sdk.resolver).h5VerifyUrl
        ConfigHandler.logger.info("SDK verifyURL is：\(url)")
        //  当前调用config的webpage
        let webpageForConfig = api.currentWebPage
        sdk.sessionManager
            .request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { [weak sdk] (response) in
                guard let sdk = sdk else { return }

                let callOnSuccess = { (args: Any) in
                    callback.callbackSuccess(param: args)
                }

                let callonFailed = { (args: Any) in
                    callback.callbackFailure(param: args)
                }

                // check for errors
                if let error = response.result.error {
                    ConfigHandler.logger.error("SDK request network internal error", error: error)
                    callonFailed(NewJsSDKErrorAPI.requestError.description())
                    return
                }

                // make sure we got some JSON since that's what we expect
                guard let json = response.result.value as? [String: Any],
                    let code = json["code"] as? Int else {
                        ConfigHandler.logger.error("SDK request biz internal json error", additionalData: ["result": "\(String(describing: response.result.value))"])
                        callonFailed(NewJsSDKErrorAPI.wrongDataFormat.description())
                        return
                }
                let msg = json["msg"] as? String ?? ""
                ConfigHandler.logger.info("SDK request success code=\(code) msg=\(msg)")
                if code == 0 {
                    // code 为 0 代表成功
                    /*
                    guard let url = currentURL, let data = json["data"] as? [String: String] else {
                     */
                    //  之前的代码强制要求必须是[String: String]，后端一旦在接口给出的value包含非String的Value，直接会导致鉴权失败，从而酿成严重线上KA事故
                    //  高危风险已经和后端同学同步过
                    //  责任人：qihongye@bytedance.com
                    //  高风险代码引入时间：Sep 17，2019
                    //  commit msg：feat(lark): webview隐藏topbar，jssdk鉴权逻辑调整
                    guard let url = currentURL, let data = json["data"] as? [String: Any] else {
                        callonFailed(NewJsSDKErrorAPI.wrongDataFormat.description())
                        return
                    }
                    if let authSession = data["jssdk_session"] as? String {
                        sdk.authSession = authSession
                        let webAppInfo = WebAppInfo(id: appId, name: data["app_name"] as? String ?? "", iconURL: data["app_icon"] as? String, status: AppStatus.runtime.rawValue, apiAuthenStatus: .authened)
                        sdk.updateSession(webAppInfo: webAppInfo, url: currentURL, session: authSession, webpage: webpageForConfig)
                    } else {
                        ConfigHandler.logger.warn("配置接口返回数据异常, jssdk_session为空")
                    }
                    var dict = [String: Any]()
                    if let sessionKey = data["session_key"] {
                        dict["session_key"] = sessionKey
                    }
                    let configs = jsApiList
                        .map { APIConfig(name: $0) }
                        .lf_toDictionary { $0.name }
                    sdk.update(url: url, config: SDKConfig(apiConfigs: configs))
                    callOnSuccess(dict)
                    return
                }
                if code == 2 {
                    callonFailed(NewJsSDKErrorAPI.wrongDataFormat.description())
                    return
                }
                callback.callbackFailure(param: NewJsSDKErrorAPI.customApiError(
                    api: NewJsSDKErrorAPI.Config.self,
                    innerCode: 3,
                    backendCode: code,
                    backendMsg: msg
                ).description())
            }
    }
}
// swiftlint:enable all
