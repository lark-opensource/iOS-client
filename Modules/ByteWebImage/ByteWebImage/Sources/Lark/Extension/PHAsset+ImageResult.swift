//
//  PHAsset + ImageResult.swift
//  ByteWebImage
//
//  Created by kangsiwan on 2022/1/18.
//

import Photos
import Foundation
import LarkSetting
import CoreServices
import LKCommonsLogging
import LarkSensitivityControl

public typealias ImageSourceFunc = () -> ImageSourceResult

public extension UIImage {
    var jpegImageInfo: ImageSourceFunc {
        return { [weak self] in
            guard let `self` = self else { return ImageSourceResult(sourceType: .unknown, data: nil, image: nil) }
            let start = CACurrentMediaTime()
            let data = self.jpegData(compressionQuality: Constants.standardJpegQuality)
            return ImageSourceResult(sourceType: .jpeg, data: data, image: self, compressCost: CACurrentMediaTime() - start)
        }
    }
}

public extension PHAsset {
    private static let logger = Logger.log(PHAsset.self, category: "LarkCore.PHAsset")

    /// 是否只对应一份 Resources
    /// - Note: 以此判断是否只对应一套资源，来让 request options 里加上 .original
    private var hasOnlyOneResource: Bool {
        let resources = PHAssetResource.assetResources(for: self)
        return resources.count == 1
    }

    // 新接口，用来指定分辨率和压缩率
    var compressedImageInfo: (ImageInfoDependency, Int, Float) -> ImageSourceResult {
        return { [weak self] dependency, destPixel, compressRate in
            guard let `self` = self else { return ImageSourceResult(sourceType: .unknown, data: nil, image: nil) }
            if let editImage = self.editImage {
                return self.editImageSourceResult(dependency: dependency, image: editImage, compressType: .custom(destPixel, compressRate))
            } else {
                return self.assetImageInfo(dependency: dependency, compressType: .custom(destPixel, compressRate))
            }
        }
    }

    var imageInfo: (ImageInfoDependency) -> ImageSourceResult {
        return { [weak self] dependency in
            guard let `self` = self else { return ImageSourceResult(sourceType: .unknown, data: nil, image: nil) }
            if let editImage = self.editImage {
                return self.editImageSourceResult(dependency: dependency, image: editImage, compressType: .default)
            } else {
                return self.assetImageInfo(dependency: dependency, compressType: .default)
            }
        }
    }

    private func editImageSourceResult(dependency: ImageInfoDependency, image: UIImage, compressType: ProcessCompressType) -> ImageSourceResult {
        let processResult: ImageProcessResult?
        switch compressType {
        case .custom(let destPixel, let compressRate):
            Self.logger.info("UniteSendImage editImageSource custom \(destPixel) \(compressRate)")
            processResult = dependency.sendImageProcessor.process(source: .image(image), destPixel: destPixel, compressRate: compressRate, scene: dependency.scene)
        case .default:
            Self.logger.info("UniteSendImage editImageSource system true")
            let option: ImageProcessOptions = dependency.useOrigin ? [.useOrigin] : (dependency.isConvertWebp ? [.needConvertToWebp] : [])
            processResult = dependency.sendImageProcessor.process(source: .image(image), option: option, scene: dependency.scene)
        }
        if let result = processResult {
            return ImageSourceResult(sourceType: result.imageType, data: result.imageData, image: result.image, compressCost: result.cost, colorSpaceName: result.colorSpaceName)
        }
        return image.jpegImageInfo()
    }

