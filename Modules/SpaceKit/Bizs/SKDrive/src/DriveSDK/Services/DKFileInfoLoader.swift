//
//  DKFileInfoLoader.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/21.
//

import Foundation
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import UIKit
import LarkDocsIcon

enum FileInfoState<FileInfo> {
    case startFetch(isAsycn: Bool) // 加载中
    case storing // 转存中
    case fetchFailed(error: Error, isPreviewing: Bool) // 请求fileInfo失败， error: 错误信息， isPreviewing：是否已经使用缓存预览中
    case fetchSucc(info: FileInfo, isPreviewing: Bool) // fileInfo请求成功
    case failedWithNoNet // 无缓存，无网络
    case startFetchPreview(info: FileInfo)
    case showDownloading(fileType: DriveFileType) // 开始下载
    case downloading(progress: Float) // 下载进度
    case downloadFailed(errorMessage: String, handler: (() -> Void)) // 下载失败
    case downloadCompleted // 下载成功
    case preview(type: DriveFileType, info: DKFilePreviewInfo) // 创建预览界面 type:实际预览的文件类型，info: 对应文件类型预览需要的数据
    case downloadNoPermission // 没有下载权限
    case unsupport(fileInfo: FileInfo, type: DriveUnsupportPreviewType) // 不支持预览
    case cacDenied(info: FileInfo) //cac管控
}

class DKFileInfoLoader<FileInfo: DKFileProtocol, Provider: DKFileInfoProvider> where Provider.FileInfo == FileInfo {
    weak var hostContainer: UIViewController?
    private let fileInfoProvider: Provider
    private let cacheService: DKCacheServiceProtocol
    private var downloader: DKPreviewDownloadService?
    private let fileEditTypeProvider: DKFileEditTypeService
    private var isLatest: Bool
    private var skipCellularCheck: Bool
    private var isInVCFollow: Bool
    /// IM 文件是否支持编辑(目前仅 Excel 接入)
    private var isIMFileEditable = BehaviorRelay<Bool>(value: false)
    // 网络状态
    private let reachabilityRelay: BehaviorRelay<Bool>
    // 业务埋点
    private let statisticsService: DKStatisticsService
    // 业务埋点参数
    var additionalStatisticParameters: [String: String]?
    // 性能埋点
    private let performanceRecorder: DrivePerformanceRecorder
    
    private var fileInfo: FileInfo
    private var fileInfoRelay: ReplaySubject<Result<DKFileProtocol, Error>>
    
    private let fileInfoProcessorProvider: FileInfoProcessorProvider
    private var fileInfoProcessor: FileInfoProcessor?
    private var processorConfig: DriveFileInfoProcessorConfig

    // 记录下载的文件类型
    private var downloadPreviewType: DrivePreviewFileType?
    
    /// 用于内部事件的绑定
    private var disposeBag = DisposeBag()
    init(fileInfo: FileInfo,
         isLatest: Bool,
         isInVCFollow: Bool,
         skipCellularCheck: Bool,
         fileInfoProvider: Provider,
         fileInfoProcessorProvider: FileInfoProcessorProvider,
         processorConfig: DriveFileInfoProcessorConfig,
         cacheService: DKCacheServiceProtocol,
         statisticsService: DKStatisticsService,
         performanceRecorder: DrivePerformanceRecorder,
         hostContainer: UIViewController) {
        self.fileInfo = fileInfo
        self.fileInfoRelay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        self.isLatest = isLatest
        self.isInVCFollow = isInVCFollow
        self.skipCellularCheck = skipCellularCheck
        self.fileInfoProvider = fileInfoProvider
        self.fileEditTypeProvider = DKFileEditTypeServiceImpl(fileId: fileInfo.fileID, fileType: fileInfo.fileType)
        self.processorConfig = processorConfig
        self.cacheService = cacheService
        self.statisticsService = statisticsService
        self.performanceRecorder = performanceRecorder
        self.fileInfoProcessorProvider = fileInfoProcessorProvider
        self.hostContainer = hostContainer
        reachabilityRelay = BehaviorRelay<Bool>(value: DocsNetStateMonitor.shared.isReachable)
        self.fileInfoRelay.onNext(.success(fileInfo))
        setupNetworkMonitor()
    }
    
