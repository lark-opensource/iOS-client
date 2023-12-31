//
//  AssetPreviewVideoCell.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/3.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import Photos
import LarkMonitor

final class AssetPreviewVideoCell: UICollectionViewCell {
    var assetIdentifier: String?
    var videoDidPlayToEnd: ((UICollectionViewCell) -> Void)? {
        didSet {
            videoView.videoDidPlayToEnd = { [weak self] _ in
                guard let `self` = self else { return }
                self.playerIcon.isHidden = false
                self.videoDidPlayToEnd?(self)
            }
        }
    }

    private let videoView = AVPlayerView()
    private let previewImageView = UIImageView()
    private let playerIcon = UIImageView(image: Resources.image_picker_video_icon)
    var item: AVPlayerItem?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(previewImageView)
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.isHidden = true
        previewImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(videoView)
        videoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(playerIcon)
        playerIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(60)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var currentImage: UIImage? {
        return previewImageView.image
    }

    func setPreviewImage(_ previewImage: UIImage?) {
        previewImageView.image = previewImage
        previewImageView.isHidden = false
    }

    func setPlayerItem(_ item: AVPlayerItem?) {
        self.item = item
        videoView.updatePlayerItem(item)
    }

    var isPlaying: Bool {
        return videoView.isPlaying
    }

    func startPlaying() {
        playerIcon.isHidden = true
        videoView.play()
    }

    func stopPlaying() {
        playerIcon.isHidden = false
        videoView.pause()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        videoView.updatePlayerItem(nil)
        self.item = nil
        previewImageView.image = nil
        previewImageView.isHidden = true
    }
}

private final class AVPlayerView: UIView {
    var videoDidPlayToEnd: ((AVPlayerView) -> Void)?

    private var playerLayer: AVPlayerLayer {
        return (layer as? AVPlayerLayer)!
    }

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    // 用于在埋点中标记不同的 item
    private var uuid = UUID()
    // 用于标记是否开始性能埋点
    private var isStartPowerMonitor = false

    init() {
        super.init(frame: .zero)
        playerLayer.player = AVPlayer()
        playerLayer.videoGravity = .resizeAspect
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer.frame = self.bounds
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updatePlayerItem(_ item: AVPlayerItem?) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        if let item = item {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(reset),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: item)
        }
        playerLayer.player?.replaceCurrentItem(with: item)
        self.uuid = UUID()
    }

    var isPlaying: Bool {
        return (playerLayer.player?.rate == 0) ? false : true
    }

    func play() {
        playerLayer.player?.play()
        if !isStartPowerMonitor {
            isStartPowerMonitor = true
            BDPowerLogManager.beginEvent("messenger_video_preview", params: [
                "scene": "album",
                "key": self.uuid.uuidString
            ])
        }
    }

    func pause() {
        playerLayer.player?.pause()
        if isStartPowerMonitor {
            isStartPowerMonitor = false
            BDPowerLogManager.endEvent("messenger_video_preview", params: [
                "scene": "album",
                "key": self.uuid.uuidString
            ])
        }
    }

    @objc
    private func reset() {
        playerLayer.player?.pause()
        playerLayer.player?.seek(to: CMTime(seconds: 0, preferredTimescale: 600))
        videoDidPlayToEnd?(self)
        if isStartPowerMonitor {
            isStartPowerMonitor = false
            BDPowerLogManager.endEvent("messenger_video_preview", params: [
                "scene": "album",
                "key": self.uuid.uuidString
            ])
        }
    }
}
