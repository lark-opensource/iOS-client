//
//  ThumbFileInfoProcessor.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/8/16.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface
import RxSwift
import UIKit

protocol ThumbFileInfoProcessorDependency {
    var driveEnabled: Bool { get }
    var minSizeForThumbnailPreview: UInt64 { get }
    func checkIfSupport(appID: String) -> Bool
    func maxFileSize(for type: String) -> UInt64
    func downloader(cacheCheck: @escaping () -> Data?) -> ThumbDownloaderProtocol
}

struct ThumbFileInfoProcessorDependencyImpl: ThumbFileInfoProcessorDependency {
    var driveEnabled: Bool {
        return DriveFeatureGate.driveEnabled
    }
    var minSizeForThumbnailPreview: UInt64 {
        return DriveFeatureGate.minSizeForThumbnailPreview
    }
    func checkIfSupport(appID: String) -> Bool {
        return DriveFeatureGate.checkIfSupport(appID: appID)
    }
    func maxFileSize(for type: String) -> UInt64 {
        return DriveFeatureGate.maxFileSize(for: type)
    }
    
    func downloader(cacheCheck: @escaping () -> Data?) -> ThumbDownloaderProtocol {
        return ThumbnailDownloader(cacheCheck)
    }
}
class ThumbFileInfoProcessor: DefaultFileInfoProcessor {
    private var thumbDownloader: ThumbDownloaderProtocol?
    private let dependency: ThumbFileInfoProcessorDependency
    private let performanceLogger: DrivePerformanceRecorder
    private var bag = DisposeBag()

    override var useCacheIfExist: Bool {
        return true
    }
    
    init(cacheService: DKCacheServiceProtocol,
         fileInfo: DKFileProtocol,
         config: DriveFileInfoProcessorConfig,
         performanceLogger: DrivePerformanceRecorder,
         networkStatus: SKNetStatusService = DocsNetStateMonitor.shared,
         dependency: ThumbFileInfoProcessorDependency = ThumbFileInfoProcessorDependencyImpl()) {
        self.performanceLogger = performanceLogger
        self.dependency = dependency
        super.init(cacheService: cacheService, fileInfo: fileInfo, config: config, networkStatus: networkStatus)
    }
    
    required init(cacheService: DKCacheServiceProtocol, fileInfo: DKFileProtocol, config: DriveFileInfoProcessorConfig, networkStatus: SKNetStatusService = DocsNetStateMonitor.shared) {
        self.performanceLogger = DrivePerformanceRecorder(fileToken: fileInfo.fileID,
                                                          fileType: fileInfo.type,
                                                          previewFrom: config.previewFrom,
                                                          sourceType: .preview,
                                                          additionalStatisticParameters: nil)
        dependency = ThumbFileInfoProcessorDependencyImpl()
        super.init(cacheService: cacheService, fileInfo: fileInfo, config: config, networkStatus: networkStatus)
    }
    
    override func getCachePreviewInfo(fileInfo: DKFileProtocol) -> DriveProccessState? {
        DocsLogger.driveInfo("ThumbFileInfoProcessor -- get cache \(DocsTracker.encrypt(id: fileInfo.fileID))")
        guard dependency.driveEnabled else { // 缩略图source为docImage，会导致关闭drive可预览，在这里做个拦截
            return nil
        }
        // 有源文件缓存
        if let state = super.getCachePreviewInfo(fileInfo: fileInfo) {
            DocsLogger.driveInfo("ThumbFileInfoProcessor -- has origin image cache \(DocsTracker.encrypt(id: fileInfo.fileID)), state: \(state)")
            return state
        }
        // 获取缩略图缓存
        guard let data = getThumbCache(cacheType: ThumbnailDownloader.cacheType, dataVersion: fileInfo.dataVersion, fileExtension: fileInfo.fileExtension) else {
            DocsLogger.driveInfo("ThumbFileInfoProcessor -- no thumbnail cache \(DocsTracker.encrypt(id: fileInfo.fileID))")
            return nil
        }
        guard let image = UIImage(data: data) else {
            DocsLogger.driveInfo("ThumbFileInfoProcessor -- data invalid \(DocsTracker.encrypt(id: fileInfo.fileID))")
            return nil
        }
        
        var previewType: DrivePreviewFileType = .similarFiles
        if fileInfo.fileType == .psd || fileInfo.fileType == .psb  {
            previewType = .png
        }
        
        let info = DriveProccesPreviewInfo.thumb(thumb: image, previewType: previewType)
        self.performanceLogger.thumbType = true
        return .setupPreview(fileType: fileInfo.fileType, info: info)
    }
    
