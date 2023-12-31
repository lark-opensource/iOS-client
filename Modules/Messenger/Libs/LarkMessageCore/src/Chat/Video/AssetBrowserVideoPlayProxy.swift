//
//  AssetBrowserVideoPlayProxy.swift
//  Lark
//
//  Created by Yuguo on 2018/8/17.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Homeric
import LarkUIKit
import TTVideoEngine
import LarkVideoDirector
import Reachability
import LarkModel
import RxSwift
import LKCommonsLogging
import LKCommonsTracker
import LarkCore
import LarkMedia
import LarkSDKInterface
import LarkStorage
import LarkCache
import LarkSetting
import LarkMessengerInterface
import LarkContainer
import UniverseDesignToast
import LarkAccountInterface
import LarkMonitor
import UniverseDesignDialog
import EENavigator

extension AudioSessionScenario {
    public static let previewAsset = AudioSessionScenario(
        "previewAsset",
        category: .playback,
        mode: .default,
        options: [])
}

public final class AssetBrowserVideoPlayProxy: NSObject, LKVideoDisplayViewProxy, UserResolverWrapper {
    static let logger = Logger.log(AssetBrowserVideoPlayProxy.self, category: "Module.AssetBrowserVideoPlayProxy")

    weak public var delegate: LKVideoDisplayViewProxyDelegate? {
        didSet {
            self.delegate?.connection = self.convert(connection: self.reach?.connection)
        }
    }

    private lazy var videoEngine: TTVideoEngine = {
        if useLarkPlayerKit {
            return LarkPlayerKit.buildEngine(userResolver: userResolver, tag: "IM", subTag: "asset_browser")
        }
        return LarkVideoEngine.videoEngine(settingService: self.userResolver.settings)
    }()
    private var useLarkPlayerKit = false
    private let disposeBag = DisposeBag()
    private let session: String?
    private let reach: Reachability? = Reachability()
    private let fileAPI: SecurityFileAPI
    private let messageAPI: MessageAPI

    private let downloadPath: IsoPath
    /// tracker 用于视频可感知埋点
    private let tracker: VideoPlayTracker = VideoPlayTracker()
    /// 性能埋点信息
    private var powerLogSession: BDPowerLogSession?
    private lazy var audioQueue = DispatchQueue(label: "asset.video.proxy.queue", qos: .userInteractive)

    public var preparedCallBack: ((AssetBrowserVideoPlayProxy) -> Void)?

    private lazy var badAVUsePreloadEnable = {
        return fgService?.staticFeatureGatingValue(with: "bad_av_use_preload") ?? false
    }()
    // 在线视频播放 url
    private var localURL: String?
    // 在线视频播放 url
    private var directPlayUrl: String?
    // 下载 toast
    private var downloadToast: UDToast?

    @ScopedInjectedLazy private var fileDependency: DriveSDKFileDependency?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?
    @ScopedInjectedLazy private var passportService: PassportUserService?

    // 用于标记是否已经开始性能埋点
    private var isInPowerEvent = false
    public let userResolver: UserResolver

    public init(session: String?, fileAPI: SecurityFileAPI, messageAPI: MessageAPI, downloadPath: IsoPath, userResolver: UserResolver) {
        self.session = session
        self.fileAPI = fileAPI
        self.messageAPI = messageAPI
        self.downloadPath = downloadPath
        self.userResolver = userResolver
        super.init()
        useLarkPlayerKit = LarkPlayerKit.isEnabled(userResolver: userResolver)
        videoEngine.delegate = self
        videoEngine.dataSource = self

        if !useLarkPlayerKit {
            // 添加视频 tag 配置为 IM
            videoEngine.setOptionForKey(VEKKey.VEKKeyLogTag_NSString.rawValue, value: "IM")
            // 添加视频 subTag 配置为 asset_browser
            videoEngine.setOptionForKey(VEKKey.VEKKeyLogSubTag_NSString.rawValue, value: "asset_browser")
            // 添加 CompanyID 为当前租户 ID
            videoEngine.setCustomCompanyID(passportService?.userTenant.tenantID ?? "")

            //无网默认开启才能使用token读取缓存
            videoEngine.proxyServerEnable = true
            videoEngine.cacheEnable = true
            TTVideoEngine.setAutoTraceReportOpen(false)
        }

        videoEngine.addPeriodicTimeObserver(forInterval: 1, queue: DispatchQueue.main) { [weak self] in
            guard let `self` = self else {
                return
            }

            self.delegate?.set(currentPlaybackTime: self.videoEngine.currentPlaybackTime,
                               duration: self.videoEngine.duration,
                               playableDuration: self.videoEngine.playableDuration)
        }

        reach?.whenReachable = { [unowned self] _ in
            self.delegate?.connection = self.convert(connection: self.reach?.connection)
        }
        try? reach?.startNotifier()
    }

