//
//  OpenPluginDocument.swift
//  OPPlugin
//
//  Created by yi on 2021/4/13.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPPluginBiz
import OPFoundation
import LarkContainer

final class OpenPluginDocument: OpenBasePlugin {

    func openDocument(
        params: OpenAPIOpenDocumentParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let gadgetContext = context.gadgetContext,
                let controller = gadgetContext.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("gadgetContext is nil")
                        .setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        guard let routeDelegate = EMAProtocolProvider.getEMADelegate() else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("not implemented")
                .setErrno(OpenAPICommonErrno.unknown)
            callback(.failure(error: error))
            return
        }
        if params.fileType == "cloudFile" {
            context.apiTrace.info("openDocument fileType: cloudFile")
            if let url = URL(string: params.filePath) {
                // driveSDK判断云文档路径合法性，会在这里判断 url 是否为合法的云文档路径，包括scheme校验。
                guard routeDelegate.canOpen(url, fromScene: .document) else {
                    context.apiTrace.debug("spaceFile filePath doesn't support, \(params.filePath)")
                    let error = OpenAPIError(code: OpenAPIOpenDocumentErrorCode.notCloudFile)
                        .setMonitorMessage("filePath doesn't support")
                        .setErrno(OpenAPIOpenDocumentErrno.notCloudFile)
                    callback(.failure(error: error))
                    return
                }
                // 打开云文档
                routeDelegate.open(
                    url,
                    fromScene: .document,
                    uniqueID: uniqueID,
                    from: controller
                )
                callback(.success(data: nil))
            } else {
                context.apiTrace.debug("filePath doesn't support, \(params.filePath)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("filePath doesn't support")
                    .setErrno(OpenAPICommonErrno.unknown)
                callback(.failure(error: error))
                return
            }
        } else {
            context.apiTrace.info("openDocument fileType: localFile")
            let fullScreen = params.padFullScreen
            do {
                let file = try FileObject(rawValue: params.filePath)
                let fsContext = FileSystem.Context(
                    uniqueId: uniqueID,
                    trace: context.apiTrace,
                    tag: "openDocument",
                    isAuxiliary: true
                )
                // 获取真实文件路径，如果为包路径，则根据 isAuxiliary 缓存到 auxiliary 目录后获取
                let systemFilePath = try FileSystemCompatible.getSystemFile(from: file, context: fsContext)
                // 打开文件
                DispatchQueue.main.async {
                    let fileURL = URL(fileURLWithPath: systemFilePath)
                    let lastPathComponent = fileURL.lastPathComponent
                    routeDelegate.openSDKPreview(
                        lastPathComponent,
                        fileUrl: fileURL,
                        fileType: params.fileType,
                        fileID: lastPathComponent,
                        showMore: params.showMenu,
                        from: controller,
                        thirdPartyAppID: uniqueID.appID,
                        padFullScreen: fullScreen
                    )
                    callback(.success(data: nil))
                }
            } catch let fileError as FileSystemError {
                let fileCommonErrno = fileError.fileCommonErrno
                var openApiError: OpenAPIError
                switch fileError {
                case FileSystemError.invalidFilePath(_) :
                    /// 非 小程序文件系统目录【包括： ttfile://user 、 ttfile://temp 或 包体目录（a/b/c, /a/b/c, ./a/b/c）】
                    openApiError = OpenAPIError(code: OpenAPIOpenDocumentErrorCode.invilidFilePath)
                        .setErrno(fileCommonErrno)
                case FileSystemError.biz(.resolveFilePathFailed(_, _)),
                     FileSystemError.biz(.resolveLocalFileInfoFailed(_, _)),
                     FileSystemError.biz(.resolveStorageModuleFailed(_)) :
                    openApiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("resolve file failed")
                        .setErrno(fileCommonErrno)
                case FileSystemError.isNotFile(_, _) :
                    // 是否文件
                    openApiError = OpenAPIError(code: OpenAPIOpenDocumentErrorCode.notFile)
                        .setErrno(fileCommonErrno)
                case FileSystemError.fileNotExists(_, _) :
                    // 文件存在性
                    openApiError = OpenAPIError(code: OpenAPIOpenDocumentErrorCode.fileNotExist)
                        .setErrno(fileCommonErrno)
                case FileSystemError.readPermissionDenied(_, _) :
                    // 读权限
                    openApiError = OpenAPIError(code: OpenAPIOpenDocumentErrorCode.readPermissionDenied)
                        .setErrno(fileCommonErrno)
                default:
                    openApiError = fileError.fileSystemUnknownError
                }
                callback(.failure(error: openApiError))
            } catch {
                context.apiTrace.error("openDocument unknown error", error: error)
                callback(.failure(error: error.fileSystemUnknownError))
            }
        }
    }
    
    func docsPicker(params: OpenAPIDocsPickerParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: @escaping (OpenAPIBaseResponse<OpenAPIDocsPickerResult>) -> Void) {
        guard let delegate = EMAProtocolProvider.getEMADelegate(), delegate.responds(to: #selector(EMAProtocol.docsPickerTitle(_:maxNum:confirm:uniqueID:from:block:))) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("docsPicker no implementation").setErrno(OpenAPICommonErrno.unable)
            callback(.failure(error: error))
            return
        }

        delegate.docsPickerTitle(
            params.pickerTitle,
            maxNum: params.maxNum,
            confirm: params.pickerConfirm,
            uniqueID: gadgetContext.uniqueID,
            from: gadgetContext.controller
        ) { (dict, isCancel) in
            if isCancel {
                // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setOuterMessage("user cancel")
                    .setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
            guard !BDPIsEmptyDictionary(dict) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("empty callback params")
                    .setErrno(OpenAPICommonErrno.unknown)
                callback(.failure(error: error))
                return
            }
            context.apiTrace.info("docsPicker success")
            callback(.success(data: OpenAPIDocsPickerResult(dict: dict)))
        }
    }


    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "openDocument", pluginType: Self.self, paramsType: OpenAPIOpenDocumentParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.openDocument(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "docsPicker", pluginType: Self.self, paramsType: OpenAPIDocsPickerParams.self, resultType: OpenAPIDocsPickerResult.self) { (this, params, context, gadgetContext, callback) in
            this.docsPicker(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}

