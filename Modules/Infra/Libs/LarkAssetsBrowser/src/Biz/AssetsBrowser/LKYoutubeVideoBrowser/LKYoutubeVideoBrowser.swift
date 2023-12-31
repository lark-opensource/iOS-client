//
//  LKYoutubeVideoBrowser.swift
//  LarkChat
//
//  Created by zc09v on 2019/6/6.
//

import UIKit
import Foundation
import WebKit
import LarkUIKit

public final class LKYoutubeVideoBrowser: BaseUIViewController, WebBrowserGestureViewDelegate, WKYTPlayerViewDelegate, UIViewControllerTransitioningDelegate {
    private let videoId: String
    public let coverImageView: UIImageView
    public let fromThumbnail: UIImageView?
    private var shouldSwipe: Bool = false
    private let loadingView = UIImageView(image: Resources.asset_video_loading)
    private let backgroundView = UIView()
    private let footerView: LKVideoDisplayFooterView
    private var timer: Timer?
    private var duration: TimeInterval = 0

    private var isVideoPlaying = false

    private lazy var ytPlayer: WKYTPlayerView = {
        let player = WKYTPlayerView(frame: .zero)
        player.delegate = self
        return player
    }()

    private let closeButton: UIButton

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public init(videoId: String, fromThumbnail: UIImageView?) {
        self.videoId = videoId
        self.fromThumbnail = fromThumbnail
        if let fromThumbnail = fromThumbnail {
            self.coverImageView = UIImageView(image: fromThumbnail.image)
            self.coverImageView.contentMode = fromThumbnail.contentMode
        } else {
            self.coverImageView = UIImageView(frame: .zero)
        }
        self.closeButton = UIButton(type: .custom)
        self.footerView = LKVideoDisplayFooterView(showMoreButton: false,
                                                   showAssetButton: false)
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        isNavigationBarHidden = true
        self.view.addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.black
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        closeButton.setImage(Resources.asset_video_close, for: .normal)
        closeButton.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        backgroundView.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(34)
            make.width.height.equalTo(24)
        }
        backgroundView.addSubview(coverImageView)
        if let size = coverImageView.image?.size {
            if (size.width / size.height) < (self.view.frame.width / self.view.frame.height) { // 长图
                coverImageView.snp.makeConstraints { (make) in
                    make.center.equalToSuperview()
                    make.height.equalToSuperview()
                    let width = self.view.frame.height * size.width / size.height
                    make.width.equalTo(width)
                }
            } else {
                coverImageView.snp.makeConstraints { (make) in
                    make.center.equalToSuperview()
                    make.width.equalToSuperview()
                    let height = self.view.frame.width * size.height / size.width
                    make.height.equalTo(height)
                }
            }
        } else {
            coverImageView.snp.makeConstraints { (make) in
                make.top.equalTo(closeButton.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        }
        backgroundView.addSubview(ytPlayer)
        ytPlayer.snp.makeConstraints { (make) in
            make.edges.equalTo(self.coverImageView.snp.edges)
        }
        backgroundView.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        self.footerView.slider.seekingToProgress = { [unowned self] progress, finished in
            if finished {
                self.ytPlayer.playVideo()
                self.ytPlayer.seek(toSeconds: progress * Float(self.duration), allowSeekAhead: true)
                self.scheduledTimer()
            } else {
                self.ytPlayer.pauseVideo()
            }
        }
        backgroundView.addSubview(self.footerView)
        self.footerView.snp.remakeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(44)
        }

        self.backgroundView.bringSubviewToFront(closeButton)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        backgroundView.addGestureRecognizer(singleTap)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGesture.maximumNumberOfTouches = 1
        backgroundView.addGestureRecognizer(panGesture)

        self.showCoverView()
        self.showLoadingView()
        ytPlayer.load(withVideoId: videoId, playerVars: ["controls": "0", "playsinline": "1"])

        self.scheduledTimer()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isNavigationBarHidden = true
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isNavigationBarHidden = false
    }

    private func showCoverView() {
        self.footerView.isHidden = true
        self.coverImageView.isHidden = false
        self.ytPlayer.isHidden = true
    }

    private func showPlayView() {
        self.coverImageView.isHidden = true
        self.ytPlayer.isHidden = false
        self.footerView.isHidden = false
        self.closeButton.isHidden = false
    }

    private func showLoadingView() {
        loadingView.isHidden = false
        loadingView.lu.addRotateAnimation()
    }

    private func hideLoadingView() {
        loadingView.isHidden = true
        loadingView.lu.removeRotateAnimation()
    }

    private func resetFooterView() {
        footerView.startTimeLabel.text = stringFromTimeInterval(0)
        footerView.endTimeLabel.text = stringFromTimeInterval(self.duration)
        footerView.slider.setProgress(0, animated: false)
        footerView.slider.setCacheProgress(0, animated: false)
    }

    @objc
    private func playButtonClicked() {
        if isVideoPlaying {
            self.ytPlayer.pauseVideo()
        } else {
            self.ytPlayer.playVideo()
        }
    }

