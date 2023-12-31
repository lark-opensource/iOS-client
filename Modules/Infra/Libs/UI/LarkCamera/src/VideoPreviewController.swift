//
//  VideoPreviewController.swift
//  Camera
//
//  Created by Kongkaikai on 2018/11/21.
//

import Foundation
import UIKit
import AVFoundation
import AVKit

final class VideoPreviewController: BasePreviewController {
    private(set) var player: AVPlayer = AVPlayer()
    private(set) var playerItem: AVPlayerItem?
    private(set) lazy var playerLayer: AVPlayerLayer = AVPlayerLayer(player: player)

    var videoURL: URL? {
        didSet {
            if let url = videoURL {
                playerItem = AVPlayerItem(asset: AVURLAsset(url: url))
                player.replaceCurrentItem(with: playerItem)
            }
        }
    }

    var onViewDidAppear: (() -> Void)?
    var onViewDidDisappear: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.black
        view.layer.addSublayer(playerLayer)

        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = view.bounds

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackFinished),
            name: .AVPlayerItemDidPlayToEndTime,
            object: self.player.currentItem)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.player.rate == 0 {
            self.player.play()
        }
        onViewDidAppear?()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDidDisappear?()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = view.bounds
    }

    @objc
    private func playbackFinished() {
        player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
        player.play()
    }
}
