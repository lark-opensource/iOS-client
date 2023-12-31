//
//  DriveVideoPlayerViewModel.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2022/3/2.
//  
// disable-lint: magic number

import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SpaceInterface
import SKInfra


class DriveVideoPlayerViewModel {
    static public let startPlaying = Notification.Name(rawValue: "docs.bytedance.notification.name.driveVideoStartPlaying")
    enum Action {
        case playDirectUrl(url: String)
        case showInterruption(msg: String)
        case showCover(image: UIImage)
    }

    enum VideoPlayerStatus {
        case prepared
        case finished
        case failed(info: [String: Any])
        case unknow
    }
    let identifier: String = UUID().uuidString
    let playerStatus = PublishSubject<VideoPlayerStatus>()
    let playerLoadStateChanged = PublishSubject<DriveVideoLoadState>()

    let playbackState = BehaviorRelay<DriveVideoPlaybackState>(value: .stopped)
    let currentPlaybackTime = BehaviorRelay<TimeInterval>(value: 0)

    let videoInfo: DriveVideo
    let engine: DriveVideoPlayer
    let resolutionHandler: DriveVideoResolutionHandler
    let isInVCFollow: Bool
    let mediaMutex: SKMediaMutexDependency?
    var displayMode: DrivePreviewMode
    let fileInfo: DriveFileInfo?
    var coverDownloader: ThumbDownloaderProtocol?
    private(set) var isFromCardMode: Bool = false
    var bindAction: ((Action) -> Void)?

    /// 屏幕常亮状态
    private var intailIdleState: Bool
    /// 记录返回后台是否已经暂停播放
    private var shouldAutoReplay = false
    /// 是否已经配置好 VideoEngine
    private var didSetupEngine = false
    /// 开始播放视频判断，如果isRunningVC不需要调用entry，退出也不需要调用leave,保证entry-leave配对使用
    private lazy var isRuningVC: Bool = {
        return HostAppBridge.shared.call(GetVCRuningStatusService()) as? Bool ?? false
    }()
    let disposeBag = DisposeBag()

    /// For VCFollow: 负责处理 Follow 内容加载流程的事件
    weak var followAPIDelegate: DriveFollowAPIDelegate?
    /// For VCFollow: 负责回调内容状态变化事件
    weak var followContentDelegate: FollowableContentDelegate?
    /// 同层 Follow 的文档挂载点
    var followMountToken: String?
    /// 接收来自 VCFollow 的状态
    let videoFollowStateSubject = PublishSubject<DriveMediaFollowState>()
    private var previousPlayingTime: Double = 0

    init(video: DriveVideo,
         player: DriveVideoPlayer,
         displayMode: DrivePreviewMode,
         isInVCFollow: Bool,
         fileInfo: DriveFileInfo? = nil,
         mediaMutex: SKMediaMutexDependency? = DocsContainer.shared.resolve(SKMediaMutexDependency.self)) {
        self.videoInfo = video
        self.engine = player
        self.displayMode = displayMode
        self.isInVCFollow = isInVCFollow
        self.mediaMutex = mediaMutex
        self.fileInfo = fileInfo
        self.resolutionHandler = DriveVideoResolutionHandler(video: video)
        self.intailIdleState = UIApplication.shared.isIdleTimerDisabled
        self.isFromCardMode = (displayMode == .card)
        addObserverPlayingNotification()
        setupCoverDownloader()
    }

    deinit {
        mediaMutex?.unlock(scene: .ccmPlay, observer: self)
        NotificationCenter.default.removeObserver(self)
    }

    func setupVideoEngine(appState: UIApplication.State) {
        engine.delegate = self
        switch videoInfo.type {
        case let .local(url):
            let autoPlay = shouldAutoPlayForSetup(appState: appState)
            engine.setup(cacheUrl: url.pathURL, shouldPlayForCover: !autoPlay)
            didSetupEngine = true
            if autoPlay {
                play()
            }
        case let .online(url):
            if let transcodeURL = resolutionHandler.currentUrl {
                bindAction?(.playDirectUrl(url: transcodeURL))
            } else {
                var newURL = url
                if let extra = videoInfo.authExtra {
                    newURL = url.docs.addEncodeQuery(parameters: ["extra": extra])
                }
                bindAction?(.playDirectUrl(url: newURL.absoluteString))
            }
        }
        // 开始播放禁用屏幕常亮
        disableScreenIdle()
        subscribeFollowSubject()
    }

