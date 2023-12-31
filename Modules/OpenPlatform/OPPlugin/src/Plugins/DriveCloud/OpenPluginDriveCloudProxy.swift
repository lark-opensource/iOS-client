//
//  OpenPluginDriveProxy.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/8/26.
//

import Foundation
import RxSwift
import UIKit

// MARK: - Upload

public enum OpenPluginDriveUploadStatus: Int {
    case pending
    case inflight
    case failed
    case success
    case queue
    case ready
    case cancel
    
    public init() {
        self = .pending
    }
}

public protocol OpenPluginDriveUploadProxy {
    /// 参数
    /// copyInsteadMoveAfterSuccess: true 则上传成功后拷贝到 Drive 缓存目录中，而非移动，需接入方自行删除临时文件
    /// 返回值
    /// 1. uploadKey: 此次上传任务的token，可以用来cancel、resume、delete上传任务
    /// 2. progress: 上传进度百分比
    /// 3. objToken: 文档token
    /// 4. uploadStatus: 状态
    func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String,
                extra: [String: String]?) -> Observable<(String, Float, String, OpenPluginDriveUploadStatus)>
    
    func cancelUpload(key: String) -> Observable<Bool>
    
    func resumeUpload(key: String) -> Observable<Bool>
    
    func deleteUploadResource(key: String) -> Observable<Bool>
}

// MARK: - Download

public enum OpenPluginDriveDownloadStatus: Int {
    case pending
    case inflight
    case failed
    case success
    case queue
    case ready
    case cancel
    
    public init() {
        self = .pending
    }
}

public struct OpenPluginDriveDownloadRequestContext {
    
    public let fileToken: String
    // 挂载点的 Token，文档中的图片则传文档Token
    public let mountNodePoint: String
    // 节点信息
    public let mountPoint: String
    // 本地文件路径
    public let localFilePath: String?

    public let extra: String?
}

public struct OpenPluginDriveDownloadResponseContext {
    // 请求信息
    public let requestContext: OpenPluginDriveDownloadRequestContext
    // 下载状态
    public let downloadStatus: OpenPluginDriveDownloadStatus
    // 下载进度（已完成的字节，总共的字节）
    public let downloadProgress: (Float, Float)
    // 错误码
    public let errorCode: Int
    
    public let key: String
    
    public let localFilePath: String
    
    public let fileName: String
    
    public let fileType: String
    
    public init(requestContext: OpenPluginDriveDownloadRequestContext,
                downloadStatus: OpenPluginDriveDownloadStatus,
                downloadProgress: (Float, Float),
                errorCode: Int = -1,
                key: String,
                localFilePath: String,
                fileName: String,
                fileType: String) {
        self.requestContext = requestContext
        self.downloadStatus = downloadStatus
        self.downloadProgress = downloadProgress
        self.errorCode = errorCode
        self.key = key
        self.localFilePath = localFilePath
        self.fileName = fileName
        self.fileType = fileType
    }
    
    public static func initailResponseContext(with request: OpenPluginDriveDownloadRequestContext, key: String) -> OpenPluginDriveDownloadResponseContext {
        return OpenPluginDriveDownloadResponseContext(requestContext: request, downloadStatus: .pending, downloadProgress: (0.0, 0.0), errorCode: -1, key: key, localFilePath: "", fileName: "", fileType: "")
    }
}

public protocol OpenPluginDriveDownloadProxy {
    
    func download(with context: OpenPluginDriveDownloadRequestContext) -> Observable<OpenPluginDriveDownloadResponseContext>
    
    func cancelDownload(key: String) -> Observable<Bool>
}

// MARK: - Preview

public struct OpenPluginDrivePreviewContext {
    
    public let fileToken: String
    // 挂载点的 Token，文档中的图片则传文档Token
    public let mountNodePoint: String
    // 节点信息
    public let mountPoint: String

    public let extra: String?
}

public struct OpenPluginDrivePreviewDownloadCompleteInfo {
    public let fileName: String

    /// description: 预览的文件 Token
    public let fileToken: String

    /// description: 预览的文件后缀名
    public let fileType: String

    /// description: 预览的文件大小
    public let size: Int

    public init(fileName: String, fileToken: String, fileType: String, size: Int) {
        self.fileName = fileName
        self.fileToken = fileToken
        self.fileType = fileType
        self.size = size
    }
}

public enum OpenPluginDrivePreviewAction {
    case saveToLocal(handler: (UIViewController, OpenPluginDrivePreviewDownloadCompleteInfo) -> Void)
}

public protocol OpenPluginDrivePreviewProxy {
    
    func preview(
        contexts: [OpenPluginDrivePreviewContext],
        actions: [OpenPluginDrivePreviewAction]?
    ) -> UIViewController?
}