    public var playerView: UIView {
        return videoEngine.playerView
    }

    public func setDirectPlayURL(_ directPlayUrl: String) {
        self.directPlayUrl = directPlayUrl
        self.localURL = nil
        if let fileKey = cacheKey(for: directPlayUrl) {
            /// 开启预加载引擎
            if !TTVideoEngine.ls_isStarted() {
                TTVideoEngine.ls_start()
            }

            /// 使用 ttVideoEngine 统一缓存，判断是否存在缓存
            tracker.hasVideoCache = TTVideoEngine.ls_getCacheSize(byKey: fileKey) > 0

            videoEngine.ls_setDirectURL(directPlayUrl, key: fileKey)
            AssetBrowserVideoPlayProxy.logger.info("set videoEngine url success file key \(fileKey)")
        } else {
            videoEngine.setDirectPlayURL(directPlayUrl, cacheFile: nil)
            AssetBrowserVideoPlayProxy.logger.info("set videoEngine url success without cache")
        }

        if let session = session {
            videoEngine.setCustomHeaderValue("session=" + session, forKey: "cookie")
        } else {
            AssetBrowserVideoPlayProxy.logger.error("users session is nil")
        }
    }

    // 清理缓存
    func removeCacheVideo(_ videoUrl: String) {
        if let fileKey = cacheKey(for: videoUrl) {
            // 删除ttvideo的缓存路径
            TTVideoEngine.ls_removeFileCache(byKey: fileKey)
        }
    }

    // 用于 ttVideoEngine cache
    private func cacheKey(for videoURL: String) -> String? {
        guard !LarkCache.isCryptoEnable() else { return nil }
        return videoURL.kf.md5
    }

    public func setLocalURL(_ localUrl: String) {
        AssetBrowserVideoPlayProxy.logger.info("set local video url")
        self.localURL = localUrl
        self.directPlayUrl = nil
        /// 本地视频指定存在 cache
        tracker.hasVideoCache = true
        videoEngine.setLocalURL(localUrl)
    }

    public func play(_ isMuted: Bool) {
        guard let asset = delegate?.currentAsset else {
            AssetBrowserVideoPlayProxy.logger.debug("video play get 'currentAsset' error")
            return
        }
        if self.goToFileBrowserIfNeeded(asset: asset) {
            videoPlayDidFinish(state: .valid)
            return
        }

        func startPlay() {
            AssetBrowserVideoPlayProxy.logger.info("play audio with isMuted \(isMuted)")
            /// 记录开始播放时间点
            self.tracker.startPlay()
            self.changeAudioSessionActive(active: true) { [weak self] in
                self?.play(asset: asset, isMuted: isMuted)
            }
        }

        AssetBrowserVideoPlayProxy.logger.info("asset proxy try Lock")
        LarkMediaManager.shared.tryLock(scene: .imVideoPlay, options: .mixWithOthers, observer: self) { [weak self] (result) in
            Self.execInMainThread {
                switch result {
                case .success:
                    startPlay()
                case .failure(let error):
                        AssetBrowserVideoPlayProxy.logger.error("asset proxy try Lock failed \(error)")
                    if case let MediaMutexError.occupiedByOther(context) = error {
                        if let msg = context.1 {
                            self?.showMediaLockAlert(msg: msg)
                        }
                        self?.videoPlayDidFinish(state: .valid)
                        return
                    } else {
                        startPlay()
                    }
                }
            }
        }
    }

