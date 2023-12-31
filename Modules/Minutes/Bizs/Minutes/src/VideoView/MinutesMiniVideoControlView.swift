//
//  MinutesMiniVideoControlView.swift
//  Minutes
//
//  Created by lvdaqian on 2021/1/30.
//

import Foundation
import SnapKit
import LarkUIKit
import UniverseDesignColor
import EENavigator
import LarkExtensions
import MinutesFoundation
import MinutesNetwork
import UIKit
import UniverseDesignIcon
import LarkMedia
import LarkContainer

protocol MinutesMiniVideoControlViewDelegate: AnyObject {
    func miniVideoControlViewDidLoad()
    func subtitleShownDidChange() -> Bool
}

class MinutesMiniVideoControlView: UIView {
    var navigationController: UINavigationController? {
        return userResolver.navigator.mainSceneTopMost?.navigationController
    }

    let userResolver: UserResolver
    weak var delegate: MinutesMiniVideoControlViewDelegate?

    let player: MinutesVideoPlayer
    let activeTimer: MinutesVideoView.ActiveTimer
    var podcastCallback: (() -> Void)?
    var backCallback: (() -> Void)?
    var moreCallback: (() -> Void)?
    var isLandscape = false

    var isClip: Bool {
        player.minutes.isClip
    }
    