    func setupVideoEngineV2(appState: UIApplication.State) {
        engine.delegate = self
        disableScreenIdle()
        subscribeFollowSubject()
    }

    private func setupVideoEngineURL() {
        guard didSetupEngine == false else { return }
        DocsLogger.driveInfo("videoPlayer: setupVideoEngineURL")
        switch videoInfo.type {
        case let .local(url):
            engine.setup(cacheUrl: url.pathURL, shouldPlayForCover: false)
        case let .online(url):
            let taskKey = self.resolutionHandler.taskKey
            if let transcodeURL = resolutionHandler.currentUrl {
                self.engine.setup(directUrl: transcodeURL, taskKey: taskKey, shouldPlayForCover: false)
            } else {
                var newURL = url
                if let extra = videoInfo.authExtra {
                    newURL = url.docs.addEncodeQuery(parameters: ["extra": extra])
                }
                self.engine.setup(directUrl: newURL.absoluteString, taskKey: taskKey, shouldPlayForCover: false)
            }
        }

        didSetupEngine = true
    }

    func setup(directUrl: String, taskKey: String, autoPlay: Bool) {
        engine.setup(directUrl: directUrl, taskKey: taskKey, shouldPlayForCover: !autoPlay)
        didSetupEngine = true
        if autoPlay {
            play()
        }
    }

    func play() {
        setupVideoEngineURL()
        guard let mutex = mediaMutex else {
            DocsLogger.error("media mutex not init")
            doPlay()
            return
        }
        mutex.tryLock(scene: .ccmPlay, mixWithOthers: true, mute: true, observer: self, interruptResult: {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                DocsLogger.driveInfo("media resource lock success")
                self.doPlay()
            case let .occupiedByOther(msg):
                DocsLogger.driveInfo("media resource occupied by other \(String(describing: msg))")
                guard let msg = msg else {
                    self.doPlay()
                    return
                }
                self.bindAction?(.showInterruption(msg: msg))
            case .unknown, .sceneNotFound:
                DocsLogger.driveInfo("media resource occupied by other \(result)")
                self.doPlay()
            }
        })

    }

    func pause() {
        doPause()
        mediaMutex?.unlock(scene: .ccmPlay, observer: self)
    }

    private func doPlay() {
        enterDriveVideo()
        engine.play()
        disableScreenIdle()
        postNotification()
    }
    private func addObserverPlayingNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(didStartPlaying(notify:)), name: Self.startPlaying, object: nil)
    }
    private func postNotification() {
        let info: [String: Any] = [
            "fromCardMode": isFromCardMode,
            "id": identifier
        ]
        NotificationCenter.default.post(name: Self.startPlaying, object: nil, userInfo: info)
    }

    @objc
    private func didStartPlaying(notify: Notification) {
        guard let info = notify.userInfo as? [String: Any] else {
            DocsLogger.driveInfo("receive notification without userinfo")
            return
        }
        guard let fromCardMode = info["fromCardMode"] as? Bool, let id = info["id"] as? String else {
            DocsLogger.driveInfo("receive notification userinfo has no id and fromCardMode")
            return
        }
        if fromCardMode && id != self.identifier {
            self.pause()
        }
    }

    private func doPause() {
        engine.pause()
        resetScreenIdle()
        leaveDriveVideo()
    }

    func onViewWillAppear() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        engine.addRemoteCommandObserverIfNeeded()
        _replayIfNeeded()
    }

    func onViewWillDisappear() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        engine.removeRemoteCommandObserverIfNeeded()
        _pauseIfNeeded()
    }

    func onVCDeinit() {
        resetScreenIdle() // 恢复屏幕初始的常亮状态
        engine.removeTimeObserver()
        engine.stop()
        engine.close()
        leaveDriveVideo()
    }
}

extension DriveVideoPlayerViewModel {
    @objc
    private func didEnterBackground() {
        if engine.mediaType == .video {
            _pauseIfNeeded()
        }
    }

    @objc
    private func willEnterForeground() {
        if engine.mediaType == .video {
            _replayIfNeeded()
        }
    }

    private func _pauseIfNeeded() {
        if engine.playbackState == .playing {
            pause()
            shouldAutoReplay = true
        } else {
            shouldAutoReplay = false
        }
    }

    private func _replayIfNeeded() {
        if engine.playbackState == .paused && shouldAutoReplay {
            play()
        }
    }