    deinit {
        DocsLogger.driveInfo("DKFileInfoLoader -- deinit")
    }
    // Input
    // 是否有复制权限
    let canCopy = BehaviorRelay<Bool>(value: true)
    // Private - Output
    private let stateRelay = PublishRelay<FileInfoState<FileInfo>>()
    private let actionRelay = PublishRelay<DKPreviewAction>()
    
    // 加载fileInfo的状态
    var state: Observable<FileInfoState<FileInfo>> {
        return stateRelay.asObservable().catchError { _ in
            return Observable<FileInfoState<FileInfo>>.never()
        }
    }
    
    // 加载fileInfo过程发出的动作
    var action: Observable<DKPreviewAction> {
        return actionRelay.asObservable().catchError { _ in
            return Observable<DKPreviewAction>.never()
        }
    }
    
    func start() {
        if !processorConfig.isIMFileEncrypted && asyncFetchFileInfoIfNeed() {
            performanceRecorder.sourceType = .cache
            performanceRecorder.hitCache = true
        } else {
            fetchFileInfo(version: fileInfo.version)
        }
    }
    
    private func asyncFetchFileInfoIfNeed() -> Bool {
        guard let previewState = getCacheState() else { return false }
        stateRelay.accept(previewState)
        guard reachabilityRelay.value else {
            DocsLogger.driveInfo("DKFileInfoLoader -- previewState: \(previewState)")
            return true
        }
        reqFileInfo(version: fileInfo.version, hasOpenFromCache: true)

        return true
    }
    
    private func getCacheState() -> FileInfoState<FileInfo>? {
        let proccesor = getFileInfoProcessor(fileType: fileInfo.fileType)
        guard let state = proccesor.getCachePreviewInfo(fileInfo: fileInfo) else {
            DocsLogger.driveInfo("DKFileInfoLoader: cachePreviewInfo nil")
            return nil
        }
        DocsLogger.driveInfo("DKFileInfoLoader: getCacheState : \(state)")
        switch state {
        case let .setupPreview(previewType, info):
            return convertInfoToPreveiwState(info: info, previewType: previewType)
        case let .unsupport(type):
            return FileInfoState.unsupport(fileInfo: fileInfo, type: type)
        case .cacDenied:
            return FileInfoState.cacDenied(info: fileInfo)
        default:
            spaceAssertionFailure("DKFileInfoLoader -- cacheState not support")
            return nil
        }
    }

    func getFileInfoProcessor(fileType: DriveFileType) -> FileInfoProcessor {
        // 这里需要更新preferPreview, 原因是拉取到fileInfo后，fileType可能会更新；
        // 同时如果是IM附件，默认为true
        let preferPreview = DriveFileInfoProcessorConfig.preferPreview(fileType: fileType,
                                                                       previewFrom: performanceRecorder.previewFrom,
                                                                       isInVCFollow: isInVCFollow) || processorConfig.isIMFile
        processorConfig.preferPreview = preferPreview
        let processor = fileInfoProcessorProvider.processor(with: fileType, originFileInfo: fileInfo, config: processorConfig)
        DocsLogger.driveInfo("DKFileInfoLoader: get processor: \(processor), fileType: \(fileType), fileInfo: \(fileInfo), ")
        return processor
    }
    
