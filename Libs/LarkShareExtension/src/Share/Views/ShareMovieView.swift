//
//  ShareMovieView.swift
//  LarkShareExtension
//
//  Created by kangkang on 2022/12/28.
//

import Foundation
import LarkExtensionCommon
import AVFoundation
import AVKit
// swiftlint:disable all
final class ShareMovieView: UIView, ShareTableHeaderProtocol {
    // protocol
    var viewHeight: CGFloat = 252

    // 固定值
    private let verticalSpacing: CGFloat = 16
    private let horizontalSpacing: CGFloat = 48
    private let pauseImageSideLength: CGFloat = 32
    private let durationLabelFontSize: CGFloat = 12

    // init传来的值
    private let item: ShareMovieItem

    // 播放器view相关参数
    private let player: AVPlayer
    private var playerLayer: AVPlayerLayer
    private let playerView: UIView = UIView()
    private let durationLabel: UILabel = UILabel()
    private let pauseImageView: UIImageView = UIImageView(image: Resources.videoBeginPlay)

    init(item: ShareMovieItem) {
        self.item = item
        player = AVPlayer(url: item.url)
        playerLayer = AVPlayerLayer(player: player)
        super.init(frame: .zero)

        // playView
        player.volume = 0
        playerLayer.frame = playerView.bounds
        playerLayer.videoGravity = .resizeAspect
        playerView.layer.addSublayer(playerLayer)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playerView)

        let quo: CGFloat = (item.movieSize?.width ?? 1) / (item.movieSize?.height ?? 1)
        playerView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        playerView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        playerView.leftAnchor.constraint(greaterThanOrEqualTo: self.leftAnchor, constant: horizontalSpacing).isActive = true
        playerView.rightAnchor.constraint(greaterThanOrEqualTo: self.rightAnchor, constant: horizontalSpacing).isActive = true
        playerView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: verticalSpacing).isActive = true
        playerView.bottomAnchor.constraint(greaterThanOrEqualTo: self.bottomAnchor, constant: verticalSpacing).isActive = true
        playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: quo).isActive = true

        // 右下角的视频时长
        let durationStr = ShareMovieView.stringFromTimeInterval(item.duration)
        durationLabel.text = durationStr
        durationLabel.font = .systemFont(ofSize: durationLabelFontSize)
        durationLabel.textColor = ColorPub.N50
        durationLabel.layer.shadowColor = ColorPub.N900.cgColor
        durationLabel.layer.shadowOffset = CGSize(width: 0, height: 0)
        durationLabel.layer.shadowOpacity = 1
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        playerView.addSubview(durationLabel)
        durationLabel.rightAnchor.constraint(equalTo: playerView.rightAnchor, constant: -4).isActive = true
        durationLabel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor, constant: -4).isActive = true

        // 暂停按钮
        pauseImageView.translatesAutoresizingMaskIntoConstraints = false
        playerView.addSubview(pauseImageView)
        pauseImageView.centerXAnchor.constraint(equalTo: playerView.centerXAnchor).isActive = true
        pauseImageView.centerYAnchor.constraint(equalTo: playerView.centerYAnchor).isActive = true
        pauseImageView.widthAnchor.constraint(equalToConstant: pauseImageSideLength).isActive = true
        pauseImageView.heightAnchor.constraint(equalToConstant: pauseImageSideLength).isActive = true

        // 单击手势，播放/暂停
        let gesture = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        playerView.addGestureRecognizer(gesture)

        // 视频结束通知，用来循环播放
        NotificationCenter.default.addObserver(self, selector: #selector(replay),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    // 播放结束，从头开始播放
    @objc
    func replay() {
        player.seek(to: CMTime(value: 0, timescale: 1))
        player.play()
    }

    // 单击view，播放/暂停
    @objc
    func singleTap(_ tapGesture: UITapGestureRecognizer) {
        if player.rate == 0 {
            player.play()
            pauseImageView.isHidden = true
        } else {
            player.pause()
            pauseImageView.isHidden = false
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = playerView.bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 视频时长转为字符串
    private static func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        let interval = Int(round(interval))
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 60 / 60)
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
// swiftlint:enable all
