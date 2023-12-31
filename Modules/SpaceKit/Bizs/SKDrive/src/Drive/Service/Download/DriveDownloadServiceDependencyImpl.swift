//
//  DriveDownloadServiceDependencyImpl.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/28.
//

import Foundation
import SKFoundation

struct DriveDownloadServiceDependencyImpl: DriveDownloadServiceDependency {
    var fileSize: UInt64 {
        return fileInfo.size
    }
    
    var downloadFileSize: UInt64 {
        switch downloadType {
        case .origin:
            return fileInfo.size
        case .similar(let meta):
            var filePreview = fileInfo.previewMetas[.similarFiles]
            return filePreview?.previewFileSize ?? meta.size
        case .preview(let type, _):
            var filePreview = fileInfo.previewMetas[type]
            // 转码中的文件，初始 fileInfo 的 previewMeta 信息中是没有 size 的信息，避免 size 不对，这里解包用 0，这样 rust 可以请求 0-0 header 信息确定 size
            return filePreview?.previewFileSize ?? 0
        }
    }
    
    var cacheURL: SKFilePath {
        switch downloadType {
        case .origin(let meta):
            return cacheService.fileDownloadURL(cacheType: cacheType, type: meta.type, dataVersion: meta.dataVersion)
        case .similar(let meta):
            return cacheService.fileDownloadURL(cacheType: cacheType, type: meta.type, dataVersion: meta.dataVersion)
        case .preview(let type, _):
            let fileType = type.toDriveFileType(originType: fileInfo.fileType).rawValue
            let cacheFileType = getCacheFileType(fileExtension: fileInfo.fileExtension, fileType: fileType)
            return cacheService.fileDownloadURL(cacheType: cacheType,
                                                type: cacheFileType,
                                                dataVersion: fileInfo.dataVersion)
        }
    }
    func isFileExsit() -> Bool {
        switch downloadType {
        case .origin, .similar:
            return cacheService.isFileExist(type: cacheType,
                                            fileExtension: fileInfo.fileExtension,
                                            dataVersion: fileInfo.dataVersion)
        case let .preview(previewType, _):
            let downloadFileType = previewType.toDriveFileType(originType: fileInfo.fileType)
            let fileExtension =
                (fileInfo.fileType.isMedia || fileInfo.fileType.isImage)
                ? fileInfo.fileExtension : downloadFileType.rawValue
            return cacheService.isFileExist(type: cacheType,
                                            fileExtension: fileExtension,
                                            dataVersion: fileInfo.dataVersion)
        }

    }
    
    func saveFile(completion: ((Bool) -> Void)?) {
        let basicInfo = DriveCacheServiceBasicInfo(cacheType: cacheType,
                                                   source: cacheSource,
                                                   token: fileInfo.fileID,
                                                   fileName: fileInfo.name,
                                                   fileType: fileInfo.type,
                                                   dataVersion: fileInfo.dataVersion,
                                                   originFileSize: fileInfo.size)
        cacheService.saveFile(filePath: cacheURL,
                              basicInfo: basicInfo) { result in
            switch result {
            case .success:
                completion?(true)
            case .failure:
                completion?(false)
            }
        }
    }
    
    let downloadType: DriveDownloadService.DownloadType
    let cacheCustomID: String?
    let fileInfo: DKFileProtocol
    ///缓存请求的来源
    let cacheSource: DriveCacheService.Source
    let cacheService: DKCacheServiceProtocol

    init(fileInfo: DKFileProtocol,
         downloadType: DriveDownloadService.DownloadType,
         cacheSource: DriveCacheService.Source,
         cacheCustomID: String? = nil,
         cacheService: DKCacheServiceProtocol) {
        self.fileInfo = fileInfo
        self.downloadType = downloadType
        self.cacheCustomID = cacheCustomID
        self.cacheSource = cacheSource
        self.cacheService = cacheService
    }
    
    private var cacheType: DriveCacheType {
        switch downloadType {
        case .origin:
            return .origin
        case .similar:
            return .similar
        case .preview:
            if let customID = cacheCustomID {
                return .associate(customID: customID)
            } else {
                return .preview
            }
        }
    }

    private func getCacheFileType(fileExtension: String?, fileType: String) -> String {
        // 1. file extension 可能是空的, 此时使用 file type 作为文件存储后缀
        // 2. 需要比较 file extension 和 file type 在忽略大小写的情况下是否相同, 如果相同则使用原始文件的后缀
        //    作为下载文件的后缀. 否则对于后缀为大写的文件, 如果用 file type 作为后缀, 比如 test.PDF 就会保存为
        //    test.pdf, 这样会导致这查询缓存时, 因后缀不匹配而查询失败.
        // 3. MS 场景共享 ppt 时, 实际上会下载转码后的 pdf 进行共享, 因此下载后需要保存为 pdf 文件. 
        DocsLogger.driveInfo("DriveDownloadServiceDependencyImpl -- getCacheFileType, " +
                             "fileExtension: \(String(describing: fileExtension)), " +
                             "fileType: \(fileType)")
        guard let fileExtension = fileExtension else {
            return fileType
        }
        if fileExtension.lowercased() == fileType.lowercased() {
            return fileExtension
        }
        return fileType
    }
}
