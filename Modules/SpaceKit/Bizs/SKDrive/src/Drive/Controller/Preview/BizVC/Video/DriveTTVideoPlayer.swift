//
//  DriveTTVideoPlayer.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/1/14.
//

import TTVideoEngine
import SKCommon
import SKFoundation
import SKUIKit
import UniverseDesignColor
import SKInfra
import LarkStorage
import LarkContainer
import LarkVideoDirector

class DriveTTVideoPlayer: NSObject {

    private let DRIVE_VIDEO_PLAYER_TAG = "docs"
    private let DRIVE_VIDEO_PLAYER_SUBTAG = "video"

    private var userResolver: UserResolver {
        Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
    }

    /// 记录停止播放后，重新seek时的播放位置，并调用setCurrentPlaybackTime函数
    /// 踩坑：engine设置play之后，state不会马上改变，这时如果调用setCurrentPlaybackTime，由于state仍然是stop，所以不起作用
    ///      当state收到改变成playing的回调时，再去做setCurrentPlaybackTime的操作，在特定的时间点进行播放。
    private var replayFromStopping: (() -> Void)?

    weak var delegate: DriveVideoPlayerDelegate?

    private var enableLarkPlayerKit: Bool = false
    private lazy var engine: TTVideoEngine = {
        DocsLogger.driveInfo("TTPlayer -- enable LarkPlayerKit: \(enableLarkPlayerKit)")
        if enableLarkPlayerKit {
            // For more information of 'tag' and 'subtag', please see:
            //   https://bytedance.feishu.cn/docx/doxcnGtf1KqHXaYECo3TwUb029i
            //   https://bytedance.feishu.cn/wiki/WT0ZwHHl9iXG41kfoTJcYLlFnRe
            return LarkPlayerKit.buildEngine(
                userResolver: userResolver,
                tag: DRIVE_VIDEO_PLAYER_TAG,
                subTag: DRIVE_VIDEO_PLAYER_SUBTAG
            )
        }
        return TTVideoEngine(ownPlayer: true)
    }()

    private var videoHeight: Double?
    private var videoWidth: Double?
    private var localURL: URL?

    private var isResuming: Bool = false
    private var resumingTime: TimeInterval = 0.0
    // 是否是首次prepare
    private var isFirstPrepare: Bool = true
    // 是否首次为了获取视频首帧封面而开始的播放
    private var isPlayForCover: Bool = false
    private let enablePlayForCover = UserScopeNoChangeFG.ZYP.ttVideoPlayForCoverEnable

    private let TTVideoCPUNumber = 16

    override init() {
        super.init()
        enableLarkPlayerKit = (UserScopeNoChangeFG.CWJ.enableLarkPlayerKit &&
                               LarkPlayerKit.isEnabled(userResolver: userResolver))
        setupVideoEngineIfNeeded()
    }

    private func setupVideoEngineIfNeeded() {
        if !enableLarkPlayerKit {
            // 添加tag，用于区分业务 https://bytedance.feishu.cn/docx/doxcnGtf1KqHXaYECo3TwUb029i
            engine.setOptions([
                VEKKeyType(value: VEKKey.VEKKeyLogTag_NSString.rawValue): DRIVE_VIDEO_PLAYER_TAG,
                VEKKeyType(value: VEKKey.VEKKeyLogSubTag_NSString.rawValue): DRIVE_VIDEO_PLAYER_SUBTAG,
                VEKKeyType(value: VEKKey.VEKKeyViewScaleMode_ENUM.rawValue): TTVideoEngineScalingMode.aspectFit.rawValue,
                VEKKeyType(value: VEKKey.VEKKeyViewRenderEngine_ENUM.rawValue): TTVideoEngineRenderEngine.metal.rawValue,
                VEKKeyType(value: VEKKey.VEKKeyPlayerPreferNearestSampleEnable.rawValue): 1,
                VEKKeyType(value: VEKKey.VEKKeyPlayerPreferNearestMaxPosOffset.rawValue): 100 * 1024 * 1024,
                VEKKeyType(value: VEKKey.VEKKeyPlayerEnableDemuxNonBlockRead_BOOL.rawValue): true,
                VEKKeyType(value: VEKKey.VEKKeyPlayerCacheMaxSeconds_NSInteger.rawValue): 360,
            ])

            if DriveFeatureGate.ttVideoOutletThreadOptimizeEnable {
                DocsLogger.driveInfo("TTPlayer -- ttVideoOutletThreadOptimizeEnable")
                engine.setOptions([
                    VEKKeyType(value: VEKKey.VEKKeyOutletThreadOptimize_NSInteger.rawValue): TTVideoCPUNumber, // TTVideo 的 outlet 线程 CPU 占用优化
                ])
            }

            if !TTVideoEngine.ls_isStarted() {
                DocsLogger.driveInfo("TTPlayer -- start local service")
                TTVideoEngine.ls_start()
            }
        }
    }

