//
//  File.swift
//  ByteWebImage
//
//  Created by bytedance on 2022/1/19.
//

import Photos
import Foundation
import CoreServices
import LarkFoundation
import LarkSetting
import LarkSensitivityControl

private var PHAssetEditImageKey: Void?

public extension PHAsset {
    /// size
    var size: Int64 {
        let resource: PHAssetResource? = self.assetResource
        var fileSize: Int64 = 0
        do {
            try ObjcExceptionHandler.catchException({
                fileSize = (resource?.value(forKey: "fileSize") as? Int64) ?? 0
            })
        } catch {
            fileSize = 0
        }
        return fileSize
    }

    /// editImage
    var editImage: UIImage? {
        get { return (objc_getAssociatedObject(self, &PHAssetEditImageKey) as? UIImage) }
        set(newValue) { objc_setAssociatedObject(self,
                                                 &PHAssetEditImageKey,
                                                 newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN) }
    }

    /// 同步执行，请确保在子线程调用
    func originalImage() -> UIImage? {
        imageWithSize(size: originSize)
    }

    /// imageWithSize
    func imageWithSize(size: CGSize) -> UIImage? {
        if let editImage = self.editImage {
            return editImage
        }
        var resultImg: UIImage?
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        // 目前发现iOS13 beat7上requestImageData isSynchronous = true时仍是异步返回，不符合预期，利用信号量异步变同步
        let sema = DispatchSemaphore(value: 0)
        do {
            _ = try AlbumEntry.requestImage(
                forToken: PHAssetToken.getPHAssetImage, manager: .default(), forAsset: self,
                targetSize: size, contentMode: .aspectFit, options: options
            ) { (image, _) in
                resultImg = image
                if #available(iOS 13.0, *) {
                    sema.signal()
                }
            }
        } catch {
            return nil
        }
        if #available(iOS 13.0, *) {
            sema.wait()
        }
        return resultImg
    }

    /// originSize
    var originSize: CGSize {
        return CGSize(width: pixelWidth, height: pixelHeight)
    }

    /// isGIF
    var isGIF: Bool {
        if let resource = PHAssetResource.assetResources(for: self).first {
            let uti = resource.uniformTypeIdentifier as CFString
            return UTTypeConformsTo(uti, kUTTypeGIF)
        }
        return false
    }

    /// format type
    var imageType: ImageFileFormat {
        guard let assetResource = assetResource else { return .unknown }
        let UTI = assetResource.uniformTypeIdentifier as CFString
        return ImageFileFormat(from: UTI)
    }

    /// Determine if the asset is in iCloud，
    /// reference material：https://stackoverflow.com/questions/31966571/check-given-phasset-is-icloud-asset
    var isInICloud: Bool {
        if let isInLocal = self.assetResource?.value(forKey: "locallyAvailable") as? Bool {
            return !isInLocal
        }
        return false
    }

    /// assetResource
    var assetResource: PHAssetResource? {
        let resourceArray = PHAssetResource.assetResources(for: self)
        let mediaType = self.mediaType
        var supportTypes: [PHAssetResourceType] = []
        if mediaType == .image {
            // .photo: 1                Photo data.
            // .fullSizePhoto: 5        Photo data in the highest quality and size available.
            // .adjustmentBasePhoto: 8  An unaltered copy of the original photo.
            // .alternatePhoto: 4       Photo data in an alternate format (such as JPEG for a RAW photo).
            supportTypes = [.fullSizePhoto, .photo, .adjustmentBasePhoto, .alternatePhoto]
        } else if mediaType == .video {
            // .video: 2                        Video data.
            // .fullSizeVideo: 6                Video data in the highest quality and size available.
            // .pairedVideo: 9                  Original video data for a Live Photo.
            // .fullSizePairedVideo: 10         Provides the current video data component of a Live Photo asset.
            // .adjustmentBasePairedVideo: 11   Provides an unaltered version of the video data for a Live Photo asset for use in reconstructing recent edits.
            // .adjustmentBaseVideo: 12         Provides an unaltered version of its video asset.
            supportTypes = [.video, .fullSizeVideo, .pairedVideo, .fullSizePairedVideo, .adjustmentBasePairedVideo]
            if #available(iOS 13, *) {
                supportTypes.append(.adjustmentBaseVideo)
            }
        }
        if #available(iOS 14, *) {
            let selectResources = resourceArray.filter { ($0.value(forKey: "isCurrent") as? Bool ?? false) }
            if let res = selectResources.first(where: { supportTypes.contains($0.type) }) {
                return res
            }
            if let firstIsCurrent = selectResources.first {
                return firstIsCurrent
            }
        }
        if let res = resourceArray.first(where: { supportTypes.contains($0.type) }) {
            return res
        }
        return resourceArray.first
    }
}