    // previewType: 本地路径实际预览的文件类型，比如原始类型为ppt，但是本地下载的是pdf，这里previewType为pdf
    private func convertInfoToPreveiwState(info: DriveProccesPreviewInfo, previewType: DriveFileType) -> FileInfoState<FileInfo> {
        switch info {
        case let .local(url, originFileType):
            DocsLogger.driveInfo("DKFileInfoLoader -- originFileType: \(originFileType)")
            let localData = DKFilePreviewInfo.LocalPreviewData(url: url,
                                                               originFileType: originFileType,
                                                               fileName: fileInfo.name,
                                                               previewFrom: performanceRecorder.previewFrom,
                                                               additionalStatisticParameters: statisticsService.additionalParameters)
            let previewInfo = DKFilePreviewInfo.local(data: localData)
            return FileInfoState.preview(type: previewType, info: previewInfo)
        case let .localMedia(url, video):
            let previewInfo = DKFilePreviewInfo.localMedia(url: url, video: video)
            return FileInfoState.preview(type: fileInfo.fileType, info: previewInfo)
        case let .streamVideo(video):
            let previewInfo = DKFilePreviewInfo.streamVideo(video: video)
            return FileInfoState.preview(type: .mp4, info: previewInfo)
        case let .previewHtml(extraInfo):
            let htmlInfo = DriveHTMLPreviewInfo(fileToken: fileInfo.fileID,
                                                   dataVersion: fileInfo.dataVersion,
                                                   extraInfo: extraInfo,
                                                   fileSize: fileInfo.size,
                                                   fileName: fileInfo.name,
                                                   canCopy: canCopy,
                                                   authExtra: processorConfig.authExtra,
                                                   mountPoint: fileInfo.mountPoint)
            let previewInfo = DKFilePreviewInfo.excelHTML(info: htmlInfo)
            return FileInfoState.preview(type: fileInfo.fileType, info: previewInfo)
        case .previewWPS:
            var info = fileInfo.wpsInfo
            if processorConfig.isIMFile && UserScopeNoChangeFG.ZYP.imWPSEditEnable {
                // 配置 IM 文件是否支持 WPS 编辑（目前仅支持 Excel）
                info.isEditable = isIMFileEditable
                DocsLogger.driveInfo("DKFileInfoLoader -- previewWPS setup editable: \(isIMFileEditable.value)")
            }
            return FileInfoState.preview(type: fileInfo.fileType, info: DKFilePreviewInfo.webOffice(info: info))
        case let .archive(viewModel):
            let info = DKFilePreviewInfo.archive(viewModel: viewModel)
            return FileInfoState.preview(type: fileInfo.fileType, info: info)
        case let .linearizedImage(preview):
            let downloaderDependency = DKImageDownloaderDependencyImpl(fileInfo: fileInfo,
                                                                       filePreview: preview,
                                                                       isLatest: isLatest,
                                                                       cacheService: cacheService)
            let info = DKFilePreviewInfo.linearizedImage(dependency: downloaderDependency)
            return FileInfoState.preview(type: fileInfo.fileType, info: info)
        case let .thumb(image, previewType):
            let downloader = DKPreviewDownloader(fileInfo: fileInfo,
                                                hostContainer: hostContainer ?? UIViewController(),
                                                 cacheService: cacheService,
                                                 skipCellularCheck: skipCellularCheck,
                                                 authExtra: fileInfo.authExtra)
            let dependency = DriveThumbImageViewModelDependencyImpl(fileInfoReplay: fileInfoRelay,
                                                                    image: image,
                                                                    downloader: downloader,
                                                                    retryFetchFileInfo: { [weak self] in
                guard let self = self else { return }
                self.fetchFileInfo(version: self.fileInfo.dataVersion)
                                                            },
                                                                    cacheSource: isLatest ? .standard : .history,
                                                                    previewType: previewType,
                                                                    networkReachable: reachabilityRelay.asObservable(),
                                                                    cacheService: cacheService)
            return FileInfoState.preview(type: fileInfo.fileType, info: DKFilePreviewInfo.thumbnail(dependency: dependency))
        }
    }

    func stopDownload() {
        downloader?.stop()
    }

    func fetchFileInfo(version: String? = nil) {
        DocsLogger.driveInfo("DKFileInfoLoader --- start loading fileInfo")
        guard reachabilityRelay.value else { // 无缓存，无网络
            stateRelay.accept(.failedWithNoNet)
            return
        }
        performanceRecorder.stageBegin(stage: .requestFileInfo)
        reqFileInfo(version: version, hasOpenFromCache: false)
    }
    
