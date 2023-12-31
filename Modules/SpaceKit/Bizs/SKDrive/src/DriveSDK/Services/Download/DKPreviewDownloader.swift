//
//  DKPreviewDownloader.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/24.
//

import Foundation
import SKCommon
import SKFoundation

protocol DKPreviewDownloadService {
    var downloadStatusHandler: ((DriveDownloadService.DownloadStatus) -> Void)? { get set }
    var forbidDownloadHandler: (() -> Void)? { get set }
    var beginDownloadHandler: (() -> Void)? { get set }
    var cacheStageHandler: ((DriveStage) -> Void)? { get set }
    func stop()
    func downloadSimilar(meta: DriveFileMeta, cacheSource: DriveCacheService.Source)
    func download(previewType: DrivePreviewFileType, cacheSource: DriveCacheService.Source, cacheCustomID: String?)
    func retryDownload(cacheSource: DriveCacheService.Source)
    func updateFileInfo(_ info: DKFileProtocol)
}

class DKPreviewDownloader: DKPreviewDownloadService {
    /// 文件下载器
    private var downloadService: DriveDownloadService?
    private var downloadType: DriveDownloadService.DownloadType? // 下载类型，源文件或转码文件
    private var cacheCustomID: String?
    private var authExtra: String?
    private var fileInfo: DKFileProtocol
    private let cacheService: DKCacheServiceProtocol
    private let skipCellularCheck: Bool
    private var previewType: DrivePreviewFileType?
    weak var hostContainer: UIViewController?
    
    // callbacks
    var downloadStatusHandler: ((DriveDownloadService.DownloadStatus) -> Void)?
    var forbidDownloadHandler: (() -> Void)?
    var beginDownloadHandler: (() -> Void)?
    var cacheStageHandler: ((DriveStage) -> Void)?

    /// 停止下载
    func stop() {
        downloadService?.stop()
    }
    
    func downloadSimilar(meta: DriveFileMeta, cacheSource: DriveCacheService.Source) {
        DocsLogger.driveInfo("download origin file",
                        extraInfo: ["token": DocsTracker.encrypt(id: fileInfo.fileID)])
        let downloadType: DriveDownloadService.DownloadType = .similar(fileMeta: meta)
        setupDownloadService(downloadType: downloadType, cacheCustomID: cacheCustomID, cacheSource: cacheSource)
        downloadService?.start()
    }
    
    func download(previewType: DrivePreviewFileType, cacheSource: DriveCacheService.Source, cacheCustomID: String?) {
        DocsLogger.driveInfo("DriveSDK.PreviewDownloader: download preview type",
                        extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID),
                                    "type": previewType.rawValue ?? ""])
        self.previewType = previewType
        guard let previewURL = fileInfo.getPreviewDownloadURLString(previewType: previewType) else {
                DocsLogger.error("download preview file without previewFileType")
                assertionFailure()
                return
        }

        let downloadType: DriveDownloadService.DownloadType = .preview(previewType: previewType, previewURL: previewURL)

        setupDownloadService(downloadType: downloadType, cacheCustomID: cacheCustomID, cacheSource: cacheSource)
        downloadService?.start()
    }

    init(fileInfo: DKFileProtocol, hostContainer: UIViewController, cacheService: DKCacheServiceProtocol, skipCellularCheck: Bool, authExtra: String?) {
        self.fileInfo = fileInfo
        self.hostContainer = hostContainer
        self.cacheService = cacheService
        self.skipCellularCheck = skipCellularCheck
        self.authExtra = authExtra
    }

    func retryDownload(cacheSource: DriveCacheService.Source) {
        guard let downloadType = downloadType else {
            DocsLogger.error("retry before download started.")
            return
        }
        DocsLogger.driveInfo("retry download file",
                        extraInfo: ["token": DocsTracker.encrypt(id: fileInfo.fileID)])
        switch downloadType {
        case let .similar(meta):
            downloadSimilar(meta: meta, cacheSource: cacheSource)
        case .preview:
            guard let type = previewType else {
                DocsLogger.error("DriveSDK.PreviewDownloader: retry before download started.")
                return
            }
            download(previewType: type, cacheSource: cacheSource, cacheCustomID: cacheCustomID)
        case .origin:
            spaceAssertionFailure("DriveSDK.PreviewDownloader: 预览场景不会下载源文件")
        }
    }
    
    func updateFileInfo(_ info: DKFileProtocol) {
        self.fileInfo = info
    }

    private func setupDownloadService(downloadType: DriveDownloadService.DownloadType, cacheCustomID: String?, cacheSource: DriveCacheService.Source) {
        self.downloadType = downloadType
        self.cacheCustomID = cacheCustomID
        let dependency = DriveDownloadServiceDependencyImpl(fileInfo: fileInfo,
                                                            downloadType: downloadType,
                                                            cacheSource: cacheSource,
                                                            cacheCustomID: cacheCustomID,
                                                            cacheService: cacheService)
        if let downloadService = downloadService {
            downloadService.reset(dependeny: dependency)
            return
        }
        let downloadService = DriveDownloadService(dependency: dependency,
                                                   priority: .preview,
                                                   skipCellularCheck: skipCellularCheck,
                                                   apiType: .preview,
                                                   authExtra: authExtra,
                                                   callBack: {[weak self] (status) in
                                                    guard let `self` = self else { return }
                                                    self.downloadStatusHandler?(status)
        })
        self.downloadService = downloadService
        downloadService.hostContainer = hostContainer
        downloadService.beginDownload = { [weak self] in
            self?.beginDownloadHandler?()
        }
        downloadService.forbidDownload = { [weak self] in
            self?.forbidDownloadHandler?()
        }
        downloadService.cacheStage = { [weak self] (stage) in
            self?.cacheStageHandler?(stage)
        }
    }
}
