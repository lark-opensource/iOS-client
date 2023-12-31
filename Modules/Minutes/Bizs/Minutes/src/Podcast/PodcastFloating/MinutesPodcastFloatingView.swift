//
//  MinutesPodcastFloatingView.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/4/6.
//

import UIKit
import Foundation
import LarkUIKit
import Kingfisher
import MinutesFoundation
import UniverseDesignColor
import LarkContainer
import MinutesNetwork

class MinutesPodcastFloatingView: UIView {
    static let viewSize: CGSize = CGSize(width: 90, height: 120)

    private lazy var circleView: MinutesGradientCircleView = {
        let view = MinutesGradientCircleView(frame: CGRect.zero)
        return view
    }()

    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var durationLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.text = "00:00:00"
        label.numberOfLines = 1
        label.textAlignment = .center
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont(name: "DINAlternate-Bold", size: 14)
        return label
    }()

    private lazy var imageDownloader: ImageDownloader = {
        let imageDownloader = ImageDownloader(name: "MinutesImageDownloader")
        imageDownloader.sessionConfiguration = MinutesAPI.sessionConfiguration
        return imageDownloader
    }()

    var onTapViewBlock: ((UserResolver) -> Void)?

    private var tracker: MinutesTracker?

    let videoPlayer: MinutesVideoPlayer

    let userResolver: UserResolver
    init(videoPlayer: MinutesVideoPlayer, resolver: UserResolver) {
        self.userResolver = resolver
        self.videoPlayer = videoPlayer
        super.init(frame: CGRect.zero)

        self.backgroundColor = UIColor.ud.bgFloatOverlay

        self.layer.cornerRadius = 12
        self.layer.borderWidth = 0.5
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        self.layer.masksToBounds = true

        addSubview(circleView)
        addSubview(coverImageView)
        addSubview(durationLabel)
        layoutSubviewsManually()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapAudioFloatingView(_:)))
        self.addGestureRecognizer(tapGestureRecognizer)

        loadCoverImage(status: videoPlayer.playerStatus.videoPlayerStatus)
        addVideoPlayerHandler()
        videoPlayer.pageType = .podcast

        self.tracker = MinutesTracker(minutes: videoPlayer.minutes)

        tracker?.tracker(name: .podcastMiniView, params: [:])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSubviewsManually() {
        circleView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(12)
            maker.left.equalToSuperview().offset((MinutesPodcastFloatingView.viewSize.width - 80) / 2)
            maker.width.height.equalTo(80)
        }

        coverImageView.layer.cornerRadius = 28
        coverImageView.layer.masksToBounds = true
        coverImageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(24)
            maker.left.equalToSuperview().offset((MinutesPodcastFloatingView.viewSize.width - 56) / 2)
            maker.width.height.equalTo(56)
        }

        durationLabel.snp.makeConstraints { maker in
            maker.top.equalTo(circleView.snp.bottom).offset(2)
            maker.left.right.equalToSuperview()
        }
    }

    @objc
    private func didTapAudioFloatingView(_ gesture: UITapGestureRecognizer) {
        self.tracker?.tracker(name: .miniPodcast, params: ["action_name": "podcast_enter"])
        self.tracker?.tracker(name: .podcastMiniClick, params: ["click": "podcast_enter", "target": "vc_minutes_podcast_view"])

        onTapViewBlock?(userResolver)
    }

    private func addVideoPlayerHandler() {
        self.videoPlayer.listeners.addListener(self)
    }

    private func loadCoverImage(status: MinutesVideoPlayerStatus) {
        if status == .stopped,
           !MinutesPodcast.shared.hasNext {
            coverImageView.layer.removeAllAnimations()
            return
        }

        if status == .playing || status == .loading || videoPlayer.currentPlaybackTime.time > 0 {
            let mediaType = videoPlayer.minutes.basicInfo?.mediaType ?? .audio
            let placeholderImage: UIImage
            switch mediaType {
            case .audio:
                placeholderImage = BundleResources.Minutes.minutes_feed_list_item_audio_width
            case .text:
                placeholderImage = BundleResources.Minutes.minutes_feed_list_item_text_width
            case .video:
                placeholderImage = BundleResources.Minutes.minutes_feed_list_item_video_width
            default:
                placeholderImage = BundleResources.Minutes.minutes_feed_list_item_audio_width
            }
            coverImageView.kf.setImage(with: URL(string: videoPlayer.minutes.basicInfo?.videoCover ?? ""),
                                       placeholder: placeholderImage,
                                       options: [.downloader(imageDownloader)])
            startRotateImageView()
        } else {
            coverImageView.layer.removeAllAnimations()
            coverImageView.image = BundleResources.Minutes.minutes_podcast_floating_loading
        }
    }

    private func startRotateImageView() {
        if coverImageView.layer.animation(forKey: "animation") != nil { return }

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Double.pi * 2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [rotationAnimation]
        groupAnimation.duration = 10.0
        groupAnimation.repeatCount = .infinity
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = .forwards
        coverImageView.layer.add(groupAnimation, forKey: "animation")
    }

    private func resetDuration(_ timeInterval: TimeInterval) {
        var duration = Int(timeInterval)
        let hours: Int = duration / 3600
        let hoursString: String = hours > 9 ? "\(hours)" : "0\(hours)"

        let minutes = duration % 3600 / 60
        let minutesString = minutes > 9 ? "\(minutes)" : "0\(minutes)"

        let seconds = duration % 3600 % 60
        let secondsString = seconds > 9 ? "\(seconds)" : "0\(seconds)"

        durationLabel.text = "\(hoursString):\(minutesString):\(secondsString)"
    }
}

