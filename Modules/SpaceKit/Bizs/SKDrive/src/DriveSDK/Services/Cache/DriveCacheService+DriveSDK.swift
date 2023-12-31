//
//  DriveCacheService+DriveSDK.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/18.
//

import Foundation
import SKFoundation

/// DriveSDK 缓存接口 DKCacheService，内部实际调用 DriveCacheService
protocol DKCacheServiceProtocol {
    func fileDownloadURL(cacheType: DriveCacheType, type: String, dataVersion: String?) -> SKFilePath
    func isFileExist(type: DriveCacheType, fileExtension: String?, dataVersion: String?) -> Bool
    func getFile(fileExtension: String?, dataVersion: String?) -> Result<DriveCache.Node, Error>
    func getFile(type: DriveCacheType, fileExtension: String?, dataVersion: String?) -> Result<DriveCache.Node, Error>
    func getData(type: DriveCacheType, fileExtension: String?, dataVersion: String?) -> Result<(DriveCache.Node, Data), Error>
    func saveFile(filePath: SKFilePath,
                  basicInfo: DriveCacheServiceBasicInfo,
                  completion: ((Result<SKFilePath, Error>) -> Void)?)
    func saveData(data: Data,
                  basicInfo: DriveCacheServiceBasicInfo,
                  completion: ((Result<SKFilePath, Error>) -> Void)?)
    func deleteFile(dataVersion: String?)
}

struct DKCacheServiceImpl: DKCacheServiceProtocol {
    private let appID: String
    private let fileID: String

    private let cacheService = DriveCacheService.shared

    init(appID: String, fileID: String) {
        self.appID = appID
        self.fileID = fileID
    }

    func fileDownloadURL(cacheType: DriveCacheType, type: String, dataVersion: String? = nil) -> SKFilePath {
        cacheService.sdkFileDownloadURL(cacheType: cacheType, appID: appID, fileID: fileID, type: type)
    }

    func isFileExist(type: DriveCacheType, fileExtension: String?, dataVersion: String? = nil) -> Bool {
        return cacheService.isSDKFileExist(type: type, appID: appID, fileID: fileID, fileExtension: fileExtension)
    }

    func getFile(type: DriveCacheType, fileExtension: String?, dataVersion: String? = nil) -> Result<DriveCache.Node, Error> {
        return cacheService.getSDKFile(type: type, appID: appID, fileID: fileID, fileExtension: fileExtension)
    }
    
    func getFile(fileExtension: String?, dataVersion: String?) -> Result<DriveCache.Node, Error> {
        return cacheService.getSDKFile(appID: appID, fileID: fileID)
    }

    func getData(type: DriveCacheType, fileExtension: String?, dataVersion: String? = nil) -> Result<(DriveCache.Node, Data), Error> {
        return cacheService.getSDKData(type: type, appID: appID, fileID: fileID, fileExtension: fileExtension)
    }

    struct DKSaveFileContext {
        let saveFileContext: SaveFileContext
        let appID: String
        let fileID: String
    }
    func saveFile(filePath: SKFilePath,
                  basicInfo: DriveCacheServiceBasicInfo,
                  completion: ((Result<SKFilePath, Error>) -> Void)?) {
        let saveFileContext = SaveFileContext(filePath: filePath, 
                                              moveInsteadOfCopy: true,
                                              basicInfo: basicInfo,
                                              rewriteFileName: false)
        cacheService.saveSDKFile(appID: appID, fileID: fileID, context: saveFileContext, completion: completion)
    }

    func saveData(data: Data,
                  basicInfo: DriveCacheServiceBasicInfo,
                  completion: ((Result<SKFilePath, Error>) -> Void)?) {
        let saveDataContext = SaveDataContext(data: data, basicInfo: basicInfo)
        cacheService.saveSDKData(appID: appID, fileID: fileID, context: saveDataContext, completion: completion)
    }

    func deleteFile(dataVersion: String? = nil) {
        cacheService.deleteSDKFile(appID: appID, fileID: fileID)
    }
}

struct DriveCacheServiceImpl: DKCacheServiceProtocol {
    let fileToken: String
    
    init(fileToken: String) {
        self.fileToken = fileToken
    }