    private func setupPlayerVideoInfo(_ url: String, taskKey: String) {
        // 无网默认开启才能使用token读取缓存，这个时候videoInfo也为空
        engine.proxyServerEnable = DocsNetStateMonitor.shared.isReachable
        DocsLogger.driveInfo("TTPlayer -- task key: \(taskKey)")
        setupVideoEngineURL(url, taskKey: taskKey)
        setupEngineCustomHeader()
    }

    private func _replayFromStopping() {
        if let replay = replayFromStopping {
            replay()
            replayFromStopping = nil
        }
    }

    private func setupVideoEngineURL(_ url: String, taskKey: String) {
        if TTVideoEngine.ls_isStarted() {
            engine.ls_setDirectURL(url, key: taskKey)
        } else {
            engine.setDirectPlayURL(url)
        }
    }

    private func playWithCachedFile(_ cacheURL: URL) {
        localURL = cacheURL
        engine.setLocalURL(cacheURL.absoluteString)
    }

    private func logEnable() -> Bool {
        #if DEBUG
        return true
        #else
        return OpenAPI.docs.driveVideoLogEnable
        #endif
    }

    private func logFlag() -> TTVideoEngineLogFlag {
        logEnable() ? [.all] : []
    }

    private func setupEngineCustomHeader() {
        let cookiesString = NetConfig.shared.cookies()?.cookieString ?? ""
        if cookiesString.isEmpty {
            spaceAssertionFailure("Drive Video SDK no cookies")
        }
        engine.setCustomHeaderValue(cookiesString, forKey: "cookie")
        if SKFoundationConfig.shared.isPreReleaseEnv {
            engine.setCustomHeaderValue("Pre_release", forKey: "env")
        }
        
        if SKFoundationConfig.shared.isStagingEnv, let ttEnv = KVPublic.Common.ttenv.value() {
            engine.setCustomHeaderValue(ttEnv, forKey: "x-tt-env")
        }
    }
}

extension DriveTTVideoPlayer: DriveVideoPlayer {
    func addRemoteCommandObserverIfNeeded() {
        // No need to implement
    }

    func removeRemoteCommandObserverIfNeeded() {
        // No need to implement
    }

    var mediaType: DriveMediaType {
        // 头条播放器不用做音频播放
        return .video
    }

    var isLandscapeVideo: Bool {
        if let height = videoHeight, let width = videoWidth {
            // ipad不处理
            if height != 0, width / height > Double(4.0 / 3.0), !SKDisplay.pad {
                return true
            } else {
                return false
            }
        } else {
            spaceAssertionFailure("未取到视频宽高信息，默认竖视频")
            return false
        }
    }

    var muted: Bool {
        get {
            return engine.muted
        }
        set {
            engine.muted = newValue
        }
    }

    var playbackState: DriveVideoPlaybackState {
        switch self.engine.playbackState {
        case .stopped:
            return .stopped
        case .playing:
            return .playing
        case .paused:
            return .paused
        case .error:
            return .error
        @unknown default:
            return .error
        }
    }

    var currentPlaybackTime: Double {
        return self.engine.currentPlaybackTime
    }

    var duration: Double {
        return self.engine.duration
    }

    func setup(cacheUrl url: URL, shouldPlayForCover: Bool) {
        _setupEngine()
        playWithCachedFile(url)
        if enablePlayForCover {
            isPlayForCover = shouldPlayForCover
            if shouldPlayForCover {
                engine.muted = true
                engine.play()
                DocsLogger.driveInfo("TTPlayer -- setup cacheUrl play for cover")
            }
        } else {
            engine.prepareToPlay()
        }
    }

    func setup(directUrl url: String, taskKey: String, shouldPlayForCover: Bool) {
        _setupEngine()
        setupPlayerVideoInfo(url, taskKey: taskKey)
        if enablePlayForCover {
            // 在卡片模式下不自动播放，需要开始播放后获取到第一帧数据后暂停，为了不出现声音，需要先静音
            isPlayForCover = shouldPlayForCover
            if shouldPlayForCover {
                engine.muted = true
                engine.play()
                DocsLogger.driveInfo("TTPlayer -- setup directUrl play for cover")
            }
        } else {
            engine.prepareToPlay()
        }

    }

    private func _setupEngine() {
        TTVideoEngine.setLogFlag(logFlag())
        engine.proxyServerEnable = true
        engine.playerView.backgroundColor = UIColor.ud.N900.nonDynamic
        engine.hardwareDecode = true
        engine.delegate = self
        engine.cacheEnable = false
        engine.addPeriodicTimeObserver(forInterval: 1.0, queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            // 避免 debug 下太频繁打印，有需要自行打开
            // DocsLogger.driveDebug("TTPlayer - currentPlayback: \(self.engine.currentPlaybackTime)")
            var currentTime = self.engine.currentPlaybackTime
            if self.isResuming {
                self.isResuming = false
                currentTime = self.resumingTime
                self.resumingTime = 0.0
                self.delegate?.videoPlayer(self, currentPlaybackTime: currentTime, duration: self.engine.duration)
            }
            // TTVideo 在暂停情况下，某些视频的 currentPlaybackTime 会继续更新，这里限制在 Playing 情况下才更新
            if self.engine.playbackState == .playing {
                self.delegate?.videoPlayer(self, currentPlaybackTime: currentTime, duration: self.engine.duration)
            }
        }
    }