    private func setupNetworkMonitor() {
        RxNetworkMonitor.networkStatus(observerObj: self).map { $1 }.bind(to: reachabilityRelay).disposed(by: disposeBag)
    }
}


extension DKFileInfoLoader {

    private func reqFileInfo(version: String?, hasOpenFromCache: Bool) {
        DocsLogger.driveInfo("DKFileInfoLoader --- start req fileInfo, hasOpenFromCache: \(hasOpenFromCache)")
        stateRelay.accept(.startFetch(isAsycn: hasOpenFromCache))
        fileInfoProvider.request(version: version)
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] result -> Observable<(FileInfoResult<FileInfo>, ExcelFileEditInfo)> in
                guard let self = self else { return .empty() }
                guard self.fileInfo.fileType.isExcel && self.processorConfig.isIMFile && UserScopeNoChangeFG.ZYP.imWPSEditEnable else {
                    return .just((result, ExcelFileEditInfo(editType: .unknown, sheetToken: nil, url: nil)))
                }
                // IM 的 Excel 文件需请求 file_edit_type 接口判断是否支持用 Sheet 打开
                return self.fileEditTypeProvider.requestEditType().map { (result, $0) }.asObservable()
            }
            .subscribe(onNext: { [weak self] (fileInfoResult, editInfo) in
                switch fileInfoResult {
                case let .succ(info):
                    self?.markReqFileInfoEnd(hasOpenFromCache: hasOpenFromCache)
                    self?.fileInfoRelay.onNext(.success(info))
                    self?.handle(fileInfo: info,
                                 editMethod: editInfo.editMethod(),
                                 hasOpenFromCache: hasOpenFromCache)
                case .storing:
                    self?.stateRelay.accept(.storing)
                }
            }, onError: { [weak self] error in
                self?.markReqFileInfoEnd(hasOpenFromCache: hasOpenFromCache)
                self?.stateRelay.accept(.fetchFailed(error: error, isPreviewing: hasOpenFromCache))
                self?.fileInfoRelay.onNext(.failure(error))
            }).disposed(by: disposeBag)
    }

    private func markReqFileInfoEnd(hasOpenFromCache: Bool) {
        // 仅记录非异步化的 fileInfo 耗时
        if hasOpenFromCache == false {
            self.performanceRecorder.stageEnd(stage: .requestFileInfo)
        }
    }

    /// 处理异步和非异步化 FileInfo 请求的结果
    private func handle(fileInfo: FileInfo,
                        editMethod: FileEditMethod? = nil,
                        hasOpenFromCache: Bool = false) {
        DocsLogger.driveInfo("DKFileInfoLoader --- handling fileInfo, hasOpenFromCache: \(hasOpenFromCache), fileInfo: \(fileInfo)")
        self.fileInfo = fileInfo
        setupDownloaderIfNeed(fileInfo: fileInfo) // 在fileInfo拉取到后创建downloader
        stateRelay.accept(.fetchSucc(info: fileInfo, isPreviewing: hasOpenFromCache))
        
        // IM 加密文件
        if processorConfig.isIMFileEncrypted {
            DocsLogger.driveInfo("DKFileInfoLoader --- handle IM Encrypted file")
            stateRelay.accept(.unsupport(fileInfo: fileInfo, type: .imfileEncrypted))
            return
        }
        

        // 判断是否用需要用Sheet打开
        if shouldOpenWithSheet(editMethod: editMethod) {
            return
        }

        let processor = getFileInfoProcessor(fileType: fileInfo.fileType)
        processor.handle(fileInfo: fileInfo, hasOpenFromCache: hasOpenFromCache) { [weak self] result in
            guard let self = self else { return }
            if let state = result {
                self.handleProcessState(state)
            }
        }
        self.fileInfoProcessor = processor
    }

    private func shouldOpenWithSheet(editMethod: FileEditMethod?) -> Bool {
        guard let editMethod = editMethod else { return false }
        switch editMethod {
        case .wps:
            // 标记可以用 WPS 编辑
            isIMFileEditable.accept(true)
            DocsLogger.driveInfo("DKFileInfoLoader -- set wps editable true")
            return false
        case .sheet(let url):
            let identifier = UUID().uuidString
            let url = url
                .append(name: ShadowFileURLParam.shadowFileId, value: identifier)
                .append(name: ShadowFileURLParam.docFrom, value: FromSource.imExcel.rawValue)
            // 通过打开 Sheet 进行预览和编辑
            actionRelay.accept(.openShadowFile(id: identifier, url: url))
            // 移除老的缓存信息
            cacheService.deleteFile(dataVersion: nil)
            DocsLogger.driveInfo("DKFileInfoLoader -- open as sheet")
            return true
        case .none:
            return false
        }
    }

    private func handleProcessState(_ state: DriveProccessState) {
        DocsLogger.driveInfo("DKFileInfoLoader --- handleProcessState, \(state)")
        switch state {
        case .downloadOrigin:
            guard let info = fileInfo as? DriveFileInfo else {
                spaceAssertionFailure("only DriveFileInfo can download Origin file")
                stateRelay.accept(.startFetchPreview(info: fileInfo))
                return
            }
            let cacheSource: DriveCacheService.Source = self.isLatest ? .standard : .history
            stateRelay.accept(.showDownloading(fileType: info.fileType))
            downloader?.downloadSimilar(meta: info.getFileMeta(), cacheSource: cacheSource)
        case let .unsupport(type):
            stateRelay.accept(.unsupport(fileInfo: fileInfo, type: type))
        case .startPreviewGet:
            stateRelay.accept(.startFetchPreview(info: fileInfo))
        case let .setupPreview(fileType, info):
            let state = convertInfoToPreveiwState(info: info, previewType: fileType)
            stateRelay.accept(state)
        case .downloadPreview, .startTranscoding, .fetchPreviewURLFail, .endTranscoding, .cacDenied:
            spaceAssertionFailure("DKFileInfoLoader -- fileInfo阶段没有这个几个状态: \(state)")
        }
    }
}


