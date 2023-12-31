//
//  DriveAVPlayer.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/1/15.
//

import AVFoundation
import MediaPlayer
import SKCommon
import SKResource
import SKFoundation
import SKUIKit
import UniverseDesignColor
import LarkDocsIcon

class DriveAVPlayer: NSObject {
    class DriveAVPlayerView: UIView {
        let playerLayer: AVPlayerLayer
        init(player: AVPlayer) {
            self.playerLayer = AVPlayerLayer(player: player)
            super.init(frame: .zero)
            self.backgroundColor = UIColor.ud.N900.nonDynamic
            self.layer.addSublayer(playerLayer)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }

    class DriveAudioView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.ud.N900.nonDynamic
            // icon 只有 48x48 的大小，但是一直都被放大到 72 用
            let imageView = UIImageView(image: DriveFileType.mp3.roundImage)
            addSubview(imageView)
            imageView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.height.equalTo(72)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private(set) lazy var playerItem: AVPlayerItem = {
        let playerItem = AVPlayerItem(url: fileURL)
        return playerItem
    }()

    private(set) lazy var player: AVPlayer = {
        let player = AVPlayer(playerItem: playerItem)
        return player
    }()

    private lazy var avplayerView: UIView = {
        if self.playerItem.isVideoAvailable {
            return DriveAVPlayerView(player: player)
        } else if self.playerItem.isAudioAvailable {
            return DriveAudioView()
        } else {
            spaceAssertionFailure("no support type")
            return DriveAVPlayerView(player: player)
        }
    }()
    let fileURL: URL
    weak var delegate: DriveVideoPlayerDelegate?
    private var playbackTimeObserver: Any?
    // 是否是首次prepare
    private var isFirstPrepare: Bool = true
    // 是否播放结束
    private var didFinished: Bool = false

    init(url: URL) {
        self.fileURL = url
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didFinish(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        playerItem.addObserver(self,
                               forKeyPath: "status",
                               options: .new,
                               context: nil)
        player.addObserver(self,
                           forKeyPath: "timeControlStatus",
                           options: .new,
                           context: nil)
        playbackTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: nil) {[weak self] _ in
            guard let self = self else { return }
            if self.currentPlaybackTime > self.duration {
                // 当"实际播放的时长"比文件"总时长"更长时，主动停止播放，避免进度展示有问题
                self.player.pause()
                self.setupPlayerForFinish()
            } else {
                self.delegate?.videoPlayer(self, currentPlaybackTime: self.currentPlaybackTime, duration: self.duration)
            }
        }
    }

    deinit {
        DocsLogger.driveInfo("DriveAVPlayer deinit", category: "avplayer")
    }

    @objc
    private func didFinish(_ noti: NSNotification) {
        guard let item = noti.object as? AVPlayerItem,
              item == self.playerItem else {
            return
        }
        setupPlayerForFinish()
    }

    private func setupPlayerForFinish() {
        didFinished = true
        delegate?.videoPlayerDidFinish(self)
        updateNowPlayingInfo()
        DocsLogger.driveInfo("DidFinish currentTime: \(self.currentPlaybackTime) : \(self.duration)",
                             category: "avplayer")
    }

    private func resetPlayer(url: URL) {
        DocsLogger.driveInfo("resetPlayer url", category: "avplayer")
        playerItem.removeObserver(self, forKeyPath: "status")
        playerItem = AVPlayerItem(url: url)
        playerItem.addObserver(self,
                               forKeyPath: "status",
                               options: .new,
                               context: nil)
        self.player.replaceCurrentItem(with: playerItem)
    }

