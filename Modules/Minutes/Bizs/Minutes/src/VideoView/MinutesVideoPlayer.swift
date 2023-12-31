//
//  MinutesVideoPlayer.swift
//  Minutes
//
//  Created by lvdaqian on 2021/1/14.
//

import Foundation
import TTVideoEngine
import MinutesFoundation
import MinutesNetwork
import Kingfisher
import LarkMedia
import MediaPlayer
import UniverseDesignToast
import LarkCache
import LarkSetting
import LarkReleaseConfig
import LarkStorage
import LarkContainer
import MinutesFoundation
import UniverseDesignIcon
import LarkVideoDirector

extension MinutesInfo {
    static let cache = makeMinutesCache()
    var playURL: URL? {
        if MinutesPodcast.shared.isInPodcast, let url = self.basicInfo?.podcastURL {
            // 在播客，返回了video
            return url
        } else if let url = self.basicInfo?.videoURL {
            // 不在播客模式，返回了 hls
            return url
        } else {
            let cache = makeMinutesCache()
            let key = "\(objectToken).m4a"
            if cache.containsFile(forKey: key) {
                let path = cache.filePath(forKey: key)
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    var noPlayURL: Bool {
        if let info = basicInfo,
           info.podcastURL != nil,
           info.videoURL != nil {
            // has remote play url
            return false
        } else {
            let key = "\(objectToken).m4a"
            // local play url
            return !MinutesInfo.cache.containsFile(forKey: key)
        }
    }

    var isRemotePlayURL: Bool {
        if let info = basicInfo,
           info.podcastURL != nil,
           info.videoURL != nil {
            // has remote play url
            return true
        } else {
            return false
        }
    }
}

public struct PlayerStatusWrapper {
    let playbackState: TTVideoEnginePlaybackState
    let loadState: TTVideoEngineLoadState
    let videoPlayerStatus: MinutesVideoPlayerStatus
    
    init(playbackState: TTVideoEnginePlaybackState, loadState: TTVideoEngineLoadState) {
        self.playbackState = playbackState
        self.loadState = loadState
        self.videoPlayerStatus =         MinutesVideoPlayerStatus.from(playbackState: playbackState, loadState: loadState)
    }
}

enum PlayerPageType: Int {
    case detail
    case clip
    case podcast
    
    var description: String {
        switch self {
        case .detail, .clip:
            return "normal"
        case .podcast:
            return "podcast"
        }
    }
}

public enum MinutesVideoPlayerStatus {
    case unkown
    case perpare
    case playing
    case paused
    case stopped
    case loading
    case error

    static func from(playbackState: TTVideoEnginePlaybackState, loadState: TTVideoEngineLoadState) -> MinutesVideoPlayerStatus {
        switch (playbackState, loadState) {
        case (_, .error), (.error, _):
            return .error
        case (.playing, .playable):
            return .playing
        case (.playing, .stalled), (.playing, .unknown):
            return .loading
        case (.paused, .unknown), (.paused, .playable):
            return .paused
        case (.stopped, .playable):
            return .stopped
        case (.stopped, .stalled), (.paused, .stalled):
            return .perpare
        case (.stopped, .unknown):
            return .unkown
        }
    }

    func buttonImage(_ isFinish: Bool, size: CGSize = CGSize(width: 24, height: 24)) -> UIImage? {
        if isFinish {
            return BundleResources.Minutes.minutes_refresh_outlined
        }

        switch self {
        case .paused, .stopped:
                return UDIcon.getIconByKey(.playFilled, iconColor: .white, size: size)
        case .playing:
            return UDIcon.getIconByKey(.pauseFilled, iconColor: .white, size: size)
        case .error:
            return UDIcon.getIconByKey(.videoOffFilled, iconColor: UIColor.ud.iconN1, size: CGSize(width: size.width, height: size.width))
        case .unkown:
            return UDIcon.getIconByKey(.playFilled, iconColor: .white, size: size)
        default:
            return nil
        }
    }
}

public enum PlaybackTimePayloadKey: String, Hashable {
    case manualOffset   // 是否需要不依赖回调，手动更新offset
    case resetDragging  // 点击了快进/快退/拖动进度条/点击进度条，重置drag
    case didTappedRow   // 传递点击文字时的row
}

public struct PlaybackTime: Equatable {
    let time: TimeInterval
    var payload: [PlaybackTimePayloadKey: NSInteger]

    init(_ time: TimeInterval,
         manualOffset: NSInteger = 0,
         resetDragging: NSInteger = 0,
         didTappedRow: NSInteger? = nil) {
        self.time = time
        self.payload = [.manualOffset: manualOffset, .resetDragging: resetDragging]
        if let didTappedRow = didTappedRow {
            self.payload[.didTappedRow] = didTappedRow
        }
    }

    init?(_ millisecondString: String,
          manualOffset: NSInteger = 0,
          resetDragging: NSInteger = 0,
          didTappedRow: NSInteger? = nil) {
        guard let ms = Double(millisecondString) else { return nil }
        self.time = ms * 1000.0
        self.payload = [.manualOffset: manualOffset, .resetDragging: resetDragging]
        if let didTappedRow = didTappedRow {
            self.payload[.didTappedRow] = didTappedRow
        }
    }

    var millisecondString: String {
        let ms = Int((time * 1000).rounded())
        return "\(ms)"
    }

    var millisecond: NSInteger {
        return Int((time * 1000).rounded())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.time == rhs.time
    }
}

public protocol MinutesVideoPlayerListener: AnyObject {
    func videoEngineDidLoad()
    func videoEngineDidChangedStatus(status: PlayerStatusWrapper)
    func videoEngineDidChangedPlaybackTime(time: PlaybackTime)
}


public protocol MinutesVideoDelegate: AnyObject {
    func didSavePlayTime()
    func didRemovePlayTime()
}

public final class MinutesVideoPlayer: NSObject {
    static let maxCacheSize: Int = 100 * 1024 * 1024
    static let trackDuration: Int = 60000
    lazy var scenario = AudioSessionScenario("MinutesVideoPlayer_\(Unmanaged.passUnretained(self).toOpaque())", category: .playback, mode: .moviePlayback)

    let store = KVStores.udkv(
        space: .global,
        domain: Domain.biz.minutes
    )
    
    var listeners = MulticastListener<MinutesVideoPlayerListener>()
    weak var delegate: MinutesVideoDelegate?
    
    var videoEngineInit: Bool = false
    var isSkipingSilence = false

    var videoEngine = TTVideoEngine(ownPlayer: true)
    let minutes: Minutes
    var shouldSavePlayTime: Bool
    var hasLockPanel: Bool
    private var playedDuration: Int = 0
    
    private var playTimestamp: Int = 0
    private var playTimeSlice: Int = 0
    
    var pageType: PlayerPageType = .detail {
        willSet {
            if newValue == pageType { return }
            updatePlayTimestamp()
            trackPlayDuration()
        }
    }
    
    let userResolver: UserResolver?
    private(set) var playURL: URL?

    /// 记录停止播放后(未开始播放前)，重新seek时的播放位置，并调用setCurrentPlaybackTime函数
    /// 踩坑：engine设置play之后，state不会马上改变，这时如果调用setCurrentPlaybackTime，由于state仍然是stop，所以不起作用
    ///      当state收到改变成playing的回调时，再去做setCurrentPlaybackTime的操作，在特定的时间点进行播放。
    var replayFromStopping: (() -> Void)?

    private(set) var currentPlaybackTime: PlaybackTime = PlaybackTime(0.0) {
        didSet {
            guard oldValue != currentPlaybackTime else { return }
            self.listeners.invokeListeners { listener in
                listener.videoEngineDidChangedPlaybackTime(time: currentPlaybackTime)
            }
            self.trackPlayDurationIfNeeded()
            self.updateSilenceInfo()
        }
    }

    var playerStatus: PlayerStatusWrapper = PlayerStatusWrapper(playbackState: .stopped, loadState: .unknown)  {
        didSet {
            guard oldValue.videoPlayerStatus != playerStatus.videoPlayerStatus else { return }
            if isSkipingSilence == true, playerStatus.loadState == .playable {
                isSkipingSilence = false
            }
            self.listeners.invokeListeners { listener in
                listener.videoEngineDidChangedStatus(status: playerStatus)
            }
            //currentStatus.update(data: currentPlayerStatus)
            MinutesLogger.video.info("player status changed: \(oldValue.videoPlayerStatus) ==> \(playerStatus.videoPlayerStatus)")
            if MinutesPodcast.shared.isInPodcast, oldValue.videoPlayerStatus == .playing, playerStatus.videoPlayerStatus == .stopped {
                MinutesPodcast.shared.playNextMinutes()
            }
        }
    }
    
    var currentPlayerStatus: MinutesVideoPlayerStatus {
        playerStatus.videoPlayerStatus
    }

    public var duration: TimeInterval {
        return videoEngine.duration
    }

    public var lastError: Error?

    public var isFinish: Bool {
        let couldPlay = videoEngine.loadState == .playable
        return couldPlay && videoEngine.currentPlaybackTime >= videoEngine.duration
    }

    public var playbackSpeed: CGFloat = 1.0 {
        didSet {
            videoEngine.playbackSpeed = playbackSpeed
            self.mediaInfoConfiguration()
        }
    }
    let coverView: UIImageView = UIImageView()

    public var playerView: UIView {
        return videoEngine.playerView
    }

    public var isAudioOnly: Bool {
        let isAudioOnly = minutes.basicInfo?.mediaType != .video
        return isAudioOnly
    }

    public var isPlayURLReady: Bool {
        if self.playURL != nil {
            return true
        } else {
            return false
        }
    }

    lazy var imageDownloader: ImageDownloader = MinutesAPI.imageDownloader

    let tracker: MinutesTracker

    //private var subtitlePlayer: MinutesSubtitlePlayer?
    //lazy private var subtitlePlayer: MinutesSubtitlePlayer = MinutesSubtitlePlayer(playerView, minutes: minutes)

//    public var isSubtitleShown: Bool {
//        return subtitlePlayer?.isShown ?? false
//    }

    // skip silence
    public var shouldSkipSilence: Bool = false {
        didSet {
            fetchSilenceInfoIfNeeded()
        }
    }

    var dependency: MinutesDependency? {
        return try? userResolver?.resolve(assert: MinutesDependency.self)
    }
    
    private func setPeriodTime(_ interval: TimeInterval) {
        videoEngine.removeTimeObserver()
        videoEngine.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] in
            self?.updateTime()
        }
    }

    fileprivate func setupVideoEngine(_ minutes: Minutes) {

        let speed = videoEngine.playbackSpeed
        videoEngine.removeTimeObserver()
        videoEngine.stop()
        videoEngine.close()
        videoEngine.delegate = nil
        videoEngine.dataSource = nil
        
        videoEngine = TTVideoEngine(ownPlayer: true)
        videoEngine.delegate = self
        videoEngine.dataSource = self
        videoEngine.isEnableBackGroundPlay = true
        var videoOptions: [VEKKeyType: Any] = [
            VEKKeyType(value: VEKKey.VEKKeyViewScaleMode_ENUM.rawValue): TTVideoEngineScalingMode.aspectFit.rawValue,
            VEKKeyType(value: VEKKey.VEKKeyViewRenderEngine_ENUM.rawValue): TTVideoEngineRenderEngine.metal.rawValue,
            VEKKeyType(value: VEKKey.VEKKeyMedialoaderEnable_BOOL.rawValue): true,
            VEKKeyType(value: VEKKey.VEKKeyLogTag_NSString.rawValue): "normalvideo",
            VEKKeyType(value: VEKKey.VEKKeyLogSubTag_NSString.rawValue): "vc_minutes",
            VEKKeyType(value: VEKKey.VEKKeyPlayerTTHLSDrm_BOOL.rawValue): true
        ]
        if let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "minutes_video_player_config")) {
            if let videoConfig = settings["engine"] as? [String: Any] {
                MinutesLogger.video.info("get video engine config: \(videoConfig)")
                videoOptions = self.updateEngine(videoOptions: videoOptions, videoConfig: videoConfig)
            }
        }
        videoEngine.setOptions(videoOptions)
        VideoEngineSetupManager.shared.setupVideoEngineDelegateIfNeeded()