    override func handle(fileInfo: DKFileProtocol, hasOpenFromCache: Bool, complete: @escaping (DriveProccessState?) -> Void) {
        guard dependency.driveEnabled else { // 缩略图source为docImage，会导致关闭drive可预览，在这里做个拦截
            DocsLogger.driveError("ThumbFileInfoProcessor -- drive disable")
            self.fallbackHandle(fileInfo: fileInfo, hasOpenFromCache: hasOpenFromCache, complete: complete)
            return
        }
        guard let meta = fileInfo.getMeta() else {
            DocsLogger.driveError("ThumbFileInfoProcessor -- begin IM file not support thumbnail")
            self.fallbackHandle(fileInfo: fileInfo, hasOpenFromCache: hasOpenFromCache, complete: complete)
            return
        }
        guard !checkNeedFallBack(fileInfo: fileInfo) || hasOpenFromCache else {
            self.fallbackHandle(fileInfo: fileInfo, hasOpenFromCache: hasOpenFromCache, complete: complete)
            return
        }
        if hasOpenFromCache && checkIfIsSameFile(curFileInfo: originFileInfo, newFileInfo: fileInfo) {
            DocsLogger.driveInfo("ThumbFileInfoProcessor -- file not changed \(DocsTracker.encrypt(id: fileInfo.fileID))")
            complete(nil)
        } else {
            DocsLogger.driveInfo("ThumbFileInfoProcessor -- file not changed, do normal process")
            deleteCacheFileIfNeeded(curFileInfo: originFileInfo, newFileInfo: fileInfo)
            if let previewType = getPreviewType(fileInfo: fileInfo) {
                self.performanceLogger.stageBegin(stage: .loadThumb)
                downloadThumb(meta: meta, extra: fileInfo.authExtra, complete: {[weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case let .success(image):
                        let info = DriveProccesPreviewInfo.thumb(thumb: image, previewType: previewType)
                        let state = DriveProccessState.setupPreview(fileType: fileInfo.fileType, info: info)
                        self.performanceLogger.thumbType = true
                        self.performanceLogger.stageEnd(stage: .loadThumb)
                        complete(state)
                    case let .failure(error):
                        DocsLogger.driveError("ThumbFileInfoProcessor -- start fallback for \(DocsTracker.encrypt(id: meta.fileToken))", error: error)
                        self.performanceLogger.thumbType = false
                        self.fallbackHandle(fileInfo: fileInfo, hasOpenFromCache: false, complete: complete)
                    }
                })
            } else {
                fallbackHandle(fileInfo: fileInfo, hasOpenFromCache: hasOpenFromCache, complete: complete)
            }

        }
    }
    
    private func fallbackHandle(fileInfo: DKFileProtocol, hasOpenFromCache: Bool, complete: @escaping (DriveProccessState?) -> Void) {
        super.handle(fileInfo: fileInfo, hasOpenFromCache: hasOpenFromCache, complete: complete)
    }
    
    func getThumbCache(cacheType: DriveCacheType, dataVersion: String?, fileExtension: String?) -> Data? {
        // if no data version
        guard let dataVersion = dataVersion else {
            return (try? self.cacheService.getData(type: cacheType, fileExtension: nil, dataVersion: "").get())?.1
        }

        // if no data version
        if let (_, data) = try? self.cacheService.getData(type: cacheType, fileExtension: fileExtension, dataVersion: dataVersion).get() {
            return data
        } else {
            return nil
        }
    }
    
    private func getPreviewType(fileInfo: DKFileProtocol) -> DrivePreviewFileType? {
        guard let previewType = fileInfo.getPreferPreviewType(isInVCFollow: config.isInVCFollow) else {
            DocsLogger.driveInfo("ThumbFileInfoProcessor -- no preview type")
            if fileInfo.fileType.isSupport {
                DocsLogger.driveInfo("ThumbFileInfoProcessor -- local support download similar")
                return .similarFiles
            } else {
                DocsLogger.driveInfo("ThumbFileInfoProcessor -- local unsupport need fallback")
                return nil
            }
        }
        if previewType == .similarFiles {
            return .similarFiles
        } else if let preview = fileInfo.previewMetas[previewType], preview.previewStatus == .ready, previewType.isImageLin {
            // 如果转码成功，并且是渐进式，不走缩略图，使用渐进式
            return nil
        } else if let preview = fileInfo.previewMetas[previewType], preview.previewStatus == .ready {
            return previewType
        } else if fileInfo.fileType.isSupport {
            return .similarFiles
        } else {
            return nil
        }
    }
    
    private func downloadThumb(meta: DriveFileMeta, extra: String?, complete: @escaping (Result<UIImage, Error>) -> Void) {
        self.bag = DisposeBag()
        let checker = { [weak self] () -> Data? in
            guard let self = self else { return nil }
            return self.getThumbCache(cacheType: ThumbnailDownloader.cacheType, dataVersion: meta.dataVersion, fileExtension: meta.fileExtension)
        }
        let downloader = dependency.downloader(cacheCheck: checker)
        let teaParams = [DriveStatistic.RustTeaParamKey.downloadFor: DriveStatistic.DownloadFor.driveImageThumbnail]
        downloader.downloadThumb(meta: meta, extra: extra, priority: .userInteraction, teaParams: teaParams)
            .subscribe(onNext: { (image) in
                complete(.success(image))
            }, onError: { error in
                complete(.failure(error))
            }).disposed(by: bag)
        self.thumbDownloader = downloader
    }
    
    private func checkNeedFallBack(fileInfo: DKFileProtocol) -> Bool {
        guard dependency.checkIfSupport(appID: config.appID) else {
            DocsLogger.driveInfo("ThumbFileInfoProcessor -- not support appID \(config.appID) token: \(DocsTracker.encrypt(id: fileInfo.fileID))")
            return true
        }
        guard fileInfo.size > dependency.minSizeForThumbnailPreview else {
            DocsLogger.driveInfo("ThumbFileInfoProcessor -- no need thumbnail for size \(fileInfo.size) token: \(DocsTracker.encrypt(id: fileInfo.fileID))")
            return true
        }
        
        guard fileInfo.size > 0, fileInfo.size < dependency.maxFileSize(for: fileInfo.type) else {
            DocsLogger.driveInfo("ThumbFileInfoProcessor -- no need thumbnail for size \(fileInfo.size) token: \(DocsTracker.encrypt(id: fileInfo.fileID))")
            return true
        }
        return false
    }
}
