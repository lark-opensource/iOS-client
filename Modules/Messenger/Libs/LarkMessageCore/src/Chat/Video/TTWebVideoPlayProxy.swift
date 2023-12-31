//
//  TTWebVideoPlayProxy.swift
//  LarkChat
//
//  Created by zc09v on 2019/6/5.
//

import UIKit
import Foundation
import TTVideoEngine
import LarkVideoDirector
import LarkUIKit
import Reachability
import RxSwift
import LKCommonsLogging
import LarkCore
import LarkSDKInterface
import LarkStorage
import LarkFeatureGating
import LarkMessengerInterface
import LarkSetting
import LarkContainer
import UniverseDesignToast
import LarkAccountInterface
import LKCommonsTracker
import LarkMonitor
import LarkMedia
import UniverseDesignDialog
import EENavigator

public final class TTWebVideoPlayProxy: NSObject, LKVideoDisplayViewProxy, UserResolverWrapper {
    static let logger = Logger.log(TTWebVideoPlayProxy.self, category: "Module.TTWebVideoPlayProxy")

    public var delegate: LKVideoDisplayViewProxyDelegate? {
        didSet {
            self.delegate?.connection = self.convert(connection: self.reach?.connection)
        }
    }
    public let userResolver: UserResolver
    private lazy var videoEngine: TTVideoEngine = {
        if useLarkPlayerKit {
            return LarkPlayerKit.buildEngine(userResolver: userResolver, tag: "IM", subTag: "asset_browser")
        }
        return LarkVideoEngine.videoEngine(settingService: self.userResolver.settings)
    }()
    private var useLarkPlayerKit = false
    private let reach: Reachability? = Reachability()
    private let disposeBag = DisposeBag()
    private let videoApi: VideoAPI
    private let downloadPath: IsoPath
    //外部设置的url不能直接用于播放(第三方视频网站不会直接暴露播放地址)，需要通过接口反解
    private var needFetchPlayUrl: Bool = true
    //外部设置的url
    private var directPlayUrl: String?
    /// 性能埋点信息
    private var powerLogSession: BDPowerLogSession?
    // 下载 toast
    private var downloadToast: UDToast?
    public var playerView: UIView {
        return videoEngine.playerView
    }

    private lazy var audioQueue = DispatchQueue(label: "web.video.proxy.queue", qos: .userInteractive)

    public var preparedCallBack: ((TTWebVideoPlayProxy) -> Void)?

    private lazy var badAVUsePreloadEnable: Bool = {
        let fg = self.userResolver.fg
        return fg.staticFeatureGatingValue(with: "bad_av_use_preload")
    }()

    private let maxCacheSize = 200 * 1024 * 1024

    // 用于标记是否已经开始性能埋点
    private var isInPowerEvent = false

    deinit {
        videoEngine.removeTimeObserver()
        reach?.stopNotifier()
    }
    @ScopedInjectedLazy private var passportService: PassportUserService?

