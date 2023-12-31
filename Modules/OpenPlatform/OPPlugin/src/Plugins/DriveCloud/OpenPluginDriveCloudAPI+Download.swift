//
//  OpenPluginDriveCloudAPI+Download.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/9/1.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkOpenPluginManager
import RxSwift
import OPFoundation
import LKCommonsLogging

extension OpenPluginDriveCloudAPI {
    
    private static let downloadLogger = Logger.oplog(OpenPluginDriveCloudAPI.self, category: "Download")
    
    public func downloadFileFromCloud(
        params: OpenPluginDownloadFileFromCloudRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginDownloadFileFromCloudResponse>) -> Void) {
            
            // 创建埋点
            let startMonitor = OPMonitor.startMonitor(withContext: context, name: MonitorEventName.DownloadStart)
            let resultMonitor = OPMonitor.resultMonitor(withContext: context, name: MonitorEventName.DownloadResult)
            
            // 上下文变量定义
            var uniqueID: OPAppUniqueID
            var fsContext: FileSystem.Context
            var inputFileObj: FileObject?
            var tempDownloadPath: String
            let apiName = "tt.\(APIName.downloadFileFromCloud.rawValue)"
            
            // 请求上下文,校验及准备
            do {
                uniqueID = try OpenPluginNetwork.getUniqueID(context: context)
                
                // 如果用户传了ttfile:// 路径， 就将其转换成privatePath和文件名，doc下载完后，将目标移动出来，放到用户指定的ttfile下
                // 如果用户没有传ttfile:// 路径，就生成一个privatePath，doc下载完成后，将其移动出来，放到用户指定的ttfile下
                fsContext = FileSystem.Context(
                    uniqueId: uniqueID,
                    trace: context.apiTrace,
                    tag: apiName,
                    isAuxiliary: false
                )
                
                if let filePath = params.filePath, !filePath.isEmpty {
                    inputFileObj = try OpenPluginDownloadTask.generateInputObject(context: fsContext, filePath: filePath)
                }
                
                // 下载文件临时存放地址, 用于下载, 下载完毕后会移动到正式路径
                // 创建临时保存目录, 避免下载同名文件时覆盖
                tempDownloadPath = try OpenPluginDownloadTask.generatePrivateTmpRandomInnerPath(from: uniqueID)
                
            } catch let error {
                context.apiTrace.error(
                    "\(apiName) prepare download context fail: \(error)",
                    tag: apiName
                )
                // 文件类型错误转义成网络封装的错误
                let apiError = OpenPluginNetwork.apiError(context: context, error: error)
                startMonitor.flushFail(withAPIError: apiError)
                resultMonitor.flushFail(withAPIError: apiError)
                callback(.failure(error: apiError))
                return
            }
            
            // 埋点处理
            startMonitor.flushSuccess()
            
            context.apiTrace.info(
                "\(apiName) will call drive api",
                tag: apiName,
                additionalData: [
                    "inputFilePath": inputFileObj?.rawValue.toBase64() ?? "",
                    "downloadTempFilePath": tempDownloadPath.toBase64(),
                ]
            )
            
            // 方案1: localFilePath传入nil, 返回自动生成的乱码文件名.
            // 方案2: 传入path+文件名，check是否返回文件。能正常返回，但是文件名丢失了.
            // 方案3: 传入path, check是否塞入正确文件名. 采用方案3
            let requestContext = OpenPluginDriveDownloadRequestContext(
                fileToken: params.fileToken,
                mountNodePoint: params.mountNodePoint,
                mountPoint: params.mountPoint,
                localFilePath: tempDownloadPath,
                extra: extraString(extra: params.extra))
            
            var wrapperCallback: ((String) -> ())? = { errorDetail in
                let errno = OpenAPIDriveCloudErrno.driveSdkError(errorDetail: errorDetail)
                let apiError = OpenAPIError(errno: errno)
                resultMonitor.flushFail(withAPIError: apiError)
                callback(.failure(error: apiError))
            }

            var lastProgressTimestamp = Date().timeIntervalSince1970 * 1000

            container.add(operation: DriveOperation(taskID: params.taskID))
            _ = downloader.download(with: requestContext)
                .subscribe {[weak self] response in
                    guard let self = self else {
                        context.apiTrace.error("self is nil")
                        callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unknown)))
                        return
                    }
                    self.container.update(key: response.key, forTaskID: params.taskID)

                    if self.container.shouldAbort(params.taskID) == true,
                        let abortCallback = self.container.abortCallback(params.taskID) {
                        self.handleAbort(context: context, taskID: params.taskID, key: response.key, callback: abortCallback)
                    }

                    let status = response.downloadStatus
                    guard status == .success
                            || status == .failed
                            || status == .cancel
                            || status == .inflight else {
                        context.apiTrace.info("not success/failed/cancel/inflight, status is \(status.rawValue)")
                        return
                    }

                    if status == .inflight || status == .success {
                        let totalSize = response.downloadProgress.1
                        guard totalSize > 0 else { return }
                        let progress = response.downloadProgress.0 * 100 / totalSize
                        let currentTimestamp = Date().timeIntervalSince1970 * 1000
                        guard currentTimestamp - lastProgressTimestamp >= self.progressInternal || progress >= 100 else {
                            return
                        }
                        lastProgressTimestamp = currentTimestamp
                        self.handleProgress(context: context, progress: progress, taskID: params.taskID)
                    }
                    if status == .inflight {
                        return
                    }
                    guard status == .success else {
                        // failed or cancel
                        context.apiTrace.error(
                            "\(apiName) callback error",
                            tag: apiName,
                            additionalData: [
                                "key": response.key,
                                "fileToken": response.requestContext.fileToken,
                                "downloadStatus": "\(status.rawValue)",
                            ]
                        )
                        let errorDetail = Self.driveSDKExtraErrString(errorCode: response.errorCode, driveError: nil)
                        if let wrapperCallback = wrapperCallback {
                            wrapperCallback(errorDetail)
                        } else {
                            Self.downloadLogger.error("Cannot find wrapperCallback when \(errorDetail)")
                        }
                        wrapperCallback = nil
                        return
                    }
                    let filePath = response.localFilePath
                    let fileName = response.fileName
                    let destFilePath: String
                    do {
                        /// 将文件移动到目标路径
                        destFilePath = try OpenPluginDownloadTask.moveDownloadFile(
                            context: fsContext,
                            source: filePath,
                            filename: fileName,
                            targetFileObj: inputFileObj
                        )
                    } catch let error {
                        context.apiTrace.error(
                            "\(apiName) moved download file failed: \(error)",
                            tag: apiName
                        )
                        // 文件类型错误转义成网络封装的错误
                        let apiError = OpenPluginNetwork.apiError(context: context, error: error)
                        resultMonitor.flushFail(withAPIError: apiError)
                        callback(.failure(error: apiError))
                        return
                    }
                    context.apiTrace.info(
                        "\(apiName) callback success",
                        tag: apiName,
                        additionalData: [
                            "key": response.key,
                            "fileToken": response.requestContext.fileToken,
                        ]
                    )
                    resultMonitor.flushSuccess()
                    callback(.success(data: OpenPluginDownloadFileFromCloudResponse(tempFilePath: destFilePath)))
                    self.container.remove(params.taskID)
                } onError: { [weak self] error in
                    context.apiTrace.error(
                        "\(apiName) callback fail:" + error.localizedDescription,
                        tag: apiName
                    )
                    if let wrapperCallback = wrapperCallback {
                        wrapperCallback(Self.driveSDKExtraErrString(errorCode: nil, driveError: error))
                    } else {
                        Self.downloadLogger.error("Cannot find wrapperCallback when onError is called")
                    }
                    wrapperCallback = nil
                    self?.container.remove(params.taskID)
                }.disposed(by: disposeBag)
        }

    public func downloadFileFromCloudAbort(
        params: OpenPluginDownloadFileFromCloudAbortRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            guard container.hasOperation(taskID: params.taskID) else {
                context.apiTrace.info("downloadFileFromCloudAbort has not operation \(params.taskID) ")
                callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unknown)))
                return
            }
            if let key = container.key(params.taskID) {
                context.apiTrace.info("uploadFileToCloudAbort has key \(key) \(params.taskID)")
                handleAbort(context: context, taskID: params.taskID, key: key, callback: callback)
            } else {
                context.apiTrace.info("uploadFileToCloudAbort has not key \(params.taskID)")
                container.abort(params.taskID, callback: callback)
            }
        }

    private func handleAbort(
        context: OpenAPIContext,
        taskID: String,
        key: String,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        context.apiTrace.error("start abort \(taskID)")
        container.removeAbortTask(taskID)
        downloader.cancelDownload(key: key).subscribe {[weak self] success in
            context.apiTrace.error("abort result \(success)")
            if success {
                callback(.success(data: nil))
                self?.container.remove(taskID)
            } else {
                callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unknown)))
            }
        } onError: { [weak self] error in
            context.apiTrace.error("abort fail \(error.localizedDescription)")
            callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unknown)))
        }
        .disposed(by: disposeBag)
    }

    private func handleProgress(context: OpenAPIContext, progress: Float, taskID: String) {
        guard taskID.count > 0 else {
            context.apiTrace.error("download handle progress taskID is empty")
            return
        }
        let realProgress = progress <= 100 ? progress : 100;
        let response = OpenPluginOnDownloadFileFromCloudUpdateResponse(taskID: taskID, progress: Int(realProgress))
        do {
            let fireEvent = try OpenAPIFireEventParams(
                event: APIName.onDownloadFileFromCloudUpdate.rawValue,
                sourceID: NSNotFound,
                data: response.toJSONDict(),
                preCheckType: .shouldInterruption,
                sceneType: .normal
            )
            let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
        } catch let error {
            context.apiTrace.error("create OpenAPIFireEventParams fail, \(error.localizedDescription)")
        }
    }
}
