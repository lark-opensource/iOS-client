//
//  OpenPluginNetwork+Download.swift
//  OPPlugin
//
//  Created by MJXin on 2022/1/14.
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

// MARK: - tt.downloadFile
extension OpenPluginNetwork {
    
    /// 创建向 Rust 发请求的 pb command  对象
    /// 协议详见: https://bytedance.feishu.cn/docs/doccneX8fwDNL2Zi6nz20Ay9Xf6
    /// - Parameters:
    ///   - context: API 上下文
    ///   - url: 请求地址
    ///   - payload: JSSDK 下发的 payload
    /// - Returns: Command 及 extra 对象
    private func createRequestCommand(withContext context: OpenAPIContext, url: URL, payload: String) throws -> (Openplatform_Api_OpenAPIRequest, OpenPluginNetworkDownloadParamsExtra) {
        let apiName = APIName.downloadFile
        let uniqueID = try Self.getUniqueID(context: context)
        var apiContext = try Self.apiContext(from: uniqueID)

        // 下载文件临时存放地址, 用于下载, 下载完毕后会移动到正式路径
        let tempDownloadPath = try OpenPluginDownloadTask.generateTempDownloadPath(from: uniqueID)
        let storageCookies = OpenPluginNetwork.getStorageCookies(cookieService:cookieService, from: uniqueID, url: url)
        let userAgent = OpenPluginNetwork.getOriginUserAgent()
        let referer = OpenPluginNetwork.getOriginReferer()
        let timeout = OpenPluginNetwork.getAPITimeoutConfig(api: apiName, uniqueID: uniqueID)

        // 生成 Extra
        let extra = OpenPluginNetworkDownloadParamsExtra(
            downloadFilePath: tempDownloadPath,
            cookies: storageCookies,
            originUA: userAgent,
            referer: referer,
            timeout: timeout
        )

        // 生成 Request
        var request = Openplatform_Api_OpenAPIRequest()
        apiContext.traceID = context.apiTrace.traceId
        request.apiContext = apiContext
        request.apiName = apiName.rawValue
        request.payload = payload
        request.extra = try Self.encode(type: .internal, model: extra)

        return (request, extra)
    }
    
