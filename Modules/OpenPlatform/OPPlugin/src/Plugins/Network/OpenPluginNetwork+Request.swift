//
//  OpenPluginNetworkRequest.swift
//  OPPlugin
//
//  Created by MJXin on 2021/11/3.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer
import LarkRustClient
import RustPB
import LKCommonsLogging
import RxSwift
import SwiftyJSON
import OPFoundation

// MARK: - tt.request & tt.requestAbort
extension OpenPluginNetwork {
    private static let prefetchDetailKey = "prefetchDetail"
    
    public func request(
        context: OpenAPIContext,
        params: OpenPluginNetworkRequestParams,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            let startMonitor = OPMonitor.startMonitor(withContext: context, name: MonitorEventName.RequestStart)
            let resultMonitor = OPMonitor.resultMonitor(withContext: context, name: MonitorEventName.RequestResult)
            context.apiTrace.info(
                "tt.request V2 will start request",
                tag: "tt.request"
            )

            // 上下文变量定义
            var uniqueID: OPAppUniqueID
            var requestPayload: OpenPluginNetworkRequestParamsPayload
            var taskID: String
            var url: URL
            var reqCmd: (request: Openplatform_Api_OpenAPIRequest, extra: OpenPluginNetworkRequestParamsExtra)
            var usePrefetchCache: Bool = false
            var cookies: [String]
            
            do {
                // 上下文处理, 判空, 序列化等
                uniqueID = try Self.getUniqueID(context: context)
                requestPayload = try Self.decode(
                    type: .input,
                    model: OpenPluginNetworkRequestParamsPayload.self,
                    fromJson: params.payload)
                url = try self.encode(urlString: requestPayload.url)
                taskID = requestPayload.taskID
                usePrefetchCache = requestPayload.usePrefetchCache ?? false

                // 设置埋点信息
                startMonitor.setStartInfo(fromURL: url, payload: requestPayload)
                resultMonitor.setRequestInfo(fromUniqueID: uniqueID, url: url, payload: requestPayload)

                cookies = OpenPluginNetwork.getStorageCookies(cookieService:cookieService, from: uniqueID, url: url)
            } catch let error {
                context.apiTrace.error(
                    "tt.request prepare request context fail:" + error.localizedDescription,
                    tag: "tt.request"
                )
                let apiError = Self.apiError(context: context, error: error)
                startMonitor.flushFail(withAPIError: apiError)
                resultMonitor.flushFail(withAPIError: apiError)
                callback(.failure(error: apiError))
                return
            }

            context.apiTrace.info(
                "tt.request will tryUsePrefetch",
                tag: "tt.request",
                additionalData: [
                    "taskID": taskID,
                    "method": requestPayload.method ?? "",
                    "url": url.safeURLString,
                ]
            )

            // 使用prefetch
            // 流程：优先尝试使用prefetch，通过block回调告诉主流程是否成功，成功则返回prefetch得到的数据，否则继续走正常请求流程。
            tryUsePrefetch(context: context, params: params) { [weak self] result in
                let usePrefetchSuccess: Bool
                var prefetchDetail = [String: Any]()
                switch result {
                case .success(let dataDic):
                    do {
                        let tempData =  try JSONSerialization.data(withJSONObject: dataDic,
                                                                   options: JSONSerialization.WritingOptions.prettyPrinted)
                        let payloadStr = String(data: tempData, encoding: String.Encoding.utf8)
                        callback(.success(data: OpenAPINetworkRequestResult(payload: payloadStr)))
                        usePrefetchSuccess = true

                        if let statusCode = dataDic["statusCode"] {
                            resultMonitor.addMap([MonitorKey.HttpCode: statusCode])
                        }
                    } catch let error {
                        context.apiTrace.error("tt.request parse prefetchCache failed, \(error.localizedDescription)",
                                               tag: "tt.request")
                        usePrefetchSuccess = false
                        prefetchDetail = OpenAPIError(errno: OpenAPICommonErrno.internalError).errnoInfo
                    }
                case .failure(let error):
                    context.apiTrace.error("tt.request not use prefetchCache beacause: \(error.errnoError?.errnoValue ?? -1)",
                                           tag: "tt.request")
                    usePrefetchSuccess = false
                    prefetchDetail = error.errnoInfo
                }

                // 埋点及日志
                startMonitor.addMap([MonitorKey.UsePrefetch: usePrefetchCache])
                resultMonitor.addMap([MonitorKey.IsPrefetch: usePrefetchSuccess])
                startMonitor.flushSuccess()
                resultMonitor.setStorageCookie(cookies: cookies)
                resultMonitor.addMap([MonitorKey.UsePrefetch: usePrefetchCache])

                if usePrefetchCache {
                    resultMonitor.addMap([MonitorKey.PrefetchErrno: prefetchDetail["errno"] ?? "0"])
                    resultMonitor.addMap([MonitorKey.PrefetchVersion: PrefetchLarkFeatureGatingDependcy.prefetchRequestV2(uniqueID: uniqueID) ? "v2" : "v1"])
                }

                if usePrefetchSuccess {
                    context.apiTrace.info("tt.request use prefetch cache success", tag: "tt.request")
                    resultMonitor.flushSuccess()
                    return
                } else {
                    context.apiTrace.info(
                        "tt.request will send async request without prefetchCache",
                        tag: "tt.request",
                        additionalData: [
                            "taskID": taskID,
                            "method": requestPayload.method ?? "",
                            "url": url.safeURLString,
                        ]
                    )

                    guard let `self` = self else {
                        context.apiTrace.error(
                            "tt.request callback fail, self missed",
                            tag: "tt.request",
                            additionalData: ["taskID": taskID]
                        )
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setMonitorMessage("self is nil When call API")
                            .setErrno(OpenAPICommonErrno.unknown)
                        let apiError = Self.apiError(context: context, error: error)
                        resultMonitor.flushFail(withAPIError: apiError)
                        callback(.failure(error: apiError))
                        return
                    }
                    guard let cookieService = self.cookieService else {
                        let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                            .setMonitorMessage("resolve ECOCookieService failed")
                        let apiError = Self.apiError(context: context, error: error)
                        resultMonitor.flushFail(withAPIError: apiError)
                        callback(.failure(error: apiError))
                        return
                    }
                    guard let rustService = self.rustService else {
                        let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                            .setMonitorMessage("resolve RustService failed")
                        let apiError = Self.apiError(context: context, error: error)
                        resultMonitor.flushFail(withAPIError: apiError)
                        callback(.failure(error: apiError))
                        return
                    }
                    do {
                        // 发请求
                        try Self.sendAsyncRequest(
                            apiName: .request,
                            uniqueID: uniqueID,
                            trace: context.apiTrace,
                            url: url,
                            payload: params.payload,
                            cookieService: cookieService,
                            rustService: rustService,
                            disposeBag: self.disposeBag,
                            resultMonitor: resultMonitor) { (payload, extra) in
                                // 日志,埋点,callback
                                context.apiTrace.info(
                                    "tt.request callback success",
                                    tag: "tt.request",
                                    additionalData: ["taskID": taskID]
                                )
                                resultMonitor.flushSuccess()
                                let result = OpenAPINetworkRequestResult(payload: payload)
                                if usePrefetchCache {
                                    result.prefetchDetail = prefetchDetail
                                }
                                if let podfile = try? extra.podfile?.asDictionary() {
                                    var realPodfile = podfile
                                    realPodfile[MonitorKey.pluginDurationMS] = resultMonitor.metrics?[OPMonitorEventKey.duration] ?? 0
                                    realPodfile[MonitorKey.pluginEndMS] = Int64(Date().timeIntervalSince1970 * 1000)
                                    realPodfile[MonitorKey.isBackground] = context.isLazyInvoke
                                    realPodfile[MonitorKey.backgroundDuration] = context.lazyInvokeElapsedDuration
                                    result.podfile = realPodfile
                                }
                                callback(.success(data: result))
                            } fail: { error in
                                context.apiTrace.error(
                                    "tt.request callback fail" + error.localizedDescription,
                                    tag: "tt.request",
                                    additionalData: ["taskID": taskID]
                                )
                                let apiError = Self.apiError(context: context, error: error)
                                if usePrefetchCache {
                                    apiError.setAddtionalInfo([OpenPluginNetwork.prefetchDetailKey: prefetchDetail])
                                }
                                resultMonitor.flushFail(withAPIError: apiError)
                                callback(.failure(error: apiError))
                            }
                    } catch let error {
                        context.apiTrace.error(
                            "tt.request send request fail:" + error.localizedDescription,
                            tag: "tt.request"
                        )
                        let apiError = Self.apiError(context: context, error: error)
                        resultMonitor.flushFail(withAPIError: apiError)
                        callback(.failure(error: apiError))
                    }
                }
            }
    }

