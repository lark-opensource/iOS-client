//
//  UploadImageByDocAdapter.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/7/19.
//  该adape功能
//  1, 上传图片到doc服务器（应该现在都走drive上传了，保险起见先留着）
//  2, 复制图片copy to （还在用）

import Foundation
import SwiftyJSON
import SKFoundation
import SpaceInterface
import SKInfra

public final class UploadImageByDocAdapter {

    private let uploadImageNetworkService = UploadImageNetworkService() // 上传图片工具
    private let newCacheAPI: NewCacheAPI
    public var objToken: String?

    public typealias UploadImageCompletion = (Result<(uuid: String, data: [String: Any]), Error>) -> Void

    public init(_ resolver: DocsResolver = DocsContainer.shared) {
        newCacheAPI = resolver.resolve(NewCacheAPI.self)!
    }

    public func uploadImage(for params: [String: Any], completion: @escaping UploadImageCompletion) {
        var uploadType: UploadImageType = .doc // 默认原有逻辑
        if let rawVeriosn = params["uploadType"] as? Int, let version = UploadImageType(rawValue: rawVeriosn) {
            uploadType = version
        }

        switch uploadType {
        case .doc:
            uploadImageV1(with: params, completion: completion)
        case .copyTo:
            uploadImageV2_1(with: params, completion: completion)
        default :
            spaceAssert(false, "其它类型不支持")
        }
    }

    public func cancelAllTask() {
        uploadImageNetworkService.cancelAllTask()
    }
}

private extension UploadImageByDocAdapter {
    // 上传接口 V2.1 -> Copy
    private func uploadImageV2_1(with params: [String: Any], completion: @escaping UploadImageCompletion) {
        guard
            let uploadParams = params["uploadParams"] as? [String: AnyHashable],
            let driveToken = uploadParams["drive_token"] as? String,
            let mountPoint = uploadParams["mount_point"] as? String,
            let mountNodeToken = uploadParams["mount_node_token"] as? String
            else {
                DocsLogger.info("upload image v2 service parse params failure", component: LogComponents.uploadImg)
                return
        }

        var files: [[String: String]] = [["file_token": driveToken]]
        var pencilKitToken = ""
        if let token = params["pencilKitToken"] as? String {
            pencilKitToken = token
            files.append(["file_token": pencilKitToken])
        }

        var destMountInfo: [String: AnyHashable] = [
            "mount_point": mountPoint,
            "mount_key": mountNodeToken
        ]
        if let extraParams = uploadParams["extraParams"] as? [String: AnyHashable] {
            destMountInfo["ext"] = extraParams
        }
        let params = [
            "files": files,
            "dest_mount_info": destMountInfo
            ] as [String: AnyHashable]

        uploadImageNetworkService.copyImage(for: driveToken, with: params) { (result) in
            switch result {
            case .success(let (uuid, res)):
                // 通知前端
                var result = [
                    "code": 0,
                    "message": "",
                    "uuid": uuid
                    ] as [String: Any]

                guard
                    let data = res["data"] as? JSON,
                    let token = data["data"]["succ_files"][driveToken].string
                else {
                    DocsLogger.info("upload image failure, data parse failure \(res)", component: LogComponents.uploadImg)
                    return
                }

                result["data"] = [
                    "uploadType": UploadImageType.copyTo.rawValue,
                    "uuid": uuid, // 不知道这里为什么需要再传一次呢?
                    "token": token
                ]

                if !pencilKitToken.isEmpty,
                   let canvasToken = data["data"]["succ_files"][pencilKitToken].string,
                   var resultData = result["data"] as? [String: Any] {
                    resultData.updateValue(canvasToken, forKey: "pencilKitToken")
                    result["data"] = resultData
                }
                DocsLogger.info("upload image V2.1 success, uuid=\(uuid.encryptToken)", component: LogComponents.uploadImg)
                SKUploadPicStatistics.uploadPicReport(0, from: .others, uploadTo: .copy)
                completion(.success((uuid: uuid, data: result)))
            case .failure(let error):
                var errorCode: Int = -1
                var resultError: Error = error
                switch error {
                case .networkError(let error):
                    let nsError = error as NSError
                    if nsError.code != 0 {
                        errorCode = nsError.code
                        resultError = nsError
                    }
                default:
                    break
                }
                DocsLogger.info("upload image V2.1 failure, uuid=\(driveToken.encryptToken), errorCode=\(errorCode),err=\(error)", component: LogComponents.uploadImg)
                SKUploadPicStatistics.uploadPicReport(errorCode, from: .others, uploadTo: .copy, msg: "\(error)")
                completion(.failure(resultError))
            }
        }
    }