    public func download(
        context: OpenAPIContext,
        params: OpenPluginNetworkRequestParams,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            guard let rustService else {
                callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve Rust Service failed")))
                return
            }
            
            // 创建埋点
            let startMonitor = OPMonitor.startMonitor(withContext: context, name: MonitorEventName.DownloadStart)
            let resultMonitor = OPMonitor.resultMonitor(withContext: context, name: MonitorEventName.DownloadResult)
            
            // 上下文变量定义
            var uniqueID: OPAppUniqueID
            var downloadPayload: OpenPluginNetworkDownloadParamsPayload
            var taskID: String
            var fsContext: FileSystem.Context
            var inputFileObj: FileObject?
            var url: URL
            var reqCmd: (request: Openplatform_Api_OpenAPIRequest, extra: OpenPluginNetworkDownloadParamsExtra)
            
            // 请求上下文,校验及准备
            do {
                uniqueID = try Self.getUniqueID(context: context)
                downloadPayload = try Self.decode(
                    type: .input,
                    model: OpenPluginNetworkDownloadParamsPayload.self,
                    fromJson: params.payload
                )
                url = try encode(urlString: downloadPayload.url)
                taskID = downloadPayload.taskID
                
                // 设置埋点信息
                startMonitor.setStartInfo(fromURL: url, payload: downloadPayload)
                resultMonitor.setDownloadInfo(fromUniqueID: uniqueID, url: url, payload: downloadPayload)
                 
                // 处理用户传入路径, 如果传入 filePath, 则校验路径, 并创建 fileObj
                fsContext = FileSystem.Context(
                    uniqueId: uniqueID,
                    trace: context.apiTrace,
                    tag: "tt.downloadFile",
                    isAuxiliary: false
                )
                if let filePath = downloadPayload.filePath {
                    inputFileObj = try OpenPluginDownloadTask.generateInputObject(context: fsContext, filePath: filePath)
                }
                
                // 创建 pb command 对象
                reqCmd = try self.createRequestCommand(withContext: context, url: url, payload: params.payload)
            } catch let error {
                context.apiTrace.error(
                    "tt.downloadFile prepare download context fail: \(error)",
                    tag: "tt.downloadFile"
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
                "tt.downloadFile will send async request",
                tag: "tt.downloadFile",
                additionalData: [
                    "taskID": taskID,
                    "inputFilePath": downloadPayload.filePath?.toBase64() ?? "",
                    "downloadTempFilePath": reqCmd.extra.downloadFilePath.toBase64()
                ]
            )
            
            // 发送请求
            rustService.sendAsyncRequest(reqCmd.request)
                // 响应参数处理(payload, extra 反序列化)
                .flatMap({(response: Openplatform_Api_OpenAPIResponse) -> Observable<(OpenPluginNetworkDownloadResultPayload, OpenPluginNetworkDownloadResultExtra)> in
                    // 日志
                    context.apiTrace.info(
                        "tt.downloadFile received rust response",
                        tag: "tt.downloadFile",
                        additionalData: ["taskID": taskID]
                    )
                    
                    // 处理返回数据
                    let extra = try Self.decode(type: .internal, model: OpenPluginNetworkDownloadResultExtra.self, fromJson: response.extra)
                    let payload = try Self.decode(type: .internal, model: OpenPluginNetworkDownloadResultPayload.self, fromJson: response.payload)
                    
                    // 处理埋点
                    resultMonitor.setDownloadResponseInfo(from: extra)
                    
                    return Observable.just((payload, extra))
                })
                // 响应逻辑处理(移动文件到最终路径)
                .flatMap({[weak self] (payload, extra) -> Observable<String> in
                    // 日志
                    context.apiTrace.info(
                        "tt.downloadFile parsed rust response",
                        tag: "tt.downloadFile",
                        additionalData: [
                            "taskID": downloadPayload.taskID,
                            "downloadFilePath": extra.downloadFilePath,
                            "suggestedFileName": extra.suggestedFileName,
                            "statusCode": String(extra.statusCode ?? 0),
                        ]
                    )
                    guard let self = self else {
                        throw OpenPluginNetworkError.missingRequiredParams("self is nil")
                    }
                    // 保存 cookie
                    if let cookies = extra.cookie {
                        OpenPluginNetwork.saveCookies(cookieService:self.cookieService, uniqueID: uniqueID, cookies: cookies, url: url)
                    }
                    /// 将文件移动到目标路径
                    let destFilePath = try OpenPluginDownloadTask.moveDownloadFile(
                        context: fsContext,
                        source: extra.downloadFilePath,
                        filename: extra.realSuggestedFileName(),
                        targetFileObj: inputFileObj
                    )
                    var payload = payload
                    payload.tempFilePath = destFilePath
                    
                    context.apiTrace.info(
                        "tt.downloadFile moved download file",
                        tag: "tt.downloadFile",
                        additionalData: [
                            "taskID": taskID,
                            "tempFilePath": destFilePath,
                        ]
                    )
                    // 生成 payload
                    return Observable.just(try Self.encode(type: .internal, model: payload))
                }).subscribe(
                    //成功回调
                    onNext: { (payload: String) in
                        context.apiTrace.info(
                            "tt.downloadFile callback success",
                            tag: "tt.downloadFile",
                            additionalData: ["taskID": taskID]
                        )
                        
                        resultMonitor.flushSuccess()
                        callback(.success(data: OpenAPINetworkRequestResult(payload: payload)))
                    },
                    //失败回调
                    onError: { error in
                        context.apiTrace.error(
                            "tt.downloadFile callback fail:" + error.localizedDescription,
                            tag: "tt.downloadFile",
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
                ).disposed(by: disposeBag)
        }
}

// MARK: - tt.downloadFileAbort
extension OpenPluginNetwork {
    public func downloadAbort(
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
                    model: OpenPluginNetworkDownloadAbortParamsPayload.self,
                    fromJson: params.payload
                )
                var apiContext = try Self.apiContext(from: uniqueID)
                apiContext.traceID = context.apiTrace.traceId
                reqCmd = Openplatform_Api_OpenAPIRequest()
                reqCmd.apiContext = apiContext
                reqCmd.apiName = APIName.downloadFileAbort.rawValue
                reqCmd.payload = params.payload
                taskID = payload.taskID
            } catch let error {
                context.apiTrace.error(
                    "tt.downloadFile.abort prepare abort context fail:" + error.localizedDescription,
                    tag: "tt.downloadFile"
                )
                callback(.failure(error: Self.apiError(context: context, error: error)))
                return
            }
            
            context.apiTrace.info(
                "tt.downloadFile.abort will send async request",
                tag: "tt.downloadFile",
                additionalData: ["taskID": taskID]
            )
            
            // 下发指令
            rustService.sendAsyncRequest(reqCmd)
                .subscribe (
                    onNext: { (response: Openplatform_Api_OpenAPIResponse) in
                        context.apiTrace.info(
                            "tt.downloadFile.abort callbcak success",
                            tag: "tt.downloadFile",
                            additionalData: ["taskID": taskID]
                        )
                        callback(.success(data: OpenAPINetworkRequestResult(payload: nil)))
                    },
                    onError: {(error) in
                        context.apiTrace.error(
                            "tt.downloadFile.abort callbcak fail",
                            tag: "tt.downloadFile",
                            additionalData: ["taskID": taskID],
                            error: error
                        )
                        callback(.failure(
                            error: Self.apiError(context: context, error: error)
                        ))
                    }
                )
                .disposed(by: disposeBag)
    }
}
