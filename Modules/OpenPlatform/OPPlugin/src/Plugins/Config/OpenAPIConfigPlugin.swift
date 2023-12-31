//
//  WebBrowserConfigPlugin.swift
//  WebBrowser
//
//  Created by xiangyuanyuan on 2021/8/23.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LKCommonsLogging
import LarkAccountInterface
import WebKit
import LarkRustHTTP
import Alamofire
import RxSwift
import LarkOPInterface
import OPPluginBiz
import WebBrowser
import OPPluginManagerAdapter
import LarkContainer

enum ConfigAPICaller: String {
    case passport
    case other
}

final class OpenAPIConfigPlugin: OpenBasePlugin {
    
    @ScopedProvider private var userService: PassportUserService?
    
    private static let webEventName = "op_webapp_auth_strategy"
    
    // 迁移自原ConfigHandler 逻辑上未做改变
    func config(params: OpenAPIConfigParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIConfigResult>) -> Void) {
        let api = context.controller as? WebBrowser
        let currentURL = api?.webView.url
        // 此处与安卓/PC对齐，真正去鉴权的URL是去掉fragment的（微信和钉钉也是如此）
        let configURL = currentURL?.removeFragment()
        context.apiTrace.info("SDK configURL is nil? \(configURL == nil)")
        var apiCaller: ConfigAPICaller = .other
        // 主动config信息记录埋点
        OPMonitor(name: OpenAPIConfigPlugin.webEventName, code: EPMClientOpenPlatformWebWebappAuthCode.op_webapp_auth_strategy_config)
            .addMap(["appId": params.appId,
                     "signature": params.signature.md5(),
                     "url": configURL?.safeURLString])
            .tracing(api?.getTrace())
            .flush()
        
        // config 调用开始时间戳
        let startTimeStamp = Date().timeIntervalSince1970
        
        let completionHandler: ([AnyHashable : Any]?, Error?) -> Void = {
            (result, error) in
            // check for errors
            if let error = error {
                context.apiTrace.error("SDK request network internal error", error: error)
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                errorInfo.setAddtionalInfo(OpenAPIConfigError.networkError.errorInfo)
                errorInfo.setErrno(OpenAPICommonErrno.networkFail)
                callback(.failure(error: errorInfo))
                // config 调用结束埋点
                let errorCode = OpenAPIConfigError.networkError.errorInfo["errorCode"]
                let errorMessage = OpenAPIConfigError.networkError.errorInfo["errorMessage"]
                OPMonitor("wb_detail_config_end")
                    .addMap(["appid": params.appId,
                             "host": configURL?.host?.safeURLString ?? "",
                             "end_timestamp": Date().timeIntervalSince1970,
                             "duration": Date().timeIntervalSince1970 - startTimeStamp,
                             "url": configURL?.safeURLString ?? "",
                             "result_code": errorCode,
                             "raw_err_code": errorCode,
                             "err_message": errorMessage,
                             "raw_err_message": errorMessage])
                    .tracing(api?.getTrace())
                    .flush()
                return
            }
            
            // make sure we got some JSON since that's what we expect
            guard let result = result, let code = result["code"] as? Int else {
                context.apiTrace.error("SDK request biz internal json error", additionalData: ["result": "code:\(result?["code"]), msg:\(result?["msg"])"])
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                errorInfo.setAddtionalInfo(OpenAPIConfigError.invalidDataFormat.errorInfo)
                errorInfo.setErrno(OpenAPIWebConfigErrno.serverDataException)
                callback(.failure(error: errorInfo))
                // config 调用结束埋点
                let errorCode = OpenAPIConfigError.invalidDataFormat.errorInfo["errorCode"]
                let errorMessage = OpenAPIConfigError.invalidDataFormat.errorInfo["errorMessage"]
                OPMonitor("wb_detail_config_end")
                    .addMap(["appid": params.appId,
                             "host": configURL?.host?.safeURLString ?? "",
                             "end_timestamp": Date().timeIntervalSince1970,
                             "duration": Date().timeIntervalSince1970 - startTimeStamp,
                             "url": configURL?.safeURLString ?? "",
                             "result_code": errorCode,
                             "raw_err_code": errorCode,
                             "err_message": errorMessage,
                             "raw_err_message": errorMessage])
                    .tracing(api?.getTrace())
                    .flush()
                return
            }
            
            let msg = result["msg"] as? String ?? ""
            context.apiTrace.info("SDK request success code=\(code) msg=\(msg)")
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
                guard let url = currentURL, let data = result["data"] as? [String: Any] else {
                    let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    errorInfo.setAddtionalInfo(OpenAPIConfigError.invalidDataFormat.errorInfo)
                    errorInfo.setErrno(OpenAPIWebConfigErrno.serverDataException)
                    callback(.failure(error: errorInfo))
                    // config 调用结束埋点
                    let errorCode = OpenAPIConfigError.invalidDataFormat.errorInfo["errorCode"]
                    let errorMessage = OpenAPIConfigError.invalidDataFormat.errorInfo["errorMessage"]
                    OPMonitor("wb_detail_config_end")
                        .addMap(["appid": params.appId,
                                 "host": configURL?.host?.safeURLString ?? "",
                                 "end_timestamp": Date().timeIntervalSince1970,
                                 "duration": Date().timeIntervalSince1970 - startTimeStamp,
                                 "url": configURL?.safeURLString ?? "",
                                 "result_code": errorCode,
                                 "raw_err_code": errorCode,
                                 "err_message": errorMessage,
                                 "raw_err_message": errorMessage])
                        .tracing(api?.getTrace())
                        .flush()
                    return
                }
                callback(.success(data: OpenAPIConfigResult(data: result, currentURL: currentURL, jsApiList: params.jsApiList ?? [], appId: params.appId, apiCaller: apiCaller)))
                // config 调用结束埋点
                let errorCode = ""
                let errorMessage = ""
                OPMonitor("wb_detail_config_end")
                    .addMap(["appid": params.appId,
                             "host": configURL?.host?.safeURLString ?? "",
                             "end_timestamp": Date().timeIntervalSince1970,
                             "duration": Date().timeIntervalSince1970 - startTimeStamp,
                             "url": configURL?.safeURLString ?? "",
                             "result_code": 0,
                             "raw_err_code": errorCode,
                             "err_message": errorMessage,
                             "raw_err_message": errorMessage])
                    .tracing(api?.getTrace())
                    .flush()
                return
            }
            
            if code == 2 {
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                errorInfo.setAddtionalInfo(OpenAPIConfigError.invalidDataFormat.errorInfo)
                errorInfo.setErrno(OpenAPIWebConfigErrno.serverDataException)
                callback(.failure(error: errorInfo))
                // config 调用结束埋点
                let errorCode = OpenAPIConfigError.invalidDataFormat.errorInfo["errorCode"]
                let errorMessage = OpenAPIConfigError.invalidDataFormat.errorInfo["errorMessage"]
                OPMonitor("wb_detail_config_end")
                    .addMap(["appid": params.appId,
                             "host": configURL?.host?.safeURLString ?? "",
                             "end_timestamp": Date().timeIntervalSince1970,
                             "duration": Date().timeIntervalSince1970 - startTimeStamp,
                             "url": configURL?.safeURLString ?? "",
                             "result_code": errorCode,
                             "raw_err_code": errorCode,
                             "err_message": errorMessage,
                             "raw_err_message": errorMessage])
                    .tracing(api?.getTrace())
                    .flush()
                return
            }
            
            // 与安卓同学对齐过 若result中的data不存在 那么说明不是服务端业务错误 直接返回通用的10001
            if result["data"] == nil {
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                errorInfo.setAddtionalInfo(OpenAPIConfigError.networkError.errorInfo)
                errorInfo.setErrno(OpenAPICommonErrno.networkFail)
                callback(.failure(error: errorInfo))
                // config 调用结束埋点
                let errorCode = OpenAPIConfigError.networkError.errorInfo["errorCode"]
                let errorMessage = OpenAPIConfigError.networkError.errorInfo["errorMessage"]
                OPMonitor("wb_detail_config_end")
                    .addMap(["appid": params.appId,
                             "host": configURL?.host?.safeURLString ?? "",
                             "end_timestamp": Date().timeIntervalSince1970,
                             "duration": Date().timeIntervalSince1970 - startTimeStamp,
                             "url": configURL?.safeURLString ?? "",
                             "result_code": errorCode,
                             "raw_err_code": errorCode,
                             "err_message": errorMessage,
                             "raw_err_message": errorMessage])
                    .tracing(api?.getTrace())
                    .flush()
                return
            }
            
            let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            errorInfo.setAddtionalInfo(OpenAPIConfigError.bizError(code: code, msg: msg).errorInfo)
            let errorCode = OpenAPIConfigError.bizError(code: code, msg: msg).errorInfo["errorCode"] ?? 10001
            errorInfo.setErrno(OpenAPIWebConfigErrno.serverInspectError(errorDesc: msg, errorCode: "\(errorCode)"))
            callback(.failure(error: errorInfo))
            // config 调用结束埋点
            let errorMessage = OpenAPIConfigError.bizError(code: code, msg: msg).errorInfo["errorMessage"]
            OPMonitor("wb_detail_config_end")
                .addMap(["appid": params.appId,
                         "host": configURL?.host?.safeURLString ?? "",
                         "end_timestamp": Date().timeIntervalSince1970,
                         "duration": Date().timeIntervalSince1970 - startTimeStamp,
                         "url": configURL?.safeURLString ?? "",
                         "result_code": errorCode,
                         "raw_err_code": code,
                         "err_message": errorMessage,
                         "raw_err_message": msg])
                .tracing(api?.getTrace())
                .flush()
        }
        
        guard let userService else {
            callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve PassportUserService failed")))
            return
        }
        
        var parameters: [String : Any] = [
            "tenant_id": userService.userTenant.tenantID,   //  如果这里不修改，可能存在隐藏的bug，原来是对象生成的时候传入，如果切换了租户或者身份变化就错了。为了避免这个假设导致问题，改为用的时候获取
            "app_id": params.appId,
            "url": configURL?.absoluteString ?? "",
            "timestamp": params.timestamp,
            "nonce_str": params.nonceStr,
            "signature": params.signature,
            "js_api_list": params.jsApiList ?? []
        ]
        // 判断是否是passport发起的调用
        let networkContext = OpenECONetworkContext(trace: context.getTrace(), source: .api)
        if params.type == .userAccessToken {
            apiCaller = .passport
            parameters["open_id"] = params.openId
            parameters["device_id"] = params.deviceId
            EMAAPINetworkInterface.webVerify(with: networkContext, needSession: false, parameters: parameters, completionHandler: completionHandler)
        } else {
            EMAAPINetworkInterface.webVerify(with: networkContext, needSession: true, parameters: parameters, completionHandler: completionHandler)
        }
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "config", pluginType: Self.self, paramsType: OpenAPIConfigParams.self, resultType: OpenAPIConfigResult.self){ (this, params, context, callback) in
            
            this.config(params: params, context: context, callback: callback)
        }
    }
}


