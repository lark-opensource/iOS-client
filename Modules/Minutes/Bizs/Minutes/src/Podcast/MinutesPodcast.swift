//
//  MinutesPodcast.swift
//  Minutes
//
//  Created by yangyao on 2021/4/7.
//

import UIKit
import MinutesFoundation
import MinutesNetwork
import EENavigator
import Kingfisher
import UniverseDesignToast
import MediaPlayer
import TTVideoEngine
import LarkSuspendable
import LarkContainer

extension Minutes {
    private struct AssociatedKeys {
        static var podcastAutoPlayKey = "podcastAutoPlayKey"
    }
    var podcastAutoPlay: Bool {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.podcastAutoPlayKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.podcastAutoPlayKey) as? Bool {
                return value
            }
            return true
        }
    }
}

extension MinutesInfoStatus {
    var isValid: Bool {
        switch self {
        case .unkown, .complete, .fetchingData, .ready:
            return true
        default:
            return false
        }
    }
}

public protocol MinutesPodcastDelegate: AnyObject {
    func podcastMinutesChanged(data: Minutes?)
}

public final class MinutesPodcast: NSObject {
    public static let shared = MinutesPodcast()

    public var isInPodcast: Bool = false {
        didSet {
            guard oldValue != isInPodcast else { return }
            if isInPodcast {
                InnoPerfMonitor.shared.entry(scene: .minutesPodcast)
                LKMonitor.beginEvent(event: "minutes_podcast")
            } else {
                InnoPerfMonitor.shared.leave(scene: .minutesPodcast)
                LKMonitor.endEvent(event: "minutes_podcast")
            }
        }
    }

    var minutes: Minutes? {
        didSet {
            guard oldValue !== minutes || minutes == nil else { return }

            let minutes = self.minutes
            DispatchQueue.main.async {
                self.delegate?.podcastMinutesChanged(data: minutes)
                self.updatePodcastStatus()
            }

            if let info = minutes?.info {
                tracker = MinutesTracker(info: info)
            } else {
                tracker = BusinessTracker()
            }

            var extra: [String: Any] = [:]
            extra["objectToken"] = minutes?.objectToken ?? ""
            extra["hasVideo"] = minutes?.basicInfo?.mediaType == .video
            extra["contentSize"] = minutes?.data.subtitlesContentSize ?? 0
            extra["mediaDuration"] = minutes?.basicInfo?.duration ?? 0
            InnoPerfMonitor.shared.update(extra: extra)
        }
    }

    public weak var delegate: MinutesPodcastDelegate?
    
    var backgroundImageURLs: [URL] = []

    lazy var api = MinutesAPI.clone()
    lazy var imageDownloader: ImageDownloader = MinutesAPI.imageDownloader

    lazy var startTime: Date = Date()

    lazy var tracker: BusinessTracker = BusinessTracker()

    var activeTimer: Timer?
    
    weak var player: MinutesVideoPlayer?

    weak var videoEngine: TTVideoEngine? {
        player?.videoEngine
    }
    
    public var duration: TimeInterval {
        return videoEngine?.duration ?? 0.0
    }
    
    var userResolver: UserResolver?
    public func startPodcast(for minutes: Minutes, player: MinutesVideoPlayer?, resolver: UserResolver) {
        if !isInPodcast {
            startTime = Date()
            isInPodcast = true
            startActiveTimer()
        }
        self.userResolver = resolver
        self.minutes = minutes
        self.player = player
        clearTranslateData()
        configRemoteCommandCenter()
    }

    public func stopPodcast() {
        if isInPodcast {
            stopActiveTimer()
            isInPodcast = false
            removeCommandCenterTarget()
        }
        self.minutes = nil
        MinutesPodcastSuspendable.removePodcastSuspendable()
    }

    public func pausePodcast() {
        self.player?.pause()
    }
    
    private func clearTranslateData() {
        self.minutes?.translateData = nil
    }
    