// MARK: -  download
extension DKFileInfoLoader {
    private func setupDownloaderIfNeed(fileInfo: DKFileProtocol) {
        guard let hostVC = hostContainer else {
            spaceAssertionFailure("DKFileInfoLoader -- host vc is nil")
            return
        }
        if downloader == nil {
            self.downloader = DKPreviewDownloader(fileInfo: fileInfo,
                                                  hostContainer: hostVC,
                                                  cacheService: cacheService,
                                                  skipCellularCheck: skipCellularCheck,
                                                  authExtra: processorConfig.authExtra)
        } else {
            self.downloader?.updateFileInfo(fileInfo)
        }
        self.downloader?.downloadStatusHandler = { [weak self] (status) in
            guard let self = self else { return }
            self.handleDownloadStatus(status)
        }
        self.downloader?.beginDownloadHandler = { [weak self] in
            guard let self = self else { return }
            self.handleBeginDownload()
        }
        self.downloader?.forbidDownloadHandler = { [weak self] in
            guard let self = self else { return }
            self.actionRelay.accept(.cancelDownload)
            DocsLogger.warning("DKFileInfoLoader -- 4G disable download",
                               extraInfo: ["fileID": DocsTracker.encrypt(id: self.fileInfo.fileID)])
        }
        self.downloader?.cacheStageHandler = { [weak self] (stage) in
            self?.handleDownloadCacheStage(stage)
        }
    }
    
