//
//  DrivePreloadOperation.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/8/9.
//
// swiftlint:disable file_length
// nolint: long parameters

import Foundation
import SwiftyJSON
import TTVideoEngine
import SKCommon
import SKFoundation
import RxSwift
import SpaceInterface
import SKInfra
import LarkDocsIcon

protocol DrivePreloadOperationDelegate: AnyObject {
    func operation(_ operation: DrivePreloadOperation, updateFileInfo fileInfo: DriveFileInfo)
    func operation(_ operation: DrivePreloadOperation, failedWithError error: DrivePreloadOperation.PreloadError)
}

struct PreloadHtmlContext {
    let token: String
    let dataVersion: String
    let extraInfo: String
    let fileName: String
    let fileSize: UInt64
    let mountPoint: String
}

struct SaveDriveDataContext {
    let type: DriveCacheType
    let token: String
    let dataVersion: String
    let fileName: String
    let fileSize: UInt64
}

private class DrivePreviewRequest: NSObject {
    let startTime: Date
    let fileInfo: DriveFileInfo
    var request: DocsRequest<JSON>?

    init(fileInfo: DriveFileInfo) {
        startTime = Date()
        self.fileInfo = fileInfo
    }

    func retry(callbackQueue: DispatchQueue, callback: @escaping (JSON?, Error?) -> Void) {
        cancel()
        var params: [String: Any] = ["file_token": fileInfo.fileToken,
                                     "mount_point": fileInfo.mountPoint,
                                     "preview_type": fileInfo.previewType?.rawValue ?? DrivePreviewFileType.linerizedPDF.rawValue,
                                     "regenerate": DrivePreviewFileGeneratedType.normal.rawValue]
        if let dataVersion = fileInfo.dataVersion {
            params["version"] = dataVersion
        }
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.driveGetServerPreviewURL, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        request?.start(callbackQueue: callbackQueue, result: callback)
    }

    func cancel() {
        request?.cancel()
    }
}

class DrivePreloadOperation: Operation {
    
    private let disposeBag = DisposeBag()
    
    private struct Token {
        let token: String
        let dataVersion: String
        let fileName: String
        let isOrigin: Bool
        let previewURL: String?
        let localPath: SKFilePath

        var sourceExtension: String? {
            return SKFilePath.getFileExtension(from: fileName)
        }
    }

    enum PreloadError: Error {
        case fileInfoError(Error)
        case fileSizeExceedLimit
        case fileTypeUnsupport
        case noPermissionOrAudit
        case fileNotFound
        case previewInfoError(Error)
        case downloadError
        case downloadCancelled
        case cacheError
        case cancelled

        var localizedDescription: String {
            switch self {
            case .fileInfoError(let error):
                return "预加载获取文件信息失败: \(error.localizedDescription)"
            case .fileSizeExceedLimit:
                return "预加载文件失败，文件大小超出限制"
            case .fileTypeUnsupport:
                return "预加载文件失败，不支持的文件格式"
            case .noPermissionOrAudit:
                return "预加载文件失败，无权限或文件被审核"
            case .previewInfoError(let error):
                return "预加载后去预览信息失败: \(error.localizedDescription)"
            case .downloadError:
                return "预加载文件失败，下载中出现错误"
            default:
                return "预加载文件失败，未知错误"
            }
        }
    }

    // MARK: - Async Operation Properties
    private var executingState = false
    private var finishedState = false
    override var isExecuting: Bool {
        return executingState
    }
    override var isFinished: Bool {
        return finishedState
    }
    override var isAsynchronous: Bool {
        return true
    }

    let preloadRequest: DrivePreloadService.Request
    let callbackQueue: DispatchQueue
    var preloadSource: DrivePreloadSource {
        return preloadRequest.source
    }
    var fileToken: String {
        return preloadRequest.token
    }
    var listToken: String {
        if let wikiToken {
            return wikiToken
        }
        return preloadRequest.token
    }
    
    var wikiToken: String?

    weak var delegate: DrivePreloadOperationDelegate?
    /// 打开流程上报
    private(set) var isSuccess: Bool
    private(set) var performanceLogger: DrivePerformanceRecorder
    // MARK: - Private Properties
    private var fileInfoRequest: DocsRequest<JSON>?
    private var previewRequest: DrivePreviewRequest?
    private var preloadToken: Token?
    private var downloadKey: String?
    private let cacheService: DriveCacheServiceProtocol
    private var thumbDownloader: ThumbnailDownloader?
    private let teaParams = [DriveStatistic.RustTeaParamKey.downloadFor: DriveStatistic.DownloadFor.drivePreload]

    init(preloadRequest: DrivePreloadService.Request, callbackQueue: DispatchQueue, cacheService: DriveCacheServiceProtocol, wikiToken: String?) {
        self.preloadRequest = preloadRequest
        self.callbackQueue = callbackQueue
        self.cacheService = cacheService
        self.wikiToken = wikiToken
        isSuccess = false
        self.performanceLogger = DrivePerformanceRecorder(fileToken: preloadRequest.token,
                                                          fileType: preloadRequest.fileType.rawValue,
                                                          sourceType: .preload,
                                                          additionalStatisticParameters: nil)
    }

