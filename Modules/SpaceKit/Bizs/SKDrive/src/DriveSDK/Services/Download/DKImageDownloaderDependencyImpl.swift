//
//  DKImageDownloaderDependencyImpl.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/19.
//

import Foundation
import SKFoundation

class DKImageDownloaderDependencyImpl: DriveImageDownloaderDependency {
    private let fileInfo: DKFileProtocol
    private let filePreview: DKFilePreview
    private let isLatest: Bool
    private let cacheService: DKCacheServiceProtocol
    init(fileInfo: DKFileProtocol, filePreview: DriveFilePreview, isLatest: Bool, cacheService: DKCacheServiceProtocol) {
        self.fileInfo = fileInfo
        self.filePreview = filePreview
        self.isLatest = isLatest
        self.cacheService = cacheService
    }
    var liinearizedURL: String? {
        return filePreview.previewURL
    }
    var fileSize: UInt64 {
        return fileInfo.size
    }
    
    lazy var downloadPath: SKFilePath = {
        return cacheService.fileDownloadURL(cacheType: .preview, type: fileInfo.type, dataVersion: fileInfo.dataVersion)
    }()
    
    var imageSize: CGSize? {
        return filePreview.imageSize
    }
    
    func saveImage(_ completion: @escaping (Bool, SKFilePath?) -> Void) {
        let source: DriveCacheService.Source = isLatest ? .standard : .history
        let basicInfo = DriveCacheServiceBasicInfo(cacheType: .preview,
                                                 source: source,
                                                 token: fileInfo.fileID,
                                                 fileName: fileInfo.name,
                                                 fileType: fileInfo.type,
                                                 dataVersion: fileInfo.dataVersion,
                                                 originFileSize: fileInfo.size)
        cacheService.saveFile(filePath: downloadPath, basicInfo: basicInfo) { result in
            switch result {
            case let .success(path):
                completion(true, path)
            case .failure:
                completion(false, nil)
            }
        }
    }
}
