//
//  OpenPluginDriveCloudAPI+Preview.swift
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

    public func openFileFromCloud(
        params: OpenPluginOpenFileFromCloudRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            
            guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
                return
            }
            
            guard let nav = BDPResponderHelper.topNavigationController(for: BDPResponderHelper.topmostView(controller.view.window)) else {
                let msg = "no top most vc"
                context.apiTrace.error(msg)
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage(msg)
                callback(.failure(error: error))
                return
            }

            if let paramsError = params.checkParams() {
                context.apiTrace.error("checkParams fail \(paramsError.errnoInfo)")
                callback(.failure(error: paramsError))
                return
            }
            params.adjustParams()

            guard let vc = previewProxy.preview(
                contexts: buildContexts(params),
                actions: [.saveToLocal(handler: { [weak self] _, info in
                self?.previewProxyOnDownloadComplete(taskID: params.taskID, context: context, downloadInfo: info)
            })]
            ) else {
                let msg = "no vc"
                context.apiTrace.error(msg)
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage(msg)
                callback(.failure(error: error))
                return
            }
            nav.pushViewController(vc, animated: true)
            callback(.success(data: nil))
    }
}

extension OpenPluginDriveCloudAPI {
    private func buildContexts(_ params: OpenPluginOpenFileFromCloudRequest) -> [OpenPluginDrivePreviewContext] {
        if let realFileToken = params.fileToken {
            let previewContext = OpenPluginDrivePreviewContext(
                fileToken: realFileToken,
                mountNodePoint:
                    params.mountNodePoint,
                mountPoint: params.mountPoint,
                extra: extraString(extra: params.extra)
            )
            return [previewContext]
        }
        var contexts = [OpenPluginDrivePreviewContext]()
        for file in params.files ?? [] {
            var mountNodePoint = params.mountNodePoint
            var mountPoint = params.mountPoint
            if let fileMountNodePoint = file.mountNodePoint {
                mountNodePoint = fileMountNodePoint
            }
            if let fileMountPoint = file.mountPoint {
                mountPoint = fileMountPoint
            }
            let previewContext = OpenPluginDrivePreviewContext(
                fileToken: file.fileToken,
                mountNodePoint: mountNodePoint,
                mountPoint: mountPoint,
                extra: extraString(extra: file.extra)
            )
            contexts.append(previewContext)
        }
        return contexts
    }
}

extension OpenPluginOpenFileFromCloudRequest {
    func checkParams() -> OpenAPIError? {
        if fileToken?.count ?? 0 <= 0, files?.count ?? 0 <= 0 {
            return OpenAPIError(errno: OpenAPIDriveCloudErrno.fileTokenAndFilesCanNotBothEmpty)
        }
        if let fileToken = fileToken, fileToken.count >= 0, let files = files, files.count >= 0 {
            return OpenAPIError(errno: OpenAPIDriveCloudErrno.fileTokenAndFilesCanNotBothExist)
        }
        return nil
    }

    func adjustParams() {
        guard let files = files else {
            return
        }
        var realFiles = [OpenPluginOpenFileFromCloudRequest.FilesItem]()
        for (index, item) in files.enumerated() {
            item.extra = merge(highPriorityExtra: item.extra, lowPriorityExtra: extra)
            realFiles.append(item)
        }
        self.files = realFiles
    }

    private func merge(highPriorityExtra: [AnyHashable: Any]?, lowPriorityExtra: [AnyHashable: Any]?) -> [AnyHashable: Any]? {
        guard let highPriorityExtra = highPriorityExtra, let lowPriorityExtra = lowPriorityExtra else {
            return highPriorityExtra != nil ? highPriorityExtra : lowPriorityExtra
        }
        var result = highPriorityExtra
        result.merge(lowPriorityExtra) { current, _ in current }
        return result
    }
}

extension OpenPluginDriveCloudAPI {
    func previewProxyOnDownloadComplete(taskID: String, context: OpenAPIContext, downloadInfo: OpenPluginDrivePreviewDownloadCompleteInfo) {
        let response = OpenPluginOnOpenFileFromCloudDownloadCompleteResponse(
            fileName: downloadInfo.fileName,
            fileToken: downloadInfo.fileToken,
            fileType: downloadInfo.fileType,
            size: downloadInfo.size,
            taskID: taskID
        )
        do {
            let fireEvent = try OpenAPIFireEventParams(
                event: APIName.onOpenFileFromCloudDownloadComplete.rawValue,
                sourceID: NSNotFound,
                data: response.toJSONDict(),
                preCheckType: .none,
                sceneType: .normal
            )
            let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
        } catch let error {
            context.apiTrace.error("preview create onOpenFileFromCloudDownloadComplete fail, \(error.localizedDescription)")
        }
    }
}