    override func start() {
        if isCancelled {
            willChangeValue(for: \DrivePreloadOperation.isFinished)
            finishedState = true
            didChangeValue(for: \DrivePreloadOperation.isFinished)
            return
        }
        fetchWatermark()
        fetchFileInfo()
    }

    private func fetchWatermark() {
        let watermarkKey = WatermarkKey(objToken: preloadRequest.token, type: DocsType.file.rawValue)
        WatermarkManager.shared.requestWatermarkInfo(watermarkKey)
    }

    private func fetchFileInfo() {
        if isCancelled {
            DocsLogger.warning("Drive.Preload.Download --- preload cancelled before fetch file info start", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            cancelOperation()
            return
        }
        DocsLogger.driveInfo("Drive.Preload.Download---fetching file info", extraInfo: ["token": DocsTracker.encrypt(id: preloadRequest.token)])
        let params: [String: Any] = ["file_token": preloadRequest.token,
                                     "mount_point": DriveConstants.driveMountPoint,
                                     "caller": "",
                                     "option_params": ["preview_meta", "check_cipher"]]
        performanceLogger.stageBegin(stage: .requestFileInfo, loadingType: .preload)
        fileInfoRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.fetchFileInfo, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
        fileInfoRequest?.start(callbackQueue: callbackQueue) { [weak self] (result, error) in
            guard let self = self else { return }
            self.performanceLogger.stageEnd(stage: .requestFileInfo)
            if let error = error {
                self.delegate?.operation(self, failedWithError: .fileInfoError(error))
                DocsLogger.error("Drive.Preload.Download---file info request failed with error.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)], error: error)
                self.cleanUp()
                return
            }
            guard let json = result,
                let code = json["code"].int else {
                    self.delegate?.operation(self, failedWithError: .fileInfoError(DriveError.fileInfoDataError))
                    DocsLogger.error("Drive.Preload.Download---file info data error.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                    self.cleanUp()
                    return
            }
            guard code == 0 else { // 解析错误码
                DocsLogger.error("Drive.Preload.Download---server error with code: \(code).", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                if let fileInfoErrorCode = DriveFileInfoErrorCode(rawValue: code) {
                    switch fileInfoErrorCode {
                    case .fileNotFound, .fileDeletedOnServerError, .resourceFrozenByAdmin, .resourceShreddedByAdmin:
                        self.delegate?.operation(self, failedWithError: .fileNotFound)
                    case .machineAuditFailureError, .humanAuditFailureError, .noPermission:
                        self.delegate?.operation(self, failedWithError: .noPermissionOrAudit)
                    case .auditFailureInUploadError, .loginRequired, .parameterError, .fileDamage, .fileCopying, .fileKeyDeleted, .dlpDetectingFailed:
                        self.delegate?.operation(self, failedWithError: .fileInfoError(DriveError.serverError(code: code)))
                    }
                } else {
                    self.delegate?.operation(self, failedWithError: .fileInfoError(DriveError.serverError(code: code)))
                }
                self.cleanUp()
                return
            }

            guard let data = json["data"].dictionaryObject else {
                self.delegate?.operation(self, failedWithError: .fileInfoError(DriveError.fileInfoParserError))
                DocsLogger.error("Drive.Preload.Download---failed to parser file info data.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                self.cleanUp()
                return
            }
            guard let info = DriveFileInfo(data: data, fileToken: self.preloadRequest.token, mountNodeToken: "", mountPoint: DriveConstants.driveMountPoint) else {
                self.delegate?.operation(self, failedWithError: .fileInfoError(DriveError.fileInfoParserError))
                DocsLogger.error("Drive.Preload.Download---failed to parser file info data.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                self.cleanUp()
                return
            }
            DocsLogger.driveInfo("Drive.Preload.Download --- fetching file info succeed", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            self.delegate?.operation(self, updateFileInfo: info)
            let allowPreload = self.allowPreload(fileInfo: info)
            if !allowPreload {
                DocsLogger.driveInfo("Drive.Preload.Download --- file size too big.")
                self.delegate?.operation(self, failedWithError: .fileSizeExceedLimit)
                self.cleanUp()
                return
            }
            if self.shouldDownloadPreview(info: info) {
                self.fetchPreviewURL(fileInfo: info)
            } else if self.allowDownloadOrigin(fileInfo: info) {
                DispatchQueue.global().async {
                    self.downloadOrigin(fileInfo: info)
                }
            } else if DriveThumbPreloadConfig.shouldDownloadThumb(source: self.preloadRequest.source,
                                                                  fileSize: info.size,
                                                                  fileType: info.type) {
                self.downloadThumb(fileInfo: info)
            } else {
                DocsLogger.driveInfo("Drive.Preload.Download --- no need to preload")
                self.delegate?.operation(self, failedWithError: .fileTypeUnsupport)
                self.cleanUp()
            }
        }
    }
    // swiftlint:enable function_body_length
}

// MARK: - 下载相关
extension DrivePreloadOperation {
    private func downloadThumb(fileInfo: DriveFileInfo) {
        if isCancelled {
            DocsLogger.debug("Drive.Preload.Download --- preload cancelled before download thumb file start", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            cancelOperation()
            return
        }
        // check cache
        if cacheService.isDriveFileExist(type: ThumbnailDownloader.cacheType, token: fileInfo.fileToken, dataVersion: fileInfo.dataVersion, fileExtension: fileInfo.fileExtension) {
            DocsLogger.driveInfo("Drive.Preload.Download--- thumb already in cache.")
            self.markSucceed()
            return
        }
        DocsLogger.driveInfo("Drive.Preload.Download---downloading thumb file", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
        let checker = { [weak self] () -> Data? in
            guard let self = self else { return nil }
            if let (_, data) = try? self.cacheService.getDriveData(type: ThumbnailDownloader.cacheType,
                                                                   token: fileInfo.fileToken,
                                                                   dataVersion: fileInfo.dataVersion,
                                                                   fileExtension: fileInfo.fileExtension).get() {
                return data
            } else {
                return nil
            }
        }
        let thumbDownloader = ThumbnailDownloader(checker)
        guard let meta = fileInfo.getMeta() else {
            DocsLogger.driveInfo("Drive.Preload.Download---downloading thumb file failed no meta info", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            self.delegate?.operation(self, failedWithError: .cacheError)
            self.cleanUp()
            return
        }
        thumbDownloader.downloadThumb(meta: meta, extra: nil, priority: .default).subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.markSucceed()
        }, onError: { [weak self] error in
            guard let self = self else { return }
            let token = DocsTracker.encrypt(id: fileInfo.fileToken)
            DocsLogger.error("Drive.Preload.Download--- downoad thumb failed", extraInfo: ["token": token], error: error)
            self.delegate?.operation(self, failedWithError: .cacheError)
            self.cleanUp()
        }).disposed(by: disposeBag)
        self.thumbDownloader = thumbDownloader
    }
    private func downloadOrigin(fileInfo: DriveFileInfo) {
        if isCancelled {
            DocsLogger.debug("Drive.Preload.Download --- preload cancelled before download origin file start", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            cancelOperation()
            return
        }
        if cacheService.isDriveFileExist(type: .similar, token: fileInfo.fileToken, dataVersion: fileInfo.dataVersion, fileExtension: fileInfo.fileExtension) {
            DocsLogger.driveInfo("Drive.Preload.Download---File already in cache.")
            if preloadRequest.source == .manualOffline {
                cacheService.moveToManualOffline(files: [(token: fileInfo.fileToken, dataVersion: fileInfo.dataVersion, fileExtension: fileInfo.fileExtension)], complete: {
                    DispatchQueue.main.async {
                        let userInfo = [DriveCacheService.manualOfflineNotifyKey: [fileInfo.fileToken]]
                        NotificationCenter.default.post(name: DriveCacheService.manualOffilineNotify,
                                                        object: nil,
                                                        userInfo: userInfo)
                    }
                })
                DriveStatistic.reportDownload(action: .finishDownload,
                                              fileID: fileInfo.fileToken,
                                              fileSubType: fileInfo.fileExtension,
                                              module: SKCreateTracker.moduleString,
                                              subModule: SKCreateTracker.subModuleString,
                                              srcModule: SKCreateTracker.srcModuleString,
                                              isExport: false,
                                              isDriveSDK: false)
            }
            self.markSucceed()
            return
        }
        guard let downloadURL = fileInfo.getFileMeta().downloadPreviewURL?.absoluteString else {
            DocsLogger.error("Drive.Preload.Download--- download URL is nil")
            return
        }
        DocsLogger.driveInfo("Drive.Preload.Download---downloading origin file", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
        let dataVersion = fileInfo.dataVersion ?? "default_version"
        let localPath = cacheService.driveFileDownloadURL(cacheType: .similar, fileToken: preloadRequest.token, dataVersion: dataVersion, fileExtension: fileInfo.type)
        preloadToken = Token(token: preloadRequest.token,
                             dataVersion: dataVersion,
                             fileName: fileInfo.name,
                             isOrigin: true,
                             previewURL: nil,
                             localPath: localPath)
        performanceLogger.stageBegin(stage: .downloadFile, loadingType: .preload)
        DriveDownloadCallbackService.shared.addObserver(self)
        SpaceRustRouter.shared.downloadNormal(remoteUrl: downloadURL,
                                              localPath: localPath.pathString,
                                              fileSize: String(fileInfo.size),
                                              priority: preloadRequest.source.priority,
                                              apiType: .preview,
                                              teaParams: teaParams,
                                              authExtra: nil)
        .debug("preload drive - downloadOrigin")
        .subscribe(onNext: {[weak self] key in
            guard let self = self else { return }
            self.downloadKey = key
            self.reportStartManualOffline(request: self.preloadRequest, localPath: localPath, downloadKey: key)
        }).disposed(by: disposeBag)
    }

    private func downloadPreview(previewURL: String, dataVersion: String, originFileName: String, type: String) {
        if isCancelled {
            DocsLogger.warning("Drive.Preload.Download --- preload cancelled before download preview file start", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            cancelOperation()
            return
        }

        DocsLogger.driveInfo("Drive.Preload.Download---downloading preview file", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
        let localPath = cacheService.driveFileDownloadURL(cacheType: .preview,
                                                          fileToken: preloadRequest.token,
                                                          dataVersion: dataVersion,
                                                          fileExtension: type)
        preloadToken = Token(token: preloadRequest.token,
                             dataVersion: dataVersion,
                             fileName: originFileName,
                             isOrigin: false,
                             previewURL: previewURL,
                             localPath: localPath)
        performanceLogger.stageBegin(stage: .downloadFile, loadingType: .preload)
        DriveDownloadCallbackService.shared.addObserver(self)
        SpaceRustRouter.shared.downloadNormal(remoteUrl: previewURL,
                                              localPath: localPath.pathString,
                                              priority: preloadRequest.source.priority,
                                              apiType: .preview,
                                              teaParams: teaParams,
                                              authExtra: nil)
        .debug("preload drive - downloadPreview")
        .subscribe(onNext: {[weak self] key in
            guard let self = self else { return }
            self.downloadKey = key
            self.reportStartManualOffline(request: self.preloadRequest, localPath: localPath, downloadKey: key)
        })
        .disposed(by: disposeBag)
    }
    
    private func preloadHtml(context: PreloadHtmlContext) {
        let dataProvider = DriveHTMLDataProvider(fileToken: context.token,
                                                 dataVersion: context.dataVersion,
                                                 fileSize: context.fileSize,
                                                 authExtra: nil,
                                                 mountPoint: context.mountPoint)
        let manualOffline = (preloadSource  == .manualOffline) ? true : false
        if !dataProvider.isExtraInfoExisted() {
            dataProvider.saveExtraInfo(context.extraInfo, fileName: context.fileName, manualOffline: manualOffline)
        }
        
        let dict = JSON(parseJSON: context.extraInfo)
        guard let tabs = dict["sheets"].arrayObject else {
            DocsLogger.driveInfo("Drive.Preload.Download--can not parse extraInfo")
            cleanUp()
            return
        }
        
        DocsLogger.driveInfo("Drive.Preload.Download--parse extra info with \(tabs.count) tabs")
        
        // 预加载所有tab 和 style
        var subIds: [String] = ["style"]
        for id in 0..<tabs.count {
            subIds.append("\(id)")
        }
        
        var count = 0
        subIds.forEach { (id) in
            self.fetchHtmlData(dataProvider: dataProvider, subId: id, fileName: context.fileName, completion: { _ in
                count += 1
                DocsLogger.driveInfo("Drive.Preload.Download--preloadHtml count: \(count)", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                if count >= subIds.count {
                    self.markSucceed()
                }
            })
        }
    }
    
    private func fetchHtmlData(dataProvider: DriveHTMLDataProvider,
                               subId: String,
                               fileName: String,
                               completion: @escaping ((Bool) -> Void)) {
        guard !dataProvider.isDataExisted(subId: subId) else {
            DocsLogger.driveInfo("Drive.Preload.Download--found existed html cached data", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            completion(true)
            return
        }
        
        DocsLogger.driveInfo("fetchHtmlData begin", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token),
                                                         "subId": subId])
        let manualOffline = (preloadSource  == .manualOffline) ? true : false
        dataProvider.fetchTabData(subId: subId)
            .observeOn(MainScheduler.instance)
            .subscribe { (data) in
                dataProvider.saveData(subId: subId, data: data, fileName: fileName, manualOffline: manualOffline)
                DocsLogger.driveInfo("fetchHtmlData succeed with data: \(data.count)", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token),
                                                                                            "subId": subId])
                completion(true)
            } onError: { (error) in
                DocsLogger.error("fetchHtmlData failed with error: \(error)", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token),
                                                                                        "subId": subId])
                completion(false)
            }.disposed(by: disposeBag)
    }
    
    private func preloadVideo(dataVersion: String, filePreview: DriveFilePreview, fileInfo: DriveFileInfo) {
        guard let videoInfo = filePreview.videoInfo,
              let downloadURL = fileInfo.getPreviewDownloadURLString(previewType: .similarFiles),
              let onlineURL = URL(string: downloadURL) else {
            DocsLogger.error("Drive.Preload.Download---Failed to get video info when preloading video", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewFetchError))
            self.cleanUp()
            return
        }
        let encryptedToken = DocsTracker.encrypt(id: fileInfo.fileToken)
        let cacheKey = "\(encryptedToken)_\(dataVersion)"
        let videoItem = DriveVideo(type: .online(url: onlineURL),
                                   info: videoInfo,
                                   title: fileInfo.name,
                                   size: fileInfo.size,
                                   cacheKey: cacheKey,
                                   authExtra: nil)
        let resolutionHandler = DriveVideoResolutionHandler(video: videoItem)
        let preloadURL = resolutionHandler.currentUrl ?? downloadURL
        let context = SaveDriveDataContext(type: .videoInfo, token: fileInfo.fileToken, dataVersion: dataVersion, fileName: fileInfo.name, fileSize: fileInfo.size)
        
        preloadByTTVideo(preloadURL: preloadURL, taskKey: resolutionHandler.taskKey) { [weak self] in
            self?.saveDriveData(videoInfo, context: context)
        }
    }
    
    private func preloadOgg(dataVersion: String, filePreview: DriveFilePreview, fileInfo: DriveFileInfo) {
        guard let mimeType = filePreview.mimeType,
              let preloadURL = fileInfo.getPreviewDownloadURLString(previewType: .ogg) else {
            DocsLogger.error("Drive.Preload.Download---Failed to get mimeType info when preloading ogg", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewFetchError))
            self.cleanUp()
            return
        }
        let oggInfo = DriveOggInfo(mimeType: mimeType, previewType: DrivePreviewFileType.ogg.rawValue)
        let encryptedToken = DocsTracker.encrypt(id: fileInfo.fileToken)
        let taskKey = "\(encryptedToken)_\(dataVersion)_default"
        let context = SaveDriveDataContext(type:  .oggInfo, token: fileInfo.fileToken, dataVersion: dataVersion, fileName: fileInfo.name, fileSize: fileInfo.size)
        self.preloadByTTVideo(preloadURL: preloadURL, taskKey: taskKey) { [weak self] in
            self?.saveDriveData(oggInfo, context: context)
        }
    }
    
    private func preloadByTTVideo(preloadURL: String, taskKey: String, completion: @escaping () -> Void) {
        let preloadSize = DriveFeatureGate.defaultPreloadConfig.videoCacheSizeLimit
        guard let preloadItem = TTVideoEnginePreloaderURLItem(key: taskKey, videoId: nil, urls: [preloadURL], preloadSize: Int(preloadSize)) else {
            assertionFailure("Drive.Preload.Download --- failed to create preload item")
            DocsLogger.error("Drive.Preload.Download --- failed to create preload item",
                             extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewDataError))
            self.cleanUp()
            return
        }
        if let cookiesString = NetConfig.shared.cookies()?.cookieString {
            preloadItem.setCustomHeaderValue(cookiesString, forKey: "cookie")
        }
        preloadItem.priorityLevel = TTVideoEnginePrloadPriorityDefault
        preloadItem.preloadEnd = { [weak self] (info, error) in
            guard let self = self else { return }
            if let error = error {
                DocsLogger.error("Drive.Preload.Download --- preload video end with error", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)], error: error)
                self.callbackQueue.async {
                    self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewDataError))
                    self.cleanUp()
                }
                return
            }
            DocsLogger.driveInfo("Drive.Preload.Download --- preload video success", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            completion()
            self.callbackQueue.async {
                self.markSucceed()
            }
        }
        if !TTVideoEngine.ls_isStarted() {
            TTVideoEngine.ls_start()
        }
        TTVideoEngine.ls_addTask(with: preloadItem)
    }
    
    private func retryDownload() -> Bool {
        if isCancelled { return false }
        guard let preloadToken = preloadToken else { return false }
        DocsLogger.driveInfo("Drive.Preload.Download --- retry for download", extraInfo: ["token": DocsTracker.encrypt(id: preloadToken.token)])
        if preloadToken.isOrigin {
            let context = SpaceRustRouter.DownloadRequestContext(localPath: preloadToken.localPath.pathString,
                                                                 fileToken: preloadToken.token,
                                                                 docToken: "",
                                                                 docType: nil,
                                                                 mountNodePoint: "",
                                                                 mountPoint: DriveConstants.driveMountPoint,
                                                                 dataVersion: preloadToken.dataVersion,
                                                                 priority: preloadRequest.source.priority,
                                                                 apiType: .preview,
                                                                 coverInfo: nil,
                                                                 authExtra: nil,
                                                                 disableCDN: false,
                                                                 teaParams: teaParams)
            let request = SpaceRustRouter.constructDownloadRequest(context: context)
            SpaceRustRouter.shared.download(request: request)
                .debug("preload drive - retry download origin")
                .subscribe(onNext: { [weak self] key in
                    self?.downloadKey = key
                }).disposed(by: disposeBag)
        } else {
            guard let previewURL = preloadToken.previewURL else {
                DocsLogger.error("Drive.Preload.Download --- failed to retry download preview file, cannot retrive previewURL from preloadToken",
                                 extraInfo: ["token": DocsTracker.encrypt(id: preloadToken.token)])
                return false
            }
            SpaceRustRouter.shared.downloadNormal(remoteUrl: previewURL,
                                                  localPath: preloadToken.localPath.pathString,
                                                  priority: preloadRequest.source.priority,
                                                  teaParams: teaParams,
                                                  authExtra: nil)
            .debug("preload drive - retry download preview")
            .subscribe(onNext: {[weak self] key in
                self?.downloadKey = key
            }).disposed(by: disposeBag)
        }
        return true
    }

    private func fetchPreviewURL(fileInfo: DriveFileInfo) {
        if isCancelled {
            DocsLogger.warning("Drive.Preload.Download --- preload cancelled before fetch preview url start", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            cancelOperation()
            return
        }

        if cacheService.isDriveFileExist(type: .preview, token: fileInfo.fileToken, dataVersion: fileInfo.dataVersion, fileExtension: fileInfo.fileExtension) {
            DocsLogger.driveInfo("Drive.Preload.Download---File already in cache.")
            if preloadRequest.source == .manualOffline {
                cacheService.moveToManualOffline(files: [(token: fileInfo.fileToken, dataVersion: fileInfo.dataVersion, fileExtension: fileInfo.fileExtension)], complete: nil)
                // 设置为离线可用，缓存已经存在时，也需上报 downlad 事件
                DriveStatistic.reportDownload(action: .finishDownload,
                                              fileID: fileInfo.fileToken,
                                              fileSubType: fileInfo.fileExtension,
                                              module: SKCreateTracker.moduleString,
                                              subModule: SKCreateTracker.subModuleString,
                                              srcModule: SKCreateTracker.srcModuleString,
                                              isExport: false,
                                              isDriveSDK: false)
            }
            self.markSucceed()
            return
        }

        previewRequest = DrivePreviewRequest(fileInfo: fileInfo)
        retryFetchPreviewURL(dataVersion: fileInfo.dataVersion ?? "default_version")
    }

    @objc
    private func retryFetchPreviewURL(dataVersion: String) {
        if isCancelled {
            DocsLogger.debug("Drive.Preload.Download --- preload cancelled when download retry get preview url start", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            cancelOperation()
            return
        }
        guard let previewRequest = previewRequest else {
            DocsLogger.error("Drive.Preload.Download---Failed to retry fetch preview url, preview request not found")
            self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewFetchError))
            cleanUp()
            return
        }
        DocsLogger.driveInfo("Drive.Preload.Download---fetching preview file url", extraInfo: ["token": DocsTracker.encrypt(id: preloadRequest.token)])
        performanceLogger.stageBegin(stage: .requestPreviewUrl, loadingType: .preload)
        previewRequest.retry(callbackQueue: callbackQueue) { (result, error) in
            self.performanceLogger.stageEnd(stage: .requestPreviewUrl)
            if let error = error {
                self.delegate?.operation(self, failedWithError: .previewInfoError(error))
                DocsLogger.error("Drive.Preload.Download---fetching previewURL request failed with error.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)], error: error)
                self.cleanUp()
                return
            }
            guard let json = result,
                let code = json["code"].int else {
                    self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewDataError))
                    DocsLogger.error("Drive.Preload.Download---fetching previewURL data error.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                    self.cleanUp()
                    return
            }
            guard code == 0 else { // 解析错误码
                self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.serverError(code: code)))
                DocsLogger.error("Drive.Preload.Download---server error with code: \(code).", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                self.cleanUp()
                return
            }

            guard let dataDic = json["data"].dictionaryObject,
                let data = try? JSONSerialization.data(withJSONObject: dataDic, options: []),
                let filePreview = try? JSONDecoder().decode(DriveFilePreview.self, from: data) else {
                    DocsLogger.error("Drive.Preload.Download---failed parsing file preview info data.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                    self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewDataError))
                    self.cleanUp()
                    return
            }
            switch filePreview.previewStatus {
            case .ready:

                guard let previewType = previewRequest.fileInfo.previewType else {
                    DocsLogger.error("Drive.Preload.Download---Failed to get file preview type when generating ready.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                    self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewFetchError))
                    self.cleanUp()
                    return
                }
                if previewType == .mp4 {
                    self.preloadVideo(dataVersion: dataVersion, filePreview: filePreview, fileInfo: previewRequest.fileInfo)
                    return
                }
                
                if previewType == .ogg {
                    self.preloadOgg(dataVersion: dataVersion, filePreview: filePreview, fileInfo: previewRequest.fileInfo)
                    return
                }
                
                if previewType == .html {
                    guard let extraInfo = filePreview.extra else {
                        DocsLogger.error("Drive.Preload.Download---Failed to get extra info when preloading html", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                        self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewFetchError))
                        self.cleanUp()
                        return
                    }
                    let fileInfo = previewRequest.fileInfo
                    let context = PreloadHtmlContext(token: fileInfo.fileToken, dataVersion: dataVersion, extraInfo: extraInfo, fileName: fileInfo.name, fileSize: fileInfo.size, mountPoint: fileInfo.mountPoint)
                    self.preloadHtml(context: context)
                    return
                }


                guard let previewURL = previewRequest.fileInfo.getPreviewDownloadURLString(previewType: previewType),
                      !previewURL.isEmpty else {
                        DocsLogger.error("Drive.Preload.Download---Failed to get file preview URL when generating ready.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                        self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewFetchError))
                        self.cleanUp()
                        return
                }
                DispatchQueue.global().async {
                    self.downloadPreview(previewURL: previewURL,
                                         dataVersion: dataVersion,
                                         originFileName: previewRequest.fileInfo.name,
                                         type: previewType.toDriveFileType(originType: previewRequest.fileInfo.originFileType).rawValue)
                }
            default:
                // 处理未知的服务器转换状态
                DocsLogger.driveInfo("Drive.Preload.Download---Failed getting file preview URL, error case: \(filePreview.previewStatus).",
                                extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
                if self.preloadSource == .manualOffline {
                    self.downloadOrigin(fileInfo: previewRequest.fileInfo)
                    return
                }
                self.delegate?.operation(self, failedWithError: .previewInfoError(DriveError.previewDataError))
                self.cleanUp()
                return
            }
        }
    }
}

// MARK: - DriveDownloadCallback
extension DrivePreloadOperation: DriveDownloadCallback {
    func updateProgress(context: DriveDownloadContext) {
        guard let downloadKey = downloadKey, !isCancelled else {
            DocsLogger.debug("Drive.Preload.Download --- preload cancelled when downloading file", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            cancelOperation()
            return
        }
        guard context.key == downloadKey else {
            //ignore download callback for other file
            return
        }
        guard let preloadToken = preloadToken else {
            DocsLogger.error("Drive.Preload.Download---failed to get preload token when download success.")
            cleanUp()
            return
        }

        switch context.status {
        case .failed:
            // 移动到 on failed 处理
            DocsLogger.error("Drive.Preload.Download---download file was failed.")
        case .cancel:
            // 移动到 on failed 处理
            DocsLogger.driveInfo("Drive.Preload.Download---download file was cancelled.")
        case .success:
            performanceLogger.stageEnd(stage: .downloadFile)
            guard preloadToken.localPath.exists else {
                self.delegate?.operation(self, failedWithError: .downloadError)
                DocsLogger.error("Drive.Preload.Download---download success but file not exist.")
                cleanUp()
                return
            }
            DocsLogger.debug("Drive.Preload.Download---Preload success.", extraInfo: ["token": DocsTracker.encrypt(id: self.preloadRequest.token)])
            let source: DriveCacheService.Source = preloadRequest.source == .manualOffline ? .manual : .standard
            let cacheType: DriveCacheType = preloadToken.isOrigin ? .similar : .preview
            let fileType = previewRequest?.fileInfo.type
            let fileSize = previewRequest?.fileInfo.size ?? preloadToken.localPath.fileSize

            DocsLogger.driveInfo("Drive.Preload.Download---saving file.",
                            extraInfo: ["cacheType": cacheType, "fileType": fileType ?? "", "fileSize": fileSize ?? 0])
            let basicInfo = DriveCacheServiceBasicInfo(cacheType: cacheType,
                                                       source: source,
                                                       token: preloadRequest.token,
                                                       fileName: preloadToken.fileName,
                                                       fileType: fileType,
                                                       dataVersion: preloadToken.dataVersion,
                                                       originFileSize: fileSize)
            let saveContext = SaveFileContext(filePath: preloadToken.localPath,
                                              moveInsteadOfCopy: true,
                                              basicInfo: basicInfo,
                                              rewriteFileName: false)

            cacheService.saveDriveFile(context: saveContext) { [weak self] savedNode in
                guard let self = self else { return }
                switch savedNode {
                case .success:
                    self.markSucceed()
                case .failure(let error):
                    let token = DocsTracker.encrypt(id: self.preloadRequest.token)
                    DocsLogger.error("Drive.Preload.Download---save to cache failed", extraInfo: ["token": token], error: error)
                    self.delegate?.operation(self, failedWithError: .cacheError)
                    self.cleanUp()
                    return
                }
            }
        case .pending, .inflight, .ready, .queue, .rangeFinish:
            return
        @unknown default:
            spaceAssertionFailure("check if you need to handle default case")
            DocsLogger.warning("check if you need to handle default case")
            return
        }
    }

    func onFailed(key: String, errorCode: Int) {
        performanceLogger.stageEnd(stage: .downloadFile)
        guard let downloadKey = downloadKey, !isCancelled else {
            cleanUp()
            return
        }
        guard key == downloadKey else {
            return
        }
        if errorCode == DriveTransmissionError.userCancel.rawValue {
            // preload cancel by other, resume downloading
            DispatchQueue.global().async {
                if !self.retryDownload() {
                    DocsLogger.error("Drive.Preload.Download---Download Error due to user cancelled")
                    self.delegate?.operation(self, failedWithError: .downloadCancelled)
                    self.cleanUp()
                }
            }
        } else {
            DocsLogger.error("Drive.Preload.Download---Download Error Code: \(errorCode)")
            self.delegate?.operation(self, failedWithError: .downloadError)
            cleanUp()
        }
    }
}

// MARK: - Helper Functions
extension DrivePreloadOperation {

    /// 判断是否允许进行预加载
    ///
    /// - Parameter fileInfo: 后台返回的文件信息
    /// - Returns: 是否预加载
    private func allowPreload(fileInfo: DriveFileInfo) -> Bool {
        if preloadRequest.source == .manualOffline {
            return true
        }
        if let previewType = fileInfo.previewType {
            switch previewType {
                // 视频预加载不需要考虑文件大小
            case .mp4, .ogg:
                DocsLogger.driveInfo("Drive.Preload.Download---mp4 and ogg will preload partially")
                return true
            case .pages, .jpg, .html, .linerizedPDF, .jpgLin, .archive, .png,
                    .pngLin, .transcodedPlainText, .similarFiles, .mime, .videoMeta:
                DocsLogger.driveInfo("Drive.Preload.Download--- other type will check file size")
            }
        }
        // 大于预加载限制，并且不支持加载缩略图的情况
        if fileInfo.size > preloadRequest.sizeLimit && !DriveThumbPreloadConfig.shouldDownloadThumb(source: self.preloadRequest.source,
                                                                                                    fileSize: fileInfo.size,
                                                                                                    fileType: fileInfo.type) {
            return false
        }
        return true
    }
    
    private func shouldDownloadPreview(info: DriveFileInfo) -> Bool {
        if info.size > preloadRequest.sizeLimit && preloadRequest.source != .manualOffline {
            return false
        }
        guard info.previewStatus == 1 else {
            DocsLogger.driveInfo("Drive.Preload.Download---Cannot download preview file, invalid preview status",
                            extraInfo: [
                                "token": DocsTracker.encrypt(id: info.fileToken),
                                "status": info.previewStatus as Any
            ])
            return false
        }
        if info.fileType.preferLocalPreview {
            return false
        }

        guard let previewType = info.previewType else {
            return false
        }

        switch previewType {
        case .archive, .jpgLin, .pngLin:
            return false
        case .mp4, .ogg:
            if preloadRequest.source == .manualOffline {
                // 手动离线直接下载源文件，不预加载视频
                return false
            }
            return true
        default:
            break
        }
        return true
    }

    /// 判断是否允许下载源文件
    ///
    /// - Parameter fileType: 文件类型
    /// - Returns: 是否下载源文件
    private func allowDownloadOrigin(fileInfo: DriveFileInfo) -> Bool {
        if preloadRequest.source == .manualOffline {
            return true
        }
        guard fileInfo.size < preloadRequest.sizeLimit else { return false }
        if !fileInfo.fileType.needSaveCache() {
            return false
        }

        if !fileInfo.fileType.isSupport {
            return false
        }
        return true
    }

    private func cancelOperation() {
        delegate?.operation(self, failedWithError: .cancelled)
        cleanUp()
    }

    private func markSucceed() {
        isSuccess = true
        cleanUp()
    }

    private func cleanUp() {
        fileInfoRequest?.cancel()
        if let downloadKey = downloadKey {
            SpaceRustRouter.shared.cancelDownload(key: downloadKey).subscribe(onNext: { result in
                DocsLogger.driveInfo("cleanup cancel result: \(result)")
            }).disposed(by: disposeBag)
        }
        previewRequest?.cancel()
        finished()
    }

    private func finished() {
        willChangeValue(for: \DrivePreloadOperation.isFinished)
        willChangeValue(for: \DrivePreloadOperation.isExecuting)
        executingState = false
        finishedState = true
        didChangeValue(for: \DrivePreloadOperation.isExecuting)
        didChangeValue(for: \DrivePreloadOperation.isFinished)
    }
    
    private func saveDriveData<T: Codable>(_ data: T, context: SaveDriveDataContext) {
        let jsonEncoder = JSONEncoder()
        do {
            let data = try jsonEncoder.encode(data)
            // save 的时候不要用 encryptedToken，缓存内有针对 token 清理的逻辑
            let basicInfo = DriveCacheServiceBasicInfo(cacheType: context.type,
                                                       source: .standard,
                                                       token: context.token,
                                                       fileName: context.fileName,
                                                       fileType: nil,
                                                       dataVersion: context.dataVersion,
                                                       originFileSize: context.fileSize)
            let context = SaveDataContext(data: data, basicInfo: basicInfo)
            self.cacheService.saveDriveData(context: context) { result in
                DocsLogger.driveInfo("Drive.Preload.Download --- save encode drive data, result: \(result) ")
            }
        } catch {
            DocsLogger.driveError("Drive.Preload.Download --- failed to encode drive data info", error: error)
        }
    }
}

// MARK: - 数据埋点
extension DrivePreloadOperation {
    private func reportStartManualOffline(request: DrivePreloadService.Request, localPath: SKFilePath, downloadKey: String) {
        guard request.source == .manualOffline else {
            DocsLogger.driveInfo("not manual offline will not report")
            return
        }
        let fileName = localPath.pathURL.lastPathComponent
        DocsContainer.shared.resolve(UploadAndDownloadStastis.self)?
            .recordDownloadInfo(module: SKCreateTracker.moduleString,
                                 downloadKey: downloadKey,
                                 fileID: request.token,
                                 fileSubType: SKFilePath.getFileExtension(from: fileName) ?? "",
                                 isExport: false,
                                 isDriveSDK: false)
    }
}
