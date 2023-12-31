//
//  DocDownloadCacheService.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/30.
//
// disable-lint: magic number

import Foundation
import SKFoundation
import SpaceInterface
import YYCache
import SKCommon


public class DocDownloadCacheService: SpaceDownloadCacheProtocol {

    private static let cacheDefaultDataVersion = ""
    private static let cacheDefaultFileName = "image"

    private let cacheService = DriveCacheService.shared
    static let cacheRootURL = SKFilePath.docsImageCacheDir

    private let memoryCache: YYMemoryCache = {
        let cache = YYMemoryCache()
        cache.countLimit = 128              // 限制缓存数量
        cache.costLimit = 50 * 1024 * 1024  // 限制大小为50M
        cache.shouldRemoveAllObjectsOnMemoryWarning = true
        cache.shouldRemoveAllObjectsWhenEnteringBackground = true
        return cache
    }()
    
    fileprivate init() { }

    public static let shared = DocDownloadCacheService()

    static func getDocDownloadCacheURL(key: String, type: DocCommonDownloadType) -> SKFilePath {
        let cacheType = DriveCacheType(downloadType: type)
        let fileName = shared.cacheService.driveFileCacheName(cacheType: cacheType, fileToken: key, dataVersion: cacheDefaultDataVersion, fileExtension: "")
        return cacheRootURL.appendingRelativePath(type.typeString).appendingRelativePath(fileName)
    }
    
    public func save(request: DocCommonDownloadRequestContext, completion: ((_ success: Bool) -> Void)?) {
        let filePath = Self.getDocDownloadCacheURL(key: request.fileToken, type: request.downloadType)
        let fileSize = request.originFileSize ?? filePath.fileSize
        let cacheType = DriveCacheType(downloadType: request.downloadType)
        let source: DriveCacheService.Source = request.isManualOffline ? .docsManual : .docsImage
        let fileName = request.fileName ?? Self.cacheDefaultFileName
        let dataVersion = request.dataVersion ?? Self.cacheDefaultDataVersion
        let basicInfo = DriveCacheServiceBasicInfo(cacheType: cacheType,
                                                   source: source,
                                                   token: request.fileToken,
                                                   fileName: fileName,
                                                   fileType: nil,
                                                   dataVersion: dataVersion,
                                                   originFileSize: fileSize)
        let context = SaveFileContext(filePath: filePath,
                                      moveInsteadOfCopy: true,
                                      basicInfo: basicInfo,
                                      rewriteFileName: false)
        cacheService.saveDriveFile(context: context) { result in
            switch result {
            case .success:
                completion?(true)
            case .failure:
                completion?(false)
            }
        }
    }

    public func data(key: String, type: DocCommonDownloadType) -> Data? {
        let memoryCacheKey = key + "\(type)"
        if let memoryData = memoryCache.object(forKey: memoryCacheKey) as? Data {
            return memoryData
        } else {
            let cacheType = DriveCacheType(downloadType: type)
            guard let (_, data) = try? cacheService.getDriveData(type: cacheType, token: key, dataVersion: "", fileExtension: nil).get() else {
                return nil
            }
            memoryCache.setObject(data, forKey: memoryCacheKey, withCost: UInt(data.count))
            return data
        }
    }
    
    public func dataWithVersion(key: String, type: DocCommonDownloadType, dataVersion: String?) -> Data? {
        let memoryCacheKey = key + "\(type)"
        let cacheType = DriveCacheType(downloadType: type)
        guard let (_, data) = try? cacheService.getDriveData(type: cacheType, token: key, dataVersion: dataVersion, fileExtension: nil).get() else {
            return nil
        }
        memoryCache.setObject(data, forKey: memoryCacheKey, withCost: UInt(data.count))
        return data
    }

    public func addImagesToManualCache(infos: [(String, DocCommonDownloadType)]) {
        let files = infos.lf_unique(by: { $0.0 })
            .map { (token, _) -> (token: String, dataVersion: String?, fileExtension: String?) in
                return (token, Self.cacheDefaultDataVersion, nil)
            }
        cacheService.moveToManualOffline(files: files, complete: nil)
    }

    public func removeImagesFromManualCache(infos: [(String, DocCommonDownloadType)]) {
        let tokens = infos.lf_unique(by: { $0.0 }).map { $0.0 }
        cacheService.moveOutManualOffline(tokens: tokens, complete: nil)
    }
}