    public init(videoApi: VideoAPI, downloadPath: IsoPath, userResolver: UserResolver) {
        self.downloadPath = downloadPath
        self.videoApi = videoApi
        self.userResolver = userResolver
        super.init()
        useLarkPlayerKit = LarkPlayerKit.isEnabled(userResolver: userResolver)
        videoEngine.delegate = self
        videoEngine.dataSource = self

        if !useLarkPlayerKit {
            // 添加视频 tag 配置为 IM
            videoEngine.setOptionForKey(VEKKey.VEKKeyLogTag_NSString.rawValue, value: "IM")
            // 添加视频 subTag 配置为 web_video
            videoEngine.setOptionForKey(VEKKey.VEKKeyLogSubTag_NSString.rawValue, value: "web_video")
            // 添加 CompanyID 为当前租户 ID
            videoEngine.setCustomCompanyID(passportService?.userTenant.tenantID ?? "")

            //无网默认开启才能使用token读取缓存
            videoEngine.proxyServerEnable = true
            videoEngine.cacheEnable = true
        }
        videoEngine.addPeriodicTimeObserver(forInterval: 1, queue: DispatchQueue.main) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.set(
                currentPlaybackTime: self.videoEngine.currentPlaybackTime,
                duration: self.videoEngine.duration,
                playableDuration: self.videoEngine.playableDuration)
        }
        reach?.whenReachable = { [unowned self] _ in
            self.delegate?.connection = self.convert(connection: self.reach?.connection)
        }
        try? reach?.startNotifier()
    }

    public func setLocalURL(_ localUrl: String) {
    }

    public func setDirectPlayURL(_ directPlayUrl: String) {
        TTWebVideoPlayProxy.logger.info("web video proxy set url")
        self.directPlayUrl = directPlayUrl
    }

    public func play(_ isMuted: Bool) {
        guard let directPlayUrl = directPlayUrl else {
            TTWebVideoPlayProxy.logger.error("未设置视频播放地址")
            return
        }
        func startPlay() {
            TTWebVideoPlayProxy.logger.info("web video proxy start play")
            self.changeAudioSessionActive(active: true) { [weak self] in
                self?.videoEngine.muted = isMuted
                self?.videoEngine.play()
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        // 先检测是否可以播放
        func tryStartPlay() {
            TTWebVideoPlayProxy.logger.info("web video proxy try Lock")
            LarkMediaManager.shared.tryLock(scene: .imVideoPlay, options: .mixWithOthers, observer: self) { [weak self] (result) in
                Self.execInMainThread {
                    switch result {
                    case .success:
                        startPlay()
                    case .failure(let error):
                        TTWebVideoPlayProxy.logger.error("web video proxy try Lock failed \(error)")
                        if case let MediaMutexError.occupiedByOther(context) = error {
                            if let msg = context.1 {
                                self?.showMediaLockAlert(msg: msg)
                            }
                            self?.delegate?.videoPlayDidFinish(state: .valid)
                            return
                        } else {
                            startPlay()
                        }
                    }
                }
            }
        }

        if needFetchPlayUrl {
            TTWebVideoPlayProxy.logger.info("web video proxy start fetch video url")
            self.videoApi.fetchVideoSourceUrl(url: directPlayUrl)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (playUrl) in
                    guard let self = self else { return }
                    self.needFetchPlayUrl = false
                    let fileKey = self.cacheKey(for: directPlayUrl)
                    /// 开启预加载引擎
                    if !TTVideoEngine.ls_isStarted() {
                        TTVideoEngine.ls_start()
                    }
                    self.videoEngine.ls_setDirectURL(playUrl, key: fileKey)
                    TTWebVideoPlayProxy.logger.info("set video url success key \(fileKey) and ready to play")
                    tryStartPlay()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.delegate?.videoPlayDidFinish(state: .fetchFail(error))
                    TTWebVideoPlayProxy.logger.error("视频原始播放地址获取失败 \(directPlayUrl)", error: error)
                }).disposed(by: self.disposeBag)
        } else {
            tryStartPlay()
        }
    }

    public func pause() {
        TTWebVideoPlayProxy.logger.info("web video proxy pause")
        videoEngine.pause()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    public func stop() {
        TTWebVideoPlayProxy.logger.info("web video proxy stop")
        videoEngine.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        self.changeAudioSessionActive(active: false, callBack: nil)
        LarkMediaManager.shared.unlock(scene: .imVideoPlay)
    }

    public func seekVideoProcess(_ process: Float, complete: @escaping (Bool) -> Void) {
        let currentPlaybackTime = Double(process) * videoEngine.duration
        TTWebVideoPlayProxy.logger.info("web proxy set seek process \(process) currentPlaybackTime \(currentPlaybackTime) videoEngine.duration \(videoEngine.duration)")
        if (videoEngine.duration - currentPlaybackTime) <= 2 {
            // 视频拖动到2s以内，直接完成播放
            videoEngine.stop()
            delegate?.videoPlayDidFinish(state: .valid)
        } else {
            videoEngine.setCurrentPlaybackTime(currentPlaybackTime, complete: { (result) in
                TTWebVideoPlayProxy.logger.info("web proxy set seek process \(process) currentPlaybackTime \(currentPlaybackTime)  did completed")
                complete(result)
            })
        }
    }

    public func retryFetchVideo() {
        TTWebVideoPlayProxy.logger.info("web video proxy retryFetchVideo")
        self.delegate?.retryPlay()
    }

    /// TTVideoEngine is not thread safe, need be called in main thread
    /// This method change audioSession in async queue and callback in main thread
    /// - Parameters:
    ///   - active: active or not active audioSession in async queue
    ///   - callBack: callback block in main thread
    private func changeAudioSessionActive(active: Bool, callBack: (() -> Void)?) {
        self.audioQueue.async {
            if let audioSession = LarkMediaManager.shared.getMediaResource(for: .imVideoPlay)?.audioSession {
                if active {
                    audioSession.enter(.previewAsset)
                } else {
                    audioSession.leave(.previewAsset)
                }
            }
            DispatchQueue.main.async {
                callBack?()
            }
        }
    }

    private func convert(connection: Reachability.Connection?) -> LKVideoConnection {
        guard let connection else { return .none }
        switch connection {
        case .wifi:
            return .wifi
        case .cellular:
            return .cellular
        case .none:
            return .none
        @unknown default:
            assert(false, "new value")
            return .none
        }
    }

    // 用于 ttVideoEngine cache
    private func cacheKey(for videoURL: String) -> String {
        return videoURL.kf.md5
    }

    @objc
    func showDownloadToast() {
        guard self.badAVUsePreloadEnable else {
            return
        }
        // 获取当前进度
        let currentPlaybackTime = self.videoEngine.currentPlaybackTime
        TTWebVideoPlayProxy.logger.info("show download toast, currentPlaybackTime \(currentPlaybackTime)")
        self.videoEngine.stop()
        guard let vc = self.findController(view: self.playerView) else {
            TTWebVideoPlayProxy.logger.error("cannot find vc")
            return
        }
        guard self.downloadToast == nil else {
            TTWebVideoPlayProxy.logger.error("downloadToast is not")
            return
        }

        if let directPlayUrl = directPlayUrl {
            let fileKey = cacheKey(for: directPlayUrl)
            TTWebVideoPlayProxy.logger.info("add preload task \(fileKey) current cacheSize \(TTVideoEngine.ls_getCacheSize(byKey: fileKey))")
            let preloadSize = 1024 * 1024 * 1024
            if let item = TTVideoEnginePreloaderURLItem(key: fileKey, videoId: nil, urls: [directPlayUrl], preloadSize: preloadSize) {
                let dismissBlock = { [weak self] in
                    guard let self = self else { return }
                    self.downloadToast?.remove()
                    self.downloadToast = nil
                }
                self.downloadToast = UDToast.showToast(
                    with: .init(toastType: .loading,
                                text: BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionDownloadVideo,
                                operation: .init(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)),
                    on: vc.view,
                    delay: 100_000,
                    disableUserInteraction: true,
                    operationCallBack: { (_) in
                        TTVideoEngine.ls_cancelTask(byKey: fileKey)
                        dismissBlock()
                    })
                item.preloadEnd = { [weak self] (_, error) in
                    guard let self = self else { return }
                    if let error = error {
                        TTWebVideoPlayProxy.logger.error("preload task failed \(error)")
                        dismissBlock()
                    } else {
                        TTWebVideoPlayProxy.logger.info("preload task end")
                        self.videoEngine.setOptionForKey(VEKKey.VEKKeyPlayerStartTime_CGFloat.rawValue, value: currentPlaybackTime)
                        self.videoEngine.play()
                        dismissBlock()
                        Tracker.post(TeaEvent("download_success_interlaced_video_dev"))
                    }
                }
                item.preloadCanceled = {
                    TTWebVideoPlayProxy.logger.info("preload task cancel")
                    dismissBlock()
                }
                item.preloadDidStart = { _ in
                    TTWebVideoPlayProxy.logger.info("preload task did start")
                }
                DispatchQueue.main.async {
                    TTWebVideoPlayProxy.logger.info("preload task info \(item.preloadSize) \(item.key)")
                    TTVideoEngine.ls_addTask(with: item)
                }
                Tracker.post(TeaEvent("download_interlaced_video_dev"))
            }
        } else {
            TTWebVideoPlayProxy.logger.error("add preload task failed")
        }
    }

    lazy var monitorDelay: TimeInterval = self.getMonitorDelay()

    func getMonitorDelay() -> TimeInterval {
        let delay: TimeInterval
        if let settings = try? self.userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "im_video_player_config")),
          let videoConfig = settings["lark"] as? [String: Any],
          let badAVWaitTime = videoConfig["BAD_AV_WAIT_TIME"] as? TimeInterval {
            // 下发为毫秒,需要转化为秒
            delay = badAVWaitTime / 1000
        } else {
            // 默认配置 5s
            delay = 5
        }
        AssetBrowserVideoPlayProxy.logger.info("getMonitorDelay \(delay)")
        return delay
    }

    lazy var badAVMaxDiff: Double = self.getBadAVDiff()

    func getBadAVDiff() -> Double {
        let badAVDiff: Double
        if let settings = try? self.userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "im_video_player_config")),
          let videoConfig = settings["lark"] as? [String: Any],
          let badAVDiffConfig = videoConfig["BAD_AV_DIFF"] as? Double {
            // 下发为毫秒,需要转化为秒
            badAVDiff = badAVDiffConfig
        } else {
            // 默认配置 5s
            badAVDiff = 150_000
        }
        AssetBrowserVideoPlayProxy.logger.info("get BAD_AV_DIFF  \(badAVDiff)")
        return badAVDiff
    }

    // PowerSession: 在第一次播放视频时开始记录，在 finish / error 时结束记录
    private func startPowerSessionIfNeeded() {
        guard powerLogSession == nil else { return }
        powerLogSession = BDPowerLogManager.beginSession("scene_video_play")
    }

    private func endPowerSessionIfNeeded(_ state: LKVideoPlaybackState) {
        guard let powerLogSession else { return }
        guard [.stopped, .error].contains(state) else { return }
        powerLogSession.addCustomFilter(getPowerParams())
        BDPowerLogManager.end(powerLogSession)
        self.powerLogSession = nil
    }

    // PowerEvent: 在每次播放视频（包括恢复播放）时开始记录，在 paused / finish / error 时结束记录
    private func startPowerEvent() {
        if self.isInPowerEvent {
            return
        }
        self.isInPowerEvent = true

        BDPowerLogManager.beginEvent("messenger_video_play", params: self.getPowerParams())
    }

    private func endPowerEvent(reason: String) {
        if !self.isInPowerEvent {
            return
        }
        self.isInPowerEvent = false
        var params = self.getPowerParams()
        params["reason"] = reason
        BDPowerLogManager.endEvent("messenger_video_play", params: params)
    }

    private func getPowerParams() -> [String: Any] {
        var params: [String: Any] = [:]
        params["isWebVideo"] = 1
        if let directPlayUrl = self.directPlayUrl {
            params["isLocal"] = 0
            params["fileKey"] = directPlayUrl.kf.md5
        }
        return params
    }

    func showMediaLockAlert(msg: String) {
        guard let vc = self.findController(view: self.playerView) else {
            TTWebVideoPlayProxy.logger.error("cannot find vc")
            return
        }
        let dialog = UDDialog()
        dialog.setContent(text: msg)
        dialog.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_Sure)
        self.navigator.present(dialog, from: vc)
    }

    private static func execInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

