//
//  DriveUploadCacheService.swift
//  SpaceKit
//
//  Created by liweiye on 2019/1/25.
//

import Foundation
import LarkUIKit
import Photos
import SKCommon
import SKFoundation
import RxSwift
import LarkFileKit
import ByteWebImage
import SpaceInterface
import LarkSensitivityControl
import SKInfra

final class DriveUploadCacheService {
    private static var bag = DisposeBag()
    /// 上传异步队列
    private static let uploadQueue = DispatchQueue(label: "drive.upload")
    
    private static let compressLibraryDir = "drive/drive_upload_caches/media"

    /// 媒体文件缓存目录
    private static var mediaFileCachePath: SKFilePath {
        let path = SKFilePath.driveLibraryDir.appendingRelativePath(compressLibraryDir)
        path.createDirectoryIfNeeded()
        return path
    }

    /// iCloud文件缓存目录
    private static var iCloudFileCachePath: SKFilePath {
        let path = SKFilePath.driveLibraryDir.appendingRelativePath("drive/drive_upload_caches/iCloud")
        path.createDirectoryIfNeeded()
        return path
    }

    private typealias SaveImageResult = Result<(URL, String), Error>
    private enum SaveError: Error {
        case invalidAssetMediaType(type: PHAssetMediaType)
        case resourceNotFound
    }

