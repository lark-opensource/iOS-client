//
//  DKPreviewViewModel.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/23.
//
//  swiftlint:disable file_length


import Foundation
import RxSwift
import RxCocoa
import SpaceInterface
import SKCommon
import SKFoundation
import LarkDocsIcon

extension DKPreviewViewModel {
    typealias PullInfo = (isRunning: Bool, interval: Int64)
    enum State {
        case loading // 开始请求预览数据,显示loading
        case endLoading // 加载完成，隐藏loading
        case fetchFailed(canRetry: Bool, errorMessage: String, handler: (() -> Void)?) // 请求 previewget 失败
        case transcoding(fileType: String, handler: (() -> Void)?) // 转码中
        case endTranscoding // 转码结束
        case showDownloading(fileType: DriveFileType) // 开始下载
        case downloading(progress: Float) // 下载进度
        case downloadFailed(errorMessage: String, handler: (() -> Void)) // 下载失败
        case downloadNoPermission // 没有下载权限
        case downloadCompleted // 下载成功
        case preview(type: DriveFileType, info: DKFilePreviewInfo) // 创建预览界面 type:实际预览的文件类型，info: 对应文件类型预览需要的数据
        case unsupport(fileInfo: DKFileProtocol, type: DriveUnsupportPreviewType) // 不支持预览
        case cacDenied //cac管控
    }
}

class DKPreviewViewModel: DKPreviewViewModelType {
    // 当前是否预览历史版本, 主要影响缓存类型
    private let isLatest: Bool
    // 配置如何处理preview结果
    private let processorConfig: DrivePreviewProcessorConfig
    // Private - Input
    private let _fetchEvent = PublishSubject<PreviewFlow>()
    private let _retryEvent = PublishSubject<()>()
    private let canCopyRelay = BehaviorRelay<Bool>(value: true)
    
    // Private - Output
    private let _previewState = PublishRelay<State>()
    private let _previewAction = PublishRelay<DKPreviewAction>()
    
    // Inner status
    /// 轮询preview get接口的定时器
    private var isRunPulling = BehaviorRelay<PullInfo>(value: (isRunning: false, interval: Int64.max))
    private var _netState = BehaviorRelay<Bool>(value: true)

    // 记录下载的文件类型
    private var downloadPreviewType: DrivePreviewFileType?
    private var cacheType: DriveCacheType = .preview

    private var bag = DisposeBag()

    private var dependency: DKPreviewVMDependency
    private let fileInfo: DKFileProtocol
    private let previewType: DrivePreviewFileType?
    private var previewProcessor: PreviewProcessor? = nil
    // 业务埋点参数
    var additionalStatisticParameters: [String: String]?
    // 性能埋点
    var performanceRecorder: DrivePerformanceRecorder {
        return dependency.performanceRecorder
    }

    var input: DKPreviewVMInput {
        return self
    }
    var output: DKPreviewVMOutput {
        return self
    }
        
    init(fileInfo: DKFileProtocol, isLatest: Bool, processorConfig: DrivePreviewProcessorConfig, dependency: DKPreviewVMDependency) {
        self.fileInfo = fileInfo
        self.isLatest = isLatest
        self.processorConfig = processorConfig
        self.dependency = dependency
        self.previewType = fileInfo.getPreferPreviewType(isInVCFollow: processorConfig.isInVCFollow)
        self.previewProcessor = self.processor(for: previewType, handler: self)
        setupViewModel()
    }
    deinit {
        DocsLogger.driveInfo("DriveSDK.PreviewVM: DKPreviewViewModel-deinit")
        reportCancelGenerating()
    }
    