    public func requestAbort(
        context: OpenAPIContext,
        params: OpenPluginNetworkRequestParams,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            guard let rustService else {
                callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve Rust Service failed")))
                return
            }
            
            var taskID: String
            var reqCmd: Openplatform_Api_OpenAPIRequest
            
            // 入参校验
            do {
                let uniqueID = try Self.getUniqueID(context: context)
                let payload = try Self.decode(
                    type: .input,
                    model: OpenPluginNetworkRequestAbortParamsPayload.self,
                    fromJson: params.payload
                )
                var apiContext = try Self.apiContext(from: uniqueID)
                apiContext.traceID = context.apiTrace.traceId
                reqCmd = Openplatform_Api_OpenAPIRequest()
                reqCmd.apiContext = apiContext
                reqCmd.apiName = APIName.requestAbort.rawValue
                reqCmd.payload = params.payload
                taskID = payload.taskID
            } catch let error {
                context.apiTrace.error(
                    "tt.request.abort prepare abort context fail" + error.localizedDescription,
                    tag: "tt.request"
                )
                callback(.failure(error: Self.apiError(context: context, error: error)))
                return
            }
            
            context.apiTrace.info(
                "tt.request.abort will send async request",
                tag: "tt.request",
                additionalData: ["taskID": taskID]
            )
            
            rustService.sendAsyncRequest(reqCmd)
                .subscribe (
                    onNext: { (response: Openplatform_Api_OpenAPIResponse) in
                        context.apiTrace.info(
                            "tt.request.abort callbcak success",
                            tag: "tt.request",
                            additionalData: ["taskID": taskID]
                        )
                        callback(.success(data: OpenAPINetworkRequestResult(payload: nil)))
                    },
                    onError: {(error) in
                        context.apiTrace.error(
                            "tt.request.abort callbcak fail" + error.localizedDescription,
                            tag: "tt.request",
                            additionalData: ["taskID": taskID]
                        )
                        callback(.failure(
                            error: Self.apiError(context: context, error: error)
                        ))
                    }
                )
                .disposed(by: disposeBag)
    }

