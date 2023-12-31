//
//  RustFileAPI.swift
//  Lark-Rust
//
//  Created by Sylar on 2017/12/11.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import ServerPB
import LKCommonsLogging

final class RustFileAPI: LarkAPI, FileAPI, SecurityFileAPI {
    var logger = Logger.log(SecurityFileAPI.self, category: "LarkSDK.RustSDK")
    /// 缓存一小时
    private var unfairLock = os_unfair_lock_s()
    private var _canUserDownloadFileCache: ServerPB_Compliance_CanUserDownloadRiskFileResponse?
    private var canUserDownloadFileCache: ServerPB_Compliance_CanUserDownloadRiskFileResponse? {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            return _canUserDownloadFileCache
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            if newValue != nil {
                DispatchQueue.global().asyncAfter(deadline: .now() + 3600) {
                    self.canUserDownloadFileCache = nil
                }
            }
            _canUserDownloadFileCache = newValue
            logger.info("RustFileAPI.canUserDownloadFileCache update: \(newValue?.canDownload.stringValue ?? "nil")")
        }
    }

    // swiftlint:disable function_parameter_count
    func downloadFile(
        messageId: String,
        key: String,
        authToken: String?,
        authFileKey: String,
        absolutePath: String,
        isCache: Bool = false,
        type: RustPB.Basic_V1_File.EntityType,
        channelId: String,
        sourceType: LarkModel.Message.SourceType,
        sourceID: String,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<String> {
        var request = RustPB.Media_V1_DownloadFileRequest()
        request.messageID = messageId
        request.key = key
        if let authToken = authToken {
            request.options.previewToken = authToken
        }
        request.options.authFileKey = authFileKey
        request.action = .download
        request.type = type
        request.isCache = isCache
        request.path = absolutePath
        request.channelID = channelId
        request.sourceType = sourceType
        request.sourceID = sourceID
        if let downloadFileScene = downloadFileScene {
            request.scene = downloadFileScene
        }
        return client.sendAsyncRequest(request).map { (response: RustPB.Media_V1_DownloadFileResponse) -> String in
            return response.path
        }.subscribeOn(scheduler)
    }
    // swiftlint:enable function_parameter_count

    func cancelDownloadFile(
        messageId: String,
        key: String,
        authToken: String?,
        authFileKey: String,
        type: RustPB.Basic_V1_File.EntityType,
        channelId: String,
        sourceType: LarkModel.Message.SourceType,
        sourceID: String,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<Void> {
        var request = RustPB.Media_V1_DownloadFileRequest()
        request.messageID = messageId
        request.key = key
        if let authToken = authToken {
            request.options.previewToken = authToken
        }
        request.options.authFileKey = authFileKey
        request.action = .cancel
        request.type = type
        request.channelID = channelId
        request.sourceType = sourceType
        request.sourceID = sourceID
        if let downloadFileScene = downloadFileScene {
            request.scene = downloadFileScene
        }
        return client.sendAsyncRequest(request).map { _ in }.subscribeOn(scheduler)
    }

    func uploadFiles(keyAndPaths: [String: String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void> {
        var request = RustPB.Media_V1_UploadFilesRequest()
        request.key2Paths = keyAndPaths
        request.action = .upload
        request.type = type

        return client.sendAsyncRequest(request).map { _ in }.subscribeOn(scheduler)
    }

    func uploadFiles(cids: [String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void> {
        var request = RustPB.Media_V1_UploadFilesRequest()
        request.cids = cids
        request.action = .upload
        request.type = type

        return client.sendAsyncRequest(request).map { _ in }.subscribeOn(scheduler)
    }

    func cancelUploadFiles(cids: [String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void> {
        var request = RustPB.Media_V1_UploadFilesRequest()
        request.cids = cids
        request.action = .cancel
        request.type = type

        return client.sendAsyncRequest(request).map { _ in }.subscribeOn(scheduler)
    }

    func saveFileToSpaceStore(messageId: String, chatId: String, key: String?, sourceType: LarkModel.Message.SourceType, sourceID: String) -> Observable<Void> {
        var request = RustPB.Media_V1_SaveToSpaceStoreRequest()
        request.messageID = messageId
        request.sourceType = sourceType
        request.sourceID = sourceID
        if let key = key { request.appFileID = key }
        request.appID = "1001" //这个是标志业务线的，messenger是1001
        let authExtra = [
            "msg_id": messageId,
            "chat_id": chatId
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: authExtra, options: .prettyPrinted),
           let authExtraString = String(data: jsonData, encoding: .utf8) {
            request.authExtra = authExtraString
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getFileStateRequest(messageId: String,
                             sourceType: LarkModel.Message.SourceType,
                             sourceID: String,
                             authToken: String?,
                             downloadFileScene: Media_V1_DownloadFileScene?) -> Observable<RustPB.Media_V1_GetFileStateResponse.State> {
        var request = RustPB.Media_V1_GetFileStateRequest()
        request.messageID = messageId
        request.sourceType = sourceType
        request.sourceID = sourceID
        if let authToken = authToken {
            request.options.previewToken = authToken
        }
        if let downloadFileScene = downloadFileScene {
            request.scene = downloadFileScene
        }
        return client.sendAsyncRequest(request)
            .map({ (response: RustPB.Media_V1_GetFileStateResponse) -> RustPB.Media_V1_GetFileStateResponse.State in
                return response.state
            })
            .subscribeOn(scheduler)
    }

    func getFileMeta(fileKey: String) -> Observable<FileMeta> {
        var request = RustPB.Media_V1_GetFileMetaRequest()
        request.key = fileKey
        let response: Observable<RustPB.Media_V1_GetFileMetaResponse> = client.sendAsyncRequest(request)
        return response.map({ (response) -> FileMeta in
            let filePath = response.hasFilePath ? response.filePath : nil
            let progress = response.hasProgress ? Int(response.progress) : nil
            return FileMeta(filePath: filePath, progress: progress)
        })
        .subscribeOn(scheduler)
    }

    func browseFolderRequest(
        key: String,
        authToken: String?,
        authFileKey: String,
        start: Int64,
        step: Int64,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<RustPB.Media_V1_BrowseFolderResponse> {
        var request = RustPB.Media_V1_BrowseFolderRequest()
        var serverReq = RustPB.Media_V1_BrowseFolderRequest.SerReq()
        serverReq.key = key
        if let authToken = authToken {
            request.options.previewToken = authToken
        }
        request.options.authFileKey = authFileKey
        serverReq.start = start
        serverReq.step = step
        request.serReq = serverReq
        if let downloadFileScene = downloadFileScene {
            request.scene = downloadFileScene
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func extractPackageRequest(
        key: String,
        authToken: String?,
        authFileKey: String,
        step: Int64,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<RustPB.Media_V1_ExtractPackageResponse> {
        var request = RustPB.Media_V1_ExtractPackageRequest()
        var browseFolderRequest = RustPB.Media_V1_BrowseFolderRequest()
        var serverReq = RustPB.Media_V1_BrowseFolderRequest.SerReq()
        serverReq.key = key
        serverReq.start = 0
        serverReq.step = step
        browseFolderRequest.serReq = serverReq
        if let authToken = authToken {
            browseFolderRequest.options.previewToken = authToken
        }
        browseFolderRequest.options.authFileKey = authFileKey
        if let downloadFileScene = downloadFileScene {
            browseFolderRequest.scene = downloadFileScene
        }
        request.request = browseFolderRequest
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func cancelExtractPackageRequest(key: String) -> Observable<RustPB.Media_V1_CancelExtractPackagePollResponse> {
        var request = RustPB.Media_V1_CancelExtractPackagePollRequest()
        request.key = key
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func uploadResource(uploadID: String,
                        chatID: String,
                        filePath: String,
                        fileType: Basic_V1_ResourceFile.FileType) -> Observable<Im_V1_UploadResourceResponse> {
        var uploadRequest = Im_V1_UploadResourceRequest()
        uploadRequest.uploadID = uploadID
        uploadRequest.chatID = chatID
        var file = Basic_V1_ResourceFile()
        file.fileType = fileType
        file.filePath = filePath
        uploadRequest.file = file
        return client.sendAsyncRequest(uploadRequest)
    }

    func cancelAsyncUpload(uploadIds: [String]) -> Observable<Im_V1_CancelAsyncUploadResponse> {
        var request = Im_V1_CancelAsyncUploadRequest()
        request.uploadIds = uploadIds
        return client.sendAsyncRequest(request)
    }

    func canDownloadFile(detectRiskFileMeta: DetectRiskFileMeta) -> Observable<Bool> {
        return self.canUserDownloadFile().map { (res: ServerPB_Compliance_CanUserDownloadRiskFileResponse) -> Bool in
            return res.canDownload
        }
    }

    func canDownloadFiles(detectRiskFileMetas: [DetectRiskFileMeta]) -> Observable<[String: Bool]> {
        return self.canUserDownloadFile().map { (res: ServerPB_Compliance_CanUserDownloadRiskFileResponse) -> [String: Bool] in
            return detectRiskFileMetas.reduce(into: [:]) { (partialResult, meta) in
                partialResult[meta.key] = res.canDownload
            }
        }
    }

    /// 根据@陈庆松描述，提供一个1h的缓存。
    func canUserDownloadFile() -> Observable<ServerPB_Compliance_CanUserDownloadRiskFileResponse> {
        return Observable.just(self.canUserDownloadFileCache).flatMap { userDownloadCache -> Observable<ServerPB_Compliance_CanUserDownloadRiskFileResponse> in
            if let cache = userDownloadCache {
                return .just(cache)
            }
            var request = ServerPB_Compliance_CanUserDownloadRiskFileRequest()
            request.sourceTerminal = .mobile
            request.opUsage = .download
            return self.client.sendPassThroughAsyncRequest(request, serCommand: .canUserDownloadFile)
                .do(onNext: { [weak self] (res: ServerPB_Compliance_CanUserDownloadRiskFileResponse) in
                    if self?.canUserDownloadFileCache == nil {
                        self?.canUserDownloadFileCache = res
                    }
                }, onError: { [weak self] error in
                    self?.logger.error("RustFileAPI.canUserDownloadFile()", error: error)
                })
        }
    }
}
