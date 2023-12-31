//
//  BaseRequest.swift
//  LarkLogin
//
//  Created by sniperj on 2019/1/11.
//

import Foundation
import DeviceCheck
import LKCommonsLogging
import ECOProbeMeta

class HTTPToolV3: NSObject {

    // 单例
    static let share = HTTPToolV3()

    private lazy var sessionManager: BaseSessionManager = {
        return BaseSessionManager()
    }()

    private static let logger = Logger.plog(HTTPToolV3.self, category: "SuiteLogin.v3Request")

    @discardableResult
    func urlRequest<R: ResponseV3>(
        withURLString url: String,
        method: String,
        header: [String: String]?,
        params: [String: Any]?,
        timeout: TimeInterval?,
        transform: @escaping ((_ result: NSDictionary, _ data: Data) throws -> R),
        success: @escaping ((_ result: R, _ responseHeader: ResponseHeader) -> Void),
        failure: @escaping ((_ error: V3LoginError) -> Void)
    ) -> URLSessionTask? {
        if let url = SuiteLoginUtil.queryURL(urlString: url, params: params ?? [:]) {
            var request = URLRequest(url: url)
            request.httpMethod = method.uppercased()
            if let timeout = timeout {
                request.timeoutInterval = timeout
            }
            request.allHTTPHeaderFields = header
            return handleRequest(request: request, transform: transform, success: success, failure: failure)
        } else {
            failure(.badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData))
            return nil
        }
    }

    // MARK: - 参数在 Body 的请求

    @discardableResult
    func bodyRequest<R: ResponseV3>(
        with url: String,
        method: String,
        header: [String: String]?,
        params: [String: Any]?,
        timeout: TimeInterval?,
        transform: @escaping ((_ result: NSDictionary, _ data: Data) throws -> R),
        success: @escaping ((_ result: R, _ responseHeader: ResponseHeader) -> Void),
        failure: @escaping ((_ error: V3LoginError) -> Void)
    ) -> URLSessionTask? {

        guard let url = URL(string: url) else {
            failure(V3LoginError.clientError("Invalid URL"))
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.uppercased()    // PATCH 方法小写不行
        if let timeout = timeout {
            request.timeoutInterval = timeout
        }
        request.allHTTPHeaderFields = header
        // Body Request 禁用本地缓存（存在和GET方法 URL 相同参数不同使用错缓存的情况 例如 login/2fa）
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let params = params {
            request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: .sortedKeys)
        }
        return handleRequest(request: request, transform: transform, success: success, failure: failure)
    }

    private func handleRequest<R: ResponseV3>(
        request: URLRequest,
        transform: @escaping ((_ result: NSDictionary, _ data: Data) throws -> R),
        success: @escaping ((_ result: R, _ responseHeader: ResponseHeader) -> Void),
        failure: @escaping ((_ error: V3LoginError) -> Void)
    ) -> URLSessionTask {
        let reqId = request.allHTTPHeaderFields?[CommonConst.requestId] ?? "empty_id"
        let unit = request.allHTTPHeaderFields?[CommonConst.passportUnit] ?? "empty_unit"
        let xTTEnv = request.allHTTPHeaderFields?[CommonConst.ttEnv] ?? "empty_ttEnv"
        let startTime = Date()
        let sessionType = self.sessionManager.sessionType
        let session = self.sessionManager.session
        let useCaptchaToken: Bool = request.allHTTPHeaderFields?[CommonConst.captchaToken] != nil

        let context = UniContextCreator.create(.httpRequest)
        var additionalData = [ProbeConst.xRequestID: reqId]

        PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_http_request_start,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.apiPath: request.desensitizeURLPathString],
                              context: context)
        Self.logger.info(ProbeConst.eventNetworkRequest,
                         body: "Send request: \(request.desensitizeURLString ?? ""); Method: \(request.httpMethod ?? "") req_id: \(reqId); Mode: \(sessionType) useCaptchaToken: \(useCaptchaToken) Unit: \(unit)",
                         additionalData: additionalData)

        let dataTask = session.dataTask(with: request) { (data, resp, error) in
            let duration = Int(Date().timeIntervalSince(startTime) * 1000)
            let httpCode = (resp as? HTTPURLResponse)?.statusCode
            Self.logger.info("Metrics req_time: \(duration)ms req_id: \(reqId) mode: \(sessionType) unit: \(unit)", additionalData: additionalData)
            let logID: String = resp?.getHeader(for: CommonConst.logID) ?? ""
            additionalData[ProbeConst.xTTLogID] = logID
            if let data = data {
                if let result = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? NSDictionary {
                    do {
                        let response = try transform(result, data)
                        PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_http_request_succ,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.apiPath: request.desensitizeURLPathString,
                                                                 "succ_type": "net",
                                                                 ProbeConst.duration: duration],
                                              context: context)
                        if response.code != 0 {
                            DispatchQueue.main.async {
                                var errorInfo = response.errorInfo ?? V3LoginErrorInfo(rawCode: response.code)
                                errorInfo.logID = logID
                                // 对于由服务端传递的bizError，尝试脱敏后再埋点或者打印
                                let desensitizedErrorInfo = errorInfo.desensitizedInfo
                                additionalData["error"] = desensitizedErrorInfo.description
                                PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_http_request_fail,
                                                      eventName: ProbeConst.monitorEventName,
                                                      categoryValueMap: [ProbeConst.apiPath: request.desensitizeURLPathString,
                                                                         ProbeConst.xRequestID: reqId,
                                                                         ProbeConst.xTTLogID: logID,
                                                                         "biz_code": response.code,
                                                                         ProbeConst.duration: duration],
                                                      context: context,
                                                      error: V3LoginError.badServerCode(desensitizedErrorInfo))
                                Self.logger.error(ProbeConst.eventNetworkError,
                                                  body: "request==>\(request.desensitizeURLString ?? "")/ error \n errorType: \(desensitizedErrorInfo.type.rawValue), errorMsg: \(desensitizedErrorInfo.message)/ code: \(response.code) req_id: \(reqId) mode: \(sessionType) httpCode: \(String(describing: httpCode)) unit: \(unit)",
                                                  additionalData: additionalData,
                                                  error: V3LoginError.badServerCode(desensitizedErrorInfo))

                                #if DEBUG || BETA || ALPHA
                                NetworkDebugInfoHelper.shared.appendErrorItem(host: request.url?.host,
                                                                           path: request.url?.path,
                                                                           httpCode: httpCode,
                                                                           xRequestId: reqId,
                                                                           xTTLogid: logID,
                                                                           xTTEnv: xTTEnv,
                                                                           errorCode: desensitizedErrorInfo.rawCode,
                                                                           bizCode: desensitizedErrorInfo.bizCode,
                                                                           errorMessage: desensitizedErrorInfo.message)
                                #endif

                                failure(.badServerCode(errorInfo))
                            }
                        } else {
                            let passportToken: String? = resp?.getHeader(for: CommonConst.passportToken)
                            let pwdToken: String? = resp?.getHeader(for: CommonConst.passportPWDToken)
                            // TODO: 现在 suite session key 在返回的 user 数据结构里，header 里不再包含
                            let suiteSessionKey: String? = resp?.getHeader(for: CommonConst.suiteSessionKey)
                            let verifyToken: String? = resp?.getHeader(for: CommonConst.verifyToken)
                            let flowKey: String? = resp?.getHeader(for: CommonConst.flowKey)
                            let proxyUnit: String? = resp?.getHeader(for: CommonConst.proxyUnit)
                            let logid: String? = resp?.getHeader(for: CommonConst.logID)
                            let authFlowKey: String? = resp?.getHeader(for: CommonConst.authFlowKey)
                            DispatchQueue.main.async {
                                PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_http_request_succ,
                                                      eventName: ProbeConst.monitorEventName,
                                                      categoryValueMap: [ProbeConst.apiPath: request.desensitizeURLPathString,
                                                                         "succ_type": "biz",
                                                                         ProbeConst.duration: duration],
                                                      context: context)
                                Self.logger.info(ProbeConst.eventNetworkResponse,
                                                 body: "request==>\(request.desensitizeURLString ?? "")/ success \n responseCode: \(response.code)/ req_id: \(reqId) mode: \(sessionType) httpCode: \(String(describing: httpCode)) unit: \(unit)",
                                                 additionalData: additionalData)

                                #if DEBUG || BETA || ALPHA
                                NetworkDebugInfoHelper.shared.appendSuccItem(host: request.url?.host,
                                                                      path: request.url?.path,
                                                                      httpCode: httpCode,
                                                                      xRequestId: reqId,
                                                                      xTTLogid: logid,
                                                                      xTTEnv: xTTEnv)
                                #endif
                                
                                success(response, ResponseHeader(suiteSessionKey: suiteSessionKey, passportToken: passportToken, pwdToken: pwdToken, statusCode: httpCode, verifyToken: verifyToken, flowKey: flowKey, proxyUnit: proxyUnit, xTTLogid: logid, authFlowKey: authFlowKey))
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            additionalData["error"] = V3LoginError.transformJSON(error).description
                            PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_http_request_fail,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: [ProbeConst.apiPath: request.desensitizeURLPathString,
                                                                     ProbeConst.xRequestID: reqId,
                                                                     ProbeConst.xTTLogID: logID,
                                                                     ProbeConst.duration: duration],
                                                  context: context,
                                                  error: error)
                            Self.logger.error(ProbeConst.eventNetworkError,
                                              body: "request==>\(request.desensitizeURLString ?? "")/ error \n errorMsg: transfromJsonError req_id: \(reqId) mode: \(sessionType) error: \(error) httpCode: \(String(describing: httpCode)) unit: \(unit)",
                                              additionalData: additionalData,
                                              error: V3LoginError.transformJSON(error))

                            #if DEBUG || BETA || ALPHA
                            let errorInfo = V3LoginError.transformJSON(error)
                            NetworkDebugInfoHelper.shared.appendErrorItem(host: request.url?.host,
                                                                       path: request.url?.path,
                                                                       httpCode: httpCode,
                                                                       xRequestId: reqId,
                                                                       xTTLogid: logID,
                                                                       xTTEnv: xTTEnv,
                                                                       errorCode: Int32(errorInfo.errorCode),
                                                                       bizCode: nil,
                                                                       errorMessage: errorInfo.errorDescription)
                            #endif

                            failure(.transformJSON(error))
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        let content = String(data: data, encoding: .utf8)
                        additionalData["error"] = V3LoginError.badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData).description
                        additionalData["content"] = content
                        PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_http_request_fail,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.apiPath: request.desensitizeURLPathString,
                                                                 ProbeConst.xRequestID: reqId,
                                                                 ProbeConst.xTTLogID: logID,
                                                                 ProbeConst.duration: duration],
                                              context: context,
                                              error: V3LoginError.badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData))
                        Self.logger.error(ProbeConst.eventNetworkError,
                                          body: "request==>\(request.desensitizeURLString ?? "")/ error \n errorMsg: Cannot convert response to NSDictionary req_id: \(reqId) mode: \(sessionType) content: \(String(describing: content)) httpCode: \(String(describing: httpCode)) unit: \(unit)",
                                          additionalData: additionalData,
                                          error: V3LoginError.badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData))

                        #if DEBUG || BETA || ALPHA
                        let errorInfo = V3LoginError.badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData)
                        NetworkDebugInfoHelper.shared.appendErrorItem(host: request.url?.host,
                                                                   path: request.url?.path,
                                                                   httpCode: httpCode,
                                                                   xRequestId: reqId,
                                                                   xTTLogid: logID,
                                                                   xTTEnv: xTTEnv,
                                                                   errorCode: Int32(errorInfo.errorCode),
                                                                   bizCode: nil,
                                                                   errorMessage: errorInfo.errorDescription)
                        #endif

                        failure(.badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData))
                    }
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    additionalData["error"] = V3LoginError.server(error).description
                    PassportMonitor.flush(EPMClientPassportMonitorCode.passport_monitor_http_request_fail,
                                          eventName: ProbeConst.monitorEventName,
                                          categoryValueMap: [ProbeConst.apiPath: request.desensitizeURLPathString,
                                                             ProbeConst.xRequestID: reqId,
                                                             ProbeConst.xTTLogID: logID,
                                                             ProbeConst.duration: duration],
                                          context: context,
                                          error: error)
                    Self.logger.error(ProbeConst.eventNetworkError,
                                      body: "request==>\(request.desensitizeURLString ?? "")/ error \n errorMsg: \((error as NSError).localizedDescription)/ req_id: \(reqId) mode: \(sessionType) unit: \(unit)",
                                      additionalData: additionalData,
                                      error: V3LoginError.server(error))

                    #if DEBUG || BETA || ALPHA
                    let errorInfo = V3LoginError.server(error)
                    NetworkDebugInfoHelper.shared.appendErrorItem(host: request.url?.host,
                                                               path: request.url?.path,
                                                               httpCode: httpCode,
                                                               xRequestId: reqId,
                                                               xTTLogid: logID,
                                                               xTTEnv: xTTEnv,
                                                               errorCode: Int32(errorInfo.errorCode),
                                                               bizCode: nil,
                                                               errorMessage: errorInfo.errorDescription)
                    #endif

                    let currentErrorCode = (error as NSError).code
                    // -1, -1009, -1001
                    let errorCodesToTranslate = [NSURLErrorUnknown, NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut]
                    if case .rustProxy = sessionType, errorCodesToTranslate.contains(currentErrorCode) {
                        let description = currentErrorCode == NSURLErrorTimedOut ?
                            BundleI18n.suiteLogin.Lark_Login_NumberDetectOverTimePopupTitle :
                            BundleI18n.suiteLogin.Lark_Login_ErrorMessageOfInternalNetwork
                        let userInfo = [
                            NSLocalizedDescriptionKey: description
                        ]
                        let error = NSError(domain: NSURLErrorDomain, code: currentErrorCode, userInfo: userInfo)
                        Self.logger.error(ProbeConst.eventNetworkError,
                                          body: "request==>\(request.desensitizeURLString ?? "")/ rust internal error \n errorMsg: \(error)/ req_id: \(reqId) mode: \(sessionType) httpCode: \(String(describing: httpCode)) unit: \(unit)",
                                          additionalData: additionalData,
                                          error: V3LoginError.server(error))

                        failure(.server(error))
                        return
                    }
                    failure(.server(error))
                }
            }
        }
        dataTask.resume()
        return dataTask
    }
}

extension URLResponse {
    func getHeader(for key: String) -> String? {
        guard let resp = self as? HTTPURLResponse else {
            return nil
        }
        if let value = resp.allHeaderFields[key] as? String {
            return value
        }

        var headerValue: String?
        resp.allHeaderFields.forEach { (k, v) in
            if let headerK = k as? String,
                headerK.lowercased() == key.lowercased() {
                headerValue = v as? String
            }
        }
        return headerValue
    }
}

extension URLRequest {
    var desensitizeURLString: String? {
        return self.url?.desensitizeString
    }

    var desensitizeURLPathString: String? {
        return self.url?.path
    }
}

extension URL {
    var desensitizeString: String {
        if var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            urlComponents.queryItems = nil
            return urlComponents.url?.absoluteString ?? ""
        } else {
            return self.absoluteString
        }
    }
}