extension TTWebVideoPlayProxy: TTVideoEngineDelegate {
    public func videoEngineUserStopped(_ videoEngine: TTVideoEngine) {
        TTWebVideoPlayProxy.logger.info("web video proxy videoEngineUserStopped")
        self.delegate?.videoDidStop()
    }

    public func videoEngineDidFinish(_ videoEngine: TTVideoEngine, error: Error?) {
        TTWebVideoPlayProxy.logger.info("web video proxy videoEngineDidFinish error \(error)")
        if let error = error {
            self.needFetchPlayUrl = true
            self.delegate?.videoPlayDidFinish(state: .fetchFail(error))
        } else {
            self.delegate?.videoPlayDidFinish(state: .valid)
        }
    }

    public func videoEngineDidFinish(_ videoEngine: TTVideoEngine, videoStatusException status: Int) {
        TTWebVideoPlayProxy.logger.info("web video proxy videoEngineDidFinish status \(status)")
    }

    public func videoEngineCloseAysncFinish(_ videoEngine: TTVideoEngine) {
        TTWebVideoPlayProxy.logger.info("web video proxy videoEngineCloseAysncFinish")
    }

    public func videoEnginePrepared(_ videoEngine: TTVideoEngine) {
        TTWebVideoPlayProxy.logger.info("web video proxy videoEnginePrepared")
        preparedCallBack?(self)
    }