        videoEngine.setTag("normalvideo")

        if let settings = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "im_video_player_config")) {
            if let videoConfig = settings["mdl"] as? [String: Any] {
                MinutesLogger.video.info("get video cache config: \(videoConfig)")
                updateMDL(setting: videoConfig)
            }
        }

        
        #if !targetEnvironment(simulator)
        videoEngine.hardwareDecode = true
        #endif

        //无网默认开启才能使用token读取缓存
        videoEngine.proxyServerEnable = true
        videoEngine.cacheEnable = true
        videoEngine.playerView.backgroundColor = UIColor.ud.N1000.nonDynamic
        videoEngine.playbackSpeed = speed
        let periodTime = 0.2
        setPeriodTime(periodTime)

        let customHeader = MinutesAPI.config.commonHeaders()
        for (key, value) in customHeader {
            videoEngine.setCustomHeaderValue(value, forKey: key)
        }
        videoEngine.setCustomHeaderValue(minutes.baseURL.absoluteString, forKey: "Referer")

        //subtitlePlayer = MinutesSubtitlePlayer(videoEngine.playerView, minutes: minutes)
        self.listeners.invokeListeners { listener in
            listener.videoEngineDidLoad()
        }
        self.videoEngineInit = true
    }

    public init(resolver: UserResolver?, minutes: Minutes) {
        self.userResolver = resolver
        self.minutes = minutes
        self.tracker = MinutesTracker(minutes: minutes)
        self.shouldSavePlayTime = true
        self.hasLockPanel = false
        super.init()
        initPlayTimestamp()
        TTVideoEngine.setLogFlag([.alog])

        updateMinutes(minutes.info)
        minutes.info.listeners.addListener(self)

        if let notificationName = dependency?.meeting?.mutexDidChangeNotificationName {
            NotificationCenter.default.addObserver(self, selector: #selector(didChangeModule(_:)),
                                                   name: notificationName, object: nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        clearEngine()
        LarkMediaManager.shared.unlock(scene: .mmPlay)
        trackPlayDuration()
        MinutesLogger.video.info("deinit MinutesVideoPlayer")
        MinutesLogger.video.info("total played duration: \(playedDuration)")
    }
    
    @objc private func didChangeModule(_ notification: Notification) {
        if let key = dependency?.meeting?.mutexDidChangeNotificationKey {
            let module = notification.userInfo?[key]
            if videoEngine.playbackState == .playing {
                pause()
            }
        }
    }

    func clearEngine() {
        videoEngine.removeTimeObserver()
        videoEngine.stop()
        videoEngine.close()
        LarkMediaManager.shared.getMediaResource(for: .mmPlay)?.audioSession.leave(self.scenario)
    }

    func updateMinutes(_ updated: MinutesInfo) {
        guard updated.status.isValid else {
            MinutesPodcast.shared.invalidMinutes(updated.baseURL)
            return
        }
        guard let newPlayURL = updated.playURL,
              playURL != newPlayURL else {
            return
        }
        playURL = newPlayURL
        let coverURL = URL(string: updated.basicInfo?.videoCover ?? "")
        DispatchQueue.main.async {
            self.setPlayInfo(cover: coverURL, video: newPlayURL)
        }
    }

    func setPlayInfo(cover: URL?, video: URL) {
        MinutesLogger.video.info("play url has beed set. isLocalFile \(video.isFileURL)")

        coverView.kf.setImage(with: cover, options: [.downloader(imageDownloader)])
        coverView.contentMode = .scaleAspectFit

        setupVideoEngine(minutes)

        if !TTVideoEngine.ls_isStarted() {
            TTVideoEngine.ls_start()
        }

        let key = "\(minutes.objectToken)"
        let url = video.absoluteString
        let playTime = currentPlaybackTime.time
        if playTime != 0.0 {
            delegate?.didSavePlayTime()
        }

        if video.isFileURL {
            videoEngine.setLocalURL(url)
        } else if let item = TTVideoEnginePreloaderURLItem(key: key, videoId: nil, urls: [url], preloadSize: Self.maxCacheSize) {

            let customHeader = MinutesAPI.config.commonHeaders()
            for (key, value) in customHeader {
                item.setCustomHeaderValue(value, forKey: key)
            }
            item.setCustomHeaderValue(minutes.baseURL.absoluteString, forKey: "Referer")

            TTVideoEngine.ls_addTask(with: item)
            MinutesLogger.video.info("perload task: \(key.suffix(6))")
            videoEngine.ls_setDirectURL(url, key: key)
        } else {
            MinutesLogger.video.info("direct play \(key.suffix(6))")
            videoEngine.setDirectPlayURL(url)
        }
        videoEngine.prepareToPlay()

        if MinutesPodcast.shared.isInPodcast, MinutesPodcast.shared.minutes === minutes {
            if minutes.podcastAutoPlay {
                play()
            }
        }
    }

    func updateTime() {
        guard currentPlayerStatus == .playing else {
            return
        }

        self.currentPlaybackTime = PlaybackTime(videoEngine.currentPlaybackTime)
    }

    func updateSilenceInfo() {
        let ms = Int(videoEngine.currentPlaybackTime * 1000)
        if shouldSkipSilence, let nextTime = minutes.info.silenceInfo?.nextStopTime(ms) {
            // 避免skip seek loading的时候重复seek
            guard isSkipingSilence == false else { return }
            let time: TimeInterval = Double(nextTime) / 1000.0
            seekVideoPlaybackTime(time)
            isSkipingSilence = true
        }
    }

    func tigglePlayState(from: BusinessTrackerFromSource) {
        MinutesLogger.video.info("preview tapped")
        var trackParams: [AnyHashable: Any] = [:]
        if videoEngine.playbackState == .playing {
            if from == .podcast {
                tracker.tracker(name: .podcastPage, params: ["action_name": "pause_podcast"])
                tracker.tracker(name: .podcastClick, params: ["click": "pause", "target": "none"])
            } else {
                trackParams.append(.videoPause)
                trackParams.append(from)
                tracker.tracker(name: .clickButton, params: trackParams)
                tracker.tracker(name: .detailClick, params: ["click": "video_pause", "location": from.rawValue, "target": "none"])
            }

            self.pause()
        } else {
            if from == .podcast {
                tracker.tracker(name: .podcastPage, params: ["action_name": "continue_podcast"])
                tracker.tracker(name: .podcastClick, params: ["click": "play", "target": "none"])
            } else {
                trackParams.append(.videoPlay)
                trackParams.append(from)
                tracker.tracker(name: .clickButton, params: trackParams)
                tracker.tracker(name: .detailClick, params: ["click": "video_play", "location": from.rawValue, "target": "none"])
            }

            self.play()
        }
    }

    public func play() {
        LarkMediaManager.shared.tryLock(scene: .mmPlay, observer: self) { [weak self] in
            guard let self = self else {
                return
            }
            switch $0 {
            case .success(let resource):
                DispatchQueue.main.async {
                    resource.audioSession.enter(self.scenario)
                    
                    MinutesLogger.video.info("play")
                    self.lastError = nil
                    self.videoEngine.play()
                    self.mediaInfoConfiguration()
                    self.initPlayTimestamp()
                }
                MinutesLogger.video.info("video player start play succeed")
            case .failure(let error):
                DispatchQueue.main.async {
                    let targetView = self.userResolver?.navigator.mainSceneWindow?.fromViewController?.view
                    
                    if case let MediaMutexError.occupiedByOther(context) = error {
                        if let msg = context.1 {
                            MinutesToast.showTips(with: msg, targetView: targetView)
                        }
                    } else {
                        MinutesToast.showTips(with: BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, targetView: targetView)
                    }
                }
                MinutesLogger.video.warn("video player start play failed with error: \(error)")
            }
            
        }
    }
 
    public func pause() {
        guard currentPlayerStatus == .playing else {
            return
        }
        MinutesLogger.video.info("pause")
        videoEngine.pause()
        mediaInfoConfiguration()
        updatePlayTimestamp()
    }

    public func stop() {
        MinutesLogger.video.info("stop")
        videoEngine.stop()
        updatePlayTimestamp()
    }

    public func seekVideoPlaybackTime(_ currentPlaybackTime: TimeInterval, manualOffset: NSInteger = 0, didTappedRow: NSInteger? = nil) {

        self.currentPlaybackTime = PlaybackTime(currentPlaybackTime,
                                                manualOffset: manualOffset,
                                                resetDragging: 1,
                                                didTappedRow: didTappedRow)
        DispatchQueue.main.async {
            self.mediaInfoConfiguration()
        }
        self.videoEngine.setCurrentPlaybackTime(currentPlaybackTime) { _ in
        }
    }

    public func seekVideoProcess(_ process: Double) {

        MinutesLogger.video.info("seekVideoProcess \(process)")
        guard process <= 1.0, process >= 0.0 else {
            return
        }

        let playbackTime = process * videoEngine.duration
        seekVideoPlaybackTime(playbackTime)
    }
    
    func loadPlayTime() {
        if let time = lastPlayTime {
            seekVideoPlaybackTime(time)
        }
    }

    func resetPlayTime() {
        lastPlayTimeInternal = 0
    }

    private var lastPlayTimeInternal: Double?
    
    func updateLastPlayTime(_ value: Double?) {
        lastPlayTimeInternal = value
    }
    
    var lastPlayTime: Double? {
        if let lastPlayTimeInternal = lastPlayTimeInternal {
            return lastPlayTimeInternal
        } else {
            if let dict: [String: Double] = store.value(forKey: NewPlaytimeKey) {
                lastPlayTimeInternal = dict[minutes.objectToken]
            }
            return lastPlayTimeInternal
        }
    }

    func fetchSilenceInfoIfNeeded() {
        if let info = minutes.info.silenceInfo {
            if shouldSkipSilence {
                updateSilenceInfo()
                DispatchQueue.main.async { [weak self] in
                    let targetView = self?.userResolver?.navigator.mainSceneWindow?.fromViewController?.view
                    MinutesToast.showTips(with: info.toast, targetView: targetView)
                }
            }
        } else {
            minutes.info.fetchSilenceRange(catchError: true) { [weak self]result in
                switch result {
                case .success(let info):
                    if self?.shouldSkipSilence == true {
                        self?.updateSilenceInfo()
                        DispatchQueue.main.async {
                            let targetView = self?.userResolver?.navigator.mainSceneWindow?.fromViewController?.view
                            MinutesToast.showTips(with: info.toast, targetView: targetView)
                        }
                    }
                case .failure(let error):break
                }
            }
        }
    }

    public func updatePodcastStatus() {
        updateMinutes(minutes.info)
        DispatchQueue.main.async {
            self.listeners.invokeListeners { [weak self] listener in
                guard let self = self else { return }
                listener.videoEngineDidChangedStatus(status: self.playerStatus)

            }
            let periodTime = 0.2
            self.setPeriodTime(periodTime)
            if MinutesPodcast.shared.isInPodcast && self.minutes.podcastAutoPlay && self.playURL != nil {
                self.play()
            }
        }
    }
    
    private func trackPlayDuration() {
        guard playTimeSlice > 10 else { return } // 连续播放切换妙记的时候playTimeSlice值很小，无需上报
        tracker.tracker(name: .detailStatus, params: ["play_duration": playTimeSlice, "page_type": pageType.description])
        playTimeSlice = 0
    }
    
    private func trackPlayDurationIfNeeded() {
        guard currentPlayerStatus == .playing else { return }
        updatePlayTimestamp()
        if playTimeSlice > Self.trackDuration {
            trackPlayDuration()
        }
    }
    
    private func updatePlayTimestamp() {
        let now = Int(CACurrentMediaTime() * 1000)
        let duration = now - playTimestamp
        playTimestamp = now
        if duration > 0 {
            playTimeSlice += duration
            playedDuration += duration
        }
    }
    
    private func initPlayTimestamp() {
        playTimestamp = Int(CACurrentMediaTime() * 1000)
    }
}

extension MinutesVideoPlayer: MinutesInfoChangedListener{
    public func onMinutesInfoStatusUpdate(_ info: MinutesInfo) {
        updateMinutes(info)
    }
}

extension MinutesVideoPlayer: MediaResourceInterruptionObserver {
   
    public func mediaResourceWasInterrupted(by scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType, msg: String?) {
        MinutesLogger.video.info("mediaResourceWasInterrupted by scene: \(scene) type: \(type) msg: \(msg)")
        DispatchQueue.main.async {
            self.pause()
        }
    }

    public func mediaResourceInterruptionEnd(from scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType) {
        MinutesLogger.video.info("mediaResourceInterruptionEnd from scene: \(scene) type: \(type)")
    }
}

extension MinutesVideoPlayer {
    func updateEngine(videoOptions: [VEKKeyType: Any], videoConfig: [String: Any]) -> [VEKKeyType: Any] {
        var videoOptions = videoOptions
        //////////////////////
        if let openTimeOut = videoConfig["VEKKeyPlayerOpenTimeOut"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerOpenTimeOut_NSInteger.rawValue)] = NSNumber(value: openTimeOut)
        }
        if let bufferingTimeOut = videoConfig["VEKKeyPlayerBufferingTimeOut"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerBufferingTimeOut_NSInteger.rawValue)] = NSNumber(value: bufferingTimeOut)
        }
        //////////////////////
        if let preferNearestSampleEnable = videoConfig["VEKKeyPlayerPreferNearestSampleEnable"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerPreferNearestSampleEnable.rawValue)] = preferNearestSampleEnable == 1
        }
        if let preferNearestMaxPosOffset = videoConfig["VEKKeyPlayerPreferNearestMaxPosOffset"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerPreferNearestMaxPosOffset.rawValue)] = NSNumber(value: preferNearestMaxPosOffset)
        }
        if let cacheMaxSeconds = videoConfig["VEKKeyPlayerCacheMaxSeconds"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerCacheMaxSeconds_NSInteger.rawValue)] = NSNumber(value: cacheMaxSeconds)
        }
        //////////////////////
        if let enableDemuxNonblockRead = videoConfig["PLAYER_OPTION_ENABLE_DEMUX_NONBLOCK_READ"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableDemuxNonBlockRead_BOOL.rawValue)] = enableDemuxNonblockRead == 1
        }
        if let positionUpdateInterval = videoConfig["VEKKeyPlayerPositionUpdateInterval"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerPositionUpdateInterval_NSInteger.rawValue)] = NSNumber(value: positionUpdateInterval)
        }
        if let skipFindStreamInfo = videoConfig["VEKKeyPlayerSkipFindStreamInfo"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerSkipFindStreamInfo_BOOL.rawValue)] = skipFindStreamInfo == 1
        }
        if let postPrepareMsg = videoConfig["VEKKeyPlayerPostPrepareMsg"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerPostPrepareMsg.rawValue)] = NSNumber(value: postPrepareMsg)
        }
        if let keepFormatAlive = videoConfig["VEKKEYPlayerKeepFormatAlive"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKEYPlayerKeepFormatAlive_BOOL.rawValue)] = NSNumber(value: keepFormatAlive)
        }
        if let enableOutletDropLimit = videoConfig["VEKKeyPlayerEnableOutletDropLimit"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableOutletDropLimit_BOOL.rawValue)] = enableOutletDropLimit == 1
        }
        if let mp4CheckEnable = videoConfig["VEKKeyPlayerEnableMp4Check"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableMp4Check_NSInteger.rawValue)] = mp4CheckEnable == 1
        }
        //////////////////////
        if let playerCheckVoiceInBufferingStart = videoConfig["VEKKeyPlayerCheckVoiceInBufferingStart"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerCheckVoiceInBufferingStart_BOOL.rawValue)] = playerCheckVoiceInBufferingStart == 1
        }
        if let defaultBufferEndTime = videoConfig["VEKKeyPlayerDefaultBufferEndTime"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerDefaultBufferEndTime_NSInteger.rawValue)] = NSNumber(value: defaultBufferEndTime)
        }
        if let maxBufferEndMilliSeconds = videoConfig["VEKKeyPlayersMaxBufferEndMilliSeconds"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayersMaxBufferEndMilliSeconds_NSInteger.rawValue)] = maxBufferEndMilliSeconds
        }
        if let maxBufferEndTime = videoConfig["VEKKeyPlayerMaxBufferEndTime"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerMaxBufferEndTime_NSInteger.rawValue)] = NSNumber(value: maxBufferEndTime)
        }
        //////////////////////
        if let enableEnterBufferingDirectly = videoConfig["VEKKeyEnterBufferingDirectly"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyEnterBufferingDirectly_BOOL.rawValue)] = enableEnterBufferingDirectly == 1
        }
        if let directlyBufferingEndTimeMilliSecondsEnable = videoConfig["VEKKeyPlayerEnableDirectlyBufferingEndTimeMilliSeconds"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableDirectlyBufferingEndTimeMilliSeconds_BOOL.rawValue)] = directlyBufferingEndTimeMilliSecondsEnable == 1
        }
        if let directlyBufferingEndTimeMilliSeconds = videoConfig["VEKKeyPlayerDirectlyBufferingEndTimeMilliSeconds"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerDirectlyBufferingEndTimeMilliSeconds_NSInteger.rawValue)] = directlyBufferingEndTimeMilliSeconds
        }
        if let bufferingDirectlyRenderStartReportEnable = videoConfig["VEKKeyPlayerEnableBufferingDirectlyRenderStartReport"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableBufferingDirectlyRenderStartReport_BOOL.rawValue)] = bufferingDirectlyRenderStartReportEnable == 1
        }
        if let directlyBufferingSendVideoPacketEnable = videoConfig["VEKKeyPlayerEnableDirectlyBufferingSendVideoPacket"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyPlayerEnableDirectlyBufferingSendVideoPacket_BOOL.rawValue)] = directlyBufferingSendVideoPacketEnable == 1
        }
        //////////////////////
        if let medialoaderNativeEnable = videoConfig["VEKKeyMedialoaderNativeEnable"] as? Int {
            videoOptions[VEKKeyType(value: VEKKey.VEKKeyMedialoaderNativeEnable_BOOL.rawValue)] = medialoaderNativeEnable == 1
        }

        return videoOptions
    }
    
    func updateMDL(setting: [String: Any]) {
        let videoCacheConfig = TTVideoEngine.ls_localServerConfigure()
        if let maxCacheSize = setting["DATALOADER_KEY_INT_MAXCACHESIZE"] as? Int {
            videoCacheConfig.maxCacheSize = maxCacheSize
        }
        if let enableSoccketReuse = setting["DATALOADER_SOCCKET_REUSE_ENABLE"] as? Int {
            videoCacheConfig.enableSoccketReuse = enableSoccketReuse == 1
        }
        if let enableExternDNS = setting["DATALOADER_EXTERN_DNS_ENABLE"] as? Int {
            videoCacheConfig.enableExternDNS = enableExternDNS == 1
        }
        if (setting["DATALOADER_DNS_PARSE_TYPE_ENABLE"] as? Int) == 1 {
            TTVideoEngine.ls_mainDNSParseType(.local, backup: ReleaseConfig.isFeishu ? .httpTT : .httpGoogle)
        }
        if let maxTlsVersion = setting["DATALOADER_MAX_TLS_VERSION"] as? Int {
            videoCacheConfig.maxTlsVersion = maxTlsVersion
        }
        if let enableSessionReuse = setting["DATALOADER_SESSION_REUSE_ENABLE"] as? Int {
            videoCacheConfig.isEnableSessionReuse = enableSessionReuse == 1
        }
    }
}