    /// 处理prefetch流程
    private func tryUsePrefetch(
        context: OpenAPIContext,
        params: OpenPluginNetworkRequestParams,
        callback: @escaping (Result<[String: Any], OpenAPIError>) -> Void) {
            do {
                let requestPayload = try Self.decode(
                        type: .input,
                        model: OpenPluginNetworkRequestParamsPayload.self,
                        fromJson: params.payload)
                guard let usePrefetchCache = requestPayload.usePrefetchCache, usePrefetchCache else {
                    context.apiTrace.info(
                        "tt.request use prefetch failed, because usePrefetchCache is false",
                        tag: "tt.request"
                    )
                    // 这里抛错意在告诉caller，本次reqeust不支持prefetch，属于正常流程
                    let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                        .setMonitorMessage("tt.request not use prefetch because usePrefetchCache is false")
                        .setErrno(OpenAPICommonErrno.unknown)
                    callback(.failure(error))
                    return
                }
                guard let prefetchManager = BDPAppPagePrefetchManager.shared() else {
                    context.apiTrace.error(
                        "tt.request use prefetch failed, because BDPAppPagePrefetchManager.shared() is nil",
                        tag: "tt.request"
                    )
                    let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                        .setMonitorMessage("tt.request not use prefetch because BDPAppPagePrefetchManager.shared() is nil")
                    callback(.failure(error))
                    return
                }
                let paramsDic = try Self.getDictionary(fromJson: params.payload)
                let uniqueID = try Self.getUniqueID(context: context)

                var prefetchError: OPPrefetchErrnoWrapper? = nil
                let useCache = prefetchManager.shouldUsePrefetchCache(withParam: paramsDic, uniqueID: uniqueID, requestCompletion: { data, response, prefetchDetail, error in
                    if PrefetchLarkFeatureGatingDependcy.prefetchRequestV2(uniqueID: uniqueID) {
                        OpenPluginNetwork.handlePrefetchResultV2(data: data, prefetchDetail: prefetchDetail, error: error, context: context, callback: callback)
                        return
                    }
                    var dataDic: [String: Any] = [:]
                    if let httpResponse = response as? HTTPURLResponse {
                        TMAPluginNetwork.handleCookie(with: httpResponse, uniqueId: uniqueID)
                        dataDic["statusCode"] = httpResponse.statusCode
                        dataDic["header"] = httpResponse.allHeaderFields

                        if let data = data as? Data {
                            if requestPayload.responseType == "arraybuffer" {
                                let dataBuffers: [String: Any] = ["key": "data", "base64": data.base64EncodedString()]
                                dataDic["__nativeBuffers__"] = dataBuffers
                            } else {
                                dataDic["data"] = String(data: data, encoding: String.Encoding.utf8)
                            }
                        }
                    } else {
                        context.apiTrace.error(
                            "tt.request use prefetch failed, because response isn't HTTPURLResponse",
                            tag: "tt.request"
                        )
                        // 这里抛错意在告诉caller，本次reqeust不支持prefetch，属于正常流程
                        let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                            .setMonitorMessage("tt.request use prefetch failed, because response isn't HTTPURLResponse")
                            .setErrno(OpenAPICommonErrno.unknown)
                        callback(.failure(error))
                        return
                    }
                    let resultDetail = BDPPrefetchDetail(rawValue: prefetchDetail)
                    // 预取失败(包括请求失败和复用请求失败)，一律算 failure
                    if resultDetail != .fetchAndUseSuccess, resultDetail != .reuseRequestSuccess {
                        callback(.failure(OpenAPIError(errno: OpenAPINetworkPrefetchErrno.prefetchRequestFailed)))
                        return
                    }
                    // prefetchDetail在发起请求时候，prefetchDetail 是 -1。表示没有走预取逻辑
                    if let resultDetail = resultDetail {
                        dataDic["isPrefetch"] = resultDetail.getIsPrefetchValue()
                    } else {
                        dataDic["isPrefetch"] = false
                    }
                    callback(.success(dataDic))
                }, error: &prefetchError)
                if let prefetchError = prefetchError {
                    callback(.failure(OpenAPIError(errno: prefetchError.errno)))
                } else if !useCache {
                    context.apiTrace.error(
                        "tt.request use prefetch failed, because prefetchError is nil and useCache is false",
                        tag: "tt.request"
                    )
                    let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                        .setMonitorMessage("tt.request not use prefetch because prefetchError is nil and useCache is false")
                    callback(.failure(error))
                }
            } catch let error {
                context.apiTrace.error(
                    "tt.request use prefetch failed, because \(error.localizedDescription)",
                    tag: "tt.request"
                )
                let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                    .setMonitorMessage("tt.request not use prefetch.  because detail is \(error.localizedDescription)")
                callback(.failure(error))
                return
            }
    }