    public func videoEngineReady(toPlay videoEngine: TTVideoEngine) {
        TTWebVideoPlayProxy.logger.info("web video proxy videoEngineReady")
        self.delegate?.videoReadyToPlay()
    }

    public func videoEngine(_ videoEngine: TTVideoEngine, playbackStateDidChanged playbackState: TTVideoEnginePlaybackState) {
        TTWebVideoPlayProxy.logger.info("web video proxy playbackStateDidChanged playbackState \(playbackState.rawValue)")
        var isPlay = false
        var stopReason = ""

        let state: LKVideoPlaybackState
        switch playbackState {
        case .stopped:
            state = .stopped
            stopReason = "stopped"
        case .playing:
            isPlay = true
            state = .playing
        case .paused:
            state = .paused
            stopReason = "paused"
        case .error:
            state = .error
            stopReason = "error"
        @unknown default:
            state = .error
            stopReason = "error"
        }
        if isPlay {
            self.startPowerEvent()
            startPowerSessionIfNeeded()
        } else {
            self.endPowerEvent(reason: stopReason)
            endPowerSessionIfNeeded(state)
        }
        self.delegate?.videoPlaybackStateDidChanged(state)
        self.stopDownloadMonitorIfNeeded(playbackState: playbackState, loadState: self.videoEngine.loadState)
    }

