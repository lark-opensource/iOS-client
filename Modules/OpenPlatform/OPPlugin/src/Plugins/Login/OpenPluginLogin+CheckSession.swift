//
//  OpenPluginLogin+CheckSession.swift
//  OPPlugin
//
//  Created by zhangxudong on 3/10/22.
//

import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import ECOInfra
import LarkOpenAPIModel

/// CheckSession API 每一步 会出现的错误
private enum CheckSessionStepError: Error {
    /// 获取 容器的session 失败
    case containerSession
    /// 发送请求失败
    case request
    /// 请求返回 task error 不为nil
    case responseError(String?)
    /// 请求返回的 json 是空 或者nil
    case responseJSONNil(String?)
    /// 请求返回的 json 中 error 不为 0
    case responseBizErrorCode(String?, Int?, String?)
    /// 请求返回 现实 session 不可用
    case invalidSession(String?, Int?, String?)
    
    var description: String {
        switch self {
        case .containerSession:
            return "containerSession"
        case .request:
            return "request"
        case .responseError(let logID):
            return "responseError(logid:\(logID ?? "")"
        case .responseJSONNil(let logID):
            return "responseJSONNil(logid:\(logID ?? "")"
        case .responseBizErrorCode(let logID, let code, let msg):
            return "responseBizErrorCode(logid:\(logID ?? ""), code:\(code ?? 0), msg:\(msg ?? "")"
        case .invalidSession(let logID, let code, let msg):
            return "invalidSession(logid:\(logID ?? ""), code:\(code ?? 0), msg:\(msg ?? "")"
        }
    }
}

extension CheckSessionStepError {
    /// 将内部错误转换为 APIError 并且 log
    func transformAPIError() -> OpenAPIError {
        let result: OpenAPIError
        switch self {
        case .containerSession:
            result = OpenAPIError(code: CheckSessionErrorCode.emptySession)
        case .request, .responseError, .responseJSONNil:
            result = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
        case .responseBizErrorCode:
            result = OpenAPIError(code: CheckSessionErrorCode.serverError)
        case .invalidSession:
            result = OpenAPIError(code: CheckSessionErrorCode.invalidSession)
        }
        result.setMonitorMessage("checkSessionV2 CheckSessionStepError: \(self.description)")
        return result
    }
}


extension OpenPluginLogin {

    /// checkSession api 多端一致后的实现 https://bytedance.feishu.cn/wiki/wikcn6BbhGoxw8LAlQc7R87hF6d
    public func checkSession(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("checkSessionV2 api enter")
        do {
            // 检测 是否有session
            let session = try Self.session(context: gadgetContext)
            context.apiTrace.info("checkSessionV2 get session  done")

            let monitior = OPMonitor(kEventName_mp_check_session_result)
                .tracing(context.apiTrace)
                .setUniqueID(gadgetContext.uniqueID)
                .addCategoryValue("use_expire_time", false).timing()
            // alreadyCallback用于标记 是否已经 callbak 过
            // 因为
            // 1. 总是会从发起请求校验session 是否过期
            // 2. 如果 已经callback 则不需要 再次 callback
            let alreadyCallback: Bool
            // 检测session 的过期时间
            if Self.checkExpireTime(context: context) {
                context.apiTrace.info("checkSessionV2 check session expire time OK")
                callback(.success(data: nil))
                alreadyCallback = true
                monitior
                    .setResultTypeSuccess()
                    .addCategoryValue("use_expire_time", true)
                    .timing().flush()
            } else {
                alreadyCallback = false
                context.apiTrace.info("checkSessionV2 check session expire time failed")
            }
            // 发起请求
            // 注意 alreadyCallback 的使用
            startCheckSessionRequest(context: context,
                                     gadgetContext: gadgetContext,
                                     session: session,
                                     appid: gadgetContext.uniqueID.appID,
                                     monitor: monitior,
                                     apiCallback: alreadyCallback ? nil : callback)
        } catch let error as CheckSessionStepError {
            let apiError = error.transformAPIError()
            Self.trace(for: error, context: context)
            callback(.failure(error: apiError))
        } catch {
            // 正常不应该走这里
            let message = "error is not a CheckSessionStepError, error: \(error)"
            assertionFailure(message)
            context.apiTrace.assertError(true, message)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(message)
            callback(.failure(error: error))
        }
    }

    private static func trace(for error:  CheckSessionStepError, context: OpenAPIContext) {
        context.apiTrace.error("checkSessionV2 CheckSessionStepError: " + error.description)
    }

