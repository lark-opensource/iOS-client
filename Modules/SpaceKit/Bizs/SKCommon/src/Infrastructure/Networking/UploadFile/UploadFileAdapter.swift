//
//  UploadFileAdapter.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/12/2.
//

import SwiftyJSON
import SKFoundation
import SpaceInterface
import SKInfra

enum UploadFileErrorCode: Int {
    case localFileNotExist = 1001
}

public final class UploadFileAdapter {

    private let uploadImageByDocAdapter = UploadImageByDocAdapter() //上传到doc服务器 or copy接口
    private let uploadFileService = UploadFileNetworkService() // 上传到drive工具

    private let newCacheAPI: NewCacheAPI
    public var objToken: String?

    public typealias UploadFileCompletion = (Result<(uuid: String, data: [String: Any]), Error>) -> Void
    public typealias UploadFileProgress = ([String: Any]) -> Void

    public init(_ resolver: DocsResolver = DocsContainer.shared) {
        newCacheAPI = resolver.resolve(NewCacheAPI.self)!
    }

    public func uploadFile(for params: [String: Any], progress: @escaping UploadFileProgress, completion: @escaping UploadFileCompletion) {
        var uploadType: UploadImageType = .drive
        if let rawVeriosn = params["uploadType"] as? Int, let version = UploadImageType(rawValue: rawVeriosn) {
            uploadType = version
        } else {
            DocsLogger.error("uploadType, miss", component: LogComponents.uploadFile)
        }

        switch uploadType {
        case .doc, .copyTo:
            uploadImageByDocAdapter.uploadImage(for: params, completion: completion)
        default:
            self.uploadFileToDrive(for: params, progress: progress, completion: completion)
        }
    }

    private func getContentType(_ contentTypeStr: String) -> SKPickContentType {
        var contentType: SKPickContentType = .image
        if contentTypeStr.contains(SKPickContentType.image.rawValue) {
            contentType = .image
        } else if contentTypeStr.contains(SKPickContentType.video.rawValue) {
            contentType = .video
        } else if contentTypeStr.contains(SKPickContentType.file.rawValue) {
            contentType = .file
        }
        return contentType
    }

    public func cancelAllTask() {
        uploadFileService.cancelAllTask()
        uploadImageByDocAdapter.cancelAllTask()
    }

    public func deleteUploadfile(params: [String: Any]) {
        guard let uuid = params["uuid"] as? String else {
            return
        }
        let contentType = getContentType(params["contentType"] as? String ?? "")
        let fileName = params["fileName"] as? String ?? ""
        var fileSource = params["file_url"] as? String ?? ""
        if fileSource.isEmpty {
            fileSource = params["fileUrl"] as? String ?? ""
            //上传中文件block被删除时会调用
            if fileSource.isEmpty,
               let dataAsset = newCacheAPI.getAssetWith(uuids: [uuid], objToken: nil).first {
                fileSource = dataAsset.cacheKey
            }
        }
        guard let localPath = fetchLocalPath(with: uuid, fileSource: fileSource, fileName: fileName, contentType: contentType, from: .unknow) else {
                return
        }
        uploadFileService.deleteTask(uuid: uuid, localPath: localPath)
    }

}

private extension UploadFileAdapter {

