//
//  RustSecurityFileAPI.swift
//  LarkSDK
//
//  Created by qihongye on 2023/10/7.
//

import Foundation
import RxSwift
import RustPB
import ServerPB
import LarkSDKInterface
import LarkModel

final class RustSecurityFileAPI: LarkAPI, SecurityFileAPI {
    let fileAPI: RustFileAPI

    override init(client: SDKRustService, onScheduler: ImmediateSchedulerType? = nil) {
        self.fileAPI = RustFileAPI(client: client, onScheduler: onScheduler)
        super.init(client: client, onScheduler: onScheduler)
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
        return self.fileAPI.downloadFile(
            messageId: messageId, key: key, authToken: authToken, authFileKey: authFileKey, absolutePath: absolutePath, isCache: isCache, type: type,
            channelId: channelId, sourceType: sourceType, sourceID: sourceID, downloadFileScene: downloadFileScene
        )
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
        return fileAPI.cancelDownloadFile(
            messageId: messageId, key: key, authToken: authToken, authFileKey: authFileKey, type: type, channelId: channelId, sourceType: sourceType,
            sourceID: sourceID, downloadFileScene: downloadFileScene
        )
    }

    func uploadFiles(keyAndPaths: [String: String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void> {
        return fileAPI.uploadFiles(keyAndPaths: keyAndPaths, type: type)
    }

    func uploadFiles(cids: [String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void> {
        return fileAPI.uploadFiles(cids: cids, type: type)
    }

    func cancelUploadFiles(cids: [String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void> {
        return fileAPI.cancelUploadFiles(cids: cids, type: type)
    }

    func saveFileToSpaceStore(messageId: String, chatId: String, key: String?, sourceType: LarkModel.Message.SourceType, sourceID: String) -> Observable<Void> {
        return fileAPI.saveFileToSpaceStore(
            messageId: messageId, chatId: chatId, key: key, sourceType: sourceType, sourceID: sourceID
        )
    }

    func getFileStateRequest(messageId: String,
                             sourceType: LarkModel.Message.SourceType,
                             sourceID: String,
                             authToken: String?,
                             downloadFileScene: Media_V1_DownloadFileScene?) -> Observable<RustPB.Media_V1_GetFileStateResponse.State> {
        return fileAPI.getFileStateRequest(
            messageId: messageId, sourceType: sourceType, sourceID: sourceID, authToken: authToken, downloadFileScene: downloadFileScene
        )
    }

    func getFileMeta(fileKey: String) -> Observable<FileMeta> {
        return fileAPI.getFileMeta(fileKey: fileKey)
    }

    func browseFolderRequest(
        key: String,
        authToken: String?,
        authFileKey: String,
        start: Int64,
        step: Int64,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<RustPB.Media_V1_BrowseFolderResponse> {
        return fileAPI.browseFolderRequest(key: key, authToken: authToken, authFileKey: authFileKey, start: start, step: step, downloadFileScene: downloadFileScene)
    }

    func extractPackageRequest(
        key: String,
        authToken: String?,
        authFileKey: String,
        step: Int64,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<RustPB.Media_V1_ExtractPackageResponse> {
        return fileAPI.extractPackageRequest(key: key, authToken: authToken, authFileKey: authFileKey, step: step, downloadFileScene: downloadFileScene)
    }

    func cancelExtractPackageRequest(key: String) -> Observable<RustPB.Media_V1_CancelExtractPackagePollResponse> {
        return fileAPI.cancelExtractPackageRequest(key: key)
    }

    func uploadResource(uploadID: String,
                        chatID: String,
                        filePath: String,
                        fileType: Basic_V1_ResourceFile.FileType) -> Observable<Im_V1_UploadResourceResponse> {
        return fileAPI.uploadResource(uploadID: uploadID, chatID: chatID, filePath: filePath, fileType: fileType)
    }

    func cancelAsyncUpload(uploadIds: [String]) -> Observable<Im_V1_CancelAsyncUploadResponse> {
        return fileAPI.cancelAsyncUpload(uploadIds: uploadIds)
    }

    func canUserDownloadFile() -> Observable<ServerPB_Compliance_CanUserDownloadRiskFileResponse> {
        return fileAPI.canUserDownloadFile()
    }

    func canDownloadFile(detectRiskFileMeta: DetectRiskFileMeta) -> Observable<Bool> {
        let (key, messageRiskObjectKeys) = (detectRiskFileMeta.key, detectRiskFileMeta.messageRiskObjectKeys)
        if key.isEmpty {
            return .just(true)
        }
        var canDownloadObservable: Observable<Bool>
        /// 本地有messageRiskObjectKeys标识，则直接用标识来判断是否有风险
        if !messageRiskObjectKeys.filter({ !$0.isEmpty }).isEmpty {
            /// messageRiskObjectKeys标识不包含key，视为可以下载
            let canDownload = !messageRiskObjectKeys.contains(where: { key.contains($0) })
            canDownloadObservable = .just(canDownload)
            fileAPI.logger.info("RustSecurityFileAPI.canDownloadFile() use local cache. \(canDownload)")
        } else {
            /// 如果本地没有标识，则单独发接口请求一下标记
            var request = ServerPB.ServerPB_Compliance_MGetIMFileRiskTagRequest()
            request.sourceTerminal = .mobile
            request.objectID = [key]
            canDownloadObservable = self.client.sendPassThroughAsyncRequest(request, serCommand: .getImFileRiskTag)
                .map({ (response: ServerPB.ServerPB_Compliance_MGetIMFileRiskTagResponse) -> Bool in
                    return !(response.result.first?.restrictOperation ?? false)
                })
        }
        /// 如果判断不是风险文件，直接可下载；如果标记了风险，不能下载，再看一下服务端开关，是否用户可下载。
        return canDownloadObservable.flatMap { [fileAPI] canDownload -> Observable<Bool> in
            if canDownload {
                return .just(true)
            }
            fileAPI.logger.info("RustSecurityFileAPI.canDownloadFile() use canUserDownloadFile().")
            return fileAPI.canUserDownloadFile().map({ [fileAPI] (res: ServerPB_Compliance_CanUserDownloadRiskFileResponse) in
                fileAPI.logger.info("RustSecurityFileAPI.canDownloadFile() use canUserDownloadFile result: \(res.canDownload)")
                return res.canDownload
            }).catchErrorJustReturn(true)
        }.do(onError: { [fileAPI] error in
            fileAPI.logger.error("RustSecurityFileAPI.canDownloadFile() error!", error: error)
        })
    }

    func canDownloadFiles(detectRiskFileMetas: [DetectRiskFileMeta]) -> Observable<[String: Bool]> {
        /// 检测本地没有messageRiskObjectKeys标识的情况
        var missedRiskObjectKeys: [String] = []
        var canFileDownloadMap: [String: Bool] = [:]
        var canDownloadDirectly = true

        for meta in detectRiskFileMetas {
            if meta.messageRiskObjectKeys.filter({ $0.isEmpty }).isEmpty {
                missedRiskObjectKeys.append(meta.key)
                canFileDownloadMap[meta.key] = false
                continue
            }
            let canDownload = !meta.messageRiskObjectKeys.contains(where: { meta.key.contains($0) })
            canDownloadDirectly = canDownloadDirectly && canDownload
            canFileDownloadMap[meta.key] = canDownload
        }

        let canFileDownloadMapRequest = Observable<[String: Bool]>.just(canFileDownloadMap)

        /// 没有缺失的RiskObjectKeys标识
        if missedRiskObjectKeys.isEmpty {
            return canFileDownloadMapRequest
        }
        /// 如果本地没有标识，则单独发接口请求一下标记
        var request = ServerPB.ServerPB_Compliance_MGetIMFileRiskTagRequest()
        request.sourceTerminal = .mobile
        request.objectID = missedRiskObjectKeys
        let getMissedRiskTagsRequest = self.client.sendPassThroughAsyncRequest(request, serCommand: .getImFileRiskTag)
            .map({ (response: ServerPB.ServerPB_Compliance_MGetIMFileRiskTagResponse) -> [ServerPB_Compliance_IMFileRiskTag] in
                return response.result
            })

        return Observable.combineLatest(
            Observable.just(canDownloadDirectly), canFileDownloadMapRequest, getMissedRiskTagsRequest
        ).map({ (canDownload, map, riskTags) -> (Bool, [String: Bool]) in
            var canDownload = canDownload
            var map = map
            for riskTag in riskTags {
                map[riskTag.objectID] = !riskTag.restrictOperation
                canDownload = canDownload && !riskTag.restrictOperation
            }
            return (canDownload, map)
        }).flatMap { (canDownload, map) -> Observable<(Bool, [String: Bool])> in
            if canDownload {
                return .just((canDownload, map))
            }
            return Observable.combineLatest(
                /// 服务端是否允许该用户下载
                self.fileAPI.canUserDownloadFile()
                    .map { (res: ServerPB_Compliance_CanUserDownloadRiskFileResponse) -> Bool in
                        return res.canDownload
                    }
                    .catchErrorJustReturn(true),
                Observable.just(map)
            )
        }.map { (canDownload, map) -> [String: Bool] in
            var map = map
            for (k, v) in map where !v {
                map[k] = canDownload
            }
            return map
        }
    }
}
