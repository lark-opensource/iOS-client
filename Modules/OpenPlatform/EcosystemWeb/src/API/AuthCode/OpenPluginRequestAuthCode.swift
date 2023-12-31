//
//  OpenPluginRequestAuthCode.swift
//  OPPlugin
//
//  Created by 新竹路车神 on 2021/8/16.
//

import ECOInfra
import LarkAccountInterface
import LarkAppConfig
import LarkContainer
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkWebViewContainer
import LKCommonsLogging
import OPSDK
import RustPB
import WebBrowser
import OPFoundation
import LarkSetting

/// RequestAuthCode
final class RequestAuthCodePlugin: OpenBasePlugin {
    
    @RealTimeFeatureGatingProvider(key: "openplatform.api.incremental_auth") var authCodeUnify: Bool
    
    @Provider var userService: PassportUserService
    
    let resolver: UserResolver
    
    required init(resolver: UserResolver) {
        self.resolver = resolver
        super.init(resolver: resolver)
        /// 注册 requestAuthCode 到 API 框架
        registerInstanceAsyncHandler(for: "requestAuthCode", pluginType: Self.self, paramsType: OpenAPIRequestAuthCodeParams.self, resultType: OpenAPIRequestAuthCodeResult.self) { this, params, context, callback in
            this.requestAuthCode(params: params, context: context, callback: callback)
        }
    }
    
    func requestAuthCode(params: OpenAPIRequestAuthCodeParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIRequestAuthCodeResult>) -> Void) {
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                error.setErrno(OpenAPICommonErrno.unknown)
                context.apiTrace.error("gadgetContext is nil")
                callback(.failure(error: error))
                return
            }
            guard let browser = apiContext.controller as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("apiContext.controller is not WebBrowser")
                error.setErrno(OpenAPICommonErrno.unknown)
                context.apiTrace.error("apiContext.controller is not WebBrowser")
                callback(.failure(error: error))
                return
            }

            // requestAuthCode 调用开始时间戳
            let startTimeStamp = Date().timeIntervalSince1970
            
            let trace = context.apiTrace
            let networkContext = OpenECONetworkWebContext(trace: trace, source: .web)
            RequestAuthCodeNetwork.requestAuthCode(with: params.appId, url: browser.webview.url, context: networkContext, resolver: resolver) {
                [weak browser, weak self] result in
                guard let browser, let self else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setErrno(OpenAPICommonErrno.internalError)
                        .setMonitorMessage("no browser or no self")
                    return callback(.failure(error: error))
                }
                switch result {
                case .success(let res):
                    if let code = res["code"] as? Int, code == 0, let data = res["data"] as? [String: Any] {
                        var callbackData: [String: Any] = [:]
                        callbackData["code"] = data["code"]
                        callbackData["session"] = data["session"]
                        if self.authCodeUnify, data["auto_confirm"] as? Bool == false, let scope = data["scope"] as? String, !scope.isEmpty {
                            let authParams = OpenAPIAuthParams(appID: params.appId, scope: scope, redirectUri: browser.webview.url?.absoluteString, openAppType: 2)
                            var onceFlag = false
                            self.userService.requestOpenAPIAuth(params: authParams) { result in
                                if onceFlag { return } // 回调保护
                                onceFlag = true
                                switch result {
                                case .success(let payload):
                                    callbackData["code"] = payload.code
                                    callback(.success(data: OpenAPIRequestAuthCodeResult(data: callbackData)))
                                case .failure(let authError):
                                    switch authError {
                                    case .error(let errorInfo):
                                        context.apiTrace.error("apiContext authFailed, code:\(errorInfo.code), msg:\(errorInfo.message)")
                                        callback(.success(data: OpenAPIRequestAuthCodeResult(data: callbackData)))
                                    @unknown default:
                                        callback(.success(data: OpenAPIRequestAuthCodeResult(data: callbackData)))
                                    }
                                }
                            }
                        } else {
                            callback(.success(data: OpenAPIRequestAuthCodeResult(data: callbackData)))
                        }
                        
                        context.apiTrace.info("network success, code:\(code), msg:\(res["msg"] as? String)")
                        // requestAuthCode 调用结束埋点
                        let errorCode = ""
                        let errorMessage = ""
                        OPMonitor("wb_detail_requestAuthCode_end")
                            .addMap(["appid": params.appId,
                                     "host": browser.webview.url?.host?.safeURLString ?? "",
                                     "end_timestamp": Date().timeIntervalSince1970,
                                     "duration": Date().timeIntervalSince1970 - startTimeStamp,
                                     "url": browser.webview.url?.safeURLString ?? "",
                                     "result_code": 0,
                                     "raw_err_code": errorCode,
                                     "err_message": errorMessage,
                                     "raw_err_message": errorMessage])
                            .tracing(trace)
                            .flush()
                    } else {
                        // 原逻辑为 networkError, CommoneErrorCode 不应当包含 networkError（因为每个 API 场景含义不同）。
                        // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                        // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                        let errorCode = res["code"] as? Int ?? OpenAPICommonErrorCode.internalError.rawValue
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                            .setOuterCode(res["code"] as? Int ?? OpenAPICommonErrorCode.internalError.rawValue)
                            .setOuterMessage(res["msg"] as? String ?? "")
                            .setErrno(OpenAPIWebAutoLoginErrno.serverInspectError(errorDesc: res["msg"] as? String ?? "", errorCode: "\(errorCode)"))
                        callback(.failure(error: error))
                        context.apiTrace.error("failure, code:\(res["code"] as? Int), msg:\(res["msg"] as? String)")
                        // requestAuthCode 调用结束埋点
                        let errorMessage = res["msg"] as? String ?? ""
                        OPMonitor("wb_detail_requestAuthCode_end")
                            .addMap(["appid": params.appId,
                                     "host": browser.webview.url?.host?.safeURLString ?? "",
                                     "end_timestamp": Date().timeIntervalSince1970,
                                     "duration": Date().timeIntervalSince1970 - startTimeStamp,
                                     "url": browser.webview.url?.safeURLString ?? "",
                                     "result_code": errorCode,
                                     "raw_err_code": res["code"] as? Int ?? "",
                                     "err_message": errorMessage,
                                     "raw_err_message": res["msg"] as? String ?? ""])
                            .tracing(trace)
                            .flush()
                    }
                case .failure(let err):
                    // 原逻辑为 networkError, CommoneErrorCode 不应当包含 networkError（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("network error")
                        .setError(err)
                        .setErrno(OpenAPICommonErrno.networkFail)
                    callback(.failure(error: error))
                    context.apiTrace.error("network error")
                    // requestAuthCode 调用结束埋点
                    let errorCode = ""
                    let errorMessage = "network error"
                    OPMonitor("wb_detail_requestAuthCode_end")
                        .addMap(["appid": params.appId,
                                 "host": browser.webview.url?.host?.safeURLString ?? "",
                                 "end_timestamp": Date().timeIntervalSince1970,
                                 "duration": Date().timeIntervalSince1970 - startTimeStamp,
                                 "url": browser.webview.url?.safeURLString ?? "",
                                 "result_code": errorCode,
                                 "raw_err_code": errorCode,
                                 "err_message": errorMessage,
                                 "raw_err_message": errorMessage])
                        .tracing(trace)
                        .flush()
            }
        }
    }
}

final class OpenAPIRequestAuthCodeParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "appId", validChecker: OpenAPIValidChecker.notEmpty)
    public var appId: String
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_appId]
    }
}

final class OpenAPIRequestAuthCodeResult: OpenAPIBaseResult {
    public let data: [String: Any]
    public init(data: [String: Any]) {
        self.data = data
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        data
    }
}

enum RequestAuthCodeNetworkError: String, Error {
    case noResponseNoError
    case createTaskError
}

class RequestAuthCodeNetwork {
    
    static let logger = Logger.ecosystemWebLog(RequestAuthCodeNetwork.self, category: "RequestAuthCodeNetwork")
    
    private static var service: ECONetworkService {
        Injected<ECONetworkService>().wrappedValue
    }
    //  后端请求文档：https://bytedance.feishu.cn/wiki/wikcnaXy3ZGrGopAFwEUTMw1cwe
    static func requestAuthCode(with appID: String, url: URL?, context: ECONetworkServiceContext, resolver: Resolver?, completionHandler: @escaping (Result<[String: Any], Error>) -> Void) {
        var params = [
            "appid": appID,
            "url": url?.absoluteString ?? ""
        ]
        if !FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.network.remove_larksession_from_req_body"), let userService = try? resolver?.resolve(assert: PassportUserService.self) {// user:global
            params["sessionid"] = userService.user.sessionKey
        }
        let task = service.createTask( 
            context: context,
            config: AuthCodeRequestConfig.self,
            params: params, // 用了 ECORequestBodyJSONSerializer params 会放到 body 里
            callbackQueue: DispatchQueue.main
        ) { res, err in
            var logID = (res?.response.allHeaderFields["x-tt-logid"]) ?? "empty logid"
            logger.info("finish requestAuthCode, appID:\(appID) and url.safeURLString:\(url?.safeURLString), logID:\(logID)")
            if let error = err {
                completionHandler(.failure(error))
                return
            }
            if let result = res?.result {
                completionHandler(.success(result))
                return
            }
            completionHandler(.failure(RequestAuthCodeNetworkError.noResponseNoError))
        }
        guard let requestTask = task else {
            logger.error("create task fail")
            assertionFailure("create task fail")
            completionHandler(.failure(RequestAuthCodeNetworkError.createTaskError))
            return
        }
        logger.info("start requestAuthCode, appID:\(appID) and url.safeURLString:\(url?.safeURLString)")
        service.resume(task: requestTask)
    }
}

struct AuthCodeRequestConfig: ECONetworkRequestConfig {
    
    typealias ParamsType = [String: Any]
    
    typealias ResultType = [String: Any]
    
    typealias RequestSerializer = ECORequestBodyJSONSerializer
    
    typealias ResponseSerializer = ECOResponseJSONObjSerializer<[String: Any]>
    
    static var path: String { "/open-platform/api/LoginH5" }
    
    static var method: ECONetworkHTTPMethod { .POST }
    
    static var requestSerializer: ECORequestBodyJSONSerializer { ECORequestBodyJSONSerializer() }
    
    static var responseSerializer: ECOResponseJSONObjSerializer<[String: Any]> { ECOResponseJSONObjSerializer<[String: Any]>() }
    
    static var initialHeaders: [String : String] { [
        "Content-Type": "application/json"
    ]}
    
    static var middlewares: [ECONetworkMiddleware] {
        [
            BrowserDomainMiddleware(alias: .open),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ] as [ECONetworkMiddleware]
    }
}

enum BrowserDomainMiddlewareError: String, Error {
    case hasNoAliasOpenDomain
}

/// Domain 获取中间件
class BrowserDomainMiddleware: ECONetworkMiddleware {
    
    private let alias: InitSettingKey
    
    init(alias: InitSettingKey) {
        self.alias = alias
    }
    
    private var appConfiguration: AppConfiguration {
        Injected<AppConfiguration>().wrappedValue
    }
    
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest,Error> {
        var request = request
        guard let domain = appConfiguration.settings[alias]?.first else {
            return .failure(BrowserDomainMiddlewareError.hasNoAliasOpenDomain)
        }
        request.domain = domain
        return .success(request)
    }
}
