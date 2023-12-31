//
//  DriveImageDownloadInfo.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/12.
//

import Foundation

/// 使用token下载的信息
/// token: 下载图片对应的token
/// useThumb: 是否下载缩略图
/// originDataSize: 原图data size
struct DriveImageDownloadInfo {
    let token: String
    let useThumb: Bool
    let originDataSize: Int64
    let imageSize: CGSize
    var thumbSize: CGSize? {
        guard useThumb else {
            return nil
        }
        let scale = UIScreen.main.scale
        // 屏幕宽度
        let scaleWidth = Display.width * scale
        if imageSize.width > scaleWidth {
            let scaleHeight = imageSize.height / (imageSize.width / scaleWidth)
            // 图片宽度大于屏幕宽度的情况下，使用缩放后图片宽高计算缩略图size
            return ThumbnailSize.thumbSize(targetSize: max(scaleHeight, scaleWidth))
        } else {
            // 图片宽度小于屏幕宽度的情况下，使用图片原始宽高最大值计算缩略图size
            return ThumbnailSize.thumbSize(targetSize: max(imageSize.width, imageSize.height))
        }
    }
    
    static func tokenRequestInfo(token: String, image: MailClientDraftImage?, displayWidth: CGFloat) -> DriveImageDownloadInfo {
        let useThumb = downloadDriveImageWithThumb(image: image, displayWidth: displayWidth)
        let originDataSize = image?.imageSize ?? 0
        var size: CGSize = .zero
        if let image = image {
            size = CGSize(width: CGFloat(image.imageWidth), height: CGFloat(image.imageHeight))
        }
        return DriveImageDownloadInfo(token: token, useThumb: useThumb, originDataSize: originDataSize, imageSize: size)
    }

    static private func downloadDriveImageWithThumb(image: MailClientDraftImage?, displayWidth: CGFloat) -> Bool {
        guard FeatureManager.open(.loadThumbImageEnable, openInMailClient: false) else {
            MailLogger.info("MailSchemeDataSession load thumb image disabled")
            return false
        }
        guard let image = image else {
            MailLogger.info("MailSchemeDataSession image info not found")
            return false
        }
        guard image.imageSize > minImageSizeLoadThumb() else {
            MailLogger.info("MailSchemeDataSession image too small no need to load thumb")
            return false
        }
        guard !isGif(fileName: image.imageName) else {
            MailLogger.info("MailSchemeDataSession gif download origin")
            return false
        }
        guard image.imageWidth > 0, image.imageHeight > 0 else {
            MailLogger.info("MailSchemeDataSession image size not found")
            return false
        }
        let imageSize = CGSize(width: CGFloat(image.imageWidth), height: CGFloat(image.imageHeight))
        let isLongPic = ThumbnailSize.checkIsLongImage(imageSize: imageSize, webviewWith: displayWidth)
        let bigImageInIpad = thumbWidthLessThanWebviewWidthInIpad(imageSize: imageSize)

        MailLogger.info("MailSchemeDataSession image size \(imageSize), webviewWidth \(displayWidth), isLongPic: \(isLongPic), bigImageInIpad \(bigImageInIpad)")

        if isLongPic || bigImageInIpad {
            return false
        } else {
            return true
        }
    }

    // 在iPad大屏场景下压缩后图片宽度小于webview宽度时，不进行压缩，避免出现模糊情况
    static private func thumbWidthLessThanWebviewWidthInIpad(imageSize: CGSize) -> Bool {
        guard Display.pad else { return false }
        if imageSize.width > ThumbnailSize.xxhight.rawValue
            && max(Display.width, Display.height) > ThumbnailSize.xxhight.rawValue {
            return true
        } else {
            return false
        }
    }

    static private func isGif(fileName: String) -> Bool {
        if let index = fileName.range(of: ".", options: .backwards)?.upperBound {
            let ext = String(fileName[index...])
            return ext.lowercased() == "gif"
        } else {
            return false
        }
    }

    static private func minImageSizeLoadThumb() -> Int64 {
        if let size = ProviderManager.default.commonSettingProvider?.IntValue(key: "minImageSizeNeedThumb") {
            return Int64(size)
        } else {
            return 100 * 1024 // 100KB
        }
    }
}
