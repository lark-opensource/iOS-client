//
//  PreviewProcessorProvider.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/8.
//

import Foundation
import SKCommon

protocol PreviewProcessorProvider {
    func processor(with type: DrivePreviewFileType, fileInfo: DKFileProtocol, resultHandler: PreviewProcessHandler, config: DrivePreviewProcessorConfig) -> PreviewProcessor
}


struct DefaultPreviewProcessorProvider {
    let cacheService: DKCacheServiceProtocol
    init(cacheService: DKCacheServiceProtocol) {
        self.cacheService = cacheService
    }
}

extension DefaultPreviewProcessorProvider: PreviewProcessorProvider {
    func processor(with type: DrivePreviewFileType, fileInfo: DKFileProtocol, resultHandler: PreviewProcessHandler, config: DrivePreviewProcessorConfig) -> PreviewProcessor {
        switch type {
        case .jpgLin, .pngLin:
            return LinearizedImagePreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        case .linerizedPDF:            
            return DefaultPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        case .archive:
            return ArchivePreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        case .mp4:
            return VideoPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        case .html:
            return DriveHTMLPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        case .ogg:
            return OggPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        default:
            return DefaultPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        }

    }
}

struct IMPreivewProcesorProvider: PreviewProcessorProvider {
    let cacheService: DKCacheServiceProtocol
    init(cacheService: DKCacheServiceProtocol) {
        self.cacheService = cacheService
    }

    func processor(with type: DrivePreviewFileType, fileInfo: DKFileProtocol, resultHandler: PreviewProcessHandler, config: DrivePreviewProcessorConfig) -> PreviewProcessor {
        switch type {
        case .jpgLin, .pngLin:
            return LinearizedImagePreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        case .linerizedPDF:
            return DefaultPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        case .archive:
            return ArchivePreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        case .mp4:
            return VideoPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        case .ogg:
            return OggPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        default:
            return DefaultPreviewProcessor(cacheService: cacheService, fileInfo: fileInfo, handler: resultHandler, config: config)
        }

    }
}
