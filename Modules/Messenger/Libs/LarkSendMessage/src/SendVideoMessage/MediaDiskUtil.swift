//
//  MediaDiskUtil.swift
//  LarkSendMessage
//
//  Created by 李晨 on 2022/5/31.
//

import Foundation
import LarkFeatureGating
import LarkSetting
import UIKit
import Photos
import LarkAssetsBrowser
import LarkUIKit
import LKCommonsLogging
import LarkSDKInterface
import LarkContainer
import LarkStorage
import LarkFoundation
import UniverseDesignToast

private typealias Path = LarkSDKInterface.PathWrapper

public final class MediaDiskUtil: UserResolverWrapper {
    public let userResolver: UserResolver
    static let logger = Logger.log(MediaDiskUtil.self, category: "LarkCore.MediaDiskUtil")
    var logger: Log { Self.logger }

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?

    public func checkMediaSendEnable(assets: [PHAsset], on view: UIView?) -> Bool {
        if assets.isEmpty { return true }

        let hasVideo = assets.contains { asset in
            return asset.mediaType == .video
        }
        if hasVideo,
           !self.hasFreeDiskForVideo(contents: assets.filter({ $0.mediaType == .video }).map({ .asset($0) })) {
            if let view = view {
                UDToast.showFailure(
                    with: BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1(
                                BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendVideo_Variable),
                    on: view
                )
            } else {
                self.logger.error("show disk toast view is nil")
            }
            return false
        }

        let hasImage = assets.contains { asset in
            return asset.mediaType == .image
        }
        if hasImage,
           !self.hasFreeDiskForImage() {
            if let view = view {
                UDToast.showFailure(
                    with: BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1(
                                BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendImage_Variable),
                    on: view
                )
            } else {
                self.logger.error("show disk toast view is nil")
            }
            return false
        }
        return true
    }

    public func checkImageSendEnable(image: UIImage, on view: UIView?) -> Bool {
        let result = self.hasFreeDiskForImage()
        if !result {
            if let view = view {
                UDToast.showFailure(
                    with: BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1(
                                BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendImage_Variable),
                    on: view
                )
            } else {
                self.logger.error("show disk toast view is nil")
            }
        }
        return result
    }

    public func checkVideoSendEnable(videoURL: URL, on view: UIView?) -> Bool {
        let result = self.hasFreeDiskForVideo(contents: [.fileURL(videoURL)])
        if !result {
            if let view = view {
                UDToast.showFailure(
                    with: BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendImageOrVideo_Toast1(
                                BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendVideo_Variable),
                    on: view
                )
            } else {
                self.logger.error("show disk toast view is nil")
            }
        }
        return result
    }

    public func checkVideoCompressEnable(content: SendVideoContent) -> Bool {
        guard userResolver.fg.staticFeatureGatingValue(with: "core.video.compress.disk.limit") else { return true }
        return hasFreeDiskForVideo(contents: [content])
    }

    public func checkVideoPreprocessEnable(content: SendVideoContent) -> Bool {
        guard let userGeneralSettings else { return true }
        var (result, msg) = (true, "")
        let freeDiskSpace = Double(SBUtil.importantDiskSpace)
        let preprocessLimit = userGeneralSettings.videoPreprocessConfig.value.compress.limit
        let limitDiskFreeSize = Double(preprocessLimit.diskSpaceFreeSize)
        if limitDiskFreeSize > freeDiskSpace {
            (result, msg) = (false, "free disk space isn't enough: \(freeDiskSpace)")
        }
        if let contentSize = sizeOf(content: content),
           Double(contentSize) * preprocessLimit.diskSpaceFreeCount > freeDiskSpace {
            (result, msg) = (false, "content is too large: \(contentSize), \(content)")
        }
        if !result {
            self.logger.warn("[send video] check video preprocess disk failed: " + msg)
        }
        return true
    }

    public func checkDownloadAssetsEnable(assets: [(LKDisplayAsset, UIImage?)], on view: UIView?) -> Bool {
        if assets.isEmpty { return true }

        let hasVideo = assets.contains { asset in
            return asset.0.isVideo
        }
        if hasVideo,
           !self.hasFreeDiskForVideo(contents: nil) {
            if let view = view {
                UDToast.showFailure(
                    with: BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast(
                                BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendVideo_Variable),
                    on: view
                )
            } else {
                self.logger.error("show disk toast view is nil")
            }
            return false
        }

        let hasImage = assets.contains { asset in
            return !asset.0.isVideo
        }
        if hasImage,
           !self.hasFreeDiskForImage() {
            if let view = view {
                UDToast.showFailure(
                    with: BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast(
                                BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendImage_Variable),
                    on: view
                )
            } else {
                self.logger.error("show disk toast view is nil")
            }
            return false
        }

        return true
    }

