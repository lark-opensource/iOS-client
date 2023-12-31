//
//  AttachmentDownloadProxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/10/28.
//

import Foundation
import RxSwift

/*
let ctx = DocCommonDownloadRequestContext(
    fileToken: desc.fileToken,
    mountNodePoint: userId,
    mountPoint: "email",
    priority: .default,
    downloadType: .originFile,
    localPath: localPath,
    isManualOffline: false
)
 */

// MARK: 用来和DocCommonDownloadRequestContext做map，按需扩展需要的参数
public struct DriveDownloadRequestCtx {

    public let fileToken: String

    public let mountNodePoint: String

    public let localPath: String

    public let downloadType: DriveDownloadType

    public let priority: DriveDownloadPriority
    public let disableCdn: Bool

    public enum DriveDownloadType {
        case originFile
        case previewFile
        case image
        case thumbnail(width: Int, height: Int)
    }

    public enum DriveDownloadPriority: Int32 {
        case userInteraction = 10
        case defaultHigh = 5
        case `default` = 0
        case defaultLow = -5
        case background = -10
    }

    public init(fileToken: String,
                mountNodePoint: String,
                localPath: String,
                downloadType: DriveDownloadType,
                priority: DriveDownloadPriority,
                disableCdn: Bool = false) {
        self.fileToken = fileToken
        self.mountNodePoint = mountNodePoint
        self.localPath = localPath
        self.downloadType = downloadType
        self.priority = priority
        self.disableCdn = disableCdn
    }
}

public struct DriveDownloadResponseCtx {

    public enum DownloadStatus: Int {
        /// 待定
        case pending
        /// 传输中
        case inflight
        /// 失败
        case failed
        /// 成功
        case success
        /// 队列中
        case queue
        /// 就绪
        case ready
        /// 取消
        case cancel
    }

    public let requestContext: DriveDownloadRequestCtx

    public let downloadStatus: DownloadStatus

    public let downloadProgress: (Float, Float)

    public let errorCode: Int

    public let key: String
    
    public let path: String?

    public init(requestContext: DriveDownloadRequestCtx,
                downloadStatus: DownloadStatus,
                downloadProgress: (Float, Float),
                errorCode: Int,
                key: String,
                path: String?) {
        self.requestContext = requestContext
        self.downloadStatus = downloadStatus
        self.downloadProgress = downloadProgress
        self.errorCode = errorCode
        self.key = key
        self.path = path
    }
}

public protocol DriveDownloadProxy {
    func download(with context: DriveDownloadRequestCtx, messageID: String?) -> Observable<DriveDownloadResponseCtx>
    func cancel(with key: String) -> Observable<Bool>
}

extension DriveDownloadProxy {
    func download(with context: DriveDownloadRequestCtx) -> Observable<DriveDownloadResponseCtx> {
        return download(with: context, messageID: nil)
    }
}
