//
//  OpenPluginUser+Login.swift
//  OPPlugin
//
//  Created by zhangxudong on 3/7/22.
//

import LarkOpenPluginManager
import LarkOpenAPIModel
import TTMicroApp
import OPPluginManagerAdapter
import ECOInfra
import LarkAccountInterface
import LarkContainer
import SwiftUI
/// login 请求后的callback
private typealias CompletionHandler = (_ response: OPenAPINetworkLoginModel?,
                                       _ error: Error?,
                                       _ requestID: String?) -> Void
/// OpenAPI Login每一步可能出现的错误
private enum OpenAPILoginStepError: Error {
    /// 获取gadgetContext 失败
    case gadgetContext
    /// 获取larkSession 失败
    case larkSession
    /// 发送请求失败
    case startRequest
    /// 请求返回 task error 不为nil (error)
    case responseError(Error)
    /// 请求返回的 json 是空 或者nil
    case responseModelNil
    /// 请求返回的session 为 nil (code, msg)
    case responseSessionNil(Int?, String?)
    /// 请求返回的 json 中 error 不为 0 参数为bizCode (code, msg)
    case responseModelBizErrorCode(Int?, String?)
    /// 请求返回的 data code 为 nil || "" (code, msg)
    case responseModelCodeNil(Int?, String?)
    /// 更新 Session 缓存
    case updateSessionCache
    
    var description: String {
        switch self {
        case .gadgetContext:
            return "gadgetContext"
        case .larkSession:
            return "larkSession"
        case .startRequest:
            return "startRequest"
        case .responseError(let err):
            return "responseError(\(responseErrorDetail(err))"
        case .responseModelNil:
            return "responseModelNil"
        case .responseSessionNil(let code, let msg):
            return "responseSessionNil(code:\(code ?? 0), msg:\(msg ?? ""))"
        case .responseModelBizErrorCode(let code, let msg):
            return "responseModelBizErrorCode(code:\(code ?? 0), msg:\(msg ?? ""))"
        case .responseModelCodeNil(let code, let msg):
            return  "responseModelCodeNil(code:\(code ?? 0), msg:\(msg ?? ""))"
        case .updateSessionCache:
            return "updateSessionCache"
        }
    }
    
    private func responseErrorDetail(_ error: Error) -> String {
        guard let ecoNetworkError = error as? ECONetworkError else {
            return error.localizedDescription
        }
        
        switch ecoNetworkError {
        case .http(let err):
            return "httpError:(code:\(err.code), msg:\(err.msg ?? ""))"
        case .cancel:
            return "cancel"
        case .middewareError(let err):
            return err is ECONetworkError ? responseErrorDetail(err) : "middewareError:\(err.localizedDescription)"
        case .validateFail(let err):
            return err is ECONetworkError ? responseErrorDetail(err) : "validateFail:\(err.localizedDescription)"
        case .networkError(let err):
            return err is ECONetworkError ? responseErrorDetail(err) : "networkError:\(err.localizedDescription)"
        case .requestError(let err):
            return err is ECONetworkError ? responseErrorDetail(err) : "requestError:\(err.localizedDescription)"
        case .responseError(let err):
            return err is ECONetworkError ? responseErrorDetail(err) : "responseError:\(err.localizedDescription)"
        case .serilizeRequestFail(let err):
            return err is ECONetworkError ? responseErrorDetail(err) : "serilizeRequestFail:\(err.localizedDescription)"
        case .serilizeResponseFail(let err):
            return err is ECONetworkError ? responseErrorDetail(err) : "serilizeResponseFail:\(err.localizedDescription)"
        case .innerError(let opErr):
            return "innerOPError:\(opErr.monitorCode.code)"
        default:
            return "unknown"
        }
    }
}

