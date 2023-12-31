//
// Created by duanxiaochen.7 on 2021/7/6.
// Affiliated with SKBitable.
//
// Description:

import UIKit
import Foundation
import SKFoundation
import SKCommon
import LarkTag
import SKResource
import SKBrowser
import RxSwift
import UniverseDesignProgressView
import UniverseDesignToast
import SpaceInterface
import ThreadSafeDataStructure
import SKInfra

// MARK: - Attachment Thumbnail Downloader

final class BTAttachmentThumbnailProvider {
    lazy var downloader: DocCommonDownloadProtocol? = DocsContainer.shared.resolve(DocCommonDownloadProtocol.self)
    lazy var downloadCacheServive: SpaceDownloadCacheProtocol? = DocsContainer.shared.resolve(SpaceDownloadCacheProtocol.self)
    static let downloadQueue = DispatchQueue(label: "bt.attachment.thumbnail")
    
    lazy private var newCacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)
    private var cachedImage: SafeDictionary<String, UIImage> = [:] + .readWriteLock

    func fetchThumbnail(info: BTAttachmentModel,
                        resumeBag: DisposeBag,
                        size: CGSize = CGSize(width: 360, height: 360),
                        completionHandler: @escaping (UIImage?, String, Error?) -> Void) {
        let token = info.attachmentToken
        let encryptedToken = DocsTracker.encrypt(id: token)
        let extra = info.extra
        let mountNodePoint = info.mountToken
        let mountPoint = info.mountPointType

        autoreleasepool {

            if let image = self.cachedImage[token] {
                DocsLogger.btInfo("[DATA] fetched cached image for \(encryptedToken), size: \(image.size)")
                completionHandler(image, token, nil)
                return
            }

            let downloadType: DocCommonDownloadType = .cover(width: Int(size.width), height: Int(size.height), policy: .near)
            Self.downloadQueue.async { [weak self] in
                guard let self = self else { return }
                if let data = self.downloadCacheServive?.data(key: token, type: downloadType) {
                    DocsLogger.btInfo("[DATA] fetched drive cached cover data for \(encryptedToken), size: \(data.count) Byte")

                    guard let image = self.createThumbnail(from: data as CFData, size: size) else {
                        DocsLogger.btInfo("[DATA] drive cache has cover data, but cannot generate a thumbnail")
                        completionHandler(nil, token, nil)
                        return
                    }
                    DocsLogger.btInfo("[DATA] created thumbnail image for \(encryptedToken), size: \(image.size)")
                    self.cachedImage[token] = image
                    completionHandler(image, token, nil)
                } else {
                    DocsLogger.info("[DATA] begin downloading attachment cover for \(encryptedToken)")
                    let disableCoverRetry: Bool
                    if UserScopeNoChangeFG.LYL.disableCoverRetryFix {
                        disableCoverRetry = false
                    } else {
                        disableCoverRetry = true
                    }
                    let priority: DocCommonDownloadPriority = .userInteraction
                    let context = DocCommonDownloadRequestContext(fileToken: token,
                                                                  mountNodePoint: mountNodePoint,
                                                                  mountPoint: mountPoint,
                                                                  priority: priority,
                                                                  downloadType: downloadType,
                                                                  localPath: nil,
                                                                  isManualOffline: false,
                                                                  authExtra: extra,
                                                                  dataVersion: nil,
                                                                  originFileSize: UInt64(info.size),
                                                                  fileName: info.name,
                                                                  disableCoverRetry: disableCoverRetry)
                    self.downloader?
                        .download(with: context)
                        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
                        .subscribe(onNext: { [weak self] (context) in
                            guard let `self` = self else { return }
                            let status = context.downloadStatus
                            guard status == .failed || status == .success else { return }
                            let errorCode: Int = (status == .success) ? 0 : context.errorCode
                            SKDownloadPicStatistics.downloadPicReport(errorCode, type: Int(downloadType.rawValue), from: .customSchemeDrive)

                            if status == .success, let data = self.downloadCacheServive?.data(key: token, type: downloadType) {
                                DocsLogger.btInfo("[DATA] successfully downloaded attachment cover for \(encryptedToken), size \(data.count) Byte")
                                guard let image = self.createThumbnail(from: data as CFData, size: size) else {
                                    DocsLogger.btError("[DATA] cannot generate a thumbnail")
                                    completionHandler(nil, token, nil)
                                    return
                                }
                                DocsLogger.btInfo("[DATA] created thumbnail image for \(encryptedToken), size: \(image.size)")
                                self.cachedImage[token] = image
                                completionHandler(image, token, nil)
                                self.newCacheAPI?.mapTokenAndPicKey(token: token, picKey: token, picType: Int(downloadType.rawValue), needSync: false, isDrivePic: true)
                            } else {
                                DocsLogger.btError("[DATA] failed downloading attachment cover for \(encryptedToken), result: \(status)")
                                completionHandler(nil, token, NSError(domain: "get data is failed=\(status)", code: -999, userInfo: nil))
                            }
                        }, onError: { (error) in
                            completionHandler(nil, token, error)
                        })
                        .disposed(by: resumeBag)
                }
            }

        }
    }

    private func createThumbnail(from data: CFData, size: CGSize) -> UIImage? {
        // 在 64 位机型上，kCGImageSourceShouldCache 默认为 true，会导致解码后的数据被缓存
        // 如果图片很大的话缓存就会太占 memory
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data, imageSourceOptions) else {
            DocsLogger.btError("[DATA] failed creating CGImageSource from binary data")
            return nil
        }
        // kCGImageSourceShouldCacheImmediately 传 false,
        // 使得解码的过程从渲染时(rendering time)被延后到 UIImage 创建时(image creation time，即 return 时机)
        // CGImageSourceCreateThumbnailAtIndex 返回的 CGImage 已经是降采样过的了，所以对于超大图，return 时的解码过程就没那么重了
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: size.width] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) /* 此时降采样 */ else {
            DocsLogger.btError("[DATA] downsample failed")
            return nil
        }
        return UIImage(cgImage: downsampledImage) /* 此时解码 */
    }
}