    /// 发送网络请求 且在有必要的时候回调
    private func startCheckSessionRequest(context: OpenAPIContext,
                                          gadgetContext: GadgetAPIContext,
                                          session: String,
                                          appid: String,
                                          monitor: OPMonitor,
                                          apiCallback: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)?) {
        let params = ["session": session, "appid": appid]
        let networkContext = OpenECONetworkAppContext(trace: context.getTrace(), uniqueId: gadgetContext.uniqueID, source: .api)
        let task = OpenAPINetwork.startRequest(context: networkContext,
                                               config: CheckSessionRequestConfig.self,
                                               params: params,
                                               requestCompletionHandler:
                                                { response, taskError, task in
            do {
                // 校验网络返回成功的条件
                //  1. response error weinil
                if let taskError = taskError {
                    monitor
                        .setResultTypeFail()
                        .setError(taskError)
                        .flush()
                    Self.deleteExpireTimeCache(context: context)
                    throw CheckSessionStepError.responseError(task?.trace.getRequestID())
                }
                // 2. response 的 model 有效
                guard let model: OpenAPICheckSessionModel = response?.result else {
                    monitor
                        .setResultTypeFail()
                        .addMap([kEventKey_error_msg: "Response Data Error"])
                        .flush()
                    Self.deleteExpireTimeCache(context: context)
                    throw CheckSessionStepError.responseJSONNil(task?.trace.getRequestID())
                }
                // 3. errorCode == 0
                guard model.errorCode == 0 else {
                    let errMsg = "server error \(String(describing: model.errorCode))"
                    monitor
                        .setResultTypeFail()
                        .addMap([kEventKey_error_msg: errMsg])
                        .flush()
                    Self.deleteExpireTimeCache(context: context)
                    throw CheckSessionStepError.responseBizErrorCode(task?.trace.getRequestID(), model.errorCode, model.message)
                }
                // 业务判断 data 中的 valid 字段 bool 值 为 true
                guard let data = model.data, data.valid else {
                    let errMsg = "check session failed because data is invalid response:\(model)"
                    monitor
                        .setResultTypeFail()
                        .addMap([kEventKey_error_msg: errMsg])
                        .flush()
                    // 没有通过校验 需要把本地的 session 设置为过期
                    // 为了防止 session本地过期时间有效 但是接口 显示过期 这时 也不发起callback
                    Self.deleteExpireTimeCache(context: context)
                    throw CheckSessionStepError.invalidSession(task?.trace.getRequestID(), model.errorCode, model.message)
                }

                apiCallback?(.success(data: nil))
                let expireTime = data.expireTime ?? 0
                Self.updateExpireTimeCache(context: context, expireTime: expireTime)
                monitor
                    .setResultTypeSuccess()
                    .addMap([kEventKey_error_code: 0,
                              kEventKey_error_msg: model.message ?? ""])
                    .timing()
                    .flush()
            } catch let error as CheckSessionStepError  {
                Self.trace(for: error, context: context)
                let apiError = error.transformAPIError()
                apiCallback?(.failure(error: apiError))
            } catch {
                // 正常不应该走这里
                let message = "error is not a CheckSessionStepError, error: \(error)"
                assertionFailure(message)
                context.apiTrace.assertError(true, message)
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage(message)
                apiCallback?(.failure(error: error))
            }

        })

        if task == nil {
            context.apiTrace.error("checkSessionV2 start request failed, task is nil")
            let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
            apiCallback?(.failure(error: apiError))
        } else {
            context.apiTrace.info("checkSessionV2 start request done")
        }
    }

    /// 检测 是否有session
    private static func session(context: OPAPIContextProtocol) throws -> String {
        let session = context.session
        guard !session.isEmpty else {
            throw CheckSessionStepError.containerSession
        }
        return session
    }

    /// 校验本地缓存session的过期时间
    /// 过期时间判断 https://bytedance.feishu.cn/wiki/wikcn6BbhGoxw8LAlQc7R87hF6d
    private static func checkExpireTime(context: OpenAPIContext) -> Bool {
        let storage = storge(for: context)
        let expireTime: Int
        if let value = (storage?.object(forKey: Self.kBDPSessionExpireTime) as? NSNumber)?.intValue  {
            context.apiTrace.info("checkSessionV2 get expireTime=\(value)")
            expireTime = value
        } else {
            expireTime = 0
            context.apiTrace.info("checkSessionV2 get expireTime failed! expireTime default to 0")
        }
        //    1. 缓存的过期时间:expireTime  > 0
        //    2. 服务器时间: ntpTime > 0
        //    3. expirTime - ntpTime > 1d
        guard expireTime > 0 else {
            context.apiTrace.info("checkSessionV2 check expireTime no overdue is false")
            return false
        }
        let ntpTime = SwiftBridge.ntpTime()
        let result = ntpTime > 0 && TimeInterval(expireTime) - ntpTime > 60*60*24
        context.apiTrace.info("checkSessionV2 check expireTime no overdue is \(result)")
        return result
    }
    /// 删除session过期时间缓存
    private static func deleteExpireTimeCache(context: OpenAPIContext) {
        context.apiTrace.info("deleteExpireTimeCache for appID: \(context.uniqueID)")
        updateExpireTimeCache(context: context, expireTime: 0)
    }

    /// 更新session 过期时间  如果 传入的过期时间为0 则会删除缓存
    public static func updateExpireTimeCache(context: OpenAPIContext, expireTime: Int) {
        let storage = storge(for: context)
        context.apiTrace.info("checkSessionV2 update session expire time \(expireTime) for app=\(context.uniqueID), has storege? \(storage != nil)")
        if expireTime > 0 {
            storage?.setObject(expireTime, forKey: Self.kBDPSessionExpireTime)
        } else {
            storage?.removeObject(forKey: Self.kBDPSessionExpireTime)
        }
    }
    private static func storge(for context: OpenAPIContext) -> TMAKVStorage? {
        let result = BDPCommonManager.shared()?
            .getCommonWith(context.uniqueID)?
            .sandbox?.privateStorage
        context.apiTrace.error("checkSessionV2 get storge \(result == nil ? "success" : "failed" )")
        return result
    }
}