extension OpenAPILoginStepError {
    /// 将内部错误转换为 APIError 并且 log
    var openAPIError: OpenAPIError {
        let result: OpenAPIError
        switch self {
        case .gadgetContext, .larkSession, .startRequest, .responseError, .responseModelNil:
            result = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
        case .responseSessionNil, .responseModelBizErrorCode, .responseModelCodeNil:
            result = OpenAPIError(code: OpenAPILoginErrorCode.serverError)
                .setErrno(OpenAPILoginErrno.serverError)
        case .updateSessionCache:
            result = OpenAPIError(code: OpenAPILoginErrorCode.updateSessionFailed)
                .setErrno(OpenAPILoginErrno.syncSession)
        }
        result.setMonitorMessage("login step error:" + self.description)
        return result
    }
}



/// login API 的相关逻辑
extension OpenPluginUser {
    /// login https://open.feishu.cn/document/uYjL24iN/uYzMuYzMuYzM
    /// 多端一致 https://bytedance.feishu.cn/wiki/wikcn7Rp4Tg4KrLl2ZwfjKMxcdg
    func login(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: @escaping (OpenAPIBaseResponse<OpenPluginUserLoginResult>) -> Void) {
        context.apiTrace.info("enter login api")
        guard let userService else {
            callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolver PassportUserService failed")))
            return
        }
        
        do {
            let uniqueID = gadgetContext.uniqueID
            context.apiTrace.info("get uniqueID: \(uniqueID) done")
            let larkSession = try larkSession()
            context.apiTrace.info("get larkSession done")
            // 发起 login 请求且处理网络返回以及API回调
            let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
            // 提前声明 monitor 因为需要timming 计时
            let monitor = OPMonitor(kEventName_mp_login_result).setUniqueID(uniqueID).tracing(trace).timing()
            try Self.request(context: context, gadgetContext: gadgetContext, appID: uniqueID.appID, sessionID: removeLarkSessionFromReqBody ? nil : larkSession, completionHandler: {
                response, taskError, requestID in
                do {
                    monitor.addCategoryValue(kEventKey_request_id, requestID)
                    if let taskError {
                        monitor
                            .setResultTypeFail()
                            .addMap([kEventKey_error_msg: "request taskError"])
                            .flush()
                        throw OpenAPILoginStepError.responseError(taskError)
                    }
                    context.apiTrace.info("login response taskError nil")
                    // response 的 model 有效
                    guard let response = response else {
                        monitor
                            .setResultTypeFail()
                            .addMap([kEventKey_error_msg: "Response Data Error"])
                            .flush()
                        throw OpenAPILoginStepError.responseModelNil
                    }
                    context.apiTrace.info("login response model \(response) ")
                    let result = try Self.verifyResponse(model: response)
                    context.apiTrace.info("start login reqeust parseResonse done")
                    // 是否命中 一方应用高性能登录改造
                    var firstPartyLoginOptEnabled: Bool? = nil
                    if FirstPartyMicroAppLoginOpt.shared.cookieValidForUniqueID(uniqueID) {
                        firstPartyLoginOptEnabled = true
                    }
                    if self.authCodeUnify, let autoConfirm = result.autoConfirm, !autoConfirm, let scope = result.scope, !scope.isEmpty {
                        let openAppType = OpenPluginRequestAccessAPI.openAppTypeValueFromOPAppType(uniqueID.appType)
                        let authParams = OpenAPIAuthParams(appID: uniqueID.appID, scope: scope, openAppType: openAppType)
                        var onceFlag = false
                        userService.requestOpenAPIAuth(params: authParams) { authResult in
                            if onceFlag { return } // 回调保护
                            onceFlag = true
                            switch authResult {
                            case .success(let payload):
                                do {
                                    guard let session = payload.extra?["open_session"] as? String, !session.isEmpty else {
                                        throw OpenAPIError(errno: OpenAPIRequestAccessErrno.emptySession)
                                    }
                                    try OpenPluginUser.updateSession(session, for: uniqueID)
                                    Self.loginSuccessMonitor(monitor: monitor, message: result.message, errorCode: result.errorCode)
                                    callback(.success(data: OpenPluginUserLoginResult(code: payload.code, firstPartyLoginOptEnabled: firstPartyLoginOptEnabled)))
                                } catch let error as OpenAPILoginStepError {
                                    Self.trace(for: error, context: context)
                                    callback(.failure(error: error.openAPIError))
                                    monitor.setResultTypeFail().setError(error).timing().flush()
                                } catch let apiError as OpenAPIError {
                                    context.apiTrace.info("request api auth apiError, errnoInfo:\(apiError.errnoInfo)")
                                    Self.loginSuccessMonitor(monitor: monitor, message: result.message, errorCode: result.errorCode)
                                    callback(.success(data: OpenPluginUserLoginResult(code: result.code, firstPartyLoginOptEnabled: firstPartyLoginOptEnabled)))
                                } catch {
                                    context.apiTrace.info("request api auth error:\(error.localizedDescription)")
                                    Self.loginSuccessMonitor(monitor: monitor, message: result.message, errorCode: result.errorCode)
                                    callback(.success(data: OpenPluginUserLoginResult(code: result.code, firstPartyLoginOptEnabled: firstPartyLoginOptEnabled)))
                                }
                            case .failure(let authError):
                                Self.loginSuccessMonitor(monitor: monitor, message: result.message, errorCode: result.errorCode)
                                callback(.success(data: OpenPluginUserLoginResult(code: result.code, firstPartyLoginOptEnabled: firstPartyLoginOptEnabled)))
                                switch authError {
                                case .error(let errorInfo):
                                    context.apiTrace.info("request api auth authError,code:\(errorInfo.code), msg:\(errorInfo.message)")
                                @unknown default:
                                    context.apiTrace.info("request api auth error, unknown")
                                }
                            }
                        }
                    } else {
                        // 缓存session
                        try Self.updateSession(result.session, for: uniqueID)
                        context.apiTrace.info("updateSession done")
                        Self.loginSuccessMonitor(monitor: monitor, message: result.message, errorCode: result.errorCode)
                        callback(.success(data: OpenPluginUserLoginResult(code: result.code, firstPartyLoginOptEnabled: firstPartyLoginOptEnabled)))
                    }
                    context.apiTrace.info("login api callback success")
                } catch let error as OpenAPILoginStepError {
                    Self.trace(for: error, context: context)
                    callback(.failure(error: error.openAPIError))
                    monitor.setResultTypeFail().setError(error).timing().flush()
                } catch let error as OpenAPIError {
                    callback(.failure(error: error))
                    monitor.setResultTypeFail().setError(error).timing().flush()
                } catch {
                    let message = "error is not a OpenAPIError, error: \(error)"
                    assertionFailure(message)
                    context.apiTrace.error(message)
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.unknown)
                        .setMonitorMessage(message)
                    callback(.failure(error: error))
                    monitor.setResultTypeFail().setError(error).timing().flush()
                }
            })
            context.apiTrace.info("start login reqeust done")
        } catch let error as OpenAPILoginStepError {
            Self.trace(for: error, context: context)
            callback(.failure(error: error.openAPIError))
        } catch {
            let message = "error is not a OpenAPIError, error: \(error)"
            assertionFailure(message)
            context.apiTrace.error(message)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage(message)
            callback(.failure(error: error))
        }
    }

    private static func loginSuccessMonitor(monitor: OPMonitor, message: String?, errorCode: Int) {
        monitor.addCategoryValue(kEventKey_result_type, kEventValue_success)
            .timing()
            .addCategoryValue(kEventKey_error_code, errorCode)
            .addCategoryValue(kEventKey_error_msg, message)
            .flush()
    }

    private static func trace(for stepError: OpenAPILoginStepError, context: OpenAPIContext) {
        context.apiTrace.error("login step error:" + stepError.description)
    }
    /// 发起 login 请求
    private static func request(context: OpenAPIContext,
                                gadgetContext: OPAPIContextProtocol,
                                appID: String,
                                sessionID: String?,
                                completionHandler: @escaping CompletionHandler) throws {
        let networkService = Injected<ECONetworkService>().wrappedValue
        let networkContext = OpenECONetworkAppContext(trace: context.getTrace(), uniqueId: gadgetContext.uniqueID, source: .api)
        let config = UserLoginRequestConfig.self
        // 这里提前声明task 是为了拿到 task的 requestID
        // 因为 生成requesID是异步的所以只有在 请求返回之后才能确定 reqeustID可用
        let appType = gadgetContext.uniqueID.appType
        let appTypeValue = OpenPluginRequestAccessAPI.openAppTypeValueFromOPAppType(appType)
        var task: ECONetworkServiceTask<OPenAPINetworkLoginModel>?
        var params: [String : Codable] = ["appid": appID, "app_type": appTypeValue ?? -1]
        if let sessionID {
            params["sessionid"] = sessionID
        }
        task = networkService.createTask(context: networkContext,
                                         config: config,
                                         params: params,
                                         callbackQueue: DispatchQueue.main) {
            (response, error) in
            //如果 task 初始化成功 且由于框架原因没有执行到 网络callback 则会存在 retain cycle
            let requestID = Self.requestID(context: context, task: task)
            task = nil
            completionHandler(response?.result, error, requestID)
        }
        guard let requestTask = task else {
            throw OpenAPILoginStepError.startRequest
        }
        networkService.resume(task: requestTask)
    }
    