    /// 初始化播放器后，是否需要自动开始播放
    func shouldAutoPlayForSetup(appState: UIApplication.State) -> Bool {
        // 非卡片模式和 App 处于活跃状态下才自动开始播放
        var shouldAutoPlay = displayMode == .normal && appState == .active
        if self.isInVCFollow {
            // VCFollow 下打开附件，视频不自动播放，与 PC 端同步
            shouldAutoPlay = false
        }
        return shouldAutoPlay
    }
}

// MARK: - AudioSessionScenario & ScreenIdle
extension DriveVideoPlayerViewModel {
    static let audioQueue = DispatchQueue(label: "DriveAudioSessionScenarioQueue", qos: .userInteractive)

    func enterDriveVideo() {
        guard !isRuningVC else {
            DocsLogger.driveInfo("Video conference is running")
            return
        }
        DriveVideoPlayerViewModel.audioQueue.async {
            self.mediaMutex?.enterDriveAudioSessionScenario(scene: .ccmPlay, id: self.identifier)
        }
    }

    func leaveDriveVideo() {
        guard !isRuningVC else {
            DocsLogger.driveInfo("Video conference is running")
            return
        }
        DriveVideoPlayerViewModel.audioQueue.async {
            self.mediaMutex?.leaveDriveAudioSessionScenario(scene: .ccmPlay, id: self.identifier)
        }
    }

    private func disableScreenIdle() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    private func resetScreenIdle() {
        UIApplication.shared.isIdleTimerDisabled = intailIdleState
    }
}

// MARK: - DriveVideoPlayerDelegate
extension DriveVideoPlayerViewModel: DriveVideoPlayerDelegate {

    func videoPlayerPrepared(_ videoEngine: DriveVideoPlayer) {
        playerStatus.onNext(.prepared)
        followAPIDelegate?.followDidReady()
    }

    func videoPlayerDidFinish(_ videoEngine: DriveVideoPlayer) {
        playerStatus.onNext(.finished)
    }

    func videoPlayerPlayFail(_ videoEngine: DriveVideoPlayer, error: Error?, localPath: URL?) {
        var extraInfo: [String: Any] = [:]
        if let err = error as NSError? {
            var codec = "unknown"
            if let url = localPath, let videoCodec = SKFilePath(absUrl: url).getVideoCodecType() {
                codec = videoCodec
            }
            extraInfo["error_message"] = "\(err.localizedDescription): code(\(err.code)) codec: \(codec)"
        }
        DocsLogger.driveInfo("videoPlayer failed: \(extraInfo)")
        playerStatus.onNext(.failed(info: extraInfo))
    }

    func videoPlayer(_ videoPlayer: DriveVideoPlayer, playbackStateDidChanged playbackState: DriveVideoPlaybackState) {
        self.playbackState.accept(playbackState)
    }

    func videoPlayer(_ videoPlayer: DriveVideoPlayer, loadStateDidChanged loadState: DriveVideoLoadState) {
        playerLoadStateChanged.onNext(loadState)
    }

    func videoPlayer(_ videoPlayer: DriveVideoPlayer, currentPlaybackTime time: TimeInterval, duration: TimeInterval) {
        currentPlaybackTime.accept(time)
    }
}

// MARK: - VCFollow
extension DriveVideoPlayerViewModel: FollowableContent {

    var followModuleStateObservable: Observable<FollowModuleState> {
        return Observable
            .combineLatest(playbackState, currentPlaybackTime.distinctUntilChanged())
            .compactMap { [weak self] playbackState, playbackTime in
                guard let self = self else { return nil }
                return self.convertToFollowModuleState(playbackState: playbackState,
                                                playbackTime: playbackTime)
            }
    }

    func setup(followDelegate: DriveFollowAPIDelegate, mountToken: String?) {
        self.followAPIDelegate = followDelegate
        self.followMountToken = mountToken
        self.followAPIDelegate?.register(followContent: self)
    }

    func registerFollowableContent() {
        followAPIDelegate?.register(followContent: self)
    }

