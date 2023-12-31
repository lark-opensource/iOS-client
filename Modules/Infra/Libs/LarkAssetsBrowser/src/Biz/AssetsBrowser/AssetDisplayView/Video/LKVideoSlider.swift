//
//  LKVideoSlider.swift
//  LarkUIKit
//
//  Created by Yuguo on 2018/8/16.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor

open class LKVideoSlider: UIView {
    private lazy var thumbView: UIView = {
        let thumbView = UIView()
        thumbView.layer.cornerRadius = thumbViewWidth / 2
        thumbView.backgroundColor = UIColor.white
        thumbView.frame = CGRect(x: 0, y: 0, width: thumbViewWidth, height: thumbViewWidth)
        thumbView.layer.shadowOffset = CGSize(width: 0, height: 2)
        thumbView.layer.shadowOpacity = 0.4
        thumbView.layer.shadowRadius = 1
        let shadowPath = UIBezierPath(ovalIn: thumbView.bounds)
        thumbView.layer.shadowPath = shadowPath.cgPath
        thumbView.isUserInteractionEnabled = false
        return thumbView
    }()

    private lazy var backgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.layer.cornerRadius = sliderHeight / 2
        backgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        return backgroundView
    }()

    private lazy var trackProgressView: UIView = {
        let trackProgressView = UIView()
        trackProgressView.backgroundColor = UIColor.ud.colorfulBlue
        trackProgressView.layer.cornerRadius = sliderHeight / 2
        return trackProgressView
    }()

    private lazy var cacheProgressView: UIView = {
        let cacheProgressView = UIView()
        cacheProgressView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        cacheProgressView.layer.cornerRadius = sliderHeight / 2
        return cacheProgressView
    }()

    public lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = createPanGesture()
        return panGesture
    }()

    private let sliderHeight: CGFloat = 2
    private let thumbViewWidth: CGFloat = 12

    private var progressBeforeDragging: Float = 0

    private(set) var progress: Float = 0
    private(set) var cacheProgress: Float = 0
    private(set) var isInteractive: Bool = false

    public var seekingToProgress: ((_ progress: Float, _ finished: Bool) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.buildViewHierarchy()
        self.addGestureRecognizer(panGesture)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.updateLayout()
    }

    public func setProgress(_ progress: Float, animated: Bool) {
        let progress = min(1, max(0, progress))
        self.progress = progress
        UIView.animate(withDuration: animated ? 0.3 : 0, delay: 0, options: .curveLinear, animations: {
            self.updateTrackProgress()
        }, completion: nil)
    }

    public func setCacheProgress(_ progress: Float, animated: Bool) {
        let progress = min(1, max(0, progress))
        self.cacheProgress = progress
        UIView.animate(withDuration: animated ? 0.3 : 0, delay: 0, options: .curveLinear, animations: {
            self.updateCacheProgress()
        }, completion: nil)
    }

    open func createPanGesture() -> UIPanGestureRecognizer {
        return UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
    }
}

// MARK: Private Method
private extension LKVideoSlider {
    var maxProgressWidth: CGFloat {
        return self.backgroundView.frame.width - thumbViewWidth
    }

    func buildViewHierarchy() {
        self.addSubview(self.backgroundView)
        self.backgroundView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(sliderHeight)
        }
        self.addSubview(self.thumbView)
        self.backgroundView.addSubview(self.cacheProgressView)
        self.backgroundView.addSubview(self.trackProgressView)
    }

    private func updateLayout() {
        self.trackProgressView.frame.size.height = self.backgroundView.frame.height
        self.cacheProgressView.frame.size.height = self.backgroundView.frame.height
        self.thumbView.center.y = self.backgroundView.center.y
        // slider的frame发生变化，track和cache的长度需要根据“进度”变化长短
        updateTrackProgress()
        updateCacheProgress()
    }

    public func updateTrackProgress() {
        let width = self.backgroundView.frame.width * CGFloat(self.progress)
        self.trackProgressView.frame = CGRect(origin: trackProgressView.frame.origin,
                                              size: CGSize(width: width, height: trackProgressView.frame.height))
        self.updateThumbPosition()
    }

    func updateCacheProgress() {
        let width = self.backgroundView.frame.width * CGFloat(self.cacheProgress)
        self.cacheProgressView.frame = CGRect(origin: cacheProgressView.frame.origin,
                                              size: CGSize(width: width, height: cacheProgressView.frame.height))
    }

    func updateThumbPosition() {
        let minCenterX = self.thumbViewWidth / 2
        let maxCenterX = self.backgroundView.frame.width - self.thumbViewWidth / 2
        self.thumbView.center.x = self.maxProgressWidth * CGFloat(self.progress) + minCenterX
        self.thumbView.center.x = max(minCenterX, min(maxCenterX, self.thumbView.center.x))
    }

    @objc
    public func handlePan(pan: UIPanGestureRecognizer) {
        let translate = pan.translation(in: self)
        switch pan.state {
        case .began:
            self.isInteractive = true
            self.progressBeforeDragging = self.progress
            UIView.animate(withDuration: 0.3) {
                self.thumbView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
        case .changed:
            let progressDelta = translate.x / self.maxProgressWidth
            let newProgress = progressBeforeDragging + Float(progressDelta)
            self.setProgress(newProgress, animated: false)

            if let seekingToProgress = self.seekingToProgress {
                seekingToProgress(self.progress, false)
            }
        case .cancelled, .ended, .failed:
            UIView.animate(withDuration: 0.3) {
                self.thumbView.transform = CGAffineTransform.identity
            }
            self.isInteractive = false

            if let seekingToProgress = self.seekingToProgress {
                seekingToProgress(self.progress, true)
            }
        default:
            break
        }
    }
}