#if DEBUG
    /// 单测需要
    static var mockSession: String?
    static var mockUpdateSessionSuccess: Bool?
#endif
    /// 从passport获取LarkSession
    func larkSession() throws -> String {
#if DEBUG
        /// 单测需要
        if let mockSession = Self.mockSession {
            return mockSession
        }
#endif
        guard let userService else {
            throw OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve PassportUserService failed")
        }
        guard let session = userService.user.sessionKey else {
            throw OpenAPILoginStepError.larkSession
        }
        
        return session
    }

    /// 在sandbox 中更新 session 目前不阻断主逻辑
    static func updateSession(_ session: String,
                              for uniqueID: OPAppUniqueID) throws {
        guard let sessionManager = TMASessionManager.shared() else {
            throw OpenAPILoginStepError.updateSessionCache
        }
#if DEBUG
        /// 单测需要 
        if let mockUpdateSessionSuccess = Self.mockUpdateSessionSuccess {
            if !mockUpdateSessionSuccess {
                throw OpenAPILoginStepError.updateSessionCache
            }
            return
        }
#endif
        let module = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPStorageModuleProtocol.self)
        guard let storageModule = module as? BDPStorageModuleProtocol,
              let sandbox = storageModule.sandbox(for: uniqueID) else {
                  throw OpenAPILoginStepError.updateSessionCache
              }
        sessionManager.updateSession(session, sandbox: sandbox)
    }

    /// 验证数据正确的条件
    /// 1. errcode == 0 thorw OpenAPILoginStepError.resoonseSessionNil
    /// 2. session 不为空 throw OpenAPILoginStepError.responseModelBizErrorCode
    /// 3. code 不为空 throw OpenAPILoginStepError.responseModelCodeNil
    private static func verifyResponse(model: OPenAPINetworkLoginModel) throws -> (session: String, code: String, message: String?, errorCode: Int, autoConfirm: Bool?, scope: String?) {

        guard let session = model.session, !session.isEmpty else {
            throw OpenAPILoginStepError.responseSessionNil(model.errorCode, model.message)
        }
        let bizErrorCode = model.errorCode ?? 0
        guard  bizErrorCode == 0 else {
            throw OpenAPILoginStepError.responseModelBizErrorCode(model.errorCode, model.message)
        }
        guard let code = model.data?.code, !code.isEmpty else {
            throw OpenAPILoginStepError.responseModelCodeNil(model.errorCode, model.message)
        }
        return (session: session,
                code: code,
                message: model.message,
                errorCode: bizErrorCode, autoConfirm: model.autoConfirm, scope: model.scope)
    }

    // 从task 中获取 reqeustID
    public static func requestID(context: OpenAPIContext,
                                 task: ECONetworkServiceTaskProtocol?)
    -> String? {
        guard let requestID = task?.trace.getRequestID(), !requestID.isEmpty else {
            let message = "requestID is nil"
            assertionFailure(message)
            context.apiTrace.error(message)
            return nil
        }
        return requestID

    }
}