    func webBrowserHandleTouch() {
        self.handleSingleTap()
    }

    @objc
    func handlePanGesture(ges: UIPanGestureRecognizer) {
        let translation = ges.translation(in: self.backgroundView)
        let velocity = ges.velocity(in: self.backgroundView)
        switch ges.state {
        case .began:
            shouldSwipe = translation.y >= 0
            if shouldSwipe {
                self.closeButton.isHidden = true
                self.footerView.isHidden = true
            }
        case .changed:
            guard shouldSwipe else {
                return
            }
            var fraction = translation.y / backgroundView.bounds.height
            fraction = max(fraction, 0)
            self.backgroundView.backgroundColor = UIColor.black.withAlphaComponent(1 - fraction)
            let scaleTransform = CGAffineTransform(scaleX: 1 - fraction, y: 1 - fraction)
            let translationTransform = CGAffineTransform(translationX: translation.x, y: translation.y)
            self.coverImageView.transform = scaleTransform.concatenating(translationTransform)
            self.ytPlayer.transform = scaleTransform.concatenating(translationTransform)
        case .ended, .cancelled:
            guard shouldSwipe else {
                return
            }
            let shouldComplete = velocity.y > 50
            if !shouldComplete || ges.state == .cancelled {
                UIView.animate(withDuration: 0.25, animations: {
                    self.closeButton.isHidden = false
                    self.footerView.isHidden = false
                    self.coverImageView.transform = CGAffineTransform.identity
                    self.ytPlayer.transform = CGAffineTransform.identity
                    self.backgroundView.backgroundColor = UIColor.black
                })
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        default:
            break
        }
    }

    @objc
    func handleSingleTap() {
        if ytPlayer.isHidden {
            self.footerView.isHidden = true
        } else {
            self.closeButton.isHidden = !self.closeButton.isHidden
            self.footerView.isHidden = !self.footerView.isHidden
            self.invalidateTimer()
            if !self.footerView.isHidden && self.isVideoPlaying {
                self.scheduledTimer()
            }
        }
    }

    private func scheduledTimer() {
        self.invalidateTimer()
        self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] (_) in
            self?.closeButton.isHidden = true
            self?.footerView.isHidden = true
        }
    }

    private func invalidateTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }

    private func stringFromTimeInterval(_ interval: TimeInterval) -> String {
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

    private func hookWebBrowserTouch() {
        // 当点击webview在内部时，手势会被webview(UIWebBrowserView)吞掉,在上面加层拦截
        for subView in ytPlayer.webView?.scrollView.subviews ?? [] {
            if let contentViewClass = NSClassFromString("WKContentView"),
               subView.isKind(of: contentViewClass) {
                let gestureView = WebBrowserGestureView()
                gestureView.delegate = self
                gestureView.backgroundColor = UIColor.clear
                subView.addSubview(gestureView)
                gestureView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
        }
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

    // WKYTPlayerViewDelegate
    public func playerViewDidBecomeReady(_ playerView: WKYTPlayerView) {
        ytPlayer.getDuration { [weak self] (duration, _) in
            self?.duration = duration
            self?.ytPlayer.playVideo()
        }
    }

    public func playerView(_ playerView: WKYTPlayerView, receivedError error: WKYTPlayerError) {}

    public func playerView(_ playerView: WKYTPlayerView, didChangeTo state: WKYTPlayerState) {
        switch state {
        case .playing:
            if self.ytPlayer.isHidden {
                self.hookWebBrowserTouch()
                self.resetFooterView()
                self.hideLoadingView()
                self.showPlayView()
            }
            self.isVideoPlaying = true
        case .ended:
            self.resetFooterView()
            self.ytPlayer.seek(toSeconds: 0, allowSeekAhead: true)
            self.ytPlayer.stopVideo()
            self.invalidateTimer()
        default:
            self.isVideoPlaying = false
        }
    }

    public func playerView(_ playerView: WKYTPlayerView, didPlayTime playTime: Float) {
        guard isVideoPlaying else {
            return
        }
        if playTime > 0 {
            footerView.startTimeLabel.text = stringFromTimeInterval(TimeInterval(playTime))
        }
        let duration = Float(self.duration)
        var playPercent = playTime / duration
        playPercent = min(max(0, playPercent), 1)
        footerView.slider.setProgress(playPercent, animated: false)

        var cachePercent = playTime / duration
        cachePercent = min(max(0, cachePercent), 1)
        footerView.slider.setCacheProgress(cachePercent, animated: false)
    }

    // UIViewControllerTransitioningDelegate
    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return LKYoutubeVideoBrowserPresentTransitioning()
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return LKYoutubeVideoBrowserDismissTransitioning()
    }
}

private protocol WebBrowserGestureViewDelegate: AnyObject {
    func webBrowserHandleTouch()
}

private final class WebBrowserGestureView: UIView {
    weak var delegate: WebBrowserGestureViewDelegate?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.delegate?.webBrowserHandleTouch()
        super.touchesBegan(touches, with: event)
    }
}