    public func checkDownloadAssetsEnableInOB(assets: [(LKDisplayAsset, UIImage?)]) -> (Bool, ((UIView?) -> Void)?) {
        if assets.isEmpty { return (true, nil) }

        let hasVideo = assets.contains { asset in
            return asset.0.isVideo
        }
        if hasVideo,
           !self.hasFreeDiskForVideo(contents: nil) {
            return (false, { (view) in
                if let view = view {
                    UDToast.showFailure(
                        with: BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast(
                                    BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendVideo_Variable),
                        on: view
                    )
                } else {
                    self.logger.error("show disk toast view is nil")
                }
            })
        }

        let hasImage = assets.contains { asset in
            return !asset.0.isVideo
        }
        if hasImage,
           !self.hasFreeDiskForImage() {
                return (false, { (view) in
                    if let view = view {
                        UDToast.showFailure(
                            with: BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast(
                                        BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendImage_Variable),
                            on: view
                        )
                    } else {
                        self.logger.error("show disk toast view is nil")
                    }
                })
        }

        return (true, nil)
    }

    public func checkDownloadVideoEnable(on view: UIView?) -> Bool {
        let result = self.hasFreeDiskForVideo(contents: nil)
        if !result {
            if let view = view {
                UDToast.showFailure(
                    with: BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSaveImageOrVideo_Toast(
                                BundleI18n.LarkSendMessage.Lark_IM_InsufficientStorageUnableToSendVideo_Variable),
                    on: view
                )
            } else {
                self.logger.error("show disk toast view is nil")
            }
        }
        return result
    }

    private func hasFreeDiskForImage() -> Bool {
        var result = true
        var params: [String: Any] = [:]
        // 获取剩余空间
        let freeDiskSpace = SBUtil.importantDiskSpace
        let directFreeSpace = SBUtil.directDiskSpace
        var limitDiskSpace = 52_428_800
        // 从setting获取允许磁盘剩余的空间
        if let uploadConfig = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "image_upload_component_config")),
           let checkConfig = uploadConfig["file_size_check_config"] as? [String: Any],
           let freeSize = checkConfig["disk_free_size_limit"] as? Int {
            limitDiskSpace = freeSize
        }
        params["limitDiskSpace"] = limitDiskSpace
        params["freeDiskSpace"] = freeDiskSpace
        params["directFreeSpace"] = directFreeSpace
        if Double(limitDiskSpace) > Double(freeDiskSpace) {
            result = false
        }
        self.logger.info("check image disk enable, result \(result), params \(params)")
        return result
    }

    private func hasFreeDiskForVideo(contents: [SendVideoContent]?) -> Bool {
        guard let userGeneralSettings else {
            return true
        }
        var result = true
        var params: [String: Any] = [:]
        // 获取剩余空间
        let freeDiskSpace = SBUtil.importantDiskSpace
        let directFreeSpace = SBUtil.directDiskSpace
        let sendSetting = userGeneralSettings.videoSynthesisSetting.value.sendSetting
        let limitDiskFreeSize = sendSetting.limitDiskFreeSize
        params["limitDiskFreeSize"] = limitDiskFreeSize
        params["freeDiskSpace"] = freeDiskSpace
        params["directFreeSpace"] = directFreeSpace
        if Double(limitDiskFreeSize) > Double(freeDiskSpace) {
            result = false
        }

        if result, let contents {
            let fileSizes = contents.compactMap({ sizeOf(content: $0) })
            if contents.count == 1, let fileSize = fileSizes.first {
                params["fileSize"] = fileSize
                if Double(fileSize) * Double(sendSetting.limitDiskFreeMultiple) > Double(freeDiskSpace) {
                    result = false
                }
            } else if contents.count > 1 {
                let totalFileSize = Double(fileSizes.reduce(0, +))
                let maxFileSize = Double(fileSizes.max() ?? 0)
                params["totalFileSize"] = totalFileSize
                params["maxFileSize"] = maxFileSize
                params["count"] = contents.count
                if totalFileSize + sendSetting.limitDiskFreeMaxFactor * maxFileSize > Double(freeDiskSpace) {
                    result = false
                }
            }
        }
        self.logger.info("check video disk enable, result \(result), params \(params)")
        return result
    }

    /// Disk usage of content in bytes
    private func sizeOf(content: SendVideoContent) -> UInt64? {
        var fileSize: UInt64?
        switch content {
        case .asset(let asset):
            do {
                try ObjcExceptionHandler.catchException({
                    fileSize = videoAssetResources(for: asset)?.value(forKey: "fileSize") as? UInt64
                })
            } catch {
                self.logger.error("failed to get fileSize of asset: \(asset)")
            }
        case .fileURL(let url):
            fileSize = Path(url.path).fileSize
        }
        return fileSize
    }

    private func videoAssetResources(for asset: PHAsset) -> PHAssetResource? {
        let resources = PHAssetResource.assetResources(for: asset)
        let supportTypes: [PHAssetResourceType] = [.video, .fullSizeVideo]
        if let current = resources.first(where: { resource in
            if #available(iOS 14, *) {
                var isCurrent = false
                if let value = resource.value(forKey: "isCurrent") as? Bool {
                    isCurrent = value
                }
                return isCurrent && supportTypes.contains(resource.type)
            }
            return false
        }) {
            return current
        }
        return resources.first { $0.type == .video } ?? resources.first
    }
}