    private static func handlePrefetchResultV2(
        data: Any?,
        prefetchDetail: Int,
        error: Error?,
        context: OpenAPIContext,
        callback: @escaping (Result<[String: Any], OpenAPIError>) -> Void) {
            let resultDetail = BDPPrefetchDetail(rawValue: prefetchDetail)
            // 预取失败(包括请求失败和复用请求失败)，一律算 failure
            if resultDetail != .fetchAndUseSuccess, resultDetail != .reuseRequestSuccess {
                context.apiTrace.error(
                    "tt.request use prefetch failed, because resultDetail, \(resultDetail)",
                    tag: "tt.request"
                )
                let errno = OpenAPIError(errno: OpenAPINetworkPrefetchErrno.prefetchRequestFailed)
                    .setMonitorMessage("tt.request use prefetch failed, because resultDetail is not fetchAndUseSuccess or reuseRequestSuccess")
                callback(.failure(errno))
                return
            }
            if let error = error {
                context.apiTrace.error(
                    "tt.request use prefetch failed, because \(error.localizedDescription)",
                    tag: "tt.request"
                )
                let errno = OpenAPIError(errno: OpenAPINetworkPrefetchErrno.prefetchRequestFailed)
                    .setMonitorMessage("tt.request use prefetch failed, because error is not nil")
                callback(.failure(errno))
                return
            }
            do {
                guard let data = data as? Data, var dataDic = try JSONSerialization.jsonObject(with: data) as? [String : Any] else {
                    context.apiTrace.error(
                        "tt.request use prefetch failed, because data to json fail",
                        tag: "tt.request"
                    )
                    let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                        .setMonitorMessage("tt.request use prefetch failed, because data to json fail")
                    callback(.failure(error))
                    return
                }
                if let resultDetail = resultDetail {
                    dataDic["isPrefetch"] = resultDetail.getIsPrefetchValue()
                } else {
                    dataDic["isPrefetch"] = false
                }
                callback(.success(dataDic))
            } catch let error {
                context.apiTrace.error(
                    "tt.request use prefetch failed, because \(error.localizedDescription)",
                    tag: "tt.request"
                )
                callback(.failure(OpenAPIError(errno: OpenAPICommonErrno.unknown)))
            }
    }
}

extension BDPPrefetchDetail {
    /// 特定用途：根据prefetch返回的detail，判断isPrefetch的字段值
    func getIsPrefetchValue() -> Bool {
        switch self {
        case .fetchNetError:
            return false
        case .fetchAndUseSuccess:
            return true
        case .reuseRequestSuccess:
            return true
        case .reuseRequestFail:
            return true
        @unknown default:
            return false
        }
    }
}