    func resume(_ url: String, taskKey: String) {
        let currentTime = self.engine.currentPlaybackTime
        self.resumingTime = currentTime
        self.isResuming = true
        self.engine.stop()
        self.engine.proxyServerEnable = true
        self.setupVideoEngineURL(url, taskKey: taskKey)
        setupEngineCustomHeader()
        self.engine.play()
        replayFromStopping = { [weak self] in
            self?.engine.setCurrentPlaybackTime(currentTime, complete: { _ in })
        }
    }

    func removeTimeObserver() {
        self.engine.removeTimeObserver()
    }

    func close() {
        DocsLogger.driveInfo("TTPlayer - execute close")
        self.engine.close()
    }

    var playerView: UIView {
        return self.engine.playerView
    }

    func play() {
        DocsLogger.driveInfo("TTPlayer - execute play")
        self.engine.play()
    }

    func stop() {
        DocsLogger.driveInfo("TTPlayer - execute stop")
        self.engine.stop()
    }

    func pause() {
        DocsLogger.driveInfo("TTPlayer - execute pause")
        self.engine.pause()
    }

    func seek(progress: Float, completion: ((Bool) -> Void)?) {
        let currentPlaybackTime = Double(progress) * engine.duration
        if engine.playbackState == .stopped {
            replayFromStopping = { [weak self] in
                self?.engine.setCurrentPlaybackTime(currentPlaybackTime, complete: completion ?? { _ in })
            }
            play()
        } else {
            engine.setCurrentPlaybackTime(currentPlaybackTime, complete: completion ?? { _ in })
        }
        if engine.playbackState == .paused {
            // 主动调整进度时，且是暂停状态下主动更新 currentPlaybackTime
            delegate?.videoPlayer(self, currentPlaybackTime: currentPlaybackTime, duration: self.engine.duration)
        }
    }
}

extension DriveTTVideoPlayer: TTVideoEngineDelegate {
    func videoEnginePrepared(_ videoEngine: TTVideoEngine) {
        guard isFirstPrepare else { return }
        isFirstPrepare = false
        self.videoHeight = self.engine.getOptionBykey(VEKKeyType(value: VEKGetKey.playerVideoHeight_NSInteger.rawValue)) as? Double
        self.videoWidth = self.engine.getOptionBykey(VEKKeyType(value: VEKGetKey.playerVideoWidth_NSInteger.rawValue)) as? Double
        DocsLogger.driveInfo("TTPlayer - videoPlayerPrepared")
        delegate?.videoPlayerPrepared(self)
    }

    func videoEngineUserStopped(_ videoEngine: TTVideoEngine) {

    }

    func videoEngineDidFinish(_ videoEngine: TTVideoEngine, error: Error?) {
        if let error = error {
            DocsLogger.driveError("video finish error \(error)")
            delegate?.videoPlayerPlayFail(self, error: error, localPath: localURL)
        } else {
            delegate?.videoPlayerDidFinish(self)
            DocsLogger.driveInfo("TTPlayer - videoEngineDidFinish")
        }
    }

    func videoEngineDidFinish(_ videoEngine: TTVideoEngine, videoStatusException status: Int) {}

    func videoEngineCloseAysncFinish(_ videoEngine: TTVideoEngine) {}

    func videoEngine(_ videoEngine: TTVideoEngine, playbackStateDidChanged playbackState: TTVideoEnginePlaybackState) {
        switch playbackState {
        case .playing:
            _replayFromStopping()
            if isPlayForCover && enablePlayForCover {
                // 播放获取封面，无需对外发出更新 playbackState 事件
                pause()
                engine.muted = false
                isPlayForCover = false
            } else {
                delegate?.videoPlayer(self, playbackStateDidChanged: .playing)
            }
        case .stopped:
            DocsLogger.driveInfo("TTPlayer - stopped")
            delegate?.videoPlayer(self, playbackStateDidChanged: .stopped)
        case .paused:
            DocsLogger.driveInfo("TTPlayer - paused")
            delegate?.videoPlayer(self, playbackStateDidChanged: .paused)
        case .error:
            delegate?.videoPlayer(self, playbackStateDidChanged: .error)
        @unknown default:
            break
        }
    }

    func videoEngine(_ videoEngine: TTVideoEngine, loadStateDidChanged loadState: TTVideoEngineLoadState) {
        switch loadState {
        case .playable:
            delegate?.videoPlayer(self, loadStateDidChanged: .playable)
        case .stalled:
            delegate?.videoPlayer(self, loadStateDidChanged: .stalled)
        case .unknown:
            delegate?.videoPlayer(self, loadStateDidChanged: .unknown)
        case .error:
            delegate?.videoPlayer(self, loadStateDidChanged: .error)
        @unknown default:
            break
        }
    }

    func videoEngine(_ videoEngine: TTVideoEngine, mdlKey key: String, hitCacheSze cacheSize: Int) {
        DocsLogger.driveInfo("TTPlayer did hit cache", extraInfo: ["mdlKey": key, "cacheSize": cacheSize])
    }
}
