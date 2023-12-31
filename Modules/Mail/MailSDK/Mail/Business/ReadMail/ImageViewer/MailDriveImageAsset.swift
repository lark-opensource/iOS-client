//
//  MailDriveImageAsset.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/20.
//

import Foundation
import LarkAssetsBrowser
import ByteWebImage
import RxSwift

/// 从 Drive 加载图片
final class MailDriveImageAsset: LKLoadableAsset {
    /// 缓存是否是原图
    /// isOrigin: 是否为原图
    /// data: 缓存的数据
    typealias CacheType = (isOrigin: Bool, data: Data)
    var identifier: String { url }

    var resourceType: LarkAssetsBrowser.LKAssetType { .sync }
    var updateProgressState: ((LKDisplayAssetState) -> Void)?
    let dataProcessQueue = DispatchQueue(label: "mail.image.data.process", qos: .default)

    private let imageCache: MailImageCacheProtocol
    private var driveProvider: DriveDownloadProxy?
    private let featureManager: UserFeatureManager
    private lazy var downloader: MailImageDownloaderProtocol = {
        return MailImageDownloader(userID: userID, driveProvider: driveProvider, featureManager: featureManager)
    }()

    private var bag = DisposeBag()

    var url: String
    let userID: String

    init(url: String, userID: String, driveProvider: DriveDownloadProxy?, imageCache: MailImageCacheProtocol, featureManager: UserFeatureManager) {
        self.url = url
        self.userID = userID
        self.imageCache = imageCache
        self.driveProvider = driveProvider
        self.featureManager = featureManager
    }

    var associatedPageType: LKGalleryPage.Type {
        LKAssetByteImagePage.self
    }

    func displayAsset(on assetPage: LKGalleryPage) {
        guard let page = assetPage as? LKAssetByteImagePage else { return }
        self.updateProgressState?(.none)
        page.imageView.image = nil
        page.assetIdentifier = self.url
        dataProcessQueue.async {
            if let dataType = self.getCacheImage() {
                if let image = try? ByteImage(dataType.data) {
                    DispatchQueue.main.async {
                        page.imageView.image = image
                    }
                } else {
                    MailLogger.error("download origin image invalid image data")
                }
            } else {
                self.downloadOrigin(assetPage: page)
            }
        }
    }

    func cancelAsset(on assetPage: LKGalleryPage) {
        self.bag = DisposeBag()
    }

    func downloadOrigin(on assetPage: LKGalleryPage) {
        guard let dataType = self.getCacheImage(), !dataType.isOrigin else {
            MailLogger.info("download origin image did show origin image")
            return
        }
        guard let page = assetPage as? LKAssetByteImagePage else {
            MailLogger.error("download origin image invalid asset page type")
            return
        }
        downloadOrigin(assetPage: page)
    }

    private func getCacheImage() -> CacheType? {
        // 优先获取原图预览
        if let originData = imageCache.get(key: url) {
            return CacheType(isOrigin: true, data: originData)
        }
        // 缩略图缓存
        // 由于无法确认缩略图大小，需要判断不同大小的缩略图是否存在
        for case let size in ThumbnailSize.allCases {
            let thumbSize = CGSize(width: size.rawValue, height: size.rawValue)
            let cacheKey = imageCache.cacheKey(token: url, size: thumbSize)
            if let thumbData = imageCache.get(key: cacheKey, type: .transient) {
                return CacheType(isOrigin: false, data: thumbData)
            }
        }
        return nil
    }

    private func downloadOrigin(assetPage: LKAssetByteImagePage) {
        MailLogger.info("download origin image start download origin")
        self.updateProgressState?(.progress(0.0))
        downloader.downloadWithDriveSDKObservable(token: url,
                                                  thumbnailSize: nil,
                                                  userID: userID,
                                                  priority: .userInteraction,
                                                  disableCdn: true,
                                                  cache: imageCache)?.subscribe(onNext: {[weak self, weak assetPage] state in
            guard let self = self else { return }
            guard let page = assetPage, page.assetIdentifier == self.url else { return }
            switch state {
            case let .success(imageData):
                MailLogger.info("download origin image download success")
                self.handleSuccess(imageData: imageData, page: page)
            case let .failed(errorCode):
                MailLogger.error("download origin image failed: \(errorCode)")
                self.updateProgressState?(.start)
            case .progress(let progress):
                MailLogger.info("download origin image progress: \(progress)")
                self.updateProgressState?(LKDisplayAssetState.progress(Float(progress)))
            case .waiting:
                MailLogger.info("download origin image waiting")
                self.updateProgressState?(LKDisplayAssetState.progress(0.0))
            case .cancel:
                MailLogger.info("download origin image cancel")
            }
        }).disposed(by: bag)
    }

    private func handleSuccess(imageData: Data, page: LKAssetByteImagePage) {
        dataProcessQueue.async { [weak self, weak page] in
            guard let self = self, let page = page else { return }
            if let image = try? ByteImage(imageData) {
                MailLogger.info("download origin image success")
                DispatchQueue.main.async {
                    page.imageView.image = image
                    self.updateProgressState?(.end)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.updateProgressState?(.none)
                    }
                }
            } else {
                MailLogger.error("download origin image failed show start")
                self.updateProgressState?(.start)
            }
        }
    }
}