    private let cacheService = DriveCacheService.shared

    func fileDownloadURL(cacheType: DriveCacheType, type: String, dataVersion: String?) -> SKFilePath {
        return cacheService.driveFileDownloadURL(cacheType: cacheType, fileToken: fileToken, dataVersion: dataVersion ?? "", fileExtension: type)
    }
    
    func isFileExist(type: DriveCacheType, fileExtension: String?, dataVersion: String?) -> Bool {
        return cacheService.isDriveFileExist(type: type, token: fileToken, dataVersion: dataVersion, fileExtension: fileExtension)
    }
    
    func getFile(type: DriveCacheType, fileExtension: String?, dataVersion: String?) -> Result<DriveCache.Node, Error> {
        return cacheService.getDriveFile(type: type, token: fileToken, dataVersion: dataVersion, fileExtension: fileExtension)
    }
    
    func getFile(fileExtension: String?, dataVersion: String?) -> Result<DriveCache.Node, Error> {
        return cacheService.getDriveFile(token: fileToken, dataVersion: dataVersion, fileExtension: fileExtension)
    }

    
    func getData(type: DriveCacheType, fileExtension: String?, dataVersion: String?) -> Result<(DriveCache.Node, Data), Error> {
        return cacheService.getDriveData(type: type, token: fileToken, dataVersion: dataVersion, fileExtension: fileExtension)
    }
    
    func saveFile(filePath: SKFilePath,
                  basicInfo: DriveCacheServiceBasicInfo,
                  completion: ((Result<SKFilePath, Error>) -> Void)?) {
        let basicInfo = DriveCacheServiceBasicInfo(cacheType: basicInfo.cacheType,
                                                   source: basicInfo.source,
                                                   token: fileToken,
                                                   fileName: basicInfo.fileName,
                                                   fileType: basicInfo.fileType,
                                                   dataVersion: basicInfo.dataVersion,
                                                   originFileSize: basicInfo.originFileSize)
        let context = SaveFileContext(filePath: filePath,
                                      moveInsteadOfCopy: true,
                                      basicInfo: basicInfo,
                                      rewriteFileName: false)

        cacheService.saveDriveFile(context: context, completion: completion)
    }
    
    func saveData(data: Data,
                  basicInfo: DriveCacheServiceBasicInfo,
                  completion: ((Result<SKFilePath, Error>) -> Void)?) {
        let basicInfo = DriveCacheServiceBasicInfo(cacheType: basicInfo.cacheType,
                                                   source: basicInfo.source,
                                                   token: fileToken,
                                                   fileName: basicInfo.fileName,
                                                   fileType: nil,
                                                   dataVersion: basicInfo.dataVersion,
                                                   originFileSize: basicInfo.originFileSize)
        let context = SaveDataContext(data: data, basicInfo: basicInfo)
        cacheService.saveDriveData(context: context, completion: completion)
    }
    
    func deleteFile(dataVersion: String?) {
        cacheService.deleteFile(token: fileToken, version: dataVersion, completion: nil)
    }
}

extension DriveCacheService {

    private func generateDriveSDKToken(appID: String, fileID: String) -> String {
        "DriveSDK-\(appID)-\(fileID)"
    }

    // MARK: - Checking Cache Existence

    func isSDKFileExist(type: DriveCacheType, appID: String, fileID: String, fileExtension: String? = nil) -> Bool {
        let sdkToken = generateDriveSDKToken(appID: appID, fileID: fileID)
        let filter = createExtensionFilter(fileExtension: fileExtension)
        return isFileExist(token: sdkToken, version: "") { $0.recordType == type && (filter?($0) ?? true) }
    }

    // MARK: - Retrive Cache File
    func getSDKFile(appID: String, fileID: String, fileExtension: String? = nil) -> Result<Node, Error> {
        let sdkToken = generateDriveSDKToken(appID: appID, fileID: fileID)
        // 没有指定cacheType，过滤掉orign类型
        let filter = createPreviewExtensionFilter(fileExtension: fileExtension)
        return getFile(token: sdkToken, version: "", filter: filter)
    }