    private func subscribeFollowSubject() {
        videoFollowStateSubject
            .distinctUntilChanged {
                // 仅针对播放中的状态 distinct
                if $1.status == .playing {
                    return $0.currentTime == $1.currentTime
                }
                return false
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.setFollowState(state)
        }).disposed(by: disposeBag)
    }

    private func setFollowState(_ state: DriveMediaFollowState) {
        guard !isGlitchVideoState(state) else { return }
        setVideoStatus(state.status)
        DocsLogger.driveDebug("setFollowState time: \(state.currentTime), status: \(state.status)", category: "VCFollow")
        if shouldSeekProgress(state: state) {
            guard engine.duration > 0 else { return }
            var progress = state.currentTime / engine.duration
            progress = progress > 1 ? 1 : progress
            DocsLogger.driveDebug("setFollowState progress: \(progress)", category: "VCFollow")
            engine.seek(progress: Float(progress)) { [weak self] _ in
                guard let self = self else { return }
                if self.isTimeAboutFinished(progress: progress, currentTime: state.currentTime) {
                    // 如果播放进度快见底了，直接设置停止播放，避免时长不一致导致重新开始播放
                    self.setVideoStatus(.ended)
                } else {
                    self.setVideoStatus(state.status)
                }
            }
        }
        previousPlayingTime = state.currentTime
    }

    private func setVideoStatus(_ status: DriveMediaFollowState.VideoStatus) {
        switch status {
        case .playing:
            self.play()
        case .paused:
            self.pause()
        case .ended, .notStarted:
            self.pause()
            self.playerStatus.onNext(.finished)
        }
    }

    private func shouldSeekProgress(state: DriveMediaFollowState) -> Bool {
        // 避免播放时频繁 seekProgress 导致视频卡帧，前后变化大于等于 1.5 秒内容才 seekProgress
        if abs(state.currentTime - previousPlayingTime) >= 1.5 || previousPlayingTime == 0 || state.status != .playing {
            return true
        } else {
            return false
        }
    }

    /// 判断是否错误视频状态（比如切换分辨率时，VideoPlayer 出现 end 的状态，但是进度不对）
    private func isGlitchVideoState(_ state: DriveMediaFollowState) -> Bool {
        let timeGap = abs(engine.duration - state.currentTime)
        // 播放状态为 end，且 currentTime 与结束时间相差过大
        return state.status == .ended && timeGap > 1.5
    }

    /// 判断播放进度是否即将结束
    private func isTimeAboutFinished(progress: Double, currentTime: Double) -> Bool {
        let gap = abs(engine.duration - currentTime)
        return progress > 0.95 && gap < 1
    }

    private func monitorStateChanged() {
        followModuleStateObservable
            .throttle(DispatchQueueConst.MilliSeconds_500, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] moduleState in
                guard let self = self else { return }
                self.followContentDelegate?.onContentEvent(.stateChanged(moduleState), at: self.followMountToken)
        }).disposed(by: disposeBag)
    }

    private func convertToFollowModuleState(playbackState: DriveVideoPlaybackState,
                                            playbackTime: TimeInterval) -> FollowModuleState {
        let status = playbackState.followStatus
        let videoState = DriveMediaFollowState(status: status, currentTime: playbackTime, recordId: self.followMountToken ?? "")
        return videoState.followModuleState
    }

    // MARK: - FollowableContent
    var moduleName: String {
        return DriveMediaFollowState.module
    }

    func onSetup(delegate: FollowableContentDelegate) {
        guard followContentDelegate == nil else { return }
        self.followContentDelegate = delegate
        monitorStateChanged()
    }

    func setState(_ state: FollowModuleState) {
        guard let mediaState = DriveMediaFollowState(followModuleState: state) else {
            return
        }
        videoFollowStateSubject.onNext(mediaState)
    }

    func getState() -> FollowModuleState? {
        return convertToFollowModuleState(playbackState: playbackState.value,
                                          playbackTime: currentPlaybackTime.value)
    }

    func updatePresenterState(_ state: FollowModuleState?) {}
}

extension DriveVideoPlayerViewModel: SKMediaResourceInterruptionObserver {
    func mediaResourceInterrupted(with msg: String?) {
        DocsLogger.driveInfo("media resource interrupted \(String(describing: msg))")
        DispatchQueue.main.async {
            self.doPause()
        }
    }
    func meidaResourceInterruptionEnd() {
        DocsLogger.driveInfo("media resource interrupted end")
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250, qos: .userInteractive) {
            if self.engine.mediaType != .audio {
                self.play()
            }
        }
    }

    var observerIdentifier: String {
        return identifier
    }
}

extension DriveVideoPlaybackState {
    var followStatus: DriveMediaFollowState.VideoStatus {
        switch self {
        case .stopped, .paused:
            return .paused
        case .playing:
            return .playing
        case .error:
            return .notStarted
        }
    }
}
