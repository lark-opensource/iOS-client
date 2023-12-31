//
//  MinutesVideoView.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import SnapKit
import LarkUIKit
import MinutesFoundation
import MinutesNetwork
import Lottie
import AppReciableSDK
import LarkContainer
import UniverseDesignIcon

enum MinutesVideoViewStatus {
    case perpare
    case playing
    case paused
    case stopped
    case loading
    case error

    func buttonImage(_ isFinish: Bool) -> UIImage? {

        if isFinish {
            return BundleResources.Minutes.minutes_refresh_outlined
        }

        switch self {
        case .paused, .stopped:
            return UDIcon.getIconByKey(.playFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 36, height: 36))
        case .playing:
            return UDIcon.getIconByKey(.pauseFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 36, height: 36))
        case .error:
            return UDIcon.getIconByKey(.videoOffFilled, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))
        default:
            return nil
        }
    }

    func shouldHideErrorBackground() -> Bool {
        switch self {
        case .error:
            return false
        default:
            return true
        }
    }

    func isLoading() -> Bool {
        switch self {
        case .loading, .perpare:
            return true
        default:
            return false
        }
    }

    func shouldHideCover() -> Bool {
        switch self {
        case .perpare, .stopped:
            return false
        default:
            return true
        }
    }

    func toLoading() -> MinutesVideoViewStatus {
        switch self {
        case .playing:
            return .loading
        default:
            return self
        }
    }

    func toError() -> MinutesVideoViewStatus {
        return .error
    }

    func toPerpare() -> MinutesVideoViewStatus {
        switch  self {
        case .error:
            return .error
        default:
            return .perpare
        }
    }

    func toPaused() -> MinutesVideoViewStatus {
        switch self {
        case .stopped:
            return .stopped
        default:
            return .paused
        }
    }

    func toStopped() -> MinutesVideoViewStatus {
        return .stopped
    }
}

enum MinutesMediaType {
    case video
    case audio
    case text
}

class MinutesSpeakerView: UIView {
    let speakerNameLbl: UILabel = UILabel()
    let timeLbl: UILabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
        addSubview(speakerNameLbl)
        addSubview(timeLbl)

        speakerNameLbl.font = .systemFont(ofSize: 16, weight: .medium)
        timeLbl.font = .systemFont(ofSize: 14, weight: .medium)

        speakerNameLbl.textColor = UIColor.ud.staticWhite
        timeLbl.textColor = UIColor.ud.staticWhite

