//
//  ThumbnailDownloader.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/8/23.
//

import Foundation
import RxSwift
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra

protocol ThumbDownloaderProtocol {
    func downloadThumb(meta: DriveFileMeta, extra: String?, priority: DocCommonDownloadPriority, teaParams: [String: String]) -> Observable<UIImage>
}

class ThumbnailDownloader: ThumbDownloaderProtocol {
    private let checkCacheExist: () -> Data?
    init(_ checkCacheExist: @escaping () -> Data?) {
        self.checkCacheExist = checkCacheExist
    }
    private lazy var downloader: DocCommonDownloadProtocol = DocsContainer.shared.resolve(DocCommonDownloadProtocol.self)!

    /// 缩略图下载错误码
    private static let downloadThumbErrorCode = NSURLErrorCancelled
    /// 默认的图片缩略图的宽高大小
    private static let defaultCoverSize = 360

    static let downloadType = DocCommonDownloadType.cover(width: defaultCoverSize, height: defaultCoverSize, policy: .near)
    static let cacheType = DriveCacheType.imageCover(width: defaultCoverSize, height: defaultCoverSize)

    func downloadThumb(meta: DriveFileMeta,
                       extra: String?,
                       priority: DocCommonDownloadPriority,
                       teaParams: [String: String] = [:]) -> Observable<UIImage> {
        DocsLogger.driveInfo("ThumbnailDownloader -- begin downloading thumbnail for \(DocsTracker.encrypt(id: meta.fileToken))")
        let context = DocCommonDownloadRequestContext(fileToken: meta.fileToken,
                                                      mountNodePoint: meta.mountNodeToken,
                                                      mountPoint: meta.mountPoint,
                                                      priority: priority,
                                                      downloadType: Self.downloadType,
                                                      localPath: nil,
                                                      isManualOffline: false,
                                                      authExtra: extra,
                                                      dataVersion: meta.dataVersion,
                                                      originFileSize: meta.size,
                                                      fileName: meta.name,
                                                      teaParams: teaParams)
        return self.downloader
                .download(with: context)
                .observeOn(ConcurrentDispatchQueueScheduler(queue: .global())).flatMap({ [weak self] (context) -> Observable<UIImage> in
                    guard let self = self else { return Observable.empty() }
                    let status = context.downloadStatus
                    guard status == .failed || status == .success else { return Observable.empty() }
                    if status == .success, let data = self.checkCacheExist() {
                        DocsLogger.driveInfo("ThumbnailDownloader -- successfully downloaded attachment cover for \(DocsTracker.encrypt(id: meta.fileToken)), size \(data.count) Byte")
                        guard let image = UIImage(data: data) else {
                            DocsLogger.driveError("ThumbnailDownloader -- cannot generate a thumbnail")
                            return Observable.error(self.downloadThumbError(status: status, errorCode: Self.downloadThumbErrorCode))
                        }
                        DocsLogger.driveInfo("ThumbnailDownloader -- created thumbnail image for \(DocsTracker.encrypt(id: meta.fileToken)), size: \(image.size)")
                        return Observable<UIImage>.just(image)
                    } else {
                        DocsLogger.driveError("ThumbnailDownloader -- failed downloading thumbnail image for \(DocsTracker.encrypt(id: meta.fileToken)), result: \(status)")
                        return Observable.error(self.downloadThumbError(status: status, errorCode: Self.downloadThumbErrorCode))
                    }
                })
    }
    
    private func downloadThumbError(status: DocCommonDownloadStatus, errorCode: Int) -> Error {
        return NSError(domain: "download thumbnail error \(status)", code: errorCode, userInfo: nil) as Error
    }
}
