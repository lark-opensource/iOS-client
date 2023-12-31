//
//  DriveExternalCacheHelper.swift
//  SKDrive
//
//  Created by zenghao on 2023/12/13.
//

import Foundation
import SKFoundation
import SpaceInterface
import Swinject
import LarkContainer
import SKInfra

class DriveExternalCacheHelper {
    
    // IM中使用本地发送的视频缓存
    static func getLocalIMVideoCache(fileInfo: DKFileProtocol ,completion: @escaping (DriveProccesPreviewInfo?) -> Void) {
        guard UserScopeNoChangeFG.ZH.driveSDKExternalCachePreviewEnable else {
            DocsLogger.driveError("DriveExternalCacheHelper -- no IM local file cache")
            completion(nil)
            return
        }
        
        guard fileInfo.isIMFile else {
            DocsLogger.driveError("DriveExternalCacheHelper -- only handle IM local file cache")
            completion(nil)
            return
        }
        
        // 获取msgID
        guard let authExtra = fileInfo.authExtra else {
            DocsLogger.driveInfo("DriveExternalCacheHelper -- no auth extra to get msgID")
            completion(nil)
            return
        }

        guard let jsonValue = authExtra.toDictionary() else {
            DocsLogger.driveInfo("DriveExternalCacheHelper -- invalid auth extra")
            completion(nil)
            return
        }

        guard let msgID = jsonValue["msg_id"] as? String else {
            DocsLogger.driveInfo("DriveExternalCacheHelper -- can not get msg from auth extra")
            completion(nil)
            return
        }

        let cacheService = DocsContainer.shared.resolve(DriveSDKIMLocalCacheServiceProtocol.self)!
        cacheService.getIMCache(fileID: fileInfo.fileID, msgID: msgID, complete: { localPath in
            DocsLogger.driveInfo("DriveExternalCacheHelper -- localPath: \(String(describing: localPath))")
            guard let localPath else {
                completion(nil)
                return
            }

            if fileInfo.fileType.isVideo, fileInfo.fileType.isVideoPlayerSupport {
                let filePath = SKFilePath(absUrl: localPath)
                guard filePath.exists else {
                    DocsLogger.driveInfo("DriveExternalCacheHelper -- file not exist")
                    completion(nil)
                    return
                }

                let videoInfo = DriveVideo(type: .local(url: filePath),
                                           info: nil,
                                           title: fileInfo.name,
                                           size: fileInfo.size,
                                           cacheKey: fileInfo.videoCacheKey,
                                           authExtra: authExtra)
                let previewInfo = DriveProccesPreviewInfo.localMedia(url: filePath, video: videoInfo)
                DocsLogger.driveInfo("DriveExternalCacheHelper -- preview local video: \(previewInfo)")
                
                // 保存缓存信息
                let source: DriveCacheService.Source = .thirdParty
                let cacheType: DriveCacheType = .preview
                let fileType = fileInfo.type
                let fileSize = fileInfo.size 
                let encryptedToken = DocsTracker.encrypt(id: fileInfo.fileID)

                DocsLogger.driveInfo("DriveExternalCacheHelper---saving file.",
                                     extraInfo: ["token": encryptedToken,
                                                 "cacheType": cacheType,
                                                 "fileType": fileType,
                                                 "fileSize": fileSize])
                let basicInfo = DriveCacheServiceBasicInfo(cacheType: cacheType,
                                                           source: source,
                                                           token: fileInfo.fileID,
                                                           fileName: fileInfo.name,
                                                           fileType: fileType,
                                                           dataVersion: nil,
                                                           originFileSize: fileSize)
                let saveContext = SaveFileContext(filePath: filePath,
                                                  moveInsteadOfCopy: false,
                                                  basicInfo: basicInfo,
                                                  rewriteFileName: true)
                DriveCacheService.shared.saveSDKFile(appID: DKSupportedApp.im.rawValue, fileID: fileInfo.fileID, context: saveContext) { savedNode in
                    switch savedNode {
                    case .success:
                        DocsLogger.driveInfo("DriveExternalCacheHelper -- save to cache succeed", extraInfo: ["token": encryptedToken])
                    case .failure(let error):
                        DocsLogger.driveError("DriveExternalCacheHelper---save to cache failed", extraInfo: ["token": encryptedToken], error: error)
                    }
                }
                
                
                completion(previewInfo)
                return
            } else {
                DocsLogger.driveInfo("DriveExternalCacheHelper -- only can handle IM local video cahce")
                completion(nil)
                return
            }
        })
    }
}
