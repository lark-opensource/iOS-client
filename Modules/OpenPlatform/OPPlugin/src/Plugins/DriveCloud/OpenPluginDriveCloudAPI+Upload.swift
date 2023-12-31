//
//  OpenPluginDriveCloudAPI+Upload.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/9/1.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkOpenPluginManager
import RxSwift

extension OpenPluginDriveCloudAPI {
    
    public func uploadFileToCloud(
        params: OpenPluginUploadFileToCloudRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginUploadFileToCloudResponse>) -> Void) {
            // 创建埋点
            let startMonitor = OPMonitor.startMonitor(withContext: context, name: MonitorEventName.UploadStart)
            // 创建结束点
            let resultMonitor = OPMonitor.resultMonitor(withContext: context, name: MonitorEventName.UploadResult)
            
            // 上下文变量定义
            var realFilePath: String
            var fileObj: FileObject
            let apiName = "tt.\(APIName.uploadFileToCloud.rawValue)"
            
            do {
                // 将入参 filePath 从 ttfile:// 转为 file://
                (fileObj, realFilePath) = try OpenPluginUploadTask.getRealFilePath(
                    context: context,
                    ttFilePath: params.filePath,
                    tag: apiName,
                    needCheckPageFile: false
                )
            } catch let error {
                context.apiTrace.error(
                    "\(apiName) prepare upload context fail \(error)",
                    tag: apiName
                )
                // 文件类型错误转义成网络封装的错误
                let apiError = OpenPluginNetwork.apiError(context: context, error: error)
                startMonitor.flushFail(withAPIError: apiError)
                resultMonitor.flushFail(withAPIError: apiError)
                callback(.failure(error: apiError))
                return
            }
            
            var uploadFileName: String
            if let fileName = params.fileName, !fileName.isEmpty {
                uploadFileName = fileName
            } else {
                uploadFileName = fileObj.lastPathComponent
            }
            
            // 埋点处理
            startMonitor.flushSuccess()
            
            context.apiTrace.info(
                "\(apiName) will call drive api",
                tag: apiName,
                additionalData: [
                    "inputFilePath": params.filePath.toBase64(),
                    "realFilePath": realFilePath.toBase64()
                ]
            )

            var driveExtra: [String: String]? = nil
            if let extra = params.extra,
                let extraStr = extraString(extra: extra) {
                // 这块是历史原因，drive 的 upload 接口的 extra 需要再包一层
                driveExtra = ["extra": extraStr]
            }

            var lastProgressTimestamp = Date().timeIntervalSince1970 * 1000
            container.add(operation: DriveOperation(taskID: params.taskID))
            _ = uploader.upload(localPath: realFilePath,
                                fileName: uploadFileName,
                                mountNodePoint: params.mountNodePoint,
                                mountPoint: params.mountPoint,
                                extra: driveExtra)
            .subscribe {[weak self] (uploadKey, progress, objToken, uploadStatus) in
                guard let self = self else {
                    context.apiTrace.error("self is nil")
                    callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unknown)))
                    return
                }

                self.container.update(key: uploadKey, forTaskID: params.taskID)
                if self.container.shouldAbort(params.taskID) == true,
                    let abortCallback = self.container.abortCallback(params.taskID) {
                    self.handleAbort(context: context, taskID: params.taskID, key: uploadKey, callback: abortCallback)
                }

                guard uploadStatus == .success
                        || uploadStatus == .failed
                        || uploadStatus == .cancel
                        || uploadStatus == .inflight else {
                    context.apiTrace.info("not success/failed/cancel/inflight, status is \(uploadStatus.rawValue)")
                    return
                }
                if uploadStatus == .inflight || uploadStatus == .success {
                    let currentTimestamp = Date().timeIntervalSince1970 * 1000
                    guard currentTimestamp - lastProgressTimestamp > self.progressInternal || progress >= 1 else {
                        return
                    }
                    lastProgressTimestamp = currentTimestamp
                    self.handleProgress(context: context, progress: progress * 100, taskID: params.taskID)
                }
                if uploadStatus == .inflight {
                    return
                }
                guard uploadStatus == .success else {
                    // failed or cancel
                    context.apiTrace.error(
                        "\(apiName) callback error",
                        tag: apiName,
                        additionalData: [
                            "uploadKey": uploadKey,
                            "fileToken": objToken,
                            "uploadStatus": "\(uploadStatus.rawValue)",
                        ]
                    )
                    return
                }
                context.apiTrace.info(
                    "\(apiName) callback success",
                    tag: apiName,
                    additionalData: [
                        "uploadKey": uploadKey,
                        "fileToken": objToken,
                    ]
                )
                resultMonitor.flushSuccess()
                callback(.success(data: OpenPluginUploadFileToCloudResponse(fileName: uploadFileName, fileToken: objToken)))
                self.container.remove(params.taskID)
            } onError: { [weak self] error in
                guard let self = self else {
                    context.apiTrace.error("self is nil")
                    callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unknown)))
                    return
                }
                context.apiTrace.error(
                    "\(apiName) callback fail:" + error.localizedDescription,
                    tag: apiName
                )
                let errorDetail = Self.driveSDKExtraErrString(errorCode: nil, driveError: error)
                let errno = OpenAPIDriveCloudErrno.driveSdkError(errorDetail: errorDetail)
                let apiError = OpenAPIError(errno: errno)
                resultMonitor.flushFail(withAPIError: apiError)
                callback(.failure(error: apiError))
                self.container.remove(params.taskID)
            }.disposed(by: disposeBag)
        }

    public func uploadFileToCloudAbort(
        params: OpenPluginUploadFileToCloudAbortRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            guard container.hasOperation(taskID: params.taskID) else {
                context.apiTrace.info("uploadFileToCloudAbort has not operation \(params.taskID) ")
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
        uploader.cancelUpload(key: key).subscribe {[weak self] success in
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
            context.apiTrace.error("upload handle progress taskID is empty")
            return
        }
        let realProgress = progress <= 100 ? progress : 100;
        let response = OpenPluginOnUploadFileToCloudUpdateResponse(taskID: taskID, progress: Int(realProgress))
        do {
            let fireEvent = try OpenAPIFireEventParams(
                event: APIName.onUploadFileToCloudUpdate.rawValue,
                sourceID: NSNotFound,
                data: response.toJSONDict(),
                preCheckType: .shouldInterruption,
                sceneType: .normal
            )
            let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
        } catch let error {
            context.apiTrace.error("upload create OpenAPIFireEventParams fail, \(error.localizedDescription)")
        }
    }
}