    private func assetImageInfo(dependency: ImageInfoDependency, compressType: ProcessCompressType) -> ImageSourceResult {
        var imageInfo: ImageSourceResult?
        var assetData: Data?
        var isGif = false
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        // 如果发原图并且图片没有被编辑过，指定 version = .original，否则发小 PNG / HEIF / WebP (<10KB) 的时候系统会返回 JPG
        // https://bytedance.feishu.cn/wiki/wikcniJHZbKeu1Qk8NhNgLAUbnc
        if dependency.useOrigin && self.hasOnlyOneResource {
            options.version = .original
        }
        // 目前发现ios13 beat7上requestImageData isSynchronous = true时仍是异步返回，不符合预期，利用信号量异步变同步
        let sema = DispatchSemaphore(value: 0)
        dependency.statusHandler?(.beforeRequest)
        do {
            _ = try AlbumEntry.requestImageData(forToken: PHAssetToken.getPHAssetImage, manager: .default(), forAsset: self,
                                                options: options, resultHandler: { (data, uti, orientation, info) in
                guard let data = data else {
                    Self.logger.error("PHAsset requestImageData is nil",
                                      additionalData: ["PHImageResultIsInCloudKey": "\(String(describing: info?[PHImageResultIsInCloudKey]))",
                                                       "PHImageResultIsDegradedKey": "\(String(describing: info?[PHImageResultIsDegradedKey]))",
                                                       "PHImageResultRequestIDKey": "\(String(describing: info?[PHImageResultRequestIDKey]))",
                                                       "PHImageErrorKey": "\(String(describing: info?[PHImageErrorKey]))",
                                                       "PHImageCancelledKey": "\(String(describing: info?[PHImageCancelledKey]))",
                                                       "orientation": "\(orientation.rawValue)",
                                                       "uti": uti ?? "",
                                                       "mediaType": "\(self.mediaType.rawValue)",
                                                       "sourceType": "\(self.sourceType.rawValue)",
                                                       "isHidden": "\(self.isHidden)"]
                    )
                    dependency.statusHandler?(.finishRequest)
                    if #available(iOS 13.0, *) {
                        sema.signal()
                    }
                    return
                }
                dependency.statusHandler?(.finishRequest)
                assetData = data
                if let uti = uti, UTTypeConformsTo(uti as CFString, kUTTypeGIF) {
                    isGif = true
                }
                if #available(iOS 13.0, *) {
                    sema.signal()
                }
            })
        } catch {
            Self.logger.error("PHAsset requestImageData failed: \(error)")
            dependency.statusHandler?(.finishRequest)
            if #available(iOS 13.0, *) {
                sema.signal()
            }
        }
        if #available(iOS 13.0, *) {
            sema.wait()
        }
        dependency.statusHandler?(.beforeImageProcess)
        if let data = assetData {
            // fix https://jira.bytedance.com/browse/SUITE-3283：发送Gif时 不进行 jpegData(compressionQuality:)
            if isGif {
                var image: UIImage?
                let start = CACurrentMediaTime()
                do {
                    image = try ByteImage(data)
                } catch let error {
                    Self.logger.error("gif image form data failed", tag: "decode gif", additionalData: nil, error: error)
                }
                Self.logger.info("assetImageInfo is gif \(data.count)")
                imageInfo = ImageSourceResult(sourceType: .gif, data: data, image: image, compressCost: CACurrentMediaTime() - start, colorSpaceName: image?.bt.colorSpaceName)
            } else {
                let processResult: ImageProcessResult?
                switch compressType {
                case .custom(let destPixel, let compressRate):
                    Self.logger.info("UniteSendImage phasset data custom \(destPixel) \(compressRate)")
                    processResult = dependency.sendImageProcessor.process(source: .imageData(data), destPixel: destPixel, compressRate: compressRate, scene: dependency.scene)
                case .default:
                    Self.logger.info("UniteSendImage phasset data systom \(dependency.useOrigin)")
                    // 因为使用原图后
                    let option: ImageProcessOptions = dependency.useOrigin ? [.useOrigin] : (dependency.isConvertWebp ? [.needConvertToWebp] : [])
                    processResult = dependency.sendImageProcessor.process(source: .imageData(data), option: option, scene: dependency.scene)
                }
                Self.logger.info("assetImageInfo not gif \(String(describing: processResult?.imageData.count))")
                imageInfo = ImageSourceResult(sourceType: processResult?.imageType ?? .unknown,
                                              data: processResult?.imageData, image: processResult?.image,
                                              compressCost: processResult?.cost, colorSpaceName: processResult?.colorSpaceName,
                                              compressRatio: processResult?.compressRatio, compressAlgorithm: processResult?.compressAlgorithm?.rawValue)
            }
            dependency.statusHandler?(.finishImageProcess)
        }
        return imageInfo ?? ImageSourceResult(sourceType: .unknown, data: nil, image: nil, compressCost: nil, colorSpaceName: nil)
    }
}