    private func resetPlayer() {
        DocsLogger.driveInfo("resetPlayer seek to zero", category: "avplayer")
        player.seek(to: .zero)
        didFinished = false
    }
}

extension DriveAVPlayer {
    // swiftlint:disable:next block_based_kvo
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            switch playerItem.status {
            case .readyToPlay:
                // Ready 时候更新一次视频时长，用于界面展示总时长。
                self.delegate?.videoPlayer(self, currentPlaybackTime: self.currentPlaybackTime, duration: self.duration)
                guard isFirstPrepare else { return }
                isFirstPrepare = false
                delegate?.videoPlayerPrepared(self)
            default:
                delegate?.videoPlayerPlayFail(self, error: playerItem.error, localPath: fileURL)
                DocsLogger.driveError("Play Fail: \(String(describing: playerItem.error))", category: "avplayer")
            }
        } else if keyPath == "timeControlStatus" {
            switch player.timeControlStatus {
            case .playing:
                DocsLogger.driveInfo("timeControlStatus playing", category: "avplayer")
                delegate?.videoPlayer(self, playbackStateDidChanged: .playing)
                updateNowPlayingInfo()
            case .paused:
                DocsLogger.driveInfo("timeControlStatus paused", category: "avplayer")
                delegate?.videoPlayer(self, playbackStateDidChanged: .paused)
                updateNowPlayingInfo()
            default:
                return
            }
        }
    }

    private func updateNowPlayingInfo(currentTime: Double? = nil) {
        guard mediaType == .audio else { return }
        var title: String = ""
        var artist: String = ""
        for item in playerItem.asset.metadata {
            if item.commonKey?.rawValue == "title", let value = item.value as? String {
                title = value
            }
            if item.commonKey?.rawValue == "artist", let value = item.value as? String {
                artist = value
            }
        }
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = [MPMediaItemPropertyTitle: title,
                                 MPMediaItemPropertyArtist: artist,
                                 MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
                                 MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime ?? player.currentTime().seconds,
                                 MPNowPlayingInfoPropertyPlaybackRate: player.rate]
        DocsLogger.driveInfo("Drive audio NowPlayingInfo update \(String(describing: center.nowPlayingInfo))", category: "avplayer")
    }

    private func setupRemoteCommand() {
        // 锁屏界面的操作回调
        let command = MPRemoteCommandCenter.shared()
        // 快进10s
        command.skipForwardCommand.isEnabled = true
        command.skipForwardCommand.preferredIntervals = [10]
        command.skipForwardCommand.addTarget(self, action: #selector(skipForwardCommandAction))
        // 倒退10s
        command.skipBackwardCommand.isEnabled = true
        command.skipBackwardCommand.preferredIntervals = [10]
        command.skipBackwardCommand.addTarget(self, action: #selector(skipBackwardCommandAction))
        // 进度条
        command.changePlaybackPositionCommand.isEnabled = true
        command.changePlaybackPositionCommand.addTarget(self, action: #selector(changePlaybackPositionCommandAction(event:)))
        // 开始
        command.playCommand.isEnabled = true
        command.playCommand.addTarget(self, action: #selector(playCommandAction))
        // 暂停
        command.pauseCommand.isEnabled = true
        command.pauseCommand.addTarget(self, action: #selector(pauseCommandAction))
    }

    @objc
    private func skipForwardCommandAction() -> MPRemoteCommandHandlerStatus {
        let newTime = self.player.currentTime().seconds + 10.0
        self.player.seek(to: CMTimeMakeWithSeconds(newTime, preferredTimescale: 1),
                         toleranceBefore: .zero,
                         toleranceAfter: .zero,
                         completionHandler: { _ in
                            self.updateNowPlayingInfo()
                         })
        DocsLogger.driveInfo("Drive audio skipForwardCommand kickoff", category: "avplayer")
        return .success
    }

    @objc
    private func skipBackwardCommandAction() -> MPRemoteCommandHandlerStatus {
        let newTime = self.player.currentTime().seconds - 10.0
        self.player.seek(to: CMTimeMakeWithSeconds(newTime, preferredTimescale: 1),
                         toleranceBefore: .zero,
                         toleranceAfter: .zero,
                         completionHandler: { _ in
                            self.updateNowPlayingInfo()
                         })
        DocsLogger.driveInfo("Drive audio skipBackwardCommand kickoff", category: "avplayer")
        return .success
    }

    @objc
    private func changePlaybackPositionCommandAction(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard let event = event as? MPChangePlaybackPositionCommandEvent else {
            return .commandFailed
        }
        self.player.seek(to: CMTimeMakeWithSeconds(event.positionTime, preferredTimescale: 1),
                         toleranceBefore: .zero,
                         toleranceAfter: .zero,
                         completionHandler: { _ in })
        self.updateNowPlayingInfo(currentTime: event.positionTime)
        DocsLogger.driveInfo("Drive audio changePlaybackPositionCommand kickoff", category: "avplayer")
        return .success
    }

    @objc
    private func playCommandAction() -> MPRemoteCommandHandlerStatus {
        self.play()
        DocsLogger.driveInfo("Drive audio playCommand kickoff", category: "avplayer")
        return .success
    }

    @objc
    private func pauseCommandAction() -> MPRemoteCommandHandlerStatus {
        self.pause()
        DocsLogger.driveInfo("Drive audio pauseCommand kickoff", category: "avplayer")
        return .success
    }

    private func removeCommandTarget() {
        let command = MPRemoteCommandCenter.shared()
        command.skipForwardCommand.removeTarget(self)
        command.skipBackwardCommand.removeTarget(self)
        command.changePlaybackPositionCommand.removeTarget(self)
        command.playCommand.removeTarget(self)
        command.pauseCommand.removeTarget(self)
    }
}

extension DriveAVPlayer: DriveVideoPlayer {
    func addRemoteCommandObserverIfNeeded() {
        guard mediaType == .audio else { return }
        setupRemoteCommand()
    }

    func removeRemoteCommandObserverIfNeeded() {
        guard mediaType == .audio else { return }
        removeCommandTarget()
    }

    var mediaType: DriveMediaType {
        if playerItem.isVideoAvailable {
            return .video
        } else if playerItem.isAudioAvailable {
            return .audio
        } else {
            spaceAssertionFailure("no support type")
            return .unknown
        }
    }

    var muted: Bool {
        get { return player.isMuted }
        set { player.isMuted = newValue }
    }

    var playerView: UIView {
        return avplayerView
    }

    var currentPlaybackTime: Double {
        return player.currentTime().seconds
    }

    var duration: Double {
        return player.currentItem?.duration.seconds ?? 0
    }

    var playbackState: DriveVideoPlaybackState {
        switch player.timeControlStatus {
        case .paused:
            return .paused
        case .waitingToPlayAtSpecifiedRate:
            return .paused
        case .playing:
            return .playing
        @unknown default:
            return .error
        }
    }

    var isLandscapeVideo: Bool {
        if self.playerItem.isVideoAvailable {
            if let view = self.avplayerView as? DriveAVPlayerView {
                let height = view.playerLayer.videoRect.height
                let width = view.playerLayer.videoRect.width
                // ipad不处理
                if height != 0, width / height > CGFloat(4.0 / 3.0), !SKDisplay.pad {
                    return true
                } else {
                    return false
                }
            } else {
                spaceAssertionFailure("cannot get video bounds")
                return false
            }
        } else if self.playerItem.isAudioAvailable {
            return false
        } else {
            spaceAssertionFailure("no support type")
            return false
        }
    }

    func setup(directUrl url: String, taskKey: String, shouldPlayForCover: Bool) {
        spaceAssertionFailure("avplayer no support to directUrl")
    }

    func setup(cacheUrl url: URL, shouldPlayForCover: Bool) {
        spaceAssertionFailure("avplayer no support to cacheUrl")
    }

    func play() {
        DocsLogger.driveInfo("play", category: "avplayer")
        if didFinished {
            // 播放结束重新开始播放前，resetPlayer回到初始状态
            resetPlayer()
        }
        player.play()
    }

    func stop() {
        DocsLogger.driveInfo("stop", category: "avplayer")
        player.seek(to: .zero)
        player.pause()
    }

    func pause() {
        DocsLogger.driveInfo("paused", category: "avplayer")
        player.pause()
    }

    func seek(progress: Float, completion: ((Bool) -> Void)?) {
        let time = player.currentItem?.duration.seconds
        let newTime = (time ?? 0) * Double(progress)
        player.seek(to: CMTimeMakeWithSeconds(newTime, preferredTimescale: 1),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero,
                    completionHandler: {[weak self] isFinished in
                        completion?(isFinished)
                        self?.updateNowPlayingInfo()
                    })
    }

    func removeTimeObserver() {
        DocsLogger.driveInfo("removeTimeObserver", category: "avplayer")
        self.player.removeTimeObserver(playbackTimeObserver as Any)
    }

    func close() {
        playerItem.removeObserver(self, forKeyPath: "status")
        player.removeObserver(self, forKeyPath: "timeControlStatus")
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
    }

    func resume(_ url: String, taskKey: String) {
        self.resetPlayer(url: URL(fileURLWithPath: url))
        self.player.play()
    }
}

extension AVPlayerItem {
    // 音频，视频判定为true
    var isAudioAvailable: Bool {
        return !self.asset.tracks.filter({ $0.mediaType == AVMediaType.audio }).isEmpty
    }

    // 视频判定为true
    var isVideoAvailable: Bool {
        return !self.asset.tracks.filter({ $0.mediaType == AVMediaType.video }).isEmpty
    }
}