    func getSDKFile(type: DriveCacheType, appID: String, fileID: String, fileExtension: String? = nil) -> Result<Node, Error> {
        let sdkToken = generateDriveSDKToken(appID: appID, fileID: fileID)
        // 指定了DriveCacheType，根据制定的cacheType获取文件
        let filter = createExtensionFilter(fileExtension: fileExtension)
        return getFile(token: sdkToken, version: "") { $0.recordType == type && (filter?($0) ?? true) }
    }

    func getSDKData(type: DriveCacheType, appID: String, fileID: String, fileExtension: String? = nil) -> Result<(Node, Data), Error> {
        let result = getSDKFile(type: type, appID: appID, fileID: fileID, fileExtension: fileExtension)
        switch result {
        case let .failure(error):
            DocsLogger.driveInfo("drive.sdk.cache --- failed to get sdk data, file node not found in cache")
            return .failure(error)
        case let .success(node):
            do {
                guard let path = node.fileURL else {
                    spaceAssertionFailure("drive.sdk.cache --- cache node file url not set")
                    let error = NSError(domain: "drive.file.cache", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "cache node file url not set"
                    ])
                    return .failure(error)
                }
                let data = try Data.read(from: path)
                return .success((node, data))
            } catch {
                DocsLogger.error("drive.sdk.cache --- failed to get sdk data, read data from file failed with error", error: error)
                assertionFailure()
                return .failure(error)
            }
        }
    }

    func saveSDKFile(appID: String, fileID: String, context: SaveFileContext, completion: SaveCompletion? = nil) {
        let sdkToken = generateDriveSDKToken(appID: appID, fileID: fileID)
        let cacheType = getCacheType(source: context.basicInfo.source)
        let fileSize = context.basicInfo.originFileSize ?? context.filePath.fileSize
        let record = Record(token: sdkToken,
                            version: "",
                            recordType: context.basicInfo.cacheType,
                            originName: context.basicInfo.fileName,
                            originFileSize: fileSize,
                            fileType: context.basicInfo.fileType,
                            cacheType: cacheType)
        saveFile(filePath: context.filePath,
                 record: record,
                 source: context.basicInfo.source,
                 moveInsteadOfCopy: context.moveInsteadOfCopy,
                 rewriteFileName: context.rewriteFileName,
                 completion: completion)
    }
    
    func saveSDKData(appID: String, fileID: String, context: SaveDataContext, completion: SaveCompletion? = nil) {
        DispatchQueue.global().async {
            let cacheType = context.basicInfo.cacheType
            let dataFileURL = self.sdkFileDownloadURL(cacheType: cacheType, appID: appID, fileID: fileID, type: "bin")
            guard dataFileURL.writeFile(with: context.data, mode: .over) else {
                DocsLogger.error("drive.file.cache --- failed to save drive data, write data failed")
                completion?(.failure(CacheError.writeDataFailed))
                return
            }
            
            let context = SaveFileContext(filePath: dataFileURL, 
                                          moveInsteadOfCopy: true,
                                          basicInfo: context.basicInfo,
                                          rewriteFileName: false)

            self.saveSDKFile(appID: appID, fileID: fileID, context: context)
        }
    }

    // MARK: - Deletion
    func deleteSDKFile(appID: String, fileID: String, completion: DeleteCompletion? = nil) {
        let sdkToken = generateDriveSDKToken(appID: appID, fileID: fileID)
        deleteFile(token: sdkToken, version: "", completion: completion)
    }

    // MARK: - Generate Download Path
    private func generateFileName(appID: String, fileID: String, type: String) -> String {
        return "DriveSDK_\(appID)_\(DocsTracker.encrypt(id: fileID)).\(type)"
    }

    func sdkFileCacheName(cacheType: DriveCacheType, appID: String, fileID: String, type: String) -> String {
        "\(cacheType.identifier)_" + generateFileName(appID: appID, fileID: fileID, type: type)
    }

    func sdkFileDownloadURL(cacheType: DriveCacheType, appID: String, fileID: String, type: String) -> SKFilePath {
        let fileName = sdkFileCacheName(cacheType: cacheType, appID: appID, fileID: fileID, type: type)
        return Self.downloadCacheURL.appendingRelativePath(fileName)
    }
}
