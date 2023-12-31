//
//  MediaCompressHelper.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/9/6.
//

import Foundation
import Photos
import ByteWebImage
import SKFoundation
import LKCommonsLogging
import Kingfisher
import LarkSensitivityControl

class MediaCompressHelper {
    typealias AssetMediaNames = (savedName: String, originName: String)
    static let logger = Logger.log(MediaCompressHelper.self, category: "MediaCompress.helper")
    // get saved imageName and origin image name
    // compressed image extension is png, origin image extension is the origin file type maybe heic.
    static func getImageNames(from asset: PHAsset, compress: Bool, isGifToken: String) -> AssetMediaNames {
        // MARK: - iOS 13需要按照asset 类型来过滤，第一个默认是plist文件
        let resources = PHAssetResource.assetResources(for: asset)
        let mediaType = asset.mediaType
        var matchedResources: [PHAssetResource] = []
        var fileName: String = ""
        var saveName: String = ""

        // 本地编辑过的图片，要取 .fullSizePhoto, 否则取 .photo 兜底
        let editedResource = resources.first(where: { $0.type == .fullSizePhoto })
        let originResource = resources.first(where: { $0.type == .photo })
        if let editedPhoto = editedResource {
            matchedResources = [editedPhoto]
            // 这里优先读取 originPhoto 的文件名
            // editedPhoto 的文件名会被系统修改为 "fullSizeRender"
            if let originPhoto = originResource {
                fileName = originPhoto.originalFilename
            } else {
                fileName = editedPhoto.originalFilename
            }
        } else if let originPhoto = originResource {
            matchedResources = [originPhoto]
            fileName = originPhoto.originalFilename
        } else {
            logger.info("no matched resources")
            matchedResources = []
            fileName = "unknown.JPG"
        }
        
        let pathExtention = (fileName as NSString).pathExtension
        // 存储名，与文件原名不同
        saveName = makeUniqueSavedName(extention: pathExtention)
        
        // 如果图片编辑过，图片文件类型会变成PNG
        if let editImage = asset.editImage {
            logger.info("get edited image")
            let saveNameExtension = "PNG"
            saveName = makeUniqueSavedName(extention: saveNameExtension)
            var editFileName = (fileName as NSString).deletingPathExtension
            fileName = editFileName + ".PNG"
        }
        
        // 如果是压缩图片，图片会被压缩成jpg类型，需要修改后缀
        if compress {
            if isGIFType(asset: asset, isGifToken: isGifToken) {
                logger.info("get compress GIF name with GIF extension")
                saveName = makeUniqueSavedName(extention: "GIF")
                fileName = (fileName as NSString).deletingPathExtension + ".GIF"
            } else {
                logger.info("get compress image name with png extension")
                saveName = makeUniqueSavedName(extention: "JPEG")
                fileName = (fileName as NSString).deletingPathExtension + ".JPEG"
            }
        }
        
        return (savedName: saveName, originName: fileName)
    }
    
    // get video name
    // compress： if compressed the video extension is mp4, origin video extension is according
    // to the origin file type maybe mov
    static func getVideoName(from asset: PHAsset, compress: Bool) -> AssetMediaNames {
        // MARK: - iOS 13需要按照asset 类型来过滤，第一个默认是plist文件
        let resources = PHAssetResource.assetResources(for: asset)
        let mediaType = asset.mediaType
        var matchedResources: [PHAssetResource] = []
        var fileName: String = ""
        var saveName: String = ""
        
        // 本地编辑过的视频，要取 .fullSizeVideo, 否则取 .video 兜底
        let editedResource = resources.first(where: { $0.type == .fullSizeVideo })
        let originResource = resources.first(where: { $0.type == .video })

        if let editedVideo = editedResource {
            logger.info("is edit video")
            matchedResources = [editedVideo]
            // 这里优先读取 originVideo 的文件名
            // editedVideo 的文件名会被系统修改为 "fullSizeRender"
            if let originVideo = originResource {
                fileName = originVideo.originalFilename
            } else {
                fileName = editedVideo.originalFilename
            }
        } else if let originVideo = originResource {
            matchedResources = [originVideo]
            fileName = originVideo.originalFilename
        } else {
            matchedResources = []
            fileName = "unknown.MOV"
        }
        
        let pathExtention = (fileName as NSString).pathExtension
        // 存储名，与文件原名不同
        saveName = makeUniqueSavedName(extention: pathExtention)
        
        // 如果是压缩视频，会被压缩成mp4类型，需要修改后缀
        if compress {
            logger.info("get compress video with mp4 extension")
            saveName = makeUniqueSavedName(extention: "mp4")
            fileName = (fileName as NSString).deletingPathExtension + ".mp4"
        }

        
        return (savedName: saveName, originName: fileName)
    }
    