    // 上传 -> Drive
    private func uploadFileToDrive(for params: [String: Any], progress: @escaping UploadFileProgress, completion: @escaping UploadFileCompletion) {
        guard
            let uuids = params["uuids"] as? [String],
            let uploadParams = params["uploadParams"] as? [String: AnyHashable]
            else {
                DocsLogger.info("UploadFileAdapter, parse params failure", component: LogComponents.uploadFile)
                return
        }

        var fromSource: UploadImageFrom = .unknow
        if let from = params["from"] as? String, let fromType = UploadImageFrom(rawValue: from) {
            fromSource = fromType
        }
        let contentType = getContentType(params["contentType"] as? String ?? "")
        var fileSource = params["file_url"] as? String ?? ""
        let uploadPencilKit = params["isPencilKit"] as? Bool ?? false
        if uploadPencilKit {
            DocsTracker.log(enumEvent: .clientPencilkitDataUpload, parameters: ["action": "start"])
            let dataAsset = newCacheAPI.getAssetWith(uuids: uuids, objToken: nil).first
            fileSource = dataAsset?.cacheKey ?? ""
        }

        let beginTime = Date.timeIntervalSinceReferenceDate
        DocsLogger.info("UploadFileAdapter, start, uuid=\(uuids.first?.encryptToken ?? ""), contentType=\(contentType)", component: LogComponents.uploadFile)

        for uuid in uuids {
            var fileName: String
            if contentType == .image {
                if let name = params["fileName"] as? String, !name.isEmpty {
                    // 注意：此时如果直接使用空字符串后续取文件路径会失败，导致上传失败
                    fileName = name
                } else {
                    fileName = "\(uuid).jpeg"
                }
            } else {
                fileName = params["fileName"] as? String ?? ""
            }
            guard let localPath = fetchLocalPath(with: uuid, fileSource: fileSource, fileName: fileName, contentType: contentType, from: fromSource) else {
                DocsLogger.info("UploadFileAdapter, fetchLocalPath, error, uuid=\(uuid.encryptToken)", component: LogComponents.uploadFile)
                if uploadPencilKit {
                    DocsTracker.log(enumEvent: .clientPencilkitDataUpload, parameters: ["action": "fail"])
                }
                // 资源不存在，回调给前端fail，不然会触发RN和Native一直重试
                completion(.failure(NSError(domain: "offlineSync upload Image error", code: UploadFileErrorCode.localFileNotExist.rawValue)))
                return
            }

            //drive上传文件之后会把原文件移动到drive缓存目录下，当复制图片数据到其它文档时，
            //会再次去上传绘图数据，但是原来的目录下找不到数据文件
            //需要根据缓存中的绘图数据再新建一份文件
            if uploadPencilKit,
               !localPath.exists,
               let canvasData: Data = CacheService.normalCache.object(forKey: uuid) {
                _ = localPath.createFile(with: canvasData)
            }

            uploadFileService.uploadFile(localPath: localPath,
                                         uuid: uuid,
                                         fileName: fileName,
                                         contentType: contentType,
                                         params: uploadParams,
                                         progress: { [weak self] (progressResult) in
                                            self?.handleWithProgress(progressResult,
                                                                     uuid: uuid,
                                                                     progress: progress)
                                         },
                                         completion: { [weak self] (result) in
                                            self?.handleWithResult(result,
                                                                   uuid: uuid,
                                                                   fileName: fileName,
                                                                   contentType: contentType,
                                                                   fromSource: fromSource,
                                                                   beginTime: beginTime,
                                                                   isFromPencilKit: uploadPencilKit,
                                                                   completion: completion)
                                         })
        }
    }

    private func handleWithProgress(_ progressResult: UploadFileProgressType,
                                    uuid: String,
                                    progress: @escaping UploadFileProgress) {
        guard progressResult.bytesTransferred > 0, progressResult.bytesTotal > 0, progressResult.bytesTransferred <= progressResult.bytesTotal else {
            return
        }
        // 通知前端
        let result = [
            "uuid": uuid,
            "progress": CGFloat(progressResult.bytesTransferred) / CGFloat(progressResult.bytesTotal)
            ] as [String: Any]
        progress(result)
    }