    private func setupViewModel() {
        _fetchEvent.do(onNext: { [weak self] _ in
                guard let self = self else { return }
                self._previewState.accept(.loading)
            })
            .flatMap { [weak self] _ -> Single<DKFilePreview> in
                guard let self = self else { return .never() }
                guard let previewType = self.previewType, previewType != .similarFiles,
                      var filePreview = self.fileInfo.previewMetas[previewType] else {
                    DocsLogger.driveInfo("DriveSDK.PreviewVM: no need previewGet, start download similar file")
                    self._previewState.accept(.endLoading)
                    self.downloadPreview(type: .similarFiles)
                    return .never()
                }
                filePreview.previewURL = self.fileInfo.getPreviewDownloadURLString(previewType: previewType)
                self.performanceRecorder.stageBegin(stage: .requestPreviewUrl)
                return .just(filePreview)
            }
            .do(onNext: {[weak self] _ in
                guard let self = self else { return }
                self.performanceRecorder.stageEnd(stage: .requestPreviewUrl)
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] result in
                guard let self = self else { return }
                self._previewState.accept(.endLoading)
                self.handle(preview: result)
            }, onError: { [weak self] error in
                self?._previewState.accept(.endLoading)
                self?.handle(previewError: error)
            })
            .disposed(by: bag)
        
