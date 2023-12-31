//
//  DKPreviewVMDependencyImpl.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/30.
//

import Foundation
import RxSwift

struct DKPreviewVMDependencyImpl: DKPreviewVMDependency {
    var downloader: DKPreviewDownloadService
    
    var filePreviewProvider: FilePreviewProvider
    
    var filePreviewProcessorProvider: PreviewProcessorProvider
    
    var cacheService: DKCacheServiceProtocol
    
    var previewPushService: FilePreviewPushService
    
    var networkState: Observable<Bool>
    
    var performanceRecorder: DrivePerformanceRecorder
    
    init(fileInfo: DKFileInfo,
         previewType: DrivePreviewFileType,
         skipCellularCheck: Bool,
         netState: Observable<Bool>,
         hostContainer: UIViewController,
         performanceRecorder: DrivePerformanceRecorder) {
        cacheService = DKCacheServiceImpl(appID: fileInfo.appID, fileID: fileInfo.fileID)
        downloader = DKPreviewDownloader(fileInfo: fileInfo,
                                         hostContainer: hostContainer,
                                         cacheService: cacheService,
                                         skipCellularCheck: skipCellularCheck,
                                         authExtra: nil)
        filePreviewProvider = DKFilePreviewProvider(fileInfo: fileInfo, previewType: previewType)
        previewPushService = DKFilePreviewPushService(appID: fileInfo.appID, fileID: fileInfo.fileID)
        networkState = netState
        filePreviewProcessorProvider = IMPreivewProcesorProvider(cacheService: cacheService)
        self.performanceRecorder = performanceRecorder
    }
}

struct DKPreviewAttachFileVMDependencyImpl: DKPreviewVMDependency {
    var downloader: DKPreviewDownloadService
    
    var filePreviewProvider: FilePreviewProvider
    
    var filePreviewProcessorProvider: PreviewProcessorProvider

    var cacheService: DKCacheServiceProtocol
    
    var previewPushService: FilePreviewPushService
    
    var networkState: Observable<Bool>
    
    var performanceRecorder: DrivePerformanceRecorder
    init(fileInfo: DriveFileInfo,
         previewType: DrivePreviewFileType,
         skipCellularCheck: Bool,
         netState: Observable<Bool>,
         hostContainer: UIViewController,
         performanceRecorder: DrivePerformanceRecorder) {
        cacheService = DriveCacheServiceImpl(fileToken: fileInfo.fileToken)
        downloader = DKPreviewDownloader(fileInfo: fileInfo,
                                         hostContainer: hostContainer,
                                         cacheService: cacheService,
                                         skipCellularCheck: skipCellularCheck,
                                         authExtra: fileInfo.authExtra)
        filePreviewProvider = DriveFilePreviewProvider(fileInfo: fileInfo, previewType: previewType)
        previewPushService = DrivePreviewGetPushService(fileToken: fileInfo.fileToken)
        networkState = netState
        filePreviewProcessorProvider = DefaultPreviewProcessorProvider(cacheService: cacheService)
        self.performanceRecorder = performanceRecorder
    }
}