    private func startActiveTimer() {
        guard activeTimer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true, block: { [weak self] _ in
            self?.flushPodcastStatus()
        })
        activeTimer = timer
    }

    private func stopActiveTimer() {
        guard activeTimer != nil else { return }
        activeTimer?.fire()
        activeTimer?.invalidate()
        activeTimer = nil
    }

    private func flushPodcastStatus() {
        guard isInPodcast else { return }
        let now = Date()
        let duration = now.timeIntervalSince(startTime)
        startTime = now
        tracker.tracker(name: .podcastStatus, params: ["duration": Int(duration * 1000)])
    }

    public var hasNext: Bool {
        guard let minutes = self.minutes else {
            return false
        }
        let currentURL = minutes.baseURL
        let urlList = minutes.podcastURLList
        if urlList.isEmpty { return false }
        if urlList.last == currentURL {
            return false
        }
        return true
    }

    public var hasPrev: Bool {
        guard let minutes = self.minutes else {
            return false
        }
        let currentURL = minutes.baseURL
        let urlList = minutes.podcastURLList
        if urlList.isEmpty { return false }
        if urlList.first == currentURL {
            return false
        }
        return true
    }

    public func playNextMinutes() {
        guard let minutes = self.minutes else { return }
        minutes.podcastAutoPlay = false
        guard hasNext else { return }
        let currentURL = minutes.baseURL
        let urlList = minutes.podcastURLList
        let index = (urlList.firstIndex(of: currentURL) ?? 0) + 1
        let url = urlList[index]
        if let minutes = Minutes(url) {
            minutes.podcastURLList = urlList
            self.minutes = minutes
        }
    }

    public func playPrevMinutes() {
        guard let minutes = self.minutes else { return }
        guard hasPrev else { return }
        let currentURL = minutes.baseURL
        let urlList = minutes.podcastURLList
        let index = (urlList.firstIndex(of: currentURL) ?? 1) - 1
        let url = urlList[index]
        if let minutes = Minutes(url) {
            minutes.podcastURLList = urlList
            self.minutes = minutes
        }
    }
    
    public func play() {
        MinutesLogger.podcast.info("play")
        videoEngine?.play()
        mediaInfoConfiguration()
    }

    public func pause() {
        MinutesLogger.podcast.info("pause")
        videoEngine?.pause()
        mediaInfoConfiguration()
    }

    public func invalidMinutes(_ currentURL: URL) {
        guard let minutes = self.minutes, minutes.baseURL == currentURL else { return }
        var urlList = minutes.podcastURLList
        guard urlList.contains(currentURL) else { return }

        var shouldAutoPlay: Bool = true
        let url: URL?
        if urlList.last == currentURL {
            urlList.removeLast()
            url = urlList.last
            shouldAutoPlay = false
            showToast(BundleI18n.Minutes.MMWeb_G_NoPlayableMinutes)
        } else {
            let index = (urlList.lastIndex(of: currentURL) ?? 0) + 1
            url = urlList[index]
            urlList.removeAll(where: { $0 == currentURL })
        }

        if let baseURL = url {
            if let minutes = Minutes(baseURL) {
                minutes.podcastURLList = urlList
                minutes.podcastAutoPlay = shouldAutoPlay
                self.minutes = minutes
            }
        } else {
            self.minutes = nil
        }
    }

    public func updatePodcastStatus() {
        guard let minutes = self.minutes else { return }
        if MinutesPodcastSuspendable.isExistPodcastSuspendable() {
            // 后台操作控制中心不知为何floatview不会销毁
            self.player?.clearEngine()

            let speed = MinutesPodcastSuspendable.currentPlayer()?.playbackSpeed ?? 1.0
            let player = MinutesVideoPlayer(resolver: userResolver, minutes: minutes)
            player.playbackSpeed = speed
            // 切换下一首之后，update
            self.player = player
           
            guard let userResolver = userResolver else { return }
            let podcastFloatingView = MinutesPodcastFloatingView(videoPlayer: player, resolver: userResolver)
            podcastFloatingView.onTapViewBlock = { [weak self] resolver in
                DispatchQueue.main.async {
                    let body = MinutesPodcastBody(minutes: minutes, player: player)
                    guard let from = resolver.navigator.mainSceneTopMost else { return }
                    resolver.navigator.push(body: body, from: from, animated: true, completion: { (_, response) in
                        if response.error != nil { return }
                        MinutesPodcastSuspendable.removePodcastSuspendable()
                    })
                }
            }
            MinutesPodcastSuspendable.addPodcastSuspendable(customView: podcastFloatingView, size: MinutesPodcastFloatingView.viewSize)

        }
    }

    public func loadBackgoundImage(index number: Int = 0, completionHandler: ((UIImage) -> Void)? = nil) {
        if backgroundImageURLs.isEmpty {
            Minutes.fetchPodcastBackground { [weak self] result in
                switch result {
                case .success(let response):
                    MinutesLogger.podcast.info("download podcast background image list[\(response.imageUrls.count)] success")
                    self?.backgroundImageURLs = response.imageUrls
                    self?.chooseBackgroundImage(index: number, completionHandler: completionHandler)
                case .failure(let error):
                    MinutesLogger.podcast.warn("download podcast background image list error: \(error)")
                }
            }
        } else {
            chooseBackgroundImage(index: number, completionHandler: completionHandler)
        }

    }

    private func chooseBackgroundImage(index number: Int = 0, completionHandler: ((UIImage) -> Void)? = nil) {
        guard !backgroundImageURLs.isEmpty else { return }
        let count = backgroundImageURLs.count
        let hashcode = number < 0 ? (0 - number) : number
        let index = hashcode % count
        let url = backgroundImageURLs[index]
        imageDownloader.downloadImage(with: url) { result in
            switch result {
            case .success(let value):
                MinutesLogger.podcast.info("download podcast background image(\(index)) success")
                DispatchQueue.main.async {
                    completionHandler?(value.image)
                }
            case .failure(let error):
                MinutesLogger.podcast.warn("download podcast background image(\(index)) error: \(error)")
            }
        }

    }

    private func showToast(_ toastString: String) {
        DispatchQueue.main.async {
            let targetView = self.userResolver?.navigator.mainSceneWindow?.fromViewController?.view
            MinutesToast.showTips(with: toastString, targetView: targetView)
        }
    }

}

