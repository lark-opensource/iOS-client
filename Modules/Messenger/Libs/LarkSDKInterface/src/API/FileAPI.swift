//
//  FileAPI.swift
//  LarkSDKInterface
//
//  Created by ChalrieSu on 2018/5/31.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import ServerPB

public protocol FileAPI {

    // swiftlint:disable function_parameter_count
    /// 下载文件
    ///
    /// - Parameters:
    ///   - messageId: 消息Id
    ///   - key: 文件key
    ///   - authToken: 消息链接化场景需要使用previerwID做鉴权
    ///   - authFileKey: 嵌套文件/文件夹需要使用根文件的key做鉴权
    ///   - absolutePath: 保存路径
    ///   - isCache: 使用使用 RustSDK 默认缓存路径，default: false
    ///   - type: 类型
    ///   - channelId: message 所属 chatId  https://bytedance.feishu.cn/docs/doccnUdw8r6mPI7gFSngGkYXWDc#8JD1rM
    ///   - sourceType: 源类型
    ///   - sourceID: 源ID
    /// - Returns: Observable<String>
    func downloadFile(
        messageId: String,
        key: String,
        authToken: String?,
        authFileKey: String,
        absolutePath: String,
        isCache: Bool,
        type: RustPB.Basic_V1_File.EntityType,
        channelId: String,
        sourceType: Message.SourceType,
        sourceID: String,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> Observable<String>
    // swiftlint:enable function_parameter_count

    func cancelDownloadFile(
        messageId: String,
        key: String,
        authToken: String?,
        authFileKey: String,
        type: RustPB.Basic_V1_File.EntityType,
        channelId: String,
        sourceType: Message.SourceType,
        sourceID: String,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> Observable<Void>

    func uploadFiles(keyAndPaths: [String: String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void>

    func uploadFiles(cids: [String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void>

    func cancelUploadFiles(cids: [String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void>

    func saveFileToSpaceStore(messageId: String, chatId: String, key: String?, sourceType: Message.SourceType, sourceID: String) -> Observable<Void>

    func getFileStateRequest(messageId: String,
                             sourceType: Message.SourceType,
                             sourceID: String,
                             authToken: String?,
                             downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> Observable<Media_V1_GetFileStateResponse.State>

    func getFileMeta(fileKey: String) -> Observable<FileMeta>

    func browseFolderRequest(
        key: String,
        authToken: String?,
        authFileKey: String,
        start: Int64,
        step: Int64,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<RustPB.Media_V1_BrowseFolderResponse>

    func extractPackageRequest(
        key: String,
        authToken: String?,
        authFileKey: String,
        step: Int64,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<RustPB.Media_V1_ExtractPackageResponse>

    func cancelExtractPackageRequest(key: String) -> Observable<RustPB.Media_V1_CancelExtractPackagePollResponse>

    func uploadResource(uploadID: String,
                        chatID: String,
                        filePath: String,
                        fileType: Basic_V1_ResourceFile.FileType) -> Observable<Im_V1_UploadResourceResponse>

    func cancelAsyncUpload(uploadIds: [String]) -> Observable<Im_V1_CancelAsyncUploadResponse>

    func canUserDownloadFile() -> Observable<ServerPB_Compliance_CanUserDownloadRiskFileResponse>

    func canDownloadFile(detectRiskFileMeta: DetectRiskFileMeta) -> Observable<Bool>

    func canDownloadFiles(detectRiskFileMetas: [DetectRiskFileMeta]) -> Observable<[String: Bool]>
}

public struct FileMeta {
    public let filePath: String?
    public let progress: Int?
    public init(filePath: String?, progress: Int?) {
        self.filePath = filePath
        self.progress = progress
    }
}

public struct DetectRiskFileMeta {
    public let key: String
    public let messageRiskObjectKeys: [String]
    public init(key: String, messageRiskObjectKeys: [String]) {
        self.key = key
        self.messageRiskObjectKeys = messageRiskObjectKeys
    }
}

public protocol SecurityFileAPI {
    // swiftlint:disable function_parameter_count
    func downloadFile(
        messageId: String,
        key: String,
        authToken: String?,
        authFileKey: String,
        absolutePath: String,
        isCache: Bool,
        type: RustPB.Basic_V1_File.EntityType,
        channelId: String,
        sourceType: Message.SourceType,
        sourceID: String,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> Observable<String>
    // swiftlint:enable function_parameter_count

    func cancelDownloadFile(
        messageId: String,
        key: String,
        authToken: String?,
        authFileKey: String,
        type: RustPB.Basic_V1_File.EntityType,
        channelId: String,
        sourceType: Message.SourceType,
        sourceID: String,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> Observable<Void>

    func uploadFiles(keyAndPaths: [String: String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void>

    func uploadFiles(cids: [String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void>

    func cancelUploadFiles(cids: [String], type: RustPB.Basic_V1_File.EntityType) -> Observable<Void>

    func saveFileToSpaceStore(messageId: String, chatId: String, key: String?, sourceType: Message.SourceType, sourceID: String) -> Observable<Void>

    func getFileStateRequest(messageId: String,
                             sourceType: Message.SourceType,
                             sourceID: String,
                             authToken: String?,
                             downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> Observable<Media_V1_GetFileStateResponse.State>

    func getFileMeta(fileKey: String) -> Observable<FileMeta>

    func browseFolderRequest(
        key: String,
        authToken: String?,
        authFileKey: String,
        start: Int64,
        step: Int64,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<RustPB.Media_V1_BrowseFolderResponse>

    func extractPackageRequest(
        key: String,
        authToken: String?,
        authFileKey: String,
        step: Int64,
        downloadFileScene: RustPB.Media_V1_DownloadFileScene?
    ) -> Observable<RustPB.Media_V1_ExtractPackageResponse>

    func cancelExtractPackageRequest(key: String) -> Observable<RustPB.Media_V1_CancelExtractPackagePollResponse>

    func uploadResource(uploadID: String,
                        chatID: String,
                        filePath: String,
                        fileType: Basic_V1_ResourceFile.FileType) -> Observable<Im_V1_UploadResourceResponse>

    func cancelAsyncUpload(uploadIds: [String]) -> Observable<Im_V1_CancelAsyncUploadResponse>

    func canUserDownloadFile() -> Observable<ServerPB_Compliance_CanUserDownloadRiskFileResponse>

    func canDownloadFile(detectRiskFileMeta: DetectRiskFileMeta) -> Observable<Bool>

    func canDownloadFiles(detectRiskFileMetas: [DetectRiskFileMeta]) -> Observable<[String: Bool]>
}
