//
//  DefaultFileInfoProcessorProvider.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/7.
//

import Foundation
import SKCommon
import SKFoundation
import LarkDocsIcon

protocol FileInfoProcessorProvider {
    func processor(with type: DriveFileType, originFileInfo: DKFileProtocol, config: DriveFileInfoProcessorConfig) -> FileInfoProcessor
}

struct DefaultFileInfoProcessorProvider {
    let cacheService: DKCacheServiceProtocol
    let netStatus: SKNetStatusService
    let wpsEnable: Bool
    let thumbnailPreviewEnable: Bool
    private let performanceLogger: DrivePerformanceRecorder
    init(cacheService: DKCacheServiceProtocol,
         netStatus: SKNetStatusService = DocsNetStateMonitor.shared,
         wpsEnable: Bool = DriveFeatureGate.wpsEnable,
         thumbnailPreviewEnable: Bool = DriveFeatureGate.thumbnailPreviewEnable,
         performanceLogger: DrivePerformanceRecorder) {
        self.cacheService = cacheService
        self.netStatus = netStatus
        self.wpsEnable = wpsEnable
        self.thumbnailPreviewEnable = thumbnailPreviewEnable
        self.performanceLogger = performanceLogger
    }
}

extension DefaultFileInfoProcessorProvider: FileInfoProcessorProvider {
    func processor(with type: DriveFileType, originFileInfo: DKFileProtocol, config: DriveFileInfoProcessorConfig) -> FileInfoProcessor {
        if thumbnailPreviewEnable && type.isImage {
            return ThumbFileInfoProcessor(cacheService: cacheService,
                                          fileInfo: originFileInfo,
                                          config: config,
                                          performanceLogger: performanceLogger)
        } else if type == .ogg {
            return OggFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else if type.isVideo {
            return VideoFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else if type.isArchive {
            return ArchiveFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else if type.isWpsOffice && wpsEnable {
            // 无网络并且是excel，走html
            if type.isSupportHTML && !netStatus.isReachable {
                return HtmlFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
            }
            // WPS 属于在线预览，无网络情况不应该走入 WPSFileInfoProcessor
            if netStatus.isReachable == false {
                return DefaultFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
            }
            return WPSFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else if type.isSupportHTML {
            return HtmlFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else if type.isPDF {
            return PDFFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else {
            return DefaultFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        }
    }
}

struct DKFileInfoProcessorProvider {
    let cacheService: DKCacheServiceProtocol
    let wpsEnable: Bool
    init(cacheService: DKCacheServiceProtocol,
         wpsEnable: Bool = DriveFeatureGate.wpsEnable) {
        self.cacheService = cacheService
        self.wpsEnable = wpsEnable
    }
}
extension DKFileInfoProcessorProvider: FileInfoProcessorProvider {
    func processor(with type: DriveFileType, originFileInfo: DKFileProtocol, config: DriveFileInfoProcessorConfig) -> FileInfoProcessor {
        if type.isVideo {
            return VideoFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else if type.isArchive {
            return ArchiveFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else if type.isWpsOffice && wpsEnable {
            return WPSFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else if type.isPDF {
            return PDFFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        } else {
            return DefaultFileInfoProcessor(cacheService: cacheService, fileInfo: originFileInfo, config: config)
        }
    }
}