extension MinutesPodcast {
    func configRemoteCommandCenter() {

        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        remoteCommandCenter.playCommand.addTarget(self, action: #selector(playCommand))
        remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(pauseCommand))
        remoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(changePlaybackPositionCommand(event:)))
        remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(nextTrackCommand))
        remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(previousTrackCommand))
        remoteCommandCenter.nextTrackCommand.isEnabled = hasNext
        remoteCommandCenter.previousTrackCommand.isEnabled = hasPrev
        remoteCommandCenter.skipForwardCommand.isEnabled = false
        remoteCommandCenter.skipBackwardCommand.isEnabled = false
    }
    
    @objc
    func playCommand() -> MPRemoteCommandHandlerStatus {
        MinutesLogger.podcast.info("remote command play.")
        play()
        mediaInfoConfiguration()
        return .success
    }

    @objc
    func pauseCommand() -> MPRemoteCommandHandlerStatus {
        MinutesLogger.podcast.info("remote command pause.")
        pause()
        mediaInfoConfiguration()
        return .success
    }

    func mediaInfoConfiguration() {
        guard let infos = minutes?.info else { return }

        let title = infos.basicInfo?.topic
        let owner = infos.basicInfo?.ownerInfo?.userName
        let image = player?.coverView.image

        if player?.isAudioOnly == true {
            audioInfoConfiguration(title: title ?? "", owner: owner ?? "")
            return
        }

        let player = player
        DispatchQueue.main.async {
            var info: [String: Any] = Dictionary()
            info[MPMediaItemPropertyTitle] = title
            info[MPMediaItemPropertyArtist] = owner
            info[MPMediaItemPropertyPlaybackDuration] = self.duration
            info[MPNowPlayingInfoPropertyPlaybackRate] = player?.currentPlayerStatus == .playing ? player?.playbackSpeed ?? 1.0 : 1.0

            if  player?.shouldSavePlayTime == true {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentPlaybackTime.time ?? 0.0
            } else {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
            }
            let artWork = MPMediaItemArtwork(boundsSize: image?.size ?? CGSize(width: 0, height: 0), requestHandler: { (_) -> UIImage in
                return (image ?? UIImage())
            })
            info[MPMediaItemPropertyArtwork] = artWork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    func audioInfoConfiguration(title: String, owner: String) {
        let player = player
        DispatchQueue.main.async {
            var info: [String: Any] = Dictionary()
            info[MPMediaItemPropertyTitle] = title
            info[MPMediaItemPropertyArtist] = owner
            info[MPMediaItemPropertyPlaybackDuration] = self.duration
            info[MPNowPlayingInfoPropertyPlaybackRate] = player?.currentPlayerStatus == .playing ? player?.playbackSpeed ?? 1.0 : 1.0

            if  player?.shouldSavePlayTime == true {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentPlaybackTime.time ?? 0.0
            } else {
                info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
    
    @objc
    func changePlaybackPositionCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        let seconds = (event as? MPChangePlaybackPositionCommandEvent)?.positionTime ?? 0

        MinutesLogger.podcast.info("remote command change play back posisiton to \(seconds).")
        seekVideoPlaybackTime(seconds)
        mediaInfoConfiguration()
        return .success
    }

    public func seekVideoPlaybackTime(_ currentPlaybackTime: TimeInterval, manualOffset: NSInteger = 0, didTappedRow: NSInteger? = nil) {

        DispatchQueue.main.async {
            self.mediaInfoConfiguration()
        }
        self.videoEngine?.setCurrentPlaybackTime(currentPlaybackTime) { _ in
        }
    }
    
    func removeCommandCenterTarget() {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.playCommand.removeTarget(self)
        remoteCommandCenter.pauseCommand.removeTarget(self)
        remoteCommandCenter.changePlaybackPositionCommand.removeTarget(self)
        remoteCommandCenter.nextTrackCommand.removeTarget(self)
        remoteCommandCenter.previousTrackCommand.removeTarget(self)
    }

    @objc
    private func nextTrackCommand() -> MPRemoteCommandHandlerStatus {
        MinutesLogger.podcast.info("remote command netxt track")
        playNextMinutes()
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.nextTrackCommand.isEnabled = hasNext
        remoteCommandCenter.previousTrackCommand.isEnabled = hasPrev
        return .success
    }

    @objc
    private func previousTrackCommand() -> MPRemoteCommandHandlerStatus {
        MinutesLogger.podcast.info("remote command previous track")
        playPrevMinutes()
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.nextTrackCommand.isEnabled = hasNext
        remoteCommandCenter.previousTrackCommand.isEnabled = hasPrev
        return .success
    }
}
