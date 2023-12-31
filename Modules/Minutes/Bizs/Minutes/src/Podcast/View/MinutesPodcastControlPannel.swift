//
//  MinutesPodcastControlPannel.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/4/7.
//

import Foundation
import SnapKit
import LarkUIKit
import UniverseDesignColor
import EENavigator
import LarkExtensions
import MinutesFoundation
import UniverseDesignIcon

class MinutesPodcastControlPannel: UIView {
    let player: MinutesVideoPlayer

    init(_ player: MinutesVideoPlayer) {
        self.player = player
        super.init(frame: .zero)

        player.listeners.addListener(self)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let currentTimeLabel: UILabel = UILabel()
    let endTimeLabel: UILabel = UILabel()
    let sliderPoint: UIView = UIView()
    let slider: UIView = UIView()
    private var timelines: [UIView] = []
    weak var loadingView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
        }
    }

    let forwardButton: UIButton = UIButton()
    let backwardButton: UIButton = UIButton()
    let lastButton: UIButton = UIButton()
    let nextButton: UIButton = UIButton()
    let playButton: UIButton = UIButton()
    let exitButton: UIButton = UIButton()

    var isSeeking: Bool = false

    // disable-lint: long_function
    func setupSubviews() {
        addSubview(slider)
        slider.backgroundColor = UIColor.clear
        slider.snp.makeConstraints { maker in
            maker.left.equalToSuperview().inset(20)
            maker.right.equalToSuperview().inset(20)
            maker.top.equalTo(self.snp.top).offset(4)
            maker.height.equalTo(46)
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onGesture))
        pan.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(onGesture))
        slider.addGestureRecognizer(pan)
        slider.addGestureRecognizer(tap)

        let sliderBackgourand = UIView()
        slider.addSubview(sliderBackgourand)
        sliderBackgourand.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.2)
        sliderBackgourand.snp.makeConstraints { maker in
            maker.left.right.centerY.equalToSuperview()
            maker.height.equalTo(2)
        }

        let sliderLine = UIView()
        slider.addSubview(sliderLine)
        sliderLine.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.5)
        sliderLine.snp.makeConstraints { maker in
            maker.left.centerY.height.equalTo(sliderBackgourand)
        }

        slider.addSubview(sliderPoint)
        sliderPoint.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        sliderPoint.layer.cornerRadius = 6
        sliderPoint.snp.makeConstraints { maker in
            maker.width.height.equalTo(10)
            maker.centerY.equalToSuperview()
            maker.centerX.equalTo(slider.snp.left).offset(5)
            maker.centerX.equalTo(sliderLine.snp.right)
        }

        addSubview(currentTimeLabel)
        currentTimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        currentTimeLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.35)
        currentTimeLabel.text = player.currentPlaybackTime.time.autoFormat() ?? "--:--"
        currentTimeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self.snp.top).offset(43)
            maker.left.equalToSuperview().offset(20)
        }

        addSubview(endTimeLabel)
        endTimeLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        endTimeLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.35)
        endTimeLabel.text = player.duration.autoFormat() ?? "--:--"
        endTimeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self.snp.top).offset(43)
            maker.right.equalToSuperview().offset(-20)
        }

        addSubview(playButton)
        playButton.setImage(BundleResources.Minutes.minutes_podcast_play, for: .normal)
        playButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(58)
            maker.width.height.equalTo(72)
        }

        addSubview(backwardButton)
        backwardButton.setImage(BundleResources.Minutes.minutes_podcast_qian15s, for: .normal)
        backwardButton.snp.makeConstraints { maker in
            maker.centerY.equalTo(playButton)
            maker.centerX.equalToSuperview().multipliedBy(0.55)
        }

        addSubview(forwardButton)
        forwardButton.setImage(BundleResources.Minutes.minutes_podcast_hou15s, for: .normal)
        forwardButton.snp.makeConstraints { maker in
            maker.centerY.equalTo(playButton)
            maker.centerX.equalToSuperview().multipliedBy(1.45)
        }

        addSubview(lastButton)
        lastButton.setImage(UDIcon.getIconByKey(.previousPlayFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 28, height: 28)), for: .normal)
        lastButton.isUserInteractionEnabled = MinutesPodcast.shared.hasPrev
        lastButton.isHidden = !MinutesPodcast.shared.hasPrev
        lastButton.snp.makeConstraints { maker in
            maker.centerY.equalTo(playButton)
            maker.centerX.equalToSuperview().multipliedBy(0.2)
        }

        addSubview(nextButton)
        nextButton.setImage(UDIcon.getIconByKey(.nextPlayFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 28, height: 28)), for: .normal)
        nextButton.isUserInteractionEnabled = MinutesPodcast.shared.hasNext
        nextButton.isHidden = !MinutesPodcast.shared.hasNext
        nextButton.snp.makeConstraints { maker in
            maker.centerY.equalTo(playButton)
            maker.centerX.equalToSuperview().multipliedBy(1.8)
        }

        addSubview(exitButton)
        exitButton.setImage(BundleResources.Minutes.minutes_podcast_exit, for: .normal)
        exitButton.setTitle(" \(BundleI18n.Minutes.MMWeb_G_ExitPodcastMode)", for: .normal)
        exitButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        exitButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.85), for: .normal)
        exitButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.35), for: .highlighted)
        exitButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        exitButton.layer.masksToBounds = true
        exitButton.layer.cornerRadius = 13
        exitButton.layer.borderWidth = 1.0
        exitButton.layer.ud.setBorderColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.35))
        exitButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(150)
            maker.centerX.equalToSuperview()
            maker.height.equalTo(26)
        }

        playButton.addTarget(self, action: #selector(onTapPlaybutton), for: .touchUpInside)

        forwardButton.addTarget(self, action: #selector(forward), for: .touchUpInside)
        backwardButton.addTarget(self, action: #selector(backward), for: .touchUpInside)

        lastButton.addTarget(self, action: #selector(lastMinutes), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextMinutes), for: .touchUpInside)

        exitButton.addTarget(self, action: #selector(exitPodcast), for: .touchUpInside)

        setupLoadingView(true)
        updatePlayerStatus(player.playerStatus.videoPlayerStatus)
    }
    // enable-lint: long_function

    func setupLoadingView(_ needLoading: Bool) {
        if needLoading {
            if loadingView != nil { return }
            let view = UIImageView(image: BundleResources.Minutes.minutes_podcast_loading_cycle)
            view.lu.addRotateAnimation(duration: 0.8)
            view.isUserInteractionEnabled = false
            playButton.addSubview(view)
            view.snp.makeConstraints { maker in
                maker.center.equalToSuperview()
                maker.width.height.equalTo(69)
            }
            loadingView = view
        } else {
            loadingView = nil
        }
    }

    func updatePlaybackTime(currentPlaybackTime: PlaybackTime) {
        guard isSeeking == false else { return }
        let duration = player.duration
        guard duration > 0 else { return }

        DispatchQueue.main.async {
            self.currentTimeLabel.text = currentPlaybackTime.time.autoFormat(anchorTime: duration)
            let process = currentPlaybackTime.time / duration
            let offset = process * Double(self.slider.bounds.width - 10) + 5
            self.sliderPoint.snp.updateConstraints { maker in
                maker.centerX.equalTo(offset)
            }
        }
    }

    func updatePlayerStatus(_ status: MinutesVideoPlayerStatus) {
        DispatchQueue.main.async {
            let statusDisable = status == .unkown || status == .perpare
            self.slider.isUserInteractionEnabled = !statusDisable
            self.sliderPoint.isUserInteractionEnabled = !statusDisable
            self.playButton.isUserInteractionEnabled = !statusDisable
            self.forwardButton.isUserInteractionEnabled = !statusDisable
            self.backwardButton.isUserInteractionEnabled = !statusDisable
            self.playButton.alpha = statusDisable ? 0.25 : 1.0
            self.forwardButton.alpha = statusDisable ? 0.25 : 1.0
            self.backwardButton.alpha = statusDisable ? 0.25 : 1.0

            self.currentTimeLabel.text = self.player.currentPlaybackTime.time.autoFormat(anchorTime: self.player.duration) ?? "--:--"
            self.endTimeLabel.text = self.player.duration.autoFormat() ?? "--:--"

            self.setButtonImage(for: status)

            let needLoading = (status == .loading || status == .perpare || status == .unkown || (status == .stopped && MinutesPodcast.shared.hasNext))
            self.setupLoadingView(needLoading)
        }
    }

    private func setButtonImage(for status: MinutesVideoPlayerStatus) {
        switch status {
        case .playing, .loading:
            playButton.setImage(BundleResources.Minutes.minutes_podcast_pause, for: .normal)
        default:
            playButton.setImage(BundleResources.Minutes.minutes_podcast_play, for: .normal)
        }
    }

    @objc func onTapPlaybutton() {
        player.tigglePlayState(from: .podcast)
    }

    @objc func backward() {
        player.tracker.tracker(name: .podcastPage, params: ["action_name": "fifteen_secs_back"])
        player.tracker.tracker(name: .podcastClick, params: ["click": "fifteen_secs_back", "target": "none"])

        let currentTime = player.currentPlaybackTime.time
        let nextTime = currentTime - 15
        if nextTime > 0 {
            player.seekVideoPlaybackTime(nextTime)
        } else {
            player.seekVideoPlaybackTime(0)
        }
    }

    @objc func forward() {
        player.tracker.tracker(name: .podcastPage, params: ["action_name": "fifteen_secs_forward"])
        player.tracker.tracker(name: .podcastClick, params: ["click": "fifteen_secs_forward", "target": "none"])

        let currentTime = player.currentPlaybackTime.time
        let nextTime = currentTime + 15
        if nextTime < player.duration {
            player.seekVideoPlaybackTime(nextTime)
        } else {
            player.seekVideoPlaybackTime(player.duration - 0.001)
        }
    }

    @objc func lastMinutes() {
        player.tracker.tracker(name: .podcastPage, params: ["action_name": "last_one"])
        player.tracker.tracker(name: .podcastClick, params: ["click": "last_one", "target": "none"])

        MinutesPodcast.shared.playPrevMinutes()
    }

    @objc func nextMinutes() {
        player.tracker.tracker(name: .podcastPage, params: ["action_name": "next_one"])
        player.tracker.tracker(name: .podcastClick, params: ["click": "next_one", "target": "none"])

        MinutesPodcast.shared.playNextMinutes()
    }

    @objc func exitPodcast() {
        player.tracker.tracker(name: .podcastPage, params: ["action_name": "podcast_exit"])
        player.tracker.tracker(name: .podcastClick, params: ["click": "podcast_exit", "target": "vc_minutes_detail_view"])

        MinutesPodcast.shared.stopPodcast()
    }

    @objc func onGesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began, .possible:
            isSeeking = true
        case .ended, .cancelled, .failed:
            isSeeking = false
        default:
            break
        }

        let point = gesture.location(in: slider)
        let width = slider.bounds.width - 10
        let base = width > 0 ? Double(width) : 1.0

        var offset = point.x
        switch point.x {
        case let x where x < 5.0:
            offset = 5.0
        case let x where x > width + 5.0:
            offset = width + 5.0
        default:
            offset = point.x - 5.0
        }
        sliderPoint.snp.updateConstraints { maker in
            maker.centerX.equalTo(offset)
        }

        var timeOffset = point.x
        if point.x < 0 {
            timeOffset = 0
        } else if point.x > width {
            timeOffset = width
        }
        let process: Double = Double(timeOffset) / Double(width)
        let duration = player.duration
        let time = process * duration
        currentTimeLabel.text = time.autoFormat(anchorTime: duration)

        if !isSeeking {
            player.seekVideoProcess(process)
        }
    }
}

extension MinutesPodcastControlPannel: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIScreenEdgePanGestureRecognizer {
            return true
        } else {
            return false
        }
    }
}

extension MinutesPodcastControlPannel:MinutesVideoPlayerListener {
    public func videoEngineDidLoad() {
    }

    public func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {
        self.updatePlayerStatus(status.videoPlayerStatus)
    }

    public func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        self.updatePlaybackTime(currentPlaybackTime: time)
    }
}
