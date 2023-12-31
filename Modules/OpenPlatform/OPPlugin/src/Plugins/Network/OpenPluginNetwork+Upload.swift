//
//  OpenPluginNetwork+Upload.swift
//  OPPlugin
//
//  Created by MJXin on 2021/12/24.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK
import OPPluginManagerAdapter
import LarkContainer
import LarkRustClient
import RustPB
import LKCommonsLogging
import RxSwift

// MARK: - tt.upload & tt.uploadAbort
extension OpenPluginNetwork {
    
    
    /// 创建向 Rust 发请求的 pb command  对象
    /// https://bytedance.feishu.cn/docx/doxcnHNBEfqGFdoEIG4v6MoDRrd#doxcnoQUWGIs2KmOaWq4kogdHHh
    /// - Parameters:
    ///   - context: API 上下文
    ///   - url: 请求地址
    ///   - uploadFilePath: 真实的文件上传路径(由用户传入的 ttfile 转换而来)
    ///   - payload: JSSDK 下发的 payload
    /// - Returns: Command 及 extra 对象
    private func createRequestCommand(withContext context: OpenAPIContext, url: URL, uploadFilePath: String, payload: String) throws -> (Openplatform_Api_OpenAPIRequest, OpenPluginNetworkUploadParamsExtra) {
        
        let apiName = APIName.uploadFile
        let uniqueID = try Self.getUniqueID(context: context)
        var apiContext = try Self.apiContext(from: uniqueID)
        
        // 生成 Extra, 提供给 Rust 处理请求
        let extra = OpenPluginNetworkUploadParamsExtra(
            realFilePath: uploadFilePath,
            cookies: OpenPluginNetwork.getStorageCookies(cookieService:cookieService, from: uniqueID, url: url),
            originUA: OpenPluginNetwork.getOriginUserAgent(),
            referer: OpenPluginNetwork.getOriginReferer(),
            timeout: OpenPluginNetwork.getAPITimeoutConfig(api: apiName, uniqueID: uniqueID)
        )
        
        // 准备请求数据
        var request = Openplatform_Api_OpenAPIRequest()
        apiContext.traceID = context.apiTrace.traceId
        request.apiContext = apiContext
        request.apiName = apiName.rawValue
        request.payload = payload
        request.extra = try Self.encode(type: .internal, model: extra)
        
        return (request, extra)
    }
    