        speakerNameLbl.snp.makeConstraints { make in
            make.left.greaterThanOrEqualToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalTo(self.snp.centerY)
            make.centerX.equalToSuperview()
        }
        timeLbl.snp.makeConstraints { make in
            make.left.greaterThanOrEqualToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.top.equalTo(self.snp.centerY).offset(2)
            make.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesVideoView: UIView {
    var isFullscreen: Bool = false
    lazy var isLandscape: Bool = {
        let size: CGSize = self.bounds.size
        return size.width > size.height
    }()

    class ActiveTimer {
        private(set) var lastActiveTime: TimeInterval = -10.0 {
            didSet {
                guard oldValue != lastActiveTime else { return }
                isFired = false
            }
        }

        func updateActiveTime(_ time: TimeInterval) {
            lastActiveTime = time
        }

        func fire() {
            lastActiveTime = -10.0
            isFired = true
        }

        func updateTime(_ time: TimeInterval) {
            isFired = (time - lastActiveTime) > 5
        }

        var isFired: Bool = false {
            didSet {
                guard oldValue != isFired, isFired else { return }
                onFired?(self)
            }
        }

        var onFired: ((ActiveTimer) -> Void)?
        var onReset: ((ActiveTimer) -> Void)?
    }

    let player: MinutesVideoPlayer
    let activeTimer: ActiveTimer = ActiveTimer()
    var shouldShowControlBar: Bool = true

    var coverView: UIImageView {
        return player.coverView
    }

    lazy var errorBackground: UIView = UIView()

    var videoDuration: Int = 0 {
        didSet {
            miniControllBar.videoDuration = videoDuration
        }
    }
    var chapters: [MinutesChapterInfo] = [] {
        didSet {
            miniControllBar.chapters = chapters
        }
    }

    func showSpeaker(_ name: String, time: String) {
        miniControllBar.isHidden = true
        speakerView.isHidden = false

        speakerView.speakerNameLbl.text = name
        speakerView.timeLbl.text = time
    }

    func hideSpeaker() {
        miniControllBar.isHidden = false
        speakerView.isHidden = true
    }

    let speakerView = MinutesSpeakerView()

    lazy var miniControllBar: MinutesMiniVideoControlView = {
        let control = MinutesMiniVideoControlView(resolver: userResolver, player: player, timer: activeTimer, isInCCMfg: isInCCMfg)
        control.delegate = self
        if player.minutes.isClip {
            control.shouldShowPodcast = false
        } else {
            control.shouldShowPodcast = true
        }
        control.tapScreenBlock = { [weak self] in
            self?.onTapScreen()
        }
        control.showLoadingBlock = { [weak self] in
            self?.loadingView.play()
            self?.loadingView.isHidden = false
        }
        control.hideLoadingBlock = { [weak self] in
            self?.loadingView.stop()
            self?.loadingView.isHidden = true
        }
        return control
    }()

    lazy var subtitlePlayer: MinutesSubtitlePlayer = {
        let subtitlePlayer = MinutesSubtitlePlayer(fatherView: self, minutes: player.minutes)
        return subtitlePlayer
    }()

    lazy var loadingView: LOTAnimationView = {
        let jsonPath = BundleConfig.MinutesBundle.path(
            forResource: "minutes_video_loading",
            ofType: "json",
            inDirectory: "lottie")
        let view = jsonPath.flatMap { LOTAnimationView(filePath: $0) } ?? LOTAnimationView()
        view.contentMode  = .scaleAspectFit
        view.loopAnimation = true
        // 默认隐藏
        view.isHidden = true
        return view
    }()

    var status: MinutesVideoViewStatus = .perpare {
        didSet {
            guard oldValue != status else { return }
            MinutesLogger.video.info("status changed to \(status)")
            DispatchQueue.main.async {
                self.shouldShowControlBar = true
                self.updateUIStyle()
            }

        }
    }

    lazy var audioBgView: MinutesAudioBgView = {
        let v = MinutesAudioBgView()
        v.isHidden = true
        return v
    }()

    var mediaType: MinutesMediaType = .video {
        didSet {
            audioBgView.isHidden = mediaType == .video
        }
    }

    let isInCCMfg: Bool
    let userResolver: UserResolver
    init(resolver: UserResolver, player: MinutesVideoPlayer, isInCCMfg: Bool) {
        self.userResolver = resolver
        self.player = player
        self.isInCCMfg = isInCCMfg
        super.init(frame: .zero)
        setupSubviews()

        player.listeners.addListener(self)

        activeTimer.onFired = { [weak self] _ in
            self?.shouldShowControlBar = false
            self?.updateUIStyle()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside: CGPoint, with: UIEvent?) -> Bool {
        var rect = bounds
        rect.size.height = bounds.height + 10
        return rect.contains(inside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coverView.frame = bounds
        player.playerView.frame = bounds
    }

    func setupSubviews() {
        if player.videoEngineInit {
            let playerView = player.playerView
            self.addSubview(playerView)
        }
        let coverView = player.coverView
        self.addSubview(coverView)

        addSubview(audioBgView)
        audioBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        errorBackground.backgroundColor = UIColor.ud.N1000.nonDynamic
        self.addSubview(errorBackground)
        errorBackground.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        self.openSubtitle()
        self.updateSubtitleState()

        addSubview(miniControllBar)
        miniControllBar.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.width.equalTo(51)
            maker.height.equalTo(30)
        }
        self.addSubview(speakerView)
        speakerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        speakerView.isHidden = true

        let tapScreen = UITapGestureRecognizer(target: self, action: #selector(onTapScreen))
        self.addGestureRecognizer(tapScreen)

        updatePlayerStatus(player.currentPlayerStatus)
    }

    @objc func onTapScreen() {
        activeTimer.updateActiveTime(player.currentPlaybackTime.time)
        shouldShowControlBar = !shouldShowControlBar
        self.updateUIStyle()
    }

    func updateUIStyle(_ landscape: Bool? = nil) {
        coverView.isHidden = status.shouldHideCover()
        errorBackground.isHidden = status.shouldHideErrorBackground()

        let isLandscape = landscape ?? self.isLandscape
        miniControllBar.isLandscape = isLandscape
        miniControllBar.isControlBarShowing = shouldShowControlBar
        let shouldShowMiniControllBar = !isLandscape && shouldShowControlBar
        let shouldShowOverlayControllBar = isLandscape && shouldShowControlBar

        if let landscapeStyle = landscape, landscapeStyle != self.isLandscape {
            self.isLandscape = landscapeStyle
            self.updateSubtitleState()
        }

        updateOverlayController(shouldShowOverlayControllBar)
        updateMiniController(shouldShowMiniControllBar)
        miniControllBar.updateUIStyle(isSubtitleShown: subtitlePlayer.isShown)
        miniControllBar.configureChapter { [weak self] in
            if landscape == true {
                self?.updateOverlayController(shouldShowOverlayControllBar)
            }
        }
    }

    func updateOverlayController(_ shouldShow: Bool) {
        miniControllBar.setLandscapeControl(isHidden: !shouldShow)
    }

    func updateMiniController(_ shouldShow: Bool) {
        miniControllBar.setPortraitControl(isHidden: !shouldShow)
        miniControllBar.setSlider(isHidden: isLandscape)
    }

    func updatePlayerStatus(_ playerStatus: MinutesVideoPlayerStatus){
        MinutesLogger.video.info("update status from \(status) with playerStatus: \(playerStatus)")
        activeTimer.updateActiveTime(player.currentPlaybackTime.time)
        switch playerStatus {
        case .playing:
            status = .playing
        case .loading:
            status = status.toLoading()
        case .error:
            status = status.toError()
            if let error = player.lastError {
                let extra = Extra(isNeedNet: true, category: ["object_token": player.minutes.objectToken])

                MinutesReciableTracker.shared.error(scene: .MinutesDetail,
                                                    event: .minutes_media_play_error,
                                                    userAction: "rename",
                                                    error: error,
                                                    extra: extra)
            }
        case .paused:
            status = status.toPaused()
        case .stopped:
            status = status.toStopped()
        case .perpare:
            status = status.toPerpare()
        default:
            break
        }

        if playerStatus == .error {
            let error = player.lastError ?? NSError(domain: "Load error", code: -1)
            let extra = Extra(isNeedNet: true, category: ["object_token": player.minutes.objectToken])

            MinutesReciableTracker.shared.error(scene: .MinutesDetail,
                                                event: .minutes_media_play_error,
                                                page: "detail",
                                                error: error,
                                                extra: extra)
            player.lastError = nil
        }
        if Int(player.duration * 1000 - player.currentPlaybackTime.time * 1000) < 200 {
            player.tracker.tracker(name: .detailClick, params: ["click": "video_play_finish", "target": "none"])
        }
    }

    func updateTime(_ time: PlaybackTime) {
        DispatchQueue.main.async {
            self.activeTimer.updateTime(time.time)
        }
    }
}

extension MinutesVideoView:MinutesVideoPlayerListener {
    func videoEngineDidLoad() {
        if !player.videoEngineInit {
            self.insertSubview(player.playerView, at: 0)
        }
    }

    func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {
        self.updatePlayerStatus(status.videoPlayerStatus)
    }

    func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        self.updateTime(time)
        self.subtitlePlayer.play(time)
    }
}

extension MinutesVideoView {
    public func openSubtitle() {
        subtitlePlayer.shouldShown = true
        subtitlePlayer.openSubtitle()
    }

    public func showSubtitle() {
        subtitlePlayer.shouldShown = true
        subtitlePlayer.showSubtitle()
    }

    public func hideSubtitle() {
        subtitlePlayer.shouldShown = false
        subtitlePlayer.hideSubtitle()
    }

    public func updateSubtitleState() {
        subtitlePlayer.updateSubtitle()
    }
}


extension MinutesVideoView: MinutesMiniVideoControlViewDelegate {
    func miniVideoControlViewDidLoad() {
    }

    func subtitleShownDidChange() -> Bool {
        if subtitlePlayer.isShown {
            hideSubtitle()
            return false
        } else {
            showSubtitle()
            return true
        }
    }
}

extension MinutesVideoView {
    func getVideoImage() -> UIImage? {
        guard coverView.isHidden else { return coverView.image }
        let size = bounds.size
        let render = UIGraphicsImageRenderer(bounds: bounds)
        let image = render.image { context in
            layer.render(in: context.cgContext)
        }
        if size.width > size.height {
            return image
        } else {
            let height = size.width * 9 / 16
            let y = (size.height - height) / 2
            return image.mins.cropping(to: CGRect(x: 0, y: y, width: size.width, height: height))
        }
    }
}