    func configureChapter(_ handler: (() -> Void)?) {
        if isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                self.landscapeSlider.configureChapter()
                handler?()
            })
        }
    }

    private lazy var currentTimeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor.ud.primaryOnPrimaryFill
        l.text = player.currentPlaybackTime.time.autoFormat() ?? "--:--"
        return l
    }()
    private lazy var endTimeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        l.textColor = UIColor.ud.primaryOnPrimaryFill
        let text = player.duration.autoFormat() ?? "--:--"
        l.text = " / \(text)"
        return l
    }()

    lazy var slider: MinutesSliderView = {
        let slider = MinutesSliderView(resolver: userResolver)
        slider.delegate = self
        slider.forceThumbShow = true
        return slider
    }()

    private lazy var scaleButton: ActionControl = {
        let btn = ActionControl(button: ActionButton(type: .custom))
        btn.button.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        btn.button.setImage(UDIcon.getIconByKey(.expandOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
        btn.button.setImage(UDIcon.getIconByKey(.expandOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        btn.isHidden = player.isAudioOnly
        return btn
    }()

    var videoDuration: Int = 0 {
        didSet {
            slider.videoDuration = videoDuration
            landscapeSlider.videoDuration = videoDuration
        }
    }
    var chapters: [MinutesChapterInfo] = [] {
        didSet {
            slider.chapters = chapters
            landscapeSlider.chapters = chapters
        }
    }
    
    var isSeeking: Bool = false

    var playerStatus: PlayerStatusWrapper = PlayerStatusWrapper(playbackState: .stopped, loadState: .unknown)
    var isControlBarShowing = true {
        didSet {
            if playerStatus.loadState == .playable {
                playButton.isHidden = !isControlBarShowing
            }
        }
    }
    var tapScreenBlock: (() -> Void)?
    var showLoadingBlock: (() -> Void)?
    var hideLoadingBlock: (() -> Void)?
    var fullscreenBlock: (() -> Void)?

    var playbackPlayingStatusBlock: (() -> Void)?
    var playbackPauseStatusBlock: (() -> Void)?

    private lazy var backButton: ActionControl = {
        let btn = ActionControl(button: ActionButton(type: .custom))
        btn.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        btn.button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
        btn.button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        btn.button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        return btn
    }()

    private lazy var speedButton: ActionControl = {
        let button = ActionControl(button: ActionButton(type: .custom))
        button.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.button.addTarget(self, action: #selector(speedButtonAction), for: .touchUpInside)
        button.button.setTitle("1x", for: .normal)
        button.button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.button.setTitleColor(.white, for: .normal)
        return button
    }()

    private lazy var subtitleButton: ActionControl = {
        let btn = ActionControl(button: ActionButton(type: .custom))
        btn.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        btn.button.isSelected = true
        btn.button.setImage(UDIcon.getIconByKey(.subtitlesOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
//        btn.button.setImage(UDIcon.getIconByKey(.subtitlesOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        btn.button.setImage(UDIcon.getIconByKey(.subtitlesFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .selected)
        btn.button.addTarget(self, action: #selector(subtitleButtonAction), for: .touchUpInside)
        return btn
    }()

    private lazy var podcastButton: ActionControl = {
        let btn = ActionControl(button: ActionButton(type: .custom))
        btn.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        btn.button.setImage(BundleResources.Minutes.minutes_podcast_icon_dark.ud.resized(to: CGSize(width: 24, height: 24)), for: .normal)
        btn.button.setImage(BundleResources.Minutes.minutes_podcast_icon_dark.ud.resized(to: CGSize(width: 24, height: 24)), for: .highlighted)
        btn.button.addTarget(self, action: #selector(podcastAction), for: .touchUpInside)
        return btn
    }()

    private lazy var moreButton: ActionControl = {
        let btn = ActionControl(button: ActionButton(type: .custom))
        btn.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        btn.button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
        btn.button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        btn.button.addTarget(self, action: #selector(moreAction), for: .touchUpInside)
        return btn
    }()


    private lazy var rigthTopStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.addArrangedSubview(speedButton)
        speedButton.snp.makeConstraints { make in
            make.size.equalTo(28)
        }
        stack.setCustomSpacing(16, after: speedButton)
        stack.addArrangedSubview(subtitleButton)
        subtitleButton.snp.makeConstraints { make in
            make.size.equalTo(28)
        }
        stack.setCustomSpacing(16, after: subtitleButton)
        stack.addArrangedSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.size.equalTo(28)
        }
        return stack
    }()

    private lazy var topView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.size.equalTo(28)
        }
        if Display.phone {
            v.addSubview(rigthTopStack)
            rigthTopStack.snp.makeConstraints { make in
                make.centerY.right.equalToSuperview()
            }
        }
        return v
    }()

    private lazy var leftBottomStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.addArrangedSubview(currentTimeLabel)
        stack.addArrangedSubview(endTimeLabel)
        return stack
    }()

    private lazy var rightBottomStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.addArrangedSubview(speedButton)
        speedButton.snp.makeConstraints { make in
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(28)
        }
        stack.setCustomSpacing(16, after: speedButton)
        stack.addArrangedSubview(subtitleButton)
        subtitleButton.snp.makeConstraints { make in
            make.size.equalTo(28)
        }
        stack.setCustomSpacing(16, after: subtitleButton)
        stack.addArrangedSubview(scaleButton)
        scaleButton.snp.makeConstraints { make in
            make.size.equalTo(28)
        }
        return stack
    }()

    private lazy var bottomStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.addArrangedSubview(leftBottomStack)
        if Display.pad {
            stack.addArrangedSubview(rightBottomStack)
        } else {
            stack.addArrangedSubview(scaleButton)
            scaleButton.snp.makeConstraints { make in
                make.size.equalTo(28)
            }
        }
        return stack
    }()

    private lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.playFilled, size: CGSize(width: 24, height: 24)), for: .normal)
        button.addTarget(self, action: #selector(playAction), for: .touchUpInside)
        button.backgroundColor = .black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 36
        return button
    }()

    private lazy var commentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        v.isHidden = isInCCMfg
        return v
    }()

    private lazy var landscapeBackButton: ActionControl = {
        let button = ActionControl(button: ActionButton(type: .custom))
        button.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
        button.button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.button.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        return button
    }()

    private lazy var landscapeTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .medium)
        l.textColor = UIColor.ud.N00.nonDynamic
        l.text = player.minutes.basicInfo?.topic
        return l
    }()

    private lazy var landscapeTopView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.isHidden = true
        stack.addArrangedSubview(landscapeBackButton)
        landscapeBackButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        stack.setCustomSpacing(8, after: landscapeBackButton)
        stack.addArrangedSubview(landscapeTitleLabel)
        return stack
    }()

    private enum Layout {
        static let enlargeRegionInsets = UIEdgeInsets(top: 12,
                                                      left: 12,
                                                      bottom: 12,
                                                      right: 12)
    }

    private lazy var landscapePlayButton: ActionControl = {
        let button = ActionControl(button: ActionButton(type: .custom))
        button.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.button.setImage(UDIcon.getIconByKey(.pauseFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
        button.button.setImage(UDIcon.getIconByKey(.pauseFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.button.addTarget(self, action: #selector(landscapePlayAction), for: .touchUpInside)
        return button
    }()


    private lazy var landscapeBackwardButton: ActionControl = {
        let button = ActionControl(button: ActionButton(type: .custom))
        button.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.button.setImage(UDIcon.getIconByKey(.back15sOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
        button.button.setImage(UDIcon.getIconByKey(.back15sOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.button.addTarget(self, action: #selector(backwardAction), for: .touchUpInside)
        return button
    }()

    private lazy var landscapeForwardButton: ActionControl = {
        let button = ActionControl(button: ActionButton(type: .custom))
        button.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.button.setImage(UDIcon.getIconByKey(.forward15sOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
        button.button.setImage(UDIcon.getIconByKey(.forward15sOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.button.addTarget(self, action: #selector(forwardAction), for: .touchUpInside)
        return button
    }()

    private lazy var landscapeSubtitleButton: ActionControl = {
        let button = ActionControl(button: ActionButton(type: .custom))
        button.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.button.setImage(UDIcon.getIconByKey(.subtitlesOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
//        button.button.setImage(UDIcon.getIconByKey(.subtitlesOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.button.setImage(UDIcon.getIconByKey(.subtitlesFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .selected)
        button.button.addTarget(self, action: #selector(subtitleButtonAction), for: .touchUpInside)
        return button
    }()

    private lazy var landscapeSpeedButton: ActionControl = {
        let button = ActionControl(button: ActionButton(type: .custom))
        button.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.button.tag = 999
        button.button.addTarget(self, action: #selector(speedButtonAction), for: .touchUpInside)
        button.button.setTitle("1x", for: .normal)
        button.button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.button.setTitleColor(UIColor.ud.N00.nonDynamic, for: .normal)
        return button
    }()

    private lazy var landscapeZoomoutButton: ActionControl = {
        let button = ActionControl(button: ActionButton(type: .custom))
        button.button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.button.setImage(UDIcon.getIconByKey(.minimizeOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
        button.button.setImage(UDIcon.getIconByKey(.minimizeOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.button.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        return button
    }()

    lazy var landscapeSlider: MinutesSliderView = {
        let slider = MinutesSliderView(resolver: userResolver)
        slider.thumbRadius = 7
        slider.trackHeight = 2
        slider.isDynamic = true
        slider.delegate = self
        return slider
    }()

    private lazy var landscapeLeftControlStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.addArrangedSubview(landscapePlayButton)
        landscapePlayButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        stack.setCustomSpacing(24, after: landscapePlayButton)
        stack.addArrangedSubview(landscapeBackwardButton)
        landscapeBackwardButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        stack.setCustomSpacing(24, after: landscapeBackwardButton)
        stack.addArrangedSubview(landscapeForwardButton)
        landscapeForwardButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        return stack
    }()

    private lazy var landscapeRightControlStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.addArrangedSubview(landscapeSpeedButton)
        landscapeSpeedButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        stack.setCustomSpacing(24, after: landscapeSpeedButton)
        stack.addArrangedSubview(landscapeSubtitleButton)
        landscapeSubtitleButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        stack.setCustomSpacing(24, after: landscapeSpeedButton)
        stack.addArrangedSubview(landscapeZoomoutButton)
        landscapeZoomoutButton.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        return stack
    }()

    private lazy var landscapeControlStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.addArrangedSubview(landscapeLeftControlStack)
        stack.addArrangedSubview(landscapeRightControlStack)
        return stack
    }()

    private lazy var landscapeBottomView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.isHidden = true
        stack.addArrangedSubview(landscapeSlider)
        landscapeSlider.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        stack.setCustomSpacing(18, after: landscapeSlider)
        stack.addArrangedSubview(landscapeControlStack)
        return stack
    }()

    private lazy var thumbnailView: MinutesThumbnailView = {
        let v = MinutesThumbnailView()
        v.layoutWidth = bounds.width
        v.spriteInfo = player.minutes.basicInfo?.spriteInfo
        v.duration = player.duration * 1000
        return v
    }()

    private lazy var backgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        v.isUserInteractionEnabled = false
        return v
    }()

    var displaySecond: Int = 0 {
        didSet {
            guard oldValue != displaySecond else { return }
            let duration = player.duration
            let value = displaySecond
            DispatchQueue.main.async {
                let valueStr = Double(value).autoFormat(anchorTime: duration)
                self.currentTimeLabel.text = valueStr
            }
        }
    }

    var isEditSpeaker: Bool = false {
        didSet {
            backButton.isHidden = isEditSpeaker
            moreButton.isHidden = isEditSpeaker
        }
    }

    var shouldShowPodcast: Bool = true {
        didSet{
            podcastButton.isHidden = !shouldShowPodcast
        }
    }

    var hasSubtitle: Bool = true {
        didSet {
            subtitleButton.isHidden = !hasSubtitle
            landscapeSubtitleButton.isHidden = !hasSubtitle
        }
    }

    lazy var tap = UITapGestureRecognizer(target: self, action: #selector(onTapScreen))
    lazy var pan = UIPanGestureRecognizer(target: self, action: #selector(panAction))

    let isInCCMfg: Bool
    init(resolver: UserResolver,  player: MinutesVideoPlayer, timer: MinutesVideoView.ActiveTimer, isInCCMfg: Bool) {
        self.userResolver = resolver
        self.player = player
        self.activeTimer = timer
        self.isInCCMfg = isInCCMfg
        super.init(frame: .zero)

        player.listeners.addListener(self)

        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailView.layoutWidth = bounds.width
    }

    override func point(inside: CGPoint, with: UIEvent?) -> Bool {
        var rect = bounds
        rect.size.height = bounds.height + 10
        return rect.contains(inside)
    }

    func setupSubviews() {
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if Display.phone {
            addSubview(topView)
            topView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.left.equalTo(10)
                make.right.equalTo(-14)
                make.height.equalTo(46)
            }
        }

        addSubview(bottomStack)
        bottomStack.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.bottom.right.equalTo(-14)
        }

        addSubview(commentView)
        addSubview(slider)
        slider.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(24)
            make.bottom.equalTo(11)
        }
        commentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(slider.snp.top).offset(10)
            make.height.equalTo(14)
        }

        addSubview(landscapeTopView)
        landscapeTopView.snp.makeConstraints { make in
            make.top.equalTo(30)
            make.left.equalTo(52)
            make.right.equalTo(-52)
        }

        addSubview(landscapeBottomView)
        landscapeBottomView.snp.makeConstraints { make in
            make.left.equalTo(44)
            make.bottom.equalTo(-38)
            make.right.equalTo(-44)
        }

        addSubview(playButton)
        playButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(54)
        }

        addGestureRecognizer(tap)
        addGestureRecognizer(pan)
        pan.delegate = self

        self.delegate?.miniVideoControlViewDidLoad()
    }

    func updatePlaybackTime(currentPlaybackTime: PlaybackTime) {

        guard isSeeking == false else { return }

        updateSliderOffset(currentPlaybackTime.time)
    }

    func updateSliderOffset( _ currentTime: TimeInterval? = nil) {
        let duration = player.duration
        guard duration > 0 else { return }
        let time = currentTime ?? player.currentPlaybackTime.time

        self.displaySecond = Int(time)

        var process = time / duration
        if Int(duration * 1000 - time * 1000) < 200 {
            process = 1
        }
        DispatchQueue.main.async {
            self.slider.value = process
            self.landscapeSlider.value = process
        }
    }

    func updatePlayerStatus(_ status: PlayerStatusWrapper) {
        DispatchQueue.main.async {
            // handle loading
            if status.loadState == .playable {
                self.hideLoadingBlock?()
                // 开始播放之后展示
                self.playButton.isHidden = !self.isControlBarShowing
            } else if status.loadState == .stalled {
                self.showLoadingBlock?()
            }

            // 刚播放，paused stoped 也变了
            let iconSize = self.isLandscape ? CGSize(width: 32, height: 32) : CGSize(width: 24, height: 24)
            self.playButton.setImage(status.videoPlayerStatus.buttonImage(self.player.isFinish, size: iconSize), for: .normal)

            self.currentTimeLabel.text = self.player.currentPlaybackTime.time.autoFormat(anchorTime: self.player.duration) ?? "--:--"
            let text = self.player.duration.autoFormat() ?? "--:--"
            self.endTimeLabel.text = " / \(text)"
            if status.videoPlayerStatus == .playing {
                self.landscapePlayButton.button.setImage(UDIcon.getIconByKey(.pauseFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
                self.landscapePlayButton.button.setImage(UDIcon.getIconByKey(.pauseFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
            } else {
                self.landscapePlayButton.button.setImage(UDIcon.getIconByKey(.playFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
                self.landscapePlayButton.button.setImage(UDIcon.getIconByKey(.playFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
            }
        }
    }

    @objc private func subtitleButtonAction(_ sender: UIButton) {
        let isSubtitleShown: Bool = self.delegate?.subtitleShownDidChange() ?? false

        updateSubtitleButton(isSubtitleShown: isSubtitleShown)
        updateActiveTime()
        var trackParams: [AnyHashable: Any] = ["action_name": "show_subtitles"]
        trackParams["action_enabled"] = isSubtitleShown ? 1 : 0
        player.tracker.tracker(name: .clickButton, params: trackParams)

        player.tracker.tracker(name: .detailClick, params: ["click": "show_subtitles", "is_open": isSubtitleShown ? true : false, "target": "none", "is_full_screen": false])
    }

    @objc private func speedButtonAction(_ sender: UIButton) {
        player.tracker.tracker(name: .clickButton, params: ["action_name": "adjust_button"])
        let style: SpeedViewPresentStyle = (sender.tag == 999) ? .overlay : .present
        let vc = MinutesVideoPlayerSpeedViewController(style)
        vc.player = player
        vc.onSelecteValueChanged = { [weak self] value in
            let titleString = value == 1.0 ? "1x" : String(format: "%gx", value)
            self?.landscapeSpeedButton.button.setTitle(titleString, for: .normal)
            self?.speedButton.button.setTitle(titleString, for: .normal)
        }
        vc.onSkipSwitchValueChanged = { [weak self] value in
            self?.player.shouldSkipSilence = value
        }
        if let from = self.window {
            userResolver.navigator.present(vc, from: from)
        }
        player.tracker.tracker(name: .detailSettingView, params: [:])

        player.tracker.tracker(name: .detailClick, params: ["click": "setting", "target": "vc_minutes_detail_setting_view"])
    }

    func handlePlayButtonHidden() {
        if playerStatus.loadState == .playable {
            // 还在loading态，点击不展示
            playButton.isHidden = !isControlBarShowing
        }
    }

    @objc private func backAction() {
        backCallback?()
    }

    // disable-lint: duplicated_code
    @objc private func podcastAction() {
        LarkMediaManager.shared.tryLock(scene: .mmPlay, observer: player) { [weak self] in
           guard let self = self else {
               return
           }
           switch $0 {
           case .success:
               DispatchQueue.main.async {
                   self.podcastCallback?()
               }
           case .failure(let error):
               DispatchQueue.main.async {
                   let targetView = self.userResolver.navigator.mainSceneWindow?.fromViewController?.view
                   if case let MediaMutexError.occupiedByOther(context) = error {
                       if let msg = context.1 {
                           MinutesToast.showTips(with: msg, targetView: targetView)
                       }
                   } else {
                       MinutesToast.showTips(with: BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, targetView: targetView)
                   }
               }
           }
       }
    }
    // enable-lint: duplicated_code


    @objc private func moreAction() {
        moreCallback?()
    }

    @objc func playAction() {
        // 播放之后立刻隐藏，等待回调出来之后展示
        playButton.isHidden = true
        // 如果load没有playable则展示loading
        if playerStatus.loadState != .playable {
            showLoadingBlock?()
        }

        player.tigglePlayState(from: .player)
        updateActiveTime()
    }

    @objc func landscapePlayAction() {
        playButton.isHidden = true
        if playerStatus.loadState != .playable {
            showLoadingBlock?()
        }

        player.tigglePlayState(from: .playerView)
        updateActiveTime()
    }

    @objc func backwardAction() {

        let currentTime = player.currentPlaybackTime.time
        let nextTime = currentTime - 15
        if nextTime > 0 {
            player.seekVideoPlaybackTime(nextTime)
        } else {
            player.seekVideoPlaybackTime(0)
        }
        player.tracker.tracker(name: .detailClick, params: ["click": "fifteen_secs_back", "page_name": "detail_page"])
    }

    @objc func forwardAction() {

        let currentTime = player.currentPlaybackTime.time
        let nextTime = currentTime + 15
        if nextTime < player.duration {
            activeTimer.updateActiveTime(nextTime)
            player.seekVideoPlaybackTime(nextTime)
        } else {
            activeTimer.updateActiveTime(player.duration)
            player.seekVideoPlaybackTime(player.duration - 0.001)
        }
        player.tracker.tracker(name: .detailClick, params: ["click": "fifteen_secs_forward", "page_name": "detail_page"])
    }

    @objc func zoomIn() {
            if Display.pad {
                fullscreenBlock?()
            } else {
    #if swift(>=5.7)
                if #available(iOS 16.0, *) {
                    if let activeScene = UIApplication.shared.connectedScenes.first(where: {
                        $0.activationState == .foregroundActive && $0.isKind(of: UIWindowScene.self)
                    }), let windowScene = activeScene as? UIWindowScene {


                        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS()
                        geometryPreferences.interfaceOrientations = .landscapeRight
                        windowScene.requestGeometryUpdate(geometryPreferences, errorHandler: { _ in })
                    }
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                    UIViewController.attemptRotationToDeviceOrientation()
                }
    #else
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
    #endif
            }


            player.tracker.tracker(name: .clickButton, params: ["action_name": "zoom_in"])
            player.tracker.tracker(name: .detailClick, params: ["click": "zoom_in", "target": "none"])
            updateActiveTime()
            landscapeSlider.setValue(slider.value, animated: false)
        }


        @objc func zoomOut(_ sender: UIButton) {
            if Display.pad {
                backCallback?()
            } else {
    #if swift(>=5.7)
                if #available(iOS 16.0, *) {
                    if let activeScene = UIApplication.shared.connectedScenes.first(where: {
                        $0.activationState == .foregroundActive && $0.isKind(of: UIWindowScene.self)
                    }), let windowScene = activeScene as? UIWindowScene {


                        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS()
                        geometryPreferences.interfaceOrientations = .portrait
                        windowScene.requestGeometryUpdate(geometryPreferences, errorHandler: { _ in })
                    }
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    UIViewController.attemptRotationToDeviceOrientation()
                }
    #else
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
    #endif
            }
            var trackParams = ["action_name": "zoom_out"]
            trackParams["action_type"] = sender == self.landscapeBackButton ? "back" : "shrink"
            player.tracker.tracker(name: .clickButton, params: trackParams)


            var newTrackParams = ["click": "zoom_out"]
            newTrackParams["location"] = sender == self.landscapeBackButton ? "back" : "shrink"
            player.tracker.tracker(name: .detailClick, params: newTrackParams)
            updateActiveTime()
            slider.setValue(landscapeSlider.value, animated: false)
        }
    @objc func onTapScreen() {
        if isControlBarShowing {
            activeTimer.fire()
        } else {
            tapScreenBlock?()
        }
    }

    @objc func panAction(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .possible:
            if isLandscape {
                setLandscapeControl(isHidden: false)
                showThumbnailView(with: .follow)
            } else {
                showThumbnailView(with: .follow)
            }
        case .ended, .cancelled, .failed:
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            sliderValueDidEndChanged()
        default:
            break
        }
        let translation = gesture.translation(in: self)
        let delta = translation.x / bounds.width / 5
        var value = slider.value + delta
        if value > 1 { value = 1 }
        if value < 0 { value = 0 }
        slider.setValue(value, animated: false)
        landscapeSlider.setValue(value, animated: false)
        sliderValueDidChanged(value)
        gesture.setTranslation(.zero, in: self)
    }

    private func updateActiveTime() {
        activeTimer.updateActiveTime(player.currentPlaybackTime.time)
    }

    private func updateSpeedButton() {
        let titleString = (player.playbackSpeed == 1.0) ? "1x" : String(format: "%gx", player.playbackSpeed)
        landscapeSpeedButton.button.setTitle(titleString, for: .normal)
        speedButton.button.setTitle(titleString, for: .normal)
    }

    private func updateSubtitleButton(isSubtitleShown: Bool) {
//        subtitleButton.button.setImage(UDIcon.getIconByKey(subtitleButton.button.isSelected ? .subtitlesFilled : .subtitlesOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)
//        landscapeSubtitleButton.button.setImage(UDIcon.getIconByKey(landscapeSubtitleButton.button.isSelected ? .subtitlesFilled : .subtitlesOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .highlighted)

        subtitleButton.button.isSelected = isSubtitleShown
        landscapeSubtitleButton.button.isSelected = isSubtitleShown
    }

    private func getFormatedSpeedString(by value: Double) -> String {
        let titleString: String
        if value == 1.0 || value == 2.0 || value == 3.0 {
            titleString = String(format: "%.1fx", value)
        } else {
            titleString = String(format: "%gx", value)
        }
        return titleString
    }

    func updateUIStyle(isSubtitleShown: Bool) {
        updateSliderOffset()
        updateSubtitleButton(isSubtitleShown: isSubtitleShown)
        updateSpeedButton()
    }

    func setBackground(isHidden: Bool) {
        backgroundView.isHidden = isHidden
    }

    func setSlider(isHidden: Bool) {
        slider.isHidden = isHidden
    }

    func setPortraitControl(isHidden: Bool) {
        topView.isHidden = isHidden
        bottomStack.isHidden = isHidden
        commentView.isHidden = isHidden
        slider.forceThumbShow = isControlBarShowing
        setBackground(isHidden: !isControlBarShowing)
        updatePlayButtonLayout(isLandscape: false)
    }

    func setLandscapeControl(isHidden: Bool) {
        landscapeTopView.isHidden = isHidden
        landscapeBottomView.isHidden = isHidden
        setBackground(isHidden: !isControlBarShowing)
        updatePlayButtonLayout(isLandscape: true)
    }

    func updateControlVisible(_ isVisible: Bool) {
        landscapeLeftControlStack.isHidden = !isVisible
        landscapeRightControlStack.isHidden = !isVisible
    }

    func updateReactionInfo(_ info: [ReactionInfo]) {
        let duration = player.duration * 1000
        let commentTipsViews = commentView.subviews
        commentTipsViews.forEach { v in
            v.removeFromSuperview()
        }
        info.forEach { item in
            if duration > 0 {
                let time = Double(item.startTime ?? 0)
                var offset = Double(slider.bounds.width) * (time / duration)
                if offset < 8 { offset = 8 }
                if offset > slider.bounds.width - 8 { offset = slider.bounds.width - 8 }
                let view = UIImageView.reactionView(for: item.emojiCode)
                self.commentView.addSubview(view)
                view.snp.remakeConstraints { maker in
                    maker.width.height.equalTo(16)
                    maker.centerX.equalTo(offset)
                    maker.centerY.equalToSuperview()
                }
           }
        }
    }

    func updatePlayButtonLayout(isLandscape: Bool) {
        playButton.layer.cornerRadius = isLandscape ? 36 : 27
        playButton.snp.updateConstraints { make in
            make.width.height.equalTo(isLandscape ? 72 : 54)
        }
        let iconSize = isLandscape ? CGSize(width: 32, height: 32) : CGSize(width: 24, height: 24)
        playButton.setImage(player.currentPlayerStatus.buttonImage(player.isFinish, size: iconSize), for: .normal)
    }
}

extension MinutesMiniVideoControlView: MinutesSliderViewDelegate {

    func showThumbnailView(with type: MinutesThumbnailView.ShowType) {
        isSeeking = true
        thumbnailView.duration = player.duration * 1000
        thumbnailView.margin = isLandscape ? 52 : 16
        thumbnailView.bottomOffset = isLandscape ? 130 : 18
        thumbnailView.leftOffset = isLandscape ? landscapeSlider.frame.minX + 52 : 0
        thumbnailView.rightOffset = isLandscape ? landscapeBottomView.bounds.width - landscapeSlider.frame.maxX + 52 : 0
        thumbnailView.show(in: self, with: type, originValue: slider.value)
        setBackground(isHidden: false)
    }

    func sliderValueWillChange() {
        showThumbnailView(with: .follow)

        updateControlVisible(false)
    }

    func sliderValueDidChanged(_ value: CGFloat) {
        let duration = player.duration
        let time = value * duration
        let timeStr = time.autoFormat(anchorTime: duration)
        currentTimeLabel.text = timeStr
        updateActiveTime()
        thumbnailView.updateLayout(withProcess: value, time: timeStr)
        if !isSeeking {
            activeTimer.updateActiveTime(time)
            player.seekVideoProcess(value)
            var trackParams = [AnyHashable: Any]()
            trackParams.append(.progressBarChange)
            trackParams.append(.controller)
            player.tracker.tracker(name: .clickButton, params: trackParams)

            player.tracker.tracker(name: .detailClick, params: ["click": "progress_bar_change", "location": "player", "target": "none", "is_full_screen": "false", "rate_of_video_progress": "\(value)"])
        }
    }

    func sliderValueDidEndChanged() {
        isSeeking = false
        thumbnailView.hide()
        setBackground(isHidden: !isControlBarShowing)
        if isLandscape {
            setLandscapeControl(isHidden: !isControlBarShowing)
        }

        updateControlVisible(true)
    }
}

extension MinutesMiniVideoControlView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == pan {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }

        return true
    }
}

extension MinutesMiniVideoControlView:MinutesVideoPlayerListener {
    func videoEngineDidLoad() {
    }

    func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {
        playerStatus = status
        self.updatePlayerStatus(status)
    }

    func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        self.updatePlaybackTime(currentPlaybackTime: time)
    }
}

final class MinutesVideoFullscreenPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    var detailVC: MinutesFullscreenPlaySource?
    var destFrame: CGRect?
    let isPlayed: Bool
    init(detailVC: MinutesFullscreenPlaySource?, isPlayed: Bool) {
        self.detailVC = detailVC
        self.isPlayed = isPlayed
    }

    class func minZoomScaleFor(boundsSize: CGSize, imageSize: CGSize) -> CGFloat {
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        let minScale = min(xScale, yScale)
        if imageSize.width < imageSize.height { // 图片的宽小于高时
            // 有于屏幕存在转屏情况，我们取 UIScreen 短边除以长边得到屏幕比例
            let screenRatio: CGFloat = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) /
            max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            if (imageSize.width / imageSize.height) < screenRatio { // 长图
                return xScale
            } else {
                return minScale
            }
        } else {
            return minScale
        }
    }


    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? MinutesFullscreenPlayViewController else {

            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        containerView.backgroundColor = UIColor.black

        let videoView = toVC.videoView
        let image = toVC.videoImage
        let animatedImageView = UIImageView(frame: videoView.frame)
        animatedImageView.contentMode = .scaleAspectFit
        animatedImageView.clipsToBounds = true
        animatedImageView.image = image
        animatedImageView.frame = detailVC?.animatedImageFrame(to: containerView) ?? .zero
        containerView.addSubview(animatedImageView)

        let imageSize = image?.size ?? videoView.frame.size
        let zoomScale = Self.minZoomScaleFor(
            boundsSize: containerView.bounds.size,
            imageSize: imageSize
        )
        var targetWidth = imageSize.width * zoomScale
        var targetHeight = imageSize.height * zoomScale
        if targetHeight > containerView.frame.height {
            targetHeight = containerView.frame.height
            targetWidth = targetHeight * imageSize.width / imageSize.height
        }
        let targetX = (containerView.frame.width - targetWidth) / 2
        let targetY = (containerView.frame.height - targetHeight) / 2
        let targetFrame = CGRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight)
        destFrame = targetFrame

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveLinear,
            animations: {
                animatedImageView.frame = targetFrame
            },
            completion: { _ in
//                    containerView.backgroundColor = UIColor.clear
                animatedImageView.removeFromSuperview()
                containerView.addSubview(toVC.view)
                transitionContext.completeTransition(true)
            })
    }
}


final class MinutesVideoFullscreenDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    var detailVC: MinutesFullscreenPlaySource?
    var destFrame: CGRect?
    let isPlayed: Bool
    init(detailVC: MinutesFullscreenPlaySource?, destFrame: CGRect?, isPlayed: Bool) {
        self.detailVC = detailVC
        self.destFrame = destFrame
        self.isPlayed = isPlayed
    }
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? MinutesFullscreenPlayViewController else {
            return
        }

        let containerView = transitionContext.containerView
        let videoImage = fromVC.videoView.getVideoImage()
        fromVC.videoView.removeFromSuperview()
        fromVC.view.removeFromSuperview()
        detailVC?.recoverVideoView()

        containerView.backgroundColor = UIColor.white

        let animatedImageView = UIImageView(frame: destFrame ?? fromVC.view.bounds)
        animatedImageView.contentMode = .scaleAspectFit
        animatedImageView.clipsToBounds = true
        animatedImageView.image = videoImage
        containerView.addSubview(animatedImageView)

        let targetFrame = fromVC.videoView.convert(fromVC.videoView.frame, to: containerView)

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveLinear,
            animations: {
                animatedImageView.frame = targetFrame
                containerView.backgroundColor = UIColor.clear
            }, completion: { _ in
                transitionContext.completeTransition(true)
            })
    }

    private func viewIsShow(in target: UIViewController, view: UIView) -> Bool {
        var superView = view.superview
        while superView != nil {
            if superView == target.view {
                return true
            } else {
                superView = superView?.superview
            }
        }
        return false
    }
}


class MinutesFullscreenPlayViewController: UIViewController {


    lazy var fullVideoView: MinutesVideoView = {
        let view = MinutesVideoView(resolver: userResolver, player: videoPlayer, isInCCMfg: false)
        return view
    }()

    let videoView: MinutesVideoView
    let userResolver: UserResolver
    let videoPlayer: MinutesVideoPlayer
    var videoImage: UIImage?

    weak var detailVC: MinutesFullscreenPlaySource?

    var presentTransition: MinutesVideoFullscreenPresentTransition?

    let miniControlVisibleWidth: CGFloat = 400

    init(resolver: UserResolver, videoView: MinutesVideoView, player: MinutesVideoPlayer) {
//        self.videoImage = videoView.getVideoImage()
        self.userResolver = resolver
        self.videoView = videoView
        self.videoPlayer = player
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black

        view.addSubview(videoView)
        videoView.frame = view.bounds
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoView.frame = view.bounds
        DispatchQueue.main.async {
            self.videoView.miniControllBar.landscapeSlider.configureChapter()
            self.videoView.miniControllBar.landscapeSlider.updateProgress(animated: false)
            self.videoView.miniControllBar.updateControlVisible(self.view.bounds.width > self.miniControlVisibleWidth)
        }
    }
}

extension MinutesFullscreenPlayViewController: UIViewControllerTransitioningDelegate {
    class func snapshot(with view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        presentTransition = MinutesVideoFullscreenPresentTransition(detailVC: self.detailVC, isPlayed: false)
        return presentTransition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MinutesVideoFullscreenDismissTransition(detailVC: self.detailVC, destFrame: presentTransition?.destFrame, isPlayed: false)
    }
}

protocol MinutesFullscreenPlaySource: UIViewController {
    func recoverVideoView()
    func animatedImageFrame(to view: UIView) -> CGRect
}

extension MinutesDetailViewController: MinutesFullscreenPlaySource {
    func recoverVideoView() {
        setupVideoView()
        videoView?.updateUIStyle(false)
    }

    func animatedImageFrame(to view: UIView) -> CGRect {
        view.convert(videoViewBackground.frame, to: view)
    }
}

extension MinutesClipViewController: MinutesFullscreenPlaySource {
    func recoverVideoView() {
        setupVideoView()
        videoView.updateUIStyle(false)
    }

    func animatedImageFrame(to view: UIView) -> CGRect {
        view.convert(videoViewBackground.frame, to: view)
    }
}