    // 上传接口 V1 -> Doc
    private func uploadImageV1(with params: [String: Any], completion: @escaping UploadImageCompletion) {
        guard
            let uuids = params["uuids"] as? [String], // 上传图片的 ids
            let serverPath = params["url"] as? String // 上传路径
            else {
                DocsLogger.info("upload image v1 service parse params failure", component: LogComponents.uploadImg)
                return
        }

        DocsLogger.info("UploadImageByDocAdapter uploadImageDoc, start,uuid=\(uuids.first?.encryptToken ?? "")", component: LogComponents.uploadImg)
        let beginTime = Date.timeIntervalSinceReferenceDate

        for uuid in uuids {
            guard let imageData = fetchImageDataFromCache(with: uuid, from: .unknow) else {
                DocsLogger.info("upload image fetch image data failure, uuid=\(uuid.encryptToken)", component: LogComponents.uploadImg)
                continue
            }

            let extraInfo = generateExtraInfo(params)
            uploadImageNetworkService.uploadImageV1(imageData, for: uuid, with: extraInfo, to: serverPath) { [weak self] (result) in
                let dataSize = imageData.count
                let costTime = Date.timeIntervalSinceReferenceDate - beginTime

                switch result {
                case .success(let (uuid, res)):
                    // 通知前端
                    var result = [
                        "code": 0,
                        "message": "",
                        "uuid": uuid,
                        "file": ["size": imageData.count, "name": "\(uuid).jpeg"]
                        ] as [String: Any]

                    if let rawData = res["data"] as? Data,
                        var dict = rawData.jsonDictionary?["data"] as? [String: Any] {
                        dict["uploadType"] = UploadImageType.doc.rawValue
                        result["data"] = dict
                        if let urlStr = dict["url"] as? String, let url = URL(string: urlStr) {
                            self?.newCacheAPI.storeImage(imageData as NSCoding, token: self?.objToken, forKey: url.path, needSync: false)
                        } else {
                            DocsLogger.info("UploadImageByDocAdapter uploadImageDoc, uuid= \(uuid.encryptToken), but Result has no info =\(dict)", component: LogComponents.uploadImg)
                        }
                    }

                    DocsLogger.info("UploadImageByDocAdapter uploadImageDoc, success, uuid= \(uuid.encryptToken)", component: LogComponents.uploadImg)
                    SKUploadPicStatistics.uploadPicReport(0, from: .others, uploadTo: .uploadToDocs, picSize: dataSize, cost: Int(costTime * 1000))
                    completion(.success((uuid: uuid, data: result)))
                case .failure(let error):
                    DocsLogger.info("UploadImageByDocAdapter uploadImageDoc, failure, uuid= \(uuid.encryptToken), error = \(error)", component: LogComponents.uploadImg)
                    SKUploadPicStatistics.uploadPicReport(-1, from: .others, uploadTo: .uploadToDocs, msg: "\(error)", picSize: dataSize, cost: Int(costTime * 1000))
                    completion(.failure(error))
                }
            }
        }
    }

    // 获取本地图片缓存
    private func fetchImageDataFromCache(with uuid: String, from: UploadImageFrom) -> Data? {
        let key = SKPickImageUtil.makeImageCacheKey(with: uuid) // 这里应该是和前端约定好的
        if from == .comment {
            let cacheData: NSCoding? =  DocsContainer.shared.resolve(CommentImageCacheInterface.self)?.getImage(byKey: key, token: nil)
            return cacheData as? Data
        } else {
            return newCacheAPI.getImage(byKey: key, token: self.objToken, needSync: true) as? Data
        }
    }

    // 生成上传额外信息
    private func generateExtraInfo(_ params: [String: Any]) -> [String: AnyHashable] {
        var extra: [String: AnyHashable] = [:]

        if let multiparts = params["multiparts"] as? [String: AnyHashable] {
            extra["multiparts"] = multiparts
        }

        if let header = params["request-header"] as? [String: String] {
            extra["request-header"] = header
        }

        return extra
    }
}