    static func resolutionSizeForLocalVideo(url: URL) -> CGSize {
        guard let track = AVAsset(url: url as URL).tracks(withMediaType: AVMediaType.video).first else {
            logger.error("no AVAsset video info")
            return CGSize(width: 0.0, height: 0.0)
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        logger.info("get resolution size \(size)")
        return CGSize(width: fabs(size.width), height: fabs(size.height))
    }
    
    static func getURL(from asset: PHAsset, urlToken: String, completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            try AlbumEntry.requestAVAsset(forToken: Token(urlToken), manager: PHImageManager.default(), forVideoAsset: asset, options: nil) { avAsset, _, info in
                DocsLogger.info("PHAsset: finsih requestAVAsset")
                if let avAsset = avAsset as? AVURLAsset {
                    logger.info("PHAsset: request ssuccess \(avAsset.url)")
                    completion(.success(avAsset.url))
                } else if (info?[PHImageResultIsInCloudKey] as? NSNumber)?.boolValue == true {
                    logger.error("PHAsset: requestAVAsset error: inCloud \(info)")
                    let error = NSError(domain: "drive.media.compress.helper", code: -100, userInfo: [
                        NSLocalizedDescriptionKey: "get avasset failed \(info)"
                    ])
                    completion(.failure(error))
                } else if let error = info?[PHImageErrorKey] as? Error {
                    logger.error("PHAsset: requestAVAsset error", error: error)
                    completion(.failure(error))
                } else {
                    let error = NSError(domain: "drive.media.compress.helper", code: -100, userInfo: [
                        NSLocalizedDescriptionKey: "get avasset failed \(info)"
                    ])
                    logger.error("PHAsset: requestAVAsset error \(info)")
                    completion(.failure(error))
                }
            }
        } catch {
            logger.error("AlbumEntry: requestAVAsset error ")
            completion(.failure(error))
        }
    }
    
    private static func makeUniqueId() -> String {
        let rawUUID = UUID().uuidString
        let uuid = rawUUID.replacingOccurrences(of: "-", with: "")
        return uuid.lowercased()
    }
    
    private static func makeUniqueSavedName(extention: String) -> String {
        return makeUniqueId() + "." + extention
    }
    
    static func isGIFType(asset: PHAsset, isGifToken: String) -> Bool {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        var isGIF: Bool = false
        do {
            if #available(iOS 13.0, *) {
                _ = try AlbumEntry.requestImageDataAndOrientation(forToken: Token(isGifToken),
                                                                  manager: PHImageManager.default(),
                                                                  forAsset: asset,
                                                                  options: options) { (data, _ ,_, _) in
                    guard let data = data else {
                        isGIF = false
                        return
                    }
                    let picFormat = data.kf.imageFormat
                    if picFormat == .GIF {
                        isGIF = true
                    } else {
                        isGIF = false
                    }
                }
            } else {
                _ = try AlbumEntry.requestImageData(forToken: Token(isGifToken),
                                                    manager: PHImageManager.default(),
                                                    forAsset: asset,
                                                    options: options) {(data, _ ,_, _) in
                    guard let data = data else {
                        isGIF = false
                        return
                    }
                    let picFormat = data.kf.imageFormat
                    if picFormat == .GIF {
                        isGIF = true
                    } else {
                        isGIF = false
                    }
                }
            }
        } catch {
            logger.error("AlbumEntry: requestImageDataAndOrientation error")
            isGIF = false
        }
        return isGIF
    }
    
}
