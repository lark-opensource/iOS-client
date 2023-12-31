//
//  MediaWriter.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/9/5.
//

import Foundation
import Photos
import LKCommonsLogging
import ByteWebImage
import SKFoundation
import SpaceInterface
import LarkSensitivityControl

protocol MediaWriter {
    // save compress result to a sandbox path
    func save(imageResult: CompressImageResult, to path: SKFilePath) -> Result<SKFilePath, Error>
    // save a PHAsset to a sandbox path
    func saveOrigin(asset: PHAsset, to path: SKFilePath, writeToPathToken: String) -> Result<SKFilePath, Error>
}

class MediaWriterImpl: MediaWriter {
    enum SaveError: Error {
        case invalidAssetMediaType(type: PHAssetMediaType)
        case resourceNotFound
    }
    static let logger = Logger.log(MediaWriterImpl.self, category: "MediaCompress.mediaWriter")
    func save(imageResult: CompressImageResult, to path: SKFilePath) -> Result<SKFilePath, Error> {
        do {
            if let data = imageResult.data {
                try data.write(to: path)
                return .success(path)
            } else if let image = imageResult.image, let data = image.pngData() {
                try data.write(to: path)
                return .success(path)
            } else {
                Self.logger.info("no compress result")
                return .failure(SaveError.resourceNotFound)
            }
        } catch {
            Self.logger.error("error when write file to sandbox", error: error)
            return .failure(error)
        }
    }
    
    func saveOrigin(asset: PHAsset, to path: SKFilePath, writeToPathToken: String) -> Result<SKFilePath, Error> {
        // MARK: - iOS 13需要按照asset 类型来过滤，第一个默认是plist文件
        let mediaType = asset.mediaType
        
        if mediaType == .image {
            return saveImage(asset, to: path, writeToPathToken: writeToPathToken)
        } else if mediaType == .video {
            return saveVideo(asset, to: path, writeToPathToken: writeToPathToken)
        } else {
            Self.logger.info("invalide media type \(mediaType)")
            return .failure(SaveError.invalidAssetMediaType(type: mediaType))
        }
    }
    
    private func saveImage(_ asset: PHAsset, to path: SKFilePath, writeToPathToken: String) -> Result<SKFilePath, Error> {
        let resources = PHAssetResource.assetResources(for: asset)
        let matchedResources: [PHAssetResource]
        // 本地编辑过的视频，要取 .fullSizePhoto, 否则取 .photo 兜底
        let editedResource = resources.first(where: { $0.type == .fullSizePhoto })
        let originResource = resources.first(where: { $0.type == .photo })

        if let editedImage = editedResource {
            matchedResources = [editedImage]
        } else if let originPhoto = originResource {
            matchedResources = [originPhoto]
        } else {
            matchedResources = []
        }
        
        // 如果是已经编辑过的图片
        if let editImage = asset.editImage {
            Self.logger.info("save edited image")
            do {
                try editImage.write(to: path)
                Self.logger.info("did save edited image")
                return .success(path)
            } catch {
                Self.logger.info("save edited image failed with error", error: error)
                return .failure(error)
            }
        }
        let result = self.writeToPath(matchedResources: matchedResources, path: path, writeToPathToken: writeToPathToken)
        return result
    }
    
    private func saveVideo(_ asset: PHAsset, to path: SKFilePath, writeToPathToken: String) -> Result<SKFilePath, Error> {
        let resources = PHAssetResource.assetResources(for: asset)
        let matchedResources: [PHAssetResource]
        
        // 本地编辑过的视频，要取 .fullSizeVideo, 否则取 .video 兜底
        let editedResource = resources.first(where: { $0.type == .fullSizeVideo })
        let originResource = resources.first(where: { $0.type == .video })

        if let editedVideo = editedResource {
            matchedResources = [editedVideo]
        } else if let originVideo = originResource {
            matchedResources = [originVideo]
        } else {
            matchedResources = []
        }
        let result = self.writeToPath(matchedResources: matchedResources, path: path, writeToPathToken: writeToPathToken)
        return result
    }
    
    private func writeToPath(matchedResources: [PHAssetResource], path: SKFilePath, writeToPathToken: String) -> Result<SKFilePath, Error> {
        guard matchedResources.count != 0, let resource = matchedResources.first else {
            Self.logger.warn("can not finde resources")
            return .failure(SaveError.resourceNotFound)
        }
        let resourceOptions = PHAssetResourceRequestOptions()
        resourceOptions.isNetworkAccessAllowed = true
        let semp = DispatchSemaphore(value: 0)
        var writeDataResult = Result<SKFilePath, Error>.success(path)
        do {
            try AlbumEntry.writeData(forToken: Token(writeToPathToken), manager: PHAssetResourceManager.default(), forResource: resource, toFile: path.pathURL, options: resourceOptions) { error in
                if let error = error {
                    Self.logger.error("save video resource to path error", error: error)
                    writeDataResult = .failure(error)
                } else {
                    writeDataResult = .success(path)
                }
                semp.signal()
            }
        } catch {
            Self.logger.error("AlbumEntry writeData")
            return .failure(error)
        }
        semp.wait()
        return writeDataResult
    }
}