    fileprivate func play(asset: LKDisplayAsset, isMuted: Bool) {
        switch (asset.isLocalVideoUrl, asset.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType ?? .other) {
        case (true, _):
            AssetBrowserVideoPlayProxy.logger.debug("video play local video success isMuted \(isMuted)")
            videoEngine.muted = isMuted
            videoEngine.play()
            UIApplication.shared.isIdleTimerDisabled = true
        case (false, .video(let item)):
            Tracker.post(TeaEvent(Homeric.VIDEO_PLAY, params: ["message_id": item.messageId]))

            guard videoEngine.currentPlaybackTime == 0 else {
                AssetBrowserVideoPlayProxy.logger.debug("video play video currentPlaybackTime \(videoEngine.currentPlaybackTime) isMuted \(isMuted)")
                videoEngineStartPlayWithMuted(isMuted)
                return
            }
            /// 目前业务中：公司圈的视频不需要鉴权
            if !item.needAuthentication {
                AssetBrowserVideoPlayProxy.logger.debug("video play success without Auth")
                videoEngineStartPlayWithMuted(isMuted)
                return
            }
            AssetBrowserVideoPlayProxy.logger.debug("video play getFileStateRequest isMuted \(isMuted)")
            // 初次播放需要鉴权
            AssetBrowserVideoPlayProxy.logger.info("begin Authentication")
            self.videoEngineStartPlayWithMuted(isMuted)
            videoCheckAuthority(info: item, asset: asset)
        default:
            AssetBrowserVideoPlayProxy.logger.error("video play get extraInfo error")
            tracker.failed(errorCode: -1000)
            videoPlayDidFinish(state: .invalid(nil))
        }
    }