    private func handleWithResult(_ result: UploadFileResultType,
                                  uuid: String,
                                  fileName: String,
                                  contentType: SKPickContentType,
                                  fromSource: UploadImageFrom,
                                  beginTime: TimeInterval,
                                  isFromPencilKit: Bool = false,
                                  completion: @escaping UploadFileCompletion) {
        let costTime = Date.timeIntervalSinceReferenceDate - beginTime
        let from: SKPicStatisticsUploadFrom = fromSource == .comment ? .comment : .others
        switch result {
        case .success(let (uuid, dataSize, res)):
            var result = [
                "code": 0,
                "message": "",
                "uuid": uuid,
                "file": ["size": dataSize ?? 0, "name": fileName]
                ] as [String: Any]

            guard let token = res["token"] as? String else {
                DocsLogger.info("UploadFileAdapter, failure, lack of token, uuid=\(uuid.encryptToken)", component: LogComponents.uploadFile)
                if isFromPencilKit {
                    DocsTracker.log(enumEvent: .clientPencilkitDataUpload, parameters: ["action": "fail"])
                }
                return
            }

            if isFromPencilKit {
                DocsTracker.log(enumEvent: .clientPencilkitDataUpload, parameters: ["action": "success"])
            }
            //上传图片成功，将图片缓存移动到cache缓存（可清理）
            if contentType == .image {
                let imageCacheKey = imageCachKeyFor(uuid: uuid)
                newCacheAPI.migrateImageFromStoreToCache(key: imageCacheKey)
            }

            //上传绘图成功后将数据缓存到以token为key的缓存中
            if CacheService.normalCache.containsObject(forKey: uuid),
               let data: Data = CacheService.normalCache.object(forKey: uuid) {
                CacheService.normalCache.set(object: data, forKey: token)
            }

            result["data"] = [
                "uploadType": UploadImageType.drive.rawValue,
                "uuid": uuid,
                "token": token
            ]
            DocsLogger.info("UploadFileAdapter, success,uuid=\(uuid.encryptToken)", component: LogComponents.uploadFile)
            SKUploadPicStatistics.uploadFileReport(0, contentType: contentType, from: from, uploadTo: .uploadToDrive, fileSize: dataSize ?? 0, cost: Int(costTime * 1000))
            completion(.success((uuid: uuid, data: result)))
        case .failure(let error):
            DocsLogger.info("UploadFileAdapter, failure,uuid=\(uuid.encryptToken), err=\(error)", component: LogComponents.uploadFile)
            var errorCode: Int = -1
            if isFromPencilKit {
                DocsTracker.log(enumEvent: .clientPencilkitDataUpload, parameters: ["action": "fail"])
            }
            switch error {
            case .driveError(let errCode):
                errorCode = errCode
            default: break
            }
            SKUploadPicStatistics.uploadFileReport(errorCode, contentType: contentType, from: from, uploadTo: .uploadToDrive, msg: "\(error)", cost: Int(costTime * 1000))
            completion(.failure(error))
        }
    }


    // 获取本地缓存path
    private func fetchLocalPath(with uuid: String,
                                fileSource: String,
                                fileName: String,
                                contentType: SKPickContentType,
                                from: UploadImageFrom) -> SKFilePath? {
        switch contentType {
        case .image:
            return getImageLocalPath(with: uuid, fileName: fileName, from: from)
        default:
            return getOtherFileLocalPath(with: uuid, fileSource: fileSource)
        }
    }

    private func imageCachKeyFor(uuid: String) -> String {
        return SKPickImageUtil.makeImageCacheKey(with: uuid)
    }

    private func getImageLocalPath(with uuid: String, fileName: String, from: UploadImageFrom) -> SKFilePath? {
        var imageData: Data?
        let key = imageCachKeyFor(uuid: uuid)
        if from == .comment {
            let cacheData: NSCoding? =  DocsContainer.shared.resolve(CommentImageCacheInterface.self)?.getImage(byKey: key, token: nil)
            imageData = cacheData as? Data
        } else {
            imageData = newCacheAPI.getImage(byKey: key, token: self.objToken, needSync: true) as? Data
        }
        if let imageData = imageData {
            let localPath = OCRImageCacheManager.save(imageData: imageData, with: fileName)
            return localPath
        } else {
            return nil
        }
    }

    private func getOtherFileLocalPath(with uuid: String, fileSource: String) -> SKFilePath? {
        if let fileUrl = URL(string: fileSource) {
            let lastCompoment: String = fileUrl.lastPathComponent
            if lastCompoment.isEmpty {
                return nil
            } else {
                let path = SKPickContentType.getUploadCacheUrl(lastComponent: lastCompoment)
                return path
            }
        } else {
            let pathExtension = SKFilePath.getFileExtension(from: fileSource)
            let path = SKPickContentType.getUploadCacheUrl(uuid: uuid, pathExtension: pathExtension ?? "")
            return path
        }
    }

}