    private func handleDownloadStatus(_ status: DriveDownloadService.DownloadStatus) {
        switch status {
        case .downloading(let progress):
            stateRelay.accept(.downloading(progress: progress))
        case .failed(let errorCode):
            if errorCode == "403" {
                DocsLogger.driveInfo("DKFileInfoLoader -- download - no perm",
                                extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID)])
                stateRelay.accept(.downloadNoPermission)
            } else {
                DocsLogger.driveInfo("DKFileInfoLoader -- download failed",
                                extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID),
                                            "errorCode": errorCode])
                let state = self.downloadFaildState(errorMessage: "Rust Error Code: \(errorCode)")
                self.stateRelay.accept(state)
            }
            self.performanceRecorder.stageEnd(stage: .downloadFile)
        case .success:
            self.performanceRecorder.stageEnd(stage: .downloadFile)
            self.handleDownloadCompleted()
        case .retryFetch(let errorCode):
            DocsLogger.driveInfo("DKFileInfoLoader -- download failed(can retry)",
                            extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID),
                                        "errorCode": errorCode])
            self.performanceRecorder.stageEnd(stage: .downloadFile)
            let state = downloadFaildRetryFetchState(errorMessage: "Rust Error Code: \(errorCode)")
            self.stateRelay.accept(state)
        }
    }
    
    private func handleDownloadCacheStage(_ stage: DriveStage) {
        switch stage {
        case .begin:
            performanceRecorder.stageBegin(stage: .localCacheFile)
        case .end:
            performanceRecorder.stageEnd(stage: .localCacheFile)
        }
    }
    
    private func handleBeginDownload() {
        self.performanceRecorder.stageBegin(stage: .downloadFile)
        self.stateRelay.accept(.showDownloading(fileType: fileInfo.fileType))
        DocsLogger.driveInfo("DKFileInfoLoader -- start download",
                        extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID)])
    }
    
    private func handleDownloadCompleted() {
        DocsLogger.driveInfo("DKFileInfoLoader -- download succeed", extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID)])
        self.stateRelay.accept(.downloadCompleted)
        // 下载成功，打开本地文件
        let url: SKFilePath
        // fileInfo loader只处理源文件下载的场景，预览文件下载在previewViewModel阶段
        let result = cacheService.getFile(type: .similar, fileExtension: fileInfo.fileExtension, dataVersion: fileInfo.dataVersion)
        switch result {
        case let .failure(error):
            DocsLogger.error("DKFileInfoLoader -- can not find file path")
            self.stateRelay.accept(downloadFaildState(errorMessage: "Failed to get file from cache after download success, \(error.localizedDescription)"))
            return
        case let .success(node):
            guard let path = node.fileURL else {
                spaceAssertionFailure("DKFileInfoLoader -- cache node file url not set")
                return
            }
            url = path
        }

        
        // 音视频文件特殊处理，需要更多信息
        if fileInfo.fileType.isMedia && fileInfo.fileType.isVideoPlayerSupport {
            let cacheKey = fileInfo.videoCacheKey
            let video = DriveVideo(type: .local(url: url),
                                   info: nil,
                                   title: fileInfo.name,
                                   size: fileInfo.size,
                                   cacheKey: cacheKey,
                                   authExtra: nil)
            let info = DKFilePreviewInfo.localMedia(url: url, video: video)
            self.stateRelay.accept(.preview(type: fileInfo.fileType, info: info))
        } else {
            let localData = DKFilePreviewInfo.LocalPreviewData(url: url,
                                                               originFileType: fileInfo.fileType,
                                                               fileName: fileInfo.name,
                                                               previewFrom: performanceRecorder.previewFrom,
                                                               additionalStatisticParameters: statisticsService.additionalParameters)
            let info = DKFilePreviewInfo.local(data: localData)
            self.stateRelay.accept(.preview(type: fileInfo.fileType, info: info))
        }
    }
    
    // error message 会上报到 TEA
    private func downloadFaildState(errorMessage: String) -> FileInfoState<FileInfo> {
        return .downloadFailed(errorMessage: errorMessage) { [weak self] in
            guard let self = self else { return }
            let cacheSource: DriveCacheService.Source = self.isLatest ? .standard : .history
            self.downloader?.retryDownload(cacheSource: cacheSource)
        }
    }
    
    /// Rust 下载 400 错误状态，需重新获取下载地址
    private func downloadFaildRetryFetchState(errorMessage: String) -> FileInfoState<FileInfo> {
        return .downloadFailed(errorMessage: errorMessage) { [weak self] in
            self?.fetchFileInfo(version: self?.fileInfo.version)
        }
    }
}
