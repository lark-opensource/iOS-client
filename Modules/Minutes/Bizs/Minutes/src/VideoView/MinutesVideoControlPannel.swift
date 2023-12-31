//
//  MinutesVideoControlPannel.swift
//  Minutes
//
//  Created by lvdaqian on 2021/1/15.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import EENavigator
import LarkExtensions
import MinutesFoundation
import MinutesNetwork
import Lottie
import LarkGuide
import LarkMedia
import LarkContainer
import LarkAccountInterface
import UIKit
import LarkStorage

protocol MinutesVideoControlPannelDelegate: AnyObject {
    func showToast(text: String, by pannel: MinutesVideoControlPannel)
}

class ActionButton: UIButton {
    var highlightedBlock: ((Bool) -> Void)?
    override var isHighlighted: Bool {
        didSet {
            highlightedBlock?(isHighlighted)
        }
    }

    var enlargeRegionInsets: UIEdgeInsets?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let insets = enlargeRegionInsets {
            let transformInsets = UIEdgeInsets(top: -insets.top,
                                              left: -insets.left,
                                              bottom: -insets.bottom,
                                              right: -insets.right)
            let region = bounds.inset(by: transformInsets)
            return region.contains(point)
        } else {
            return super.point(inside: point, with: event)
        }
    }
}