    public func videoEngine(_ videoEngine: TTVideoEngine, loadStateDidChanged loadState: TTVideoEngineLoadState) {
        TTWebVideoPlayProxy.logger.info("web video proxy loadStateDidChanged loadState \(loadState.rawValue)")
        switch loadState {
        case .playable:
            self.delegate?.videoLoadStateDidChanged(.playable)
        case .stalled:
            self.delegate?.videoLoadStateDidChanged(.stalled)
        default:
            break
        }
        self.stopDownloadMonitorIfNeeded(playbackState: self.videoEngine.playbackState, loadState: loadState)
    }

    public func videoEngine(_ videoEngine: TTVideoEngine, onAVBadInterlaced info: [AnyHashable: Any]?) {
        TTWebVideoPlayProxy.logger.info("asset proxy onAVBadInterlaced \(info)")
        Tracker.post(TeaEvent("player_bad_av_dev", params: ["diff": info?["diff"] ?? 0]))
        guard let diff = info?["diff"] as? Double,
              diff > self.badAVMaxDiff else {
            return
        }
        self.startDownloadMonitor()
    }

    func startDownloadMonitor() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NSObject.cancelPreviousPerformRequests(
                withTarget: self,
                selector: #selector(self.showDownloadToast),
                object: nil
            )
            self.perform(#selector(self.showDownloadToast), with: nil, afterDelay: self.monitorDelay)
        }
    }

    func stopDownloadMonitorIfNeeded(
        playbackState: TTVideoEnginePlaybackState,
        loadState: TTVideoEngineLoadState
    ) {
        if playbackState != .playing || loadState != .stalled {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                NSObject.cancelPreviousPerformRequests(
                    withTarget: self,
                    selector: #selector(self.showDownloadToast),
                    object: nil
                )
            }
        }
    }

    public func videoEngine(_ videoEngine: TTVideoEngine, mdlKey key: String, hitCacheSze cacheSize: Int) {
        TTWebVideoPlayProxy.logger.info("web proxy hit cache size \(cacheSize) key \(key)")
    }

    private func findController(view: UIView) -> UIViewController? {
        guard let next = view.next else {
            return nil
        }
        if let nextView = next as? UIView {
            return findController(view: nextView)
        } else if let nextController = next as? UIViewController {
            return nextController
        }
        return nil
    }
}

extension TTWebVideoPlayProxy: TTVideoEngineDataSource {
    public func networkType() -> TTVideoEngineNetworkType {
        return networkType(from: reach?.connection)
    }

    private func networkType(from connection: Reachability.Connection?) -> TTVideoEngineNetworkType {
        guard let connection else { return .none }
        switch connection {
        case .wifi: return .wifi
        case .cellular: return .notWifi
        case .none: return .none
        @unknown default:
            assert(false, "new value")
            return .none
        }
    }
}

extension TTWebVideoPlayProxy: MediaResourceInterruptionObserver {
    public func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        Self.execInMainThread { [weak self] in
            self?.stop()
        }
    }

    public func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
    }
}