    func videoCheckAuthority(info: MediaInfoItem, asset: LKDisplayAsset) {
        fileAPI.getFileStateRequest(messageId: info.messageId,
                                    sourceType: info.sourceType,
                                    sourceID: info.sourceId,
                                    authToken: info.authToken,
                                    downloadFileScene: info.downloadFileScene)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                AssetBrowserVideoPlayProxy.logger.debug("video play success with auth and state \(state)")
                switch state {
                case .normal:
                    AssetBrowserVideoPlayProxy.logger.info("Authentication succeed")
                case .deleted, .recoverable, .unrecoverable, .freedUp:
                    AssetBrowserVideoPlayProxy.logger.info("Authentication failed")
                    self?.delegate?.showAlert(with: state)
                    self?.videoPlayDidFinish(state: .invalid(state))
                    self?.removeCacheVideo(asset.videoUrl)
                @unknown default:
                    fatalError("unknown")
                }
            }, onError: { [weak self] error in
                AssetBrowserVideoPlayProxy.logger.error("video play getFileStateRequest", error: error)
                self?.videoPlayDidFinish(state: .error(error))
            }).disposed(by: disposeBag)
    }

    private func videoEngineStartPlayWithMuted(_ isMuted: Bool) {
        AssetBrowserVideoPlayProxy.logger.info("videoEngineStartPlayWithMuted isMuted \(isMuted)")
        videoEngine.muted = isMuted
        videoEngine.play()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    public func pause() {
        AssetBrowserVideoPlayProxy.logger.info("video engine pause")
        videoEngine.pause()
        tracker.pause()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    public func stop() {
        AssetBrowserVideoPlayProxy.logger.info("video engine stop")
        videoEngine.setOptionForKey(VEKKey.VEKKeyPlayerStartTime_CGFloat.rawValue, value: 0)
        videoEngine.stop()
        tracker.stop(finish: false)
        UIApplication.shared.isIdleTimerDisabled = false
        self.changeAudioSessionActive(active: false, callBack: nil)
        LarkMediaManager.shared.unlock(scene: .imVideoPlay)
    }

    public func seekVideoProcess(_ process: Float, complete: @escaping (Bool) -> Void) {
        let currentPlaybackTime = Double(process) * videoEngine.duration
        AssetBrowserVideoPlayProxy.logger.info("video engine set seek process \(process) currentPlaybackTime \(currentPlaybackTime) videoEngine.duration \(videoEngine.duration)")
        if (videoEngine.duration - currentPlaybackTime) <= 2 {
            // 视频拖动到2s以内，直接完成播放
            stop()
            delegate?.videoPlayDidFinish(state: .valid)
        } else {
            AssetBrowserVideoPlayProxy.logger.info("currentPlaybackTime: \(currentPlaybackTime)")
            // 如果视频从完成状态开始拖动，此时视频本身内部的资源已经被释放，那么松手后只会从头播放。因此需要设置StartTime来确定起播时间
            // 在非完成状态，也会设置startTime。但在finish和stop后会重新设置为0
            videoEngine.setOptionForKey(VEKKey.VEKKeyPlayerStartTime_CGFloat.rawValue, value: currentPlaybackTime)
            tracker.isSeek = true
            videoEngine.setCurrentPlaybackTime(currentPlaybackTime, complete: { (result) in
                AssetBrowserVideoPlayProxy.logger.info("video engine set seek process \(process) currentPlaybackTime \(currentPlaybackTime) result \(result) did completed")
                complete(result)
            })
        }
    }

    func goToFileBrowserIfNeeded(asset: LKDisplayAsset) -> Bool {
        switch asset.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType ?? .other {
        case .video(let info):
            if info.isPCOriginVideo,
               !info.messageId.isEmpty,
               let vc = self.findController(view: self.playerView) {
                var startTime = CACurrentMediaTime()
                messageAPI.fetchMessage(id: info.messageId).observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self, weak vc] (message) in
                        guard let `self` = self, let fromVC = vc else { return }
                        var extra: [String: Any] = [:]
                        if let downloadFileScene = info.downloadFileScene {
                            extra[FileBrowseFromWhere.DownloadFileSceneKey] = downloadFileScene
                        }
                        let fileMessage = message.transformToFileMessageIfNeeded()
                        self.fileDependency?.openSDKPreview(
                            message: fileMessage,
                            chat: nil,
                            fileInfo: nil,
                            from: fromVC,
                            supportForward: true,
                            canSaveToDrive: true,
                            browseFromWhere: .file(extra: extra)
                        )
                        Tracker.post(TeaEvent("original_video_click_event_dev", params: [
                            "result": 1,
                            "cost_time": (CACurrentMediaTime() - startTime) * 1000
                        ]))
                    }, onError: { error in
                        Tracker.post(TeaEvent("original_video_click_event_dev", params: [
                            "result": 0,
                            "cost_time": (CACurrentMediaTime() - startTime) * 1000,
                            "errorMsg": "\(error)"
                        ]))
                    }).disposed(by: disposeBag)
                return true
            }
        default:
            break
        }
        return false
    }

    // 统一视频完成入口，因为需要设置视频开始时间为0
    func videoPlayDidFinish(state: LKVideoState) {
        AssetBrowserVideoPlayProxy.logger.info("videoPlayDidFinish state:\(state)")
        videoEngine.setOptionForKey(VEKKey.VEKKeyPlayerStartTime_CGFloat.rawValue, value: 0.0)
        self.delegate?.videoPlayDidFinish(state: state)
    }

    deinit {
        videoEngine.removeTimeObserver()
        reach?.stopNotifier()
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

    @objc
    func showDownloadToast() {
        guard self.badAVUsePreloadEnable else {
            return
        }
        // 获取当前进度
        let currentPlaybackTime = self.videoEngine.currentPlaybackTime
        AssetBrowserVideoPlayProxy.logger.info("show download toast, currentPlaybackTime \(currentPlaybackTime)")
        self.videoEngine.stop()
        guard let vc = self.findController(view: self.playerView) else {
            AssetBrowserVideoPlayProxy.logger.error("cannot find vc")
            return
        }
        guard self.downloadToast == nil else {
            AssetBrowserVideoPlayProxy.logger.error("downloadToast is not")
            return
        }

        if let directPlayUrl = directPlayUrl,
           let fileKey = cacheKey(for: directPlayUrl) {
            AssetBrowserVideoPlayProxy.logger.info("add preload task \(fileKey) current cacheSize \(TTVideoEngine.ls_getCacheSize(byKey: fileKey))")
            let preloadSize = 1024 * 1024 * 1024
            if let item = TTVideoEnginePreloaderURLItem(key: fileKey, videoId: nil, urls: [directPlayUrl], preloadSize: preloadSize) {
                if let session = session {
                    item.setCustomHeaderValue("session=" + session, forKey: "cookie")
                } else {
                    AssetBrowserVideoPlayProxy.logger.error("users session is nil")
                }
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
                        AssetBrowserVideoPlayProxy.logger.error("preload task failed \(error)")
                        dismissBlock()
                    } else {
                        AssetBrowserVideoPlayProxy.logger.info("preload task end")
                        self.videoEngine.setOptionForKey(VEKKey.VEKKeyPlayerStartTime_CGFloat.rawValue, value: currentPlaybackTime)
                        self.videoEngine.play()
                        dismissBlock()
                        Tracker.post(TeaEvent("download_success_interlaced_video_dev"))
                    }
                }
                item.preloadCanceled = {
                    AssetBrowserVideoPlayProxy.logger.info("preload task cancel")
                    dismissBlock()
                }
                item.preloadDidStart = { _ in
                    AssetBrowserVideoPlayProxy.logger.info("preload task did start")
                }
                DispatchQueue.main.async {
                    AssetBrowserVideoPlayProxy.logger.info("preload task info \(item.preloadSize) \(item.key)")

                    TTVideoEngine.ls_addTask(with: item)
                }
                Tracker.post(TeaEvent("download_interlaced_video_dev"))
            }

        } else {
            AssetBrowserVideoPlayProxy.logger.error("add preload task failed")
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

    func showMediaLockAlert(msg: String) {
        guard let vc = self.findController(view: self.playerView) else {
            AssetBrowserVideoPlayProxy.logger.error("cannot find vc")
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

extension AssetBrowserVideoPlayProxy: TTVideoEngineDelegate {
    public func videoEngineUserStopped(_ videoEngine: TTVideoEngine) {
        AssetBrowserVideoPlayProxy.logger.info("asset proxy videoEngineUserStopped")
        self.delegate?.videoDidStop()
    }

    public func videoEngineDidFinish(_ videoEngine: TTVideoEngine, error: Error?) {
        AssetBrowserVideoPlayProxy.logger.info("asset proxy videoEngineDidFinish error \(error)")
        if let error = error {
            self.tracker.failed(error: error)
            videoPlayDidFinish(state: .error(error))
        } else {
            self.tracker.stop(finish: true)
            videoPlayDidFinish(state: .valid)
        }
    }

    public func videoEngineDidFinish(_ videoEngine: TTVideoEngine, videoStatusException status: Int) {
        AssetBrowserVideoPlayProxy.logger.info("asset proxy videoEngineDidFinish status \(status)")
        self.tracker.failed(errorCode: status)
    }

    public func videoEngineCloseAysncFinish(_ videoEngine: TTVideoEngine) {
        AssetBrowserVideoPlayProxy.logger.info("asset proxy videoEngineCloseAysncFinish")
    }

    public func videoEnginePrepared(_ videoEngine: TTVideoEngine) {
        AssetBrowserVideoPlayProxy.logger.info("asset proxy videoEngineCloseAysncFinish")
        preparedCallBack?(self)
    }

    public func videoEngineReady(toPlay videoEngine: TTVideoEngine) {
        AssetBrowserVideoPlayProxy.logger.info("asset proxy videoEngineReady")
        self.delegate?.videoReadyToPlay()
    }

    public func videoEngine(_ videoEngine: TTVideoEngine, playbackStateDidChanged playbackState: TTVideoEnginePlaybackState) {
        AssetBrowserVideoPlayProxy.logger.info("asset proxy playbackStateDidChanged \(playbackState.rawValue)")
        tracker.update(
            playbackState: playbackState,
            loadState: videoEngine.loadState
        )
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
            self.startPowerSessionIfNeeded()
        } else {
            self.endPowerEvent(reason: stopReason)
            self.endPowerSessionIfNeeded(state)
        }
        self.delegate?.videoPlaybackStateDidChanged(state)
        self.stopDownloadMonitorIfNeeded(playbackState: playbackState, loadState: self.videoEngine.loadState)
    }

    public func videoEngine(_ videoEngine: TTVideoEngine, loadStateDidChanged loadState: TTVideoEngineLoadState) {
        AssetBrowserVideoPlayProxy.logger.info("asset proxy loadStateDidChanged \(loadState.rawValue)")
        tracker.update(
            playbackState: videoEngine.playbackState,
            loadState: loadState
        )
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
        AssetBrowserVideoPlayProxy.logger.info("asset proxy onAVBadInterlaced \(info)")
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

    public func retryFetchVideo() {
        videoEngine.play()
    }

    public func videoEngine(_ videoEngine: TTVideoEngine, mdlKey key: String, hitCacheSze cacheSize: Int) {
        AssetBrowserVideoPlayProxy.logger.info("asset proxy hit cache size \(cacheSize) key \(key)")
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
        params["isWebVideo"] = 0

        if let localURL = self.localURL {
            params["isLocal"] = 1
            params["fileKey"] = localURL.kf.md5
        } else if let directPlayUrl = self.directPlayUrl {
            params["isLocal"] = 0
            params["fileKey"] = directPlayUrl.kf.md5
        }
        return params
    }
}

extension AssetBrowserVideoPlayProxy: TTVideoEngineDataSource {
    public func networkType() -> TTVideoEngineNetworkType {
        return networkType(from: reach?.connection ?? .none)
    }

    fileprivate func networkType(from connection: Reachability.Connection) -> TTVideoEngineNetworkType {
        switch connection {
        case .wifi: return .wifi
        case .cellular: return .notWifi
        case .none: return .none
        @unknown default:
            assert(false, "new value")
            return .none
        }
    }

    func convert(connection: Reachability.Connection?) -> LKVideoConnection {
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
}

extension AssetBrowserVideoPlayProxy: MediaResourceInterruptionObserver {

    public func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        Self.execInMainThread { [weak self] in
            self?.stop()
        }
    }

    public func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
    }
}