    // swiftlint:disable cyclomatic_complexity
    /// 将选择的媒体文件保存到本地沙盒，返回媒体文件所在的本地路径
    static func savePickedAssetsToLocal(assetArr: [PHAsset], mountToken: String, mountPoint: String, scene: DriveUploadScene) {
        uploadQueue.async {
            guard assetArr.isEmpty == false else {
                DocsLogger.error("传入的PHAsset数组为空")
                return
            }

            var uploadEntitys: [(path: String, fileName: String)] = []
            var total = assetArr.count

            let saveImageCompletion: (SaveImageResult) -> Void = { result in
                total -= 1
                switch result {
                case let .failure(error):
                    DocsLogger.error("media file saved to sandbox failed", error: error)
                case let .success((fileURL, fileName)):
                    DocsLogger.driveInfo("media file saved to sandbox succeed")
                    uploadEntitys.append((path: fileURL.path, fileName: fileName))
                }
                if total <= 0 {
                    upload(entitys: uploadEntitys, mountToken: mountToken, mountPoint: mountPoint, scene: scene)
                }
            }

            for asset in assetArr {
                // MARK: - iOS 13需要按照asset 类型来过滤，第一个默认是plist文件
                let resources = PHAssetResource.assetResources(for: asset)
                let mediaType = asset.mediaType
                let matchedResources: [PHAssetResource]
                var fileName: String
                if mediaType == .image {
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
                        matchedResources = []
                        fileName = "unknown.JPG"
                    }
                } else if mediaType == .video {
                    // 本地编辑过的视频，要取 .fullSizeVideo, 否则取 .video 兜底
                    let editedResource = resources.first(where: { $0.type == .fullSizeVideo })
                    let originResource = resources.first(where: { $0.type == .video })

                    if let editedVideo = editedResource {
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
                } else {
                    DocsLogger.warning("传入的PHAsset不合法,仅支持image和video", extraInfo: ["mediaType": mediaType])
                    saveImageCompletion(.failure(SaveError.invalidAssetMediaType(type: mediaType)))
                    continue
                }

                let pathExtention = (fileName as NSString).pathExtension
                /// 存储名，与文件原名不同
                let savedName = makeUniqueSavedName(extention: pathExtention)
                let savedURL = mediaFileCachePath.appendingRelativePath(savedName)
                if let editImage = asset.editImage {
                    DocsLogger.driveInfo("start to upload edited picture")
                    do {
                        let saveNameExtension = "PNG"
                        let editSavedName = makeUniqueSavedName(extention: saveNameExtension)
                        let editSavedURL = mediaFileCachePath.appendingRelativePath(editSavedName)
                        var editFileName = (fileName as NSString).deletingPathExtension
                        editFileName += ".PNG"
                        try editImage.write(to: editSavedURL)
                        DocsLogger.driveInfo("upload edited picture")
                        saveImageCompletion(.success((editSavedURL.pathURL, editFileName)))
                    } catch {
                        DocsLogger.driveInfo("save edited picture failed", error: error)
                        saveImageCompletion(.failure(error))
                    }
                    continue
                }

                guard matchedResources.count != 0, let resource = matchedResources.first else {
                    DocsLogger.warning("no suitable resource")
                    saveImageCompletion(.failure(SaveError.resourceNotFound))
                    continue
                }
                let resourceOptions = PHAssetResourceRequestOptions()
                resourceOptions.isNetworkAccessAllowed = true
                do {
                    try AlbumEntry.writeData(forToken: Token(PSDATokens.Space.space_upload_image_click_upload), manager: PHAssetResourceManager.default(), forResource: resource, toFile: savedURL.pathURL, options: resourceOptions, completionHandler: { error in
                        if let error = error {
                            saveImageCompletion(.failure(error))
                            return
                        }
                        saveImageCompletion(.success((savedURL.pathURL, fileName)))
                    })
                } catch {
                    DocsLogger.driveError("AlbumEntry writeData error")
                    saveImageCompletion(.failure(error))
                }
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity

    /// 保存拍摄的照片到本地沙盒
    static func saveTakedPhotoToLocal(image: UIImage, mountToken: String, mountPoint: String, scene: DriveUploadScene) {
        uploadQueue.async {
            let data = image.jpegData(compressionQuality: 1.0)
            let imageName = makeUniqueImageName()
            let savedURL = mediaFileCachePath.appendingRelativePath(imageName)
            do {
                try data?.write(to: savedURL, options: .atomic)
                DocsLogger.driveInfo("photo save to sandbox succeed")
                upload(path: savedURL.pathString, fileName: imageName, mountToken: mountToken, mountPoint: mountPoint, scene: scene)
            } catch {
                DocsLogger.error("photo save to sandbox failed")
            }
        }
    }

    static func upload(entitys: [(path: String, fileName: String)], mountToken: String, mountPoint: String, scene: DriveUploadScene) {
        guard entitys.isEmpty == false else {
            DocsLogger.warning("empty entities to upload")
            return
        }

        for entity in entitys {
            upload(path: entity.path,
                   fileName: entity.fileName,
                   mountToken: mountToken,
                   mountPoint: mountPoint,
                   scene: scene)
        }
    }
    
    private static func upload(path: String,
                               fileName: String,
                               mountToken: String,
                               mountPoint: String,
                               scene: DriveUploadScene) {
        /// 调用Rust SDK上传
        let context = DriveUploadRequestContext(localPath: path,
                                                fileName: fileName,
                                                mountNodePoint: mountToken,
                                                mountPoint: mountPoint,
                                                uploadCode: nil,
                                                scene: scene,
                                                objType:  nil,
                                                apiType: nil,
                                                priority: .default,
                                                extraParams: [:],
                                                extRust: [:])
        SpaceRustRouter.shared.upload(context: context)
            .subscribe(onNext: { fileKey in
                DocsLogger.driveInfo("Save to local sandbox's file key: \(fileKey)")
                let pathExtention = (fileName as NSString).pathExtension.lowercased()
                // Drive业务埋点：文件上传结果
                // Parameters:
                //   - dummy_token : 假的token，标记这次上传
                reportedClickUploadMultimediaConfirm(paramters: ["sub_file_type": pathExtention,
                                                                 "dummy_token": fileKey])
                // 上报从相册或者file选择图片后确认上传的事件
                reportConfirmUpload(key: fileKey)
            }).disposed(by: bag)
    }

    private static func makeUniqueSavedName(extention: String) -> String {
        return makeUniqueId() + "." + extention
    }

    private static func makeUniqueImageName() -> String {
        let imageNamePrefix = "photo_"
        let imageNameSuffix = ".JPG"
        return imageNamePrefix + getTimeStamp() + imageNameSuffix
    }

    private static func makeUniqueId() -> String {
        let rawUUID = UUID().uuidString
        let uuid = rawUUID.replacingOccurrences(of: "-", with: "")
        return uuid.lowercased()
    }

    private static func getTimeStamp() -> String {
        let time = Int64(Date().timeIntervalSince1970 * 1000)
        return String(time)
    }
}

extension DriveUploadCacheService: DriveUploadCacheServiceBase {
    /// 保存iCloud文件到本地沙盒
    static func saveICouldFileToLocal(urls: [URL], mountToken: String, mountPoint: String, scene: DriveUploadScene) -> Bool {
     
        uploadQueue.async {
            guard urls.isEmpty == false else {
                DocsLogger.error("传入的URL数组为空")
                return
            }
            for url in urls {
                let absPath = SKFilePath(absUrl: url)
                guard let fileSize = absPath.fileSize,
                    fileSize > 0 else {
                        DocsLogger.driveInfo("can not choose iCloud folder or Bundle")
                        continue
                }
                //源文件路径
                DocsLogger.driveInfo("Source file path: \(absPath)")
                var fileName = absPath.getFileName()
                /// 如果含有转义字符，则解码
                if let tempName = fileName.removingPercentEncoding {
                    fileName = tempName
                }
                let pathExtention = (fileName as NSString).pathExtension
                /// 存储名，与文件原名不同
                let savedName = makeUniqueSavedName(extention: pathExtention)
                let savedURL = iCloudFileCachePath.appendingRelativePath(savedName)
                if savedURL.exists {
                    try? savedURL.removeItem()
                }
                do {
                    try absPath.copyItem(to: savedURL)
                    DocsLogger.driveInfo("iCloud file saved to sandbox succeed")
                    upload(path: savedURL.pathString, fileName: fileName, mountToken: mountToken, mountPoint: mountPoint, scene: scene)
                } catch {
                    DocsLogger.error("iCloud file saved to sandbox failed, error: \(error.localizedDescription)")
                }
            }
        }
        return isValid(urls: urls)
    }
    
    /// 保存iCloud文件到本地沙盒
    /// - Parameters:
    ///   - urls: iCloud 文件链接
    ///   - isContinueWhenContainInvalidItem: 当保存的 urls 有无效的 item 是否继续执行。
    ///   - eachFileSaveResult: 每次保存完成一个文件后进行回调咨询操作，这里要注意保存是在串行队列中，如果要做耗时操作建议开另外的线程处理。
    ///   - completion: 所有文件处理完后回调成功的映射。
    /// - Returns: 是否包含有无效的 url
    static func saveICloudFile(urls: [URL],
                               isContinueWhenContainInvalidItem: Bool,
                               eachFileSaveResult: ((SaveICloudFileResult) -> Void)?,
                               completion: (([URL: SaveICloudFileResult]) -> Void)?) -> Bool {
        guard !urls.isEmpty else {
            DocsLogger.error("saveICouldFile the urls is Empty")
            return false
        }
        let isValid = isValid(urls: urls)
        guard isValid || isContinueWhenContainInvalidItem else {
            return isValid
        }
        uploadQueue.async {
            var iCloudToLocalMap: [URL: SaveICloudFileResult] = [:]
            for url in urls {
                let absPath = SKFilePath(absUrl: url)
                guard let fileSize = absPath.fileSize, fileSize > 0 else {
                    let result: SaveICloudFileResult = .fail(iCloudURL: url, error: .invalidFile)
                    eachFileSaveResult?(result)
                    iCloudToLocalMap[url] = result
                    DocsLogger.error("saveICouldFile fileSize of \(absPath) is 0")
                    continue
                }
                DocsLogger.driveInfo("saveICouldFile filePath is \(absPath)")
                var fileName = absPath.getFileName()
                /// 如果含有转义字符，则解码
                if let tempName = fileName.removingPercentEncoding {
                    fileName = tempName
                }
                let pathExtention = (fileName as NSString).pathExtension
                /// 存储名，与文件原名不同
                let savedName = makeUniqueSavedName(extention: pathExtention)
                let savedURL = iCloudFileCachePath.appendingRelativePath(savedName)
                if savedURL.exists {
                    DocsLogger.error("saveICouldFile remove preSamePath \(savedURL)")
                    try? savedURL.removeItem()
                }
                do {
                    try SKFilePath(absUrl: url).copyItem(to: savedURL)
                    let model = SaveICloudFileResult.SaveSuccessModel(iCloudURL: url, localURL: savedURL.pathURL, fileSize: fileSize, fileName: fileName)
                    let result: SaveICloudFileResult = .success(model)
                    eachFileSaveResult?(result)
                    iCloudToLocalMap[url] = result
                    DocsLogger.error("saveICouldFile save success to \(savedURL)")
                } catch {
                    let result: SaveICloudFileResult = .fail(iCloudURL: url, error: .saveFailure)
                    eachFileSaveResult?(result)
                    iCloudToLocalMap[url] = result
                    DocsLogger.error("saveICouldFile save faile, error: \(error.localizedDescription)")
                }
            }
            completion?(iCloudToLocalMap)
        }
        return isValid
    }
    
    
    /// 判断 Urls 是否是都是有效的
    /// - Parameter urls: urls
    /// - Returns: 是否有效
    static func isValid(urls: [URL]) -> Bool {
        return !urls.contains { (url) -> Bool in
            let absPath = SKFilePath(absUrl: url)
            guard absPath.isFile() else {
                // 含有文件夹
                return true
            }
            guard let size = absPath.fileSize else {
                // 含有取不到大小（通常为文件夹）的文件
                return true
            }
            // 含有大小为0的文件
            return size == 0
        }
    }
}

// MARK: - 埋点相关
extension DriveUploadCacheService {

    private static func reportedClickUploadMultimediaConfirm(paramters: [String: String]? = nil) {
        DriveStatistic.clientContentManagement(action: DriveStatisticAction.driveClickUploadMultimediaConfirm,
                                               fileId: "",
                                               additionalParameters: paramters)
    }
    
    private static func reportConfirmUpload(key: String) {
        let moduleInfo = DriveStatistic.ModuleInfo(module: SKCreateTracker.moduleString,
                                                   srcModule: SKCreateTracker.srcModuleString,
                                                   subModule: SKCreateTracker.subModuleString,
                                                   isExport: false,
                                                   isDriveSDK: false,
                                                   fileID: "")
        DriveStatistic.setKey(key, moduleInfo: moduleInfo, isUpload: true)
        DriveStatistic.reportUpload(action: .confirmUpload,
                                    fileID: "",
                                    module: SKCreateTracker.moduleString,
                                    subModule: SKCreateTracker.subModuleString,
                                    srcModule: SKCreateTracker.srcModuleString,
                                    isDriveSDK: false)
    }
}
