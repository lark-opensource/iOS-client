//
//  ICloudImageDownloader.swift
//  AnimatedTabBar
//
//  Created by liweiye on 2019/10/28.
//

import Foundation
import UIKit
import Photos
import LarkSensitivityControl
import LKCommonsLogging
import ByteWebImage
import UniverseDesignToast

public typealias ICloudAssetsDownloadCompletionHandler = (Result<Any, Error>) -> Void

open class ICloudImageDownloader {
    // MARK: Logger
    public static let logger = Logger.log(ICloudImageDownloader.self, category: "LarkUIKit.ImagePicker.ICloudImageDownloader")

    // MARK: Private Properties
    /// A manager responsible for resource downloads
    private let imageManager = PHCachingImageManager.default()

    /// A container that caches the request id for all download tasks
    private var requestIDStore: Set<PHImageRequestID> = Set()

    private let queue = DispatchQueue(label: "SafetyOperationQueue")

    deinit {
        cancelAll()
        ICloudImageDownloader.logger.info("ICloudImageDownloader -- deinit")
    }

    @discardableResult
    func downloadAsset(with asset: PHAsset,
                       progressBlock: DownloadProgressBlock? = nil,
                       completionHandler: ICloudAssetsDownloadCompletionHandler? = nil) -> PHImageRequestID? {
        let assetType = asset.mediaType
        if assetType == .image {
            return downloadImage(with: asset, progressBlock: progressBlock, completionHandler: completionHandler)
        } else if assetType == .video {
            return downloadVideo(with: asset, progressBlock: progressBlock, completionHandler: completionHandler)
        } else {
            let error = NSError(domain: "Unsupported media type", code: 999, userInfo: ["mediaType": assetType])
            completionHandler?(.failure(error))
            return nil
        }
    }

    @discardableResult
    private func downloadImage(with asset: PHAsset,
                       progressBlock: DownloadProgressBlock? = nil,
                       completionHandler: ICloudAssetsDownloadCompletionHandler? = nil) -> PHImageRequestID? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.progressHandler = { (progress, _, _, _) in
            progressBlock?(Int64(progress), asset.size)
        }
        guard let requestID = try? AlbumEntry.requestImage(forToken: AssetBrowserToken.requestImage.token,
                                                           manager: imageManager,
                                                           forAsset: asset,
                                                           targetSize: PHImageManagerMaximumSize,
                                                           contentMode: .aspectFit,
                                                           options: options,
                                                           resultHandler: { (image, info) in
                                                    DispatchQueue.main.async {
                                                        if let error = info?[PHImageErrorKey] as? Error {
                                                            completionHandler?(.failure(error))
                                                            return
                                                        }
                                                        completionHandler?(.success(image))
                                                    }
        }) else { return nil }
        queue.async {
            self.requestIDStore.insert(requestID)
        }
        return requestID
    }

    @discardableResult
    private func downloadVideo(with asset: PHAsset,
                       progressBlock: DownloadProgressBlock? = nil,
                       completionHandler: ICloudAssetsDownloadCompletionHandler? = nil) -> PHImageRequestID? {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.progressHandler = { (progress, _, _, _) in
            progressBlock?(Int64(progress), asset.size)
        }

        guard let requestID = try? AlbumEntry.requestPlayerItem(forToken: AssetBrowserToken.requestPlayerItem.token,
                                                                manager: imageManager,
                                                                forVideoAsset:  asset,
                                                                options: options,
                                                                resultHandler: { [weak self] (playerItem, info) in
            guard let url = (playerItem?.asset as? AVURLAsset)?.url else {
                self?.requestAssetData(asset, progressBlock: progressBlock, completionHandler: completionHandler)
                return
            }
            if url.isLocal {
                completionHandler?(.success(playerItem))
            } else if url.isRemote {
                /// If avplayerItem is not downloaded to the local, download it via another API
                self?.requestAssetData(asset, progressBlock: progressBlock, completionHandler: completionHandler)
            } else {
                ICloudImageDownloader.logger.info("Unknown url!")
                let error = NSError(domain: "Unknown url", code: 998, userInfo: ["url": url])
                completionHandler?(.failure(error))
            }
        }) else { return nil }
        queue.async {
            self.requestIDStore.insert(requestID)
        }
        return requestID
    }

    private func requestAssetData(_ asset: PHAsset,
                                  progressBlock: DownloadProgressBlock? = nil,
                                  completionHandler: ICloudAssetsDownloadCompletionHandler? = nil) {
        guard let resource = asset.assetResource else { return }
        let resourceOptions = PHAssetResourceRequestOptions()
        resourceOptions.isNetworkAccessAllowed = true
        var assetData = Data()
        let requestID = try? AlbumEntry.requestData(forToken: AssetBrowserToken.requestData.token,
                                                    manager: PHAssetResourceManager
            .default(),
                                                    forResource: resource,
                                                    options: resourceOptions,
                                                    dataReceivedHandler: { data in
                            assetData += data
                        }
            ) { (error) in
                if let error = error {
                    completionHandler?(.failure(error))
                } else {
                    completionHandler?(.success(assetData))
                }
            }
    }

    func cancel(requestID: PHImageRequestID) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.imageManager.cancelImageRequest(requestID)
            self.requestIDStore.remove(requestID)
        }
    }

    func cancelAll() {
        queue.async { [weak self] in
            guard let self = self else { return }
            for requestID in self.requestIDStore {
                self.imageManager.cancelImageRequest(requestID)
            }
            self.requestIDStore.removeAll()
        }
    }
}

extension URL {
    var isRemote: Bool {
        return absoluteString.lowercased().hasPrefix("http://")
        || absoluteString.lowercased().hasPrefix("https://")
    }

    var isLocal: Bool {
        return absoluteString.lowercased().hasPrefix("file://")
    }
}

// MARK: UI Toast Utils
extension ICloudImageDownloader {
    enum DownloadErrorCode: Int {
        case noNetwork = 82
    }

    static func toastError(_ error: Error?, on view: UIView) {
        if let error = error as NSError? {
            let errorCode = error.code
            if errorCode == DownloadErrorCode.noNetwork.rawValue {
                UDToast.showFailure(with: BundleI18n.LarkAssetsBrowser.Lark_Chat_AlbumSelectiCloudSyncNetworkError,
                                    on: view)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkAssetsBrowser.Lark_Chat_AlbumSelectiCloudSyncFailed,
                                    on: view)
            }
        }
    }

    @discardableResult
    static func showSyncLoadingToast(on viewToBeDisabled: UIView, cancelCallback: (() -> Void)? = nil) -> UDToast {
       return UDToast.showToast(
        with: .init(toastType: .loading,
                    text: BundleI18n.LarkAssetsBrowser.Lark_Chat_AlbumSelectiCloudSync,
                    operation: .init(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Cancel)),
        on: viewToBeDisabled,
        delay: 100_000,
        disableUserInteraction: true,
        operationCallBack: { _ in
            cancelCallback?()
        })
   }
}