    public func upload(
        context: OpenAPIContext,
        params: OpenPluginNetworkRequestParams,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            guard let rustService else {
                callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve Rust Service failed")))
                return
            }
            
            // 创建埋点
            let startMonitor = OPMonitor.startMonitor(withContext: context, name: MonitorEventName.UploadStart)
            // 创建结束点
            let resultMonitor = OPMonitor.resultMonitor(withContext: context, name: MonitorEventName.UploadResult)
            
            // 上下文变量定义
            var uniqueID: OPAppUniqueID
            var uploadPayload: OpenPluginNetworkUploadParamsPayload
            var taskID: String
            var url: URL
            var reqCmd: (request: Openplatform_Api_OpenAPIRequest, extra: OpenPluginNetworkUploadParamsExtra)
            
            do {
                // 上下文处理, 判空, 序列化等
                uniqueID = try Self.getUniqueID(context: context)
                uploadPayload = try Self.decode(
                    type: .input,
                    model: OpenPluginNetworkUploadParamsPayload.self,
                    fromJson: params.payload)
                url = try self.encode(urlString: uploadPayload.url)
                taskID = uploadPayload.taskID
                
                // 设置埋点信息
                startMonitor.setStartInfo(fromURL: url, payload: uploadPayload)
                resultMonitor.setUploadInfo(fromUniqueID: uniqueID, url: url, payload: uploadPayload)
                
                // 将入参 filePath 从 ttfile:// 转为 file://
                let (_, realPath) = try OpenPluginUploadTask.getRealFilePath(
                    context: context,
                    ttFilePath: uploadPayload.filePath,
                    tag: "tt.uploadFile"
                )
                
                // 创建 pb command 对象
                reqCmd = try self.createRequestCommand(
                    withContext: context,
                    url: url,
                    uploadFilePath: realPath,
                    payload: params.payload
                )
                
            } catch let error {
                context.apiTrace.error(
                    "tt.uploadFile prepare upload context fail \(error)",
                    tag: "tt.uploadFile"
                )
                let apiError = Self.apiError(context: context, error: error)
                startMonitor.flushFail(withAPIError: apiError)
                resultMonitor.flushFail(withAPIError: apiError)
                callback(.failure(error: apiError))
                return
            }
            
            // 埋点处理
            startMonitor.flushSuccess()
            resultMonitor.setStorageCookie(cookies: reqCmd.extra.cookie)
            
            // 加入全局缓存
            setContextWithLock(context, by: context.apiTrace.traceId)
            
            context.apiTrace.info(
                "tt.uploadFile will send async request",
                tag: "tt.uploadFile",
                additionalData: [
                    "taskID": taskID,
                    "url": url.safeURLString,
                    "inputFilePath": uploadPayload.filePath.toBase64(),
                    "realFilePath": reqCmd.extra.realFilePath.toBase64()
                ]
            )

            // 发起请求
            rustService.sendAsyncRequest(reqCmd.request)
                .flatMap({ [weak self] (response: Openplatform_Api_OpenAPIResponse) -> Observable<String> in
                    // 日志
                    context.apiTrace.info(
                        "tt.uploadFile received rust response",
                        tag: "tt.uploadFile",
                        additionalData: ["taskID": taskID]
                    )
                    
                    let extra = try Self.decode(
                        type: .internal,
                        model: OpenPluginNetworkUploadResultExtra.self,
                        fromJson: response.extra
                    )
                    // 处理 set-cookie
                    if let cookies = extra.cookie {
                        OpenPluginNetwork.saveCookies(cookieService:self?.cookieService, uniqueID: uniqueID, cookies: cookies, url: url)
                    }
                    
                    resultMonitor.setUploadResponseInfo(from: extra)
                    return Observable.just(response.payload)
                })
                .subscribe (
                    onNext: { (payload: String) in
                        context.apiTrace.info(
                            "tt.uploadFile callback success",
                            tag: "tt.uploadFile",
                            additionalData: ["taskID": taskID]
                        )
                        resultMonitor.flushSuccess()
                        callback(.success(data: OpenAPINetworkRequestResult(payload: payload)))
                    },
                    //失败回调
                    onError: { error in
                        context.apiTrace.error(
                            "tt.uploadFile callback fail:" + error.localizedDescription,
                            tag: "tt.uploadFile",
                            additionalData: ["taskID": taskID]
                        )
                        let apiError = Self.apiError(context: context, error: error)
                        resultMonitor.flushFail(withAPIError: apiError)
                        callback(.failure(error: apiError))
                    },
                    //结束处理
                    onCompleted: { [weak self] in
                        self?.setContextWithLock(nil, by: context.apiTrace.traceId)
                    }
                )
                .disposed(by: disposeBag)
    }
    
    public func uploadAbort(
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
                    model: OpenPluginNetworkUploadAbortParamsPayload.self,
                    fromJson: params.payload
                )
                
                var apiContext = try Self.apiContext(from: uniqueID)
                apiContext.traceID = context.apiTrace.traceId
                reqCmd = Openplatform_Api_OpenAPIRequest()
                reqCmd.apiContext = apiContext
                reqCmd.apiName = APIName.uploadFileAbort.rawValue
                reqCmd.payload = params.payload
                taskID = payload.taskID
            } catch let error {
                context.apiTrace.error(
                    "tt.uploadFile.abort prepare abort context fail" + error.localizedDescription,
                    tag: "tt.uploadFile"
                )
                callback(.failure(error: Self.apiError(context: context, error: error)))
                return
            }
            
            context.apiTrace.info(
                "tt.uploadFile.abort will send async request",
                tag: "tt.uploadFile",
                additionalData: ["taskID": taskID]
            )

            // 下发指令
            rustService.sendAsyncRequest(reqCmd)
                .subscribe (
                    onNext: { (response: Openplatform_Api_OpenAPIResponse) in
                        context.apiTrace.info(
                            "tt.uploadFile.abort callbcak success",
                            tag: "tt.uploadFile",
                            additionalData: ["taskID": taskID]
                        )
                        callback(.success(data: OpenAPINetworkRequestResult(payload: nil)))
                    },
                    onError: {(error) in
                        context.apiTrace.error(
                            "tt.uploadFile.abort callbcak fail" + error.localizedDescription,
                            tag: "tt.uploadFile",
                            additionalData: ["taskID": taskID]
                        )
                        callback(.failure(
                            error: Self.apiError(context: context, error: error)
                        ))
                    }
                )
                .disposed(by: disposeBag)
    }
}