        isRunPulling
            .asObservable()
            .debug("DriveSDK.PreviewVM: isRunning")
            .flatMapLatest { (pullInfo) -> Observable<Int> in
                let milliseconds = Int(pullInfo.interval)
                if pullInfo.isRunning, milliseconds >= 0 {
                    return Observable.interval(RxTimeInterval.milliseconds(milliseconds), scheduler: MainScheduler.instance)
                } else {
                    return .empty()
                }
            }
            .flatMap {[weak self] (_) -> Single<DKFilePreview> in
                guard let self = self else { return .never() }
                guard self.isWaitTranscoding else {
                    DocsLogger.driveInfo("DriveSDK.PreviewVM -- transcoding is ended, no need to request")
                    return .never()
                }
                return self.dependency.filePreviewProvider.request()
            }
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: {[weak self] result in
                    guard let self = self else { return }
                    guard self.isWaitTranscoding else {
                        DocsLogger.driveInfo("DriveSDK.PreviewVM -- transcoding is ended, no need to handle pull event")
                        return
                    }
                    self.handle(preview: result)
                }, 
                onError: { [weak self] error in
                    guard let self = self else { return }
                    guard self.isWaitTranscoding else {
                        DocsLogger.driveInfo("DriveSDK.PreviewVM -- transcoding is ended, no need to handle pull event on error")
                        return
                    }
                    self.handle(previewError: error)
                }
            )
            .disposed(by: bag)
        
        _retryEvent
            .subscribe(onNext: {[weak self] (_) in
                guard let self = self else { return }
                let cacheSource: DriveCacheService.Source = self.isLatest ? .standard : .history
                self.dependency
                    .downloader
                    .retryDownload(cacheSource: cacheSource)
            }).disposed(by: bag)

        dependency.networkState.bind(to: _netState).disposed(by: bag)
        setupDownloader()
    }
    
    private func setupDownloader() {
        dependency.downloader.downloadStatusHandler = { [weak self] (status) in
            guard let self = self else { return }
            self.handleDownloadStatus(status)
        }
        dependency.downloader.beginDownloadHandler = { [weak self] in
            guard let self = self else { return }
            self.handleBeginDownload()
        }
        dependency.downloader.forbidDownloadHandler = { [weak self] in
            guard let self = self else { return }
            self._previewAction.accept(.cancelDownload)
            DocsLogger.warning("DriveSDK.PreviewVM: 4G 流量禁止下载",
                               extraInfo: ["fileID": DocsTracker.encrypt(id: self.fileInfo.fileID)])
        }
        dependency.downloader.cacheStageHandler = { [weak self] (stage) in
            self?.handleDownloadCacheStage(stage)
        }
    }

    private func handle(preview: DKFilePreview) {
        guard let previewProcessor = self.previewProcessor else {
            DocsLogger.error("DriveSDK.PreviewVM preview: No availible previewProcessor")
            self._previewState.accept(unsupportState(type: .typeUnsupport))
            return
        }
        previewProcessor.handle(preview: preview, completion: {})
    }

    private func handle(previewError: Error) {
        guard let previewProcessor = self.previewProcessor else {
            DocsLogger.info("DriveSDK.PreviewVM previewError: No availible previewProcessor")
            self._previewState.accept(unsupportState(type: .typeUnsupport))
            return
        }
        previewProcessor.handle(error: previewError, completion: {})
    }
    
    private func waitForTranscodig(interval: Int64, handler: (() -> Void)?) {
        guard isWaitTranscoding == false else {
            DocsLogger.driveInfo("DriveSDK.PreviewVM: Already regist push service")
            return
        }
        performanceRecorder.dataCollectionBegin(key: .serverTransform, code: .start)
        DocsLogger.driveInfo("DriveSDK.PreviewVM: waitinng interval: \(interval)")
        startTimer(interval: interval)
        _previewState.accept(.transcoding(fileType: fileInfo.type, handler: handler))
        dependency
            .previewPushService
            .registPushService().flatMap({[weak self] (data) -> Single<DKFilePreview> in
                guard let self = self else { return .never() }
                guard self.isWaitTranscoding else {
                    DocsLogger.driveInfo("DriveSDK.PreviewVM -- transcoding is ended, ignore push event")
                    return .never()
                }

                if data.previewStatus == .ready,
                   data.previewType == self.previewType?.rawValue {
                    return self.dependency.filePreviewProvider.request()
                } else {
                    return .never()
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: {[weak self] (result) in
                    guard let self = self else { return }
                    guard self.isWaitTranscoding else {
                        DocsLogger.driveInfo("DriveSDK.PreviewVM -- transcoding is ended, no need to handle push event")
                        return
                    }
                    self.handle(preview: result)
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    guard self.isWaitTranscoding else {
                        DocsLogger.driveInfo("DriveSDK.PreviewVM -- transcoding is ended, no need to handle push event on error")
                        return
                    }
                    self.handle(previewError: error)
                }
            )
            .disposed(by: bag)
    }
    
    private func stopTimer() {
        DocsLogger.driveInfo("DriveSDK.PreviewVM: stop pulling timer")
        isRunPulling.accept((isRunning: false, interval: Int64.max))
    }

    private func startTimer(interval: Int64) {
        DocsLogger.driveInfo("DriveSDK.PreviewVM: start pulling timer")
        isRunPulling.accept((isRunning: true, interval: interval))
    }
    
    private func unsupportState(type: DriveUnsupportPreviewType) -> State {
        return .unsupport(fileInfo: fileInfo, type: type)
    }
    
    private func fetchFailedState(canRetry: Bool, errorMessage: String) -> State {
        return .fetchFailed(canRetry: canRetry, errorMessage: errorMessage) { [weak self] in
            self?._fetchEvent.onNext(.normal)
        }
    }

    // error message 会上报到 TEA
    private func downloadFaildState(errorMessage: String) -> State {
        return .downloadFailed(errorMessage: errorMessage) { [weak self] in
            self?._retryEvent.onNext(())
        }
    }
    
    /// Rust 下载 400 错误状态，需重新获取下载地址
    private func downloadFaildRetryFetchState(errorMessage: String) -> State {
        return .downloadFailed(errorMessage: errorMessage) { [weak self] in
            self?._fetchEvent.onNext(.normal)
        }
    }
    
    private func fileTypeToPreview(previewType: DrivePreviewFileType) -> DriveFileType {
        return previewType.toDriveFileType(originType: fileInfo.fileType)
    }
}

extension DKPreviewViewModel: DKPreviewVMInput {
    var canCopy: BehaviorRelay<Bool> {
        return canCopyRelay
    }
    
    var fetchPreview: AnyObserver<PreviewFlow> {
        return _fetchEvent.asObserver()
    }
}

extension DKPreviewViewModel: DKPreviewVMOutput {
    var previewAction: Signal<DKPreviewAction> {
        _previewAction.asSignal()
    }
    
    var previewState: Driver<State> {
        let state = fetchFailedState(canRetry: false, errorMessage: "")
        return _previewState.debug("DriveSDK.PreviewVM: State")
            .asDriver(onErrorJustReturn: state)
            .do(onSubscribed: {[weak self] in
                DocsLogger.driveInfo("DriveSDK.PreviewVM: start fetch preview")
                self?._fetchEvent.onNext(.normal)
            })
    }
    
}

extension DKPreviewViewModel: PreviewProcessHandler {
    var isWaitTranscoding: Bool {
        return isRunPulling.value.isRunning
    }

    func updateState(_ state: DriveProccessState) {
        handleProcessState(state)
    }

    private func handleProcessState(_ state: DriveProccessState) {
        DocsLogger.driveInfo("DriveSDK.PreviewVM: handleProcessState: \(state)")
        switch state {
        case let .setupPreview(type, info):
            handlePreviewInfo(fileType: type, info: info)
        case let .unsupport(type):
            _previewState.accept(unsupportState(type: type))
        case .downloadOrigin:
            downloadOrigin()
        case let .downloadPreview(type, _):
            downloadPreview(type: type)
        case .startPreviewGet:
            _fetchEvent.onNext(.normal)
        case let .startTranscoding(pullInterval, handler):
            startTranscoding(pullInterval: pullInterval, handler: handler)
        case let .endTranscoding(status):
            endTranscoding(status: status)
        case let .fetchPreviewURLFail(canRetry, errorMsg):
            let state = fetchFailedState(canRetry: canRetry, errorMessage: errorMsg)
            _previewState.accept(state)
        case .cacDenied:
            _previewState.accept(.cacDenied)
        }
    }
    
    private func handlePreviewInfo(fileType: DriveFileType, info: DriveProccesPreviewInfo) {
        switch info {
        case let .local(url, originFileType):
            let data = DKFilePreviewInfo.LocalPreviewData(url: url,
                                                          originFileType: originFileType,
                                                          fileName: fileInfo.name,
                                                          previewFrom: processorConfig.previewFrom,
                                                          additionalStatisticParameters: additionalStatisticParameters)
            let info = DKFilePreviewInfo.local(data: data)
            startPreview(fileType: fileType, info: info)
        case let .localMedia(url, video):
            let info = DKFilePreviewInfo.localMedia(url: url, video: video)
            startPreview(fileType: fileType, info: info)
        case let .streamVideo(videoInfo):
            let info = DKFilePreviewInfo.streamVideo(video: videoInfo)
            startPreview(fileType: fileType, info: info)
        case let .previewHtml(extraInfo):
            let htmlInfo = DriveHTMLPreviewInfo(fileToken: fileInfo.fileID,
                                                dataVersion: fileInfo.dataVersion,
                                                extraInfo: extraInfo,
                                                fileSize: fileInfo.size,
                                                fileName: fileInfo.name,
                                                canCopy: canCopyRelay,
                                                authExtra: processorConfig.authExtra,
                                                mountPoint: fileInfo.mountPoint)
            let info = DKFilePreviewInfo.excelHTML(info: htmlInfo)
            _previewState.accept(.preview(type: fileInfo.fileType, info: info))
        case .previewWPS:
            spaceAssertionFailure("DKPreviewViewModel 不会处理 WPS 状态")
        case let .archive(viewModel):
            let info = DKFilePreviewInfo.archive(viewModel: viewModel)
            startPreview(fileType: fileType, info: info)
        case let .linearizedImage(preview):
            let downloaderDependency = DKImageDownloaderDependencyImpl(fileInfo: fileInfo,
                                                                       filePreview: preview,
                                                                       isLatest: isLatest,
                                                                       cacheService: dependency.cacheService)
            let info = DKFilePreviewInfo.linearizedImage(dependency: downloaderDependency)
            startPreview(fileType: fileType, info: info)
        case .thumb: break
            // startPreview
        }
    }
    
    private func endTranscoding(status: DriveFilePreview.PreviewStatus) {
        reportEndGeneratingIfNeed(status: status)
        DocsLogger.driveInfo("DriveSDK.PreviewVM: end transcoding")
        dependency.previewPushService.unRegistPushService()
        stopTimer()
        _previewState.accept(.endTranscoding)
    }

    func startTranscoding(pullInterval: Int64, handler: (() -> Void)?) {
        DocsLogger.driveInfo("DriveSDK.PreviewVM: start transcoding")
        waitForTranscodig(interval: pullInterval, handler: handler)
    }

    func downloadPreview(type: DrivePreviewFileType) {
        DocsLogger.driveInfo("DriveSDK.PreviewVM: start download preview file: \(type)")
        let source: DriveCacheService.Source = isLatest ? .standard : .history
        dependency
            .downloader
            .download(previewType: type, cacheSource: source, cacheCustomID: nil)
        self.downloadPreviewType = type
        self.cacheType = .preview
    }
    
    func downloadOrigin() {
        DocsLogger.driveInfo("DriveSDK.PreviewVM: start download origin file")
        guard let meta = fileInfo.getMeta() else {
            spaceAssertionFailure("IM file cannot download origin file")
            return
        }
        let source: DriveCacheService.Source = isLatest ? .standard : .history
        dependency.downloader.downloadSimilar(meta: meta, cacheSource: source)
        self.cacheType = .similar
    }
    
    func startPreview(fileType: DriveFileType, info: DKFilePreviewInfo) {
        let state = State.preview(type: fileType, info: info)
        _previewState.accept(state)
    }
    
    private func reportEndGeneratingIfNeed(status: DriveFilePreview.PreviewStatus) {
        switch status {
        case .ready:
            performanceRecorder.dataCollectionEnd(key: .serverTransform, code: .finish)
        case .generating, .failedCanRetry:
            // do nothing
            DocsLogger.driveInfo("file is generating")
        default:
            performanceRecorder.dataCollectionEnd(key: .serverTransform, code: .failed)
        }
    }
    
    // 用户退出r时如果还没有上报finish或者failed，则上报cancel
    private func reportCancelGenerating() {
        if isWaitTranscoding {
            performanceRecorder.dataCollectionEnd(key: .serverTransform, code: .cancel)
        }
    }

}

extension DKPreviewViewModel {
    func processor(for type: DrivePreviewFileType?, handler: PreviewProcessHandler) -> PreviewProcessor? {
        guard let type = type else {
            return nil
        }
        let procesorProvider = dependency.filePreviewProcessorProvider
        return procesorProvider.processor(with: type, fileInfo: fileInfo, resultHandler: handler, config: processorConfig)
    }
}


// MARK: downloader
extension DKPreviewViewModel {
    private func handleDownloadStatus(_ status: DriveDownloadService.DownloadStatus) {
        switch status {
        case .downloading(let progress):
            self._previewState.accept(.downloading(progress: progress))
        case .failed(let errorCode):
            self.performanceRecorder.stageEnd(stage: .downloadFile)
            if errorCode == "403" {
                DocsLogger.driveInfo("DriveSDK.PreviewVM: download - no perm",
                                extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID)])
                self._previewState.accept(.downloadNoPermission)
            } else {
                DocsLogger.driveInfo("DriveSDK.PreviewVM: download failed",
                                extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID),
                                            "errorCode": errorCode])
                let state = self.downloadFaildState(errorMessage: "Rust Error Code: \(errorCode)")
                self._previewState.accept(state)
            }

        case .success:
            self.performanceRecorder.stageEnd(stage: .downloadFile)
            self.handleDownloadCompleted()
        case .retryFetch(let errorCode):
            DocsLogger.driveInfo("DriveSDK.PreviewVM: download failed(can retry)",
                            extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID),
                                        "errorCode": errorCode])
            self.performanceRecorder.stageEnd(stage: .downloadFile)
            let state = downloadFaildRetryFetchState(errorMessage: "Rust Error Code: \(errorCode)")
            self._previewState.accept(state)
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
        let type: DriveFileType
        if let previewType = self.previewType {
            type = previewType.toDriveFileType(originType: fileInfo.fileType)
        } else {
            type = fileInfo.fileType
        }

        self._previewState.accept(.showDownloading(fileType: type))
        DocsLogger.driveInfo("DriveSDK.PreviewVM: start download",
                        extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID)])
    }
    
    private func handleDownloadCompleted() {
        // 更新PerformanceRecorder 预览文件信息
        updatePreviewInfoToRecorder()
        DocsLogger.driveInfo("DriveSDK.PreviewVM: download succeed", extraInfo: ["fileID": DocsTracker.encrypt(id: fileInfo.fileID)])
        self._previewState.accept(.downloadCompleted)
        // 下载成功，打开本地文件
        let url: SKFilePath
        let result = dependency.cacheService.getFile(type: cacheType,
                                                     fileExtension: fileInfo.fileExtension,
                                                     dataVersion: fileInfo.dataVersion)
        switch result {
        case let .failure(error):
            DocsLogger.error("DriveSDK.PreviewVM: can not find file path")
            self._previewState.accept(downloadFaildState(errorMessage: "Failed to get file from cache after download success, \(error.localizedDescription)"))
            return
        case let .success(node):
            guard let path = node.fileURL else {
                spaceAssertionFailure("DriveSDK.PreviewVM: cache node file url not set")
                self._previewState.accept(downloadFaildState(errorMessage: "Failed to get file from cache after download success, cache node url not set"))
                return
            }
            url = path
        }
        
        // 使用相似文件类型预览，如果原始类型不支持预览，则显示不支持界面
        if (downloadPreviewType == .similarFiles || cacheType == .similar), !fileInfo.fileType.isSupport {
            self._previewState.accept(unsupportState(type: .typeUnsupport))
        } else {
            let type: DriveFileType
            if let previewType = downloadPreviewType {
                type = fileTypeToPreview(previewType: previewType)
            } else {
                type = fileInfo.fileType
            }
            // 音视频文件特殊处理，需要更多信息
            if fileInfo.fileType.isMedia && fileInfo.fileType.isAVPlayerSupport {
                let cacheKey = fileInfo.videoCacheKey
                let video = DriveVideo(type: .local(url: url),
                                       info: nil,
                                       title: fileInfo.name,
                                       size: fileInfo.size,
                                       cacheKey: cacheKey,
                                       authExtra: nil)
                let info = DKFilePreviewInfo.localMedia(url: url, video: video)
                self._previewState.accept(.preview(type: type, info: info))


            } else {
                let localData = DKFilePreviewInfo.LocalPreviewData(url: url,
                                                                originFileType: fileInfo.fileType,
                                                                fileName: fileInfo.name,
                                                                previewFrom: processorConfig.previewFrom,
                                                                additionalStatisticParameters: additionalStatisticParameters)
                let info = DKFilePreviewInfo.local(data: localData)
                self._previewState.accept(.preview(type: type, info: info))
            }
        }
    }
    
    private func updatePreviewInfoToRecorder() {
        let previewInfo = getPreviewFileInfo()
        performanceRecorder.previewType = previewInfo.preViewType?.rawValue
        performanceRecorder.previewExt = previewInfo.previewExt
        performanceRecorder.previewFileSize = previewInfo.previewSize
    }
    
    private func getPreviewFileInfo() -> (preViewType: DrivePreviewFileType?, previewExt: String?, previewSize: UInt64?) {
        let cacheService = dependency.cacheService
        var previewType: DrivePreviewFileType? = previewType
        var previewExt: String?
        var previewSize: UInt64?
        if let node = try? cacheService.getFile(type: cacheType,
                                                fileExtension: fileInfo.fileExtension,
                                                dataVersion: fileInfo.dataVersion).get(),
           let fileExt = node.fileExtension {
            previewExt = fileExt
            previewSize = node.fileURL?.fileSize
        } else {
            // 没有转码文件
            previewType = nil
        }
        DocsLogger.driveInfo("preview type: \(String(describing: previewType)), ext: \(String(describing: previewExt)), size: \(String(describing: previewSize))")
        return (previewType, previewExt, previewSize)
    }
}