extension MinutesPodcastFloatingView: MinutesVideoPlayerListener {
    func videoEngineDidLoad() {
    }

    func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {
        self.loadCoverImage(status: status.videoPlayerStatus)
    }

    func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        DispatchQueue.main.async {
            if self.videoPlayer.isFinish { return }
            self.resetDuration(time.time)
            self.circleView.set(currentTime: time.time, total: self.videoPlayer.duration)
        }
    }
}


// MARK: - MinutesGradientCircleView

class MinutesGradientCircleView: UIView {

    private let firstColor: UIColor = UIColor.ud.colorfulTurquoise.nonDynamic
    private let secondColor: UIColor = UIColor.ud.colorfulBlue.nonDynamic

    var ringThickness: CGFloat = 3

    private var endAngle: CGFloat = -0.5 * CGFloat.pi

    private lazy var animationShapeLayer: CAShapeLayer = CAShapeLayer()
    private lazy var solidCicleShapeLayer: CAShapeLayer = CAShapeLayer()
    private lazy var gradientLayer: CAGradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.addSublayer(solidCicleShapeLayer)
        gradientLayer.mask = animationShapeLayer
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        draw(rect, angle: endAngle)
    }

    private func draw(_ rect: CGRect, angle: CGFloat) {
        let path1 = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
        gradientLayer.frame = path1.bounds
        gradientLayer.ud.setColors([firstColor, secondColor])

        let center: CGPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let outerBorderWidth: CGFloat = 1
        let offSet = max(ringThickness * 2, ringThickness) / 2 + (outerBorderWidth * 2)
        let outerRadius: CGFloat = min(bounds.width, bounds.height) / 2 - CGFloat(offSet)

        let path2 = UIBezierPath(arcCenter: center,
                                 radius: outerRadius,
                                 startAngle: 0,
                                 endAngle: 2.0 * CGFloat.pi,
                                 clockwise: true)
        solidCicleShapeLayer.path = path2.cgPath
        solidCicleShapeLayer.ud.setFillColor(UIColor.clear)
        solidCicleShapeLayer.ud.setStrokeColor(UIColor.ud.lineBorderCard)
        solidCicleShapeLayer.lineWidth = 1
        solidCicleShapeLayer.contentsScale = layer.contentsScale

        let start: CGFloat = -0.5 * CGFloat.pi
        let end: CGFloat = endAngle
        let path3 = UIBezierPath(arcCenter: center,
                                 radius: outerRadius,
                                 startAngle: start,
                                 endAngle: end,
                                 clockwise: true)
        animationShapeLayer.path = path3.cgPath
        animationShapeLayer.ud.setFillColor(UIColor.clear)
        animationShapeLayer.ud.setStrokeColor(firstColor)
        animationShapeLayer.lineWidth = ringThickness
        animationShapeLayer.contentsScale = layer.contentsScale
        animationShapeLayer.lineCap = .round
    }

    func set(currentTime: TimeInterval, total: TimeInterval) {
        endAngle = toAngle(with: currentTime, total: total)
        setNeedsDisplay()
    }

    private func toAngle(with currentTime: TimeInterval, total: TimeInterval) -> CGFloat {
        if currentTime < total * 0.25 {
            return -0.5 * CGFloat.pi * (1 - CGFloat(currentTime / (total * 0.25)))
        } else {
            return 1.5 * CGFloat.pi * CGFloat((currentTime - total * 0.25) / (total - total * 0.25 ))
        }
    }
}