class ActionControl: UIView {
    lazy var transparentView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.backgroundColor = UIColor.ud.udtokenBtnTextBgNeutralPressed.withAlphaComponent(0.2)
        return view
    }()

    let button: ActionButton

    init(button: ActionButton) {
        self.button = button
        super.init(frame: .zero)

        transparentView.isHidden = true
        addSubview(transparentView)
        addSubview(button)

        transparentView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        button.highlightedBlock = { [weak self] isHighlighted in
            self?.transparentView.isHidden = !isHighlighted
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesVideoControlPannel: UIView, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    @ScopedProvider var passportUserService: PassportUserService?
    @ScopedProvider var guideService: NewGuideService?

    let player: MinutesVideoPlayer

    weak var delegate: MinutesVideoControlPannelDelegate?

    let isInCCMfg: Bool
    init(resolver: UserResolver, player: MinutesVideoPlayer, isInCCMfg: Bool) {
        self.userResolver = resolver
        self.player = player
        self.isInCCMfg = isInCCMfg
        super.init(frame: .zero)

        player.listeners.addListener(self)

        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let currentTimeLabel: UILabel = UILabel()
    let endTimeLabel: UILabel = UILabel()
    lazy var slider: MinutesSliderView = {
        let sv = MinutesSliderView(resolver: userResolver)
        sv.trackHeight = 2
        sv.thumbRadius = 4.5
        sv.isDynamic = true
        sv.delegate = self
        return sv
    }()
    weak var loadingView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
        }
    }

    let playButton: UIButton = UIButton()
    let speedButton: ActionControl = ActionControl(button: ActionButton())
    let forwardButton: ActionControl = ActionControl(button: ActionButton())
    let backwardButton: ActionControl = ActionControl(button: ActionButton())
    let moreButton: ActionControl = ActionControl(button: ActionButton())

    var videoDuration: Int = 0 {
        didSet {
            slider.videoDuration = videoDuration
        }
    }
    var chapters: [MinutesChapterInfo] = [] {
        didSet {
            slider.chapters = chapters
        }
    }

    var podcastCallback: (() -> Void)?

    var shareCallback: (() -> Void)?

    var isSeeking: Bool = false

    private var commentTipsViews: [UIView] = []

    func setupSubviews() {
        backgroundColor = UIColor.ud.bgFloatOverlay
        addSubview(slider)
        slider.snp.makeConstraints { maker in
            maker.left.equalToSuperview().inset(16)
            maker.right.equalToSuperview().inset(16)
            maker.top.equalToSuperview()
            maker.height.equalTo(46)
        }

        addSubview(currentTimeLabel)
        currentTimeLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        currentTimeLabel.textColor = UIColor.ud.textPlaceholder
        currentTimeLabel.text = player.currentPlaybackTime.time.autoFormat() ?? "--:--"
        currentTimeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self.snp.top).offset(40)
            maker.left.equalToSuperview().offset(16)
        }

        addSubview(endTimeLabel)
        endTimeLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        endTimeLabel.textColor = UIColor.ud.textPlaceholder
        endTimeLabel.text = player.duration.autoFormat() ?? "--:--"
        endTimeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self.snp.top).offset(40)
            maker.right.equalToSuperview().offset(-16)
        }

        addSubview(playButton)
        playButton.setImage(MinutesVideoControlPannel.playButtionImage, for: .normal)
        playButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(58)
            maker.width.height.equalTo(56)
        }
        speedButton.button.setTitleColor(UIColor.ud.iconN1, for: .normal)
        speedButton.button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        addSubview(speedButton)
        speedButton.button.setTitle(getFormatedSpeedString(by: 1), for: .normal)
        speedButton.snp.makeConstraints { maker in
            maker.centerY.equalTo(playButton)
            maker.left.equalToSuperview().inset(20)
            maker.width.height.equalTo(28)
        }


        addSubview(forwardButton)
        forwardButton.button.setImage(UDIcon.getIconByKey(.forward15sOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        forwardButton.snp.makeConstraints { maker in
            maker.centerY.equalTo(playButton)
            maker.width.height.equalTo(28)
            maker.centerX.equalTo(playButton).offset(73)
        }

        addSubview(backwardButton)
        backwardButton.button.setImage(UDIcon.getIconByKey(.back15sOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        backwardButton.snp.makeConstraints { maker in
            maker.centerY.equalTo(playButton)
            maker.width.height.equalTo(28)
            maker.centerX.equalTo(playButton).offset(-73)
        }

        addSubview(moreButton)
        moreButton.button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        moreButton.snp.makeConstraints { maker in
            maker.centerY.equalTo(playButton)
            maker.right.equalToSuperview().inset(20)
            maker.width.height.equalTo(28)
        }

        playButton.addTarget(self, action: #selector(onTapPlaybutton), for: .touchUpInside)
        speedButton.button.addTarget(self, action: #selector(onTapSpeedbutton), for: .touchUpInside)

        forwardButton.button.addTarget(self, action: #selector(forward), for: .touchUpInside)
        backwardButton.button.addTarget(self, action: #selector(backward), for: .touchUpInside)
        moreButton.button.addTarget(self, action: #selector(clickMore), for: .touchUpInside)
        setupLoadingView(true)

        let pan = UIPanGestureRecognizer()
        pan.delegate = self
        pan.addTarget(self, action: #selector(panAction))
        addGestureRecognizer(pan)
    }


    var clickMoreHandler: (() -> Void)?
    @objc func clickMore() {
        clickMoreHandler?()
    }

    func setupLoadingView(_ isLoading: Bool) {
        if isLoading && loadingView == nil {
            let view = UIImageView(image: BundleResources.Minutes.minutes_loading_cycle)
            view.lu.addRotateAnimation(duration: 0.8)
            playButton.addSubview(view)
            view.snp.makeConstraints { maker in
                maker.center.equalToSuperview()
                maker.width.height.equalTo(56)
            }
            loadingView = view
        } else {
            loadingView = nil
        }
    }

    var displaySecond: Int = 0 {
        didSet {
            guard oldValue != displaySecond else { return }
            let duration = player.duration
            let value = displaySecond
            DispatchQueue.main.async {
                self.currentTimeLabel.text = Double(value).autoFormat(anchorTime: duration)
            }
        }
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
            self.slider.setValue(process, animated: false)
        }
    }

    func updatePlayerStatus(_ status: MinutesVideoPlayerStatus) {

        DispatchQueue.main.async {

            self.currentTimeLabel.text = self.player.currentPlaybackTime.time.autoFormat(anchorTime: self.player.duration) ?? "--:--"
            self.endTimeLabel.text = self.player.duration.autoFormat() ?? "--:--"

            self.setButtonImage(for: status)

            let isLoading = (status == .loading || status == .perpare)
            self.setupLoadingView(isLoading)
        }
    }

    private func setButtonImage(for status: MinutesVideoPlayerStatus) {
        switch status {
        case .playing, .loading:
            playButton.setImage(MinutesVideoControlPannel.stopButtionImage, for: .normal)
        default:
            playButton.setImage(MinutesVideoControlPannel.playButtionImage, for: .normal)
        }
    }

    @objc func onTapPlaybutton() {
        if player.minutes.info.playURL == nil {
            self.delegate?.showToast(text: BundleI18n.Minutes.MMWeb_MV_VideoGenerating, by: self)
            return
        }
        player.tigglePlayState(from: .controller)
    }

    @objc func onTapSpeedbutton() {
        if player.minutes.info.basicInfo?.videoURL == nil {
            self.delegate?.showToast(text: BundleI18n.Minutes.MMWeb_MV_VideoGenerating, by: self)
            return
        }
        player.tracker.tracker(name: .clickButton, params: ["action_name": "adjust_button"])

        let vc = MinutesVideoPlayerSpeedViewController()
        vc.player = player
        vc.onSelecteValueChanged = { [weak self] value in
            self?.speedButton.button.setTitle(self?.getFormatedSpeedString(by: value), for: .normal)
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

    @objc func backward() {
        if player.minutes.info.basicInfo?.videoURL == nil {
            self.delegate?.showToast(text: BundleI18n.Minutes.MMWeb_MV_VideoGenerating, by: self)
            return
        }
        let currentTime = player.currentPlaybackTime.time
        let nextTime = currentTime - 15
        if nextTime > 0 {
            player.seekVideoPlaybackTime(nextTime)
        } else {
            player.seekVideoPlaybackTime(0)
        }
        player.tracker.tracker(name: .detailClick, params: ["click": "fifteen_secs_back", "page_name": "detail_page"])
    }

    @objc func forward() {
        if player.minutes.info.basicInfo?.videoURL == nil {
            self.delegate?.showToast(text: BundleI18n.Minutes.MMWeb_MV_VideoGenerating, by: self)
            return
        }
        let currentTime = player.currentPlaybackTime.time
        let nextTime = currentTime + 15
        if nextTime < player.duration {
            player.seekVideoPlaybackTime(nextTime)
        } else {
            player.seekVideoPlaybackTime(player.duration - 0.001)
        }
        player.tracker.tracker(name: .detailClick, params: ["click": "fifteen_secs_forward", "page_name": "detail_page"])
    }
    
    private func handleMediaFail(_ error: MediaMutexError) {
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

    @objc func panAction(_ gesture: UIPanGestureRecognizer) {
    }

    func updateSpeedButton() {
        speedButton.button.setTitle(getFormatedSpeedString(by: Double(player.playbackSpeed)), for: .normal)
    }

    func updateUIStyle() {
        updateSpeedButton()
        updateSliderOffset()
    }

    func getFormatedSpeedString(by value: Double) -> String {
        let titleString: String
        if value == 1.0 || value == 2.0 || value == 3.0 {
            titleString = String(format: "%.0fx", value)
        } else {
            titleString = String(format: "%gx", value)
        }
        return titleString
    }
}

extension MinutesVideoControlPannel: MinutesSliderViewDelegate {

    func sliderValueWillChange() {
        isSeeking = true
    }

    func sliderValueDidChanged(_ value: CGFloat) {
        let duration = player.duration
        let time = value * duration
        currentTimeLabel.text = time.autoFormat(anchorTime: duration)

        if !isSeeking {
            player.seekVideoProcess(value)
            var trackParams = [AnyHashable: Any]()
            trackParams.append(.progressBarChange)
            trackParams.append(.controller)
            player.tracker.tracker(name: .clickButton, params: trackParams)

            player.tracker.tracker(name: .detailClick, params: ["click": "progress_bar_change", "location": "controller", "target": "none"])
        }
    }

    func sliderValueDidEndChanged() {
        isSeeking = false
    }
}

extension MinutesVideoControlPannel {

    func updateReactionInfo(_ info: [ReactionInfo]) {
        let duration = player.duration * 1000
        commentTipsViews.forEach { v in
            v.removeFromSuperview()
        }
        commentTipsViews = []
        var views: [UIView] = []
        info.forEach { item in
            if duration > 0 {
                let time = Double(item.startTime ?? 0)
                var offset = Double(slider.bounds.width) * (time / duration)
                if offset < 0 {
                    offset = 0
                }
                let view = UIImageView.reactionView(for: item.emojiCode)
                view.isHidden = isInCCMfg
                slider.addSubview(view)
                view.snp.makeConstraints { maker in
                    maker.width.height.equalTo(16)
                    maker.centerX.equalTo(offset)
                    maker.bottom.equalTo(self.slider.snp.centerY).offset(-3)
                }
                views.append(view)
            }
        }
        commentTipsViews = views
        slider.bringThumbToFront()
    }
}

extension MinutesVideoControlPannel {
    static var playButtionImage: UIImage = {
        return colorImage(color: UIColor.ud.primaryFillDefault,
                             size: CGSize(width: 56, height: 56),
                             cornerRadius: 28,
                             icon: UDIcon.getIconByKey(.playFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)))
    }()

    // disable-lint: magic number
    static var stopButtionImage: UIImage = {
        return colorImage(color: UIColor.ud.primaryFillDefault,
                             size: CGSize(width: 56, height: 56),
                             cornerRadius: 28,
                             icon: UDIcon.getIconByKey(.pauseFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)))
    }()
    // enable-lint: magic number

    private class func colorImage(color: UIColor,
                                  size: CGSize,
                                  cornerRadius: CGFloat? = nil,
                                  icon: UIImage? = nil) -> UIImage {
        let image = UIGraphicsImageRenderer(size: size).image { renderContext in
            color.setFill()
            renderContext.fill(CGRect(origin: .zero, size: size))
        }

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = image.scale
        let rect = CGRect(origin: .zero, size: size)
        let render = UIGraphicsImageRenderer(bounds: rect, format: format)
        let newImage = render.image { _ in
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius ?? 0.0).addClip()
            image.draw(in: rect)
            if let centerImage = icon {
                let area = CGRect(x: (size.width - centerImage.size.width) / 2,
                                  y: (size.height - centerImage.size.height) / 2,
                                  width: centerImage.size.width,
                                  height: centerImage.size.height)
                centerImage.draw(in: area, blendMode: .normal, alpha: 1.0)
            }
        }

        return newImage
    }
}

extension MinutesVideoControlPannel: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UIScreenEdgePanGestureRecognizer {
            return true
        }
        return false
    }

}

extension MinutesVideoControlPannel:MinutesVideoPlayerListener {
    func videoEngineDidLoad() {
    }

    func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {
        self.updatePlayerStatus(status.videoPlayerStatus)
    }
    func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        self.updatePlaybackTime(currentPlaybackTime: time)
    }
}
