//
//  MinutesSpeakerSlider.swift
//  Minutes
//
//  Created by ByteDance on 2023/8/30.
//

import UIKit

public class MinutesSpeakerSlider: UIView {
    private var progressBeforeDragging: CGFloat = 0

    private(set) var progress: CGFloat = 0
    private(set) var isInteractive: Bool = false

    var timeline: (startTime: Int, stopTime: Int) = (0, 0)

    enum Layout {
        static let sliderHeight: CGFloat = 5
        static let thumbViewWidth: CGFloat = 23
    }

    private lazy var thumbView: UIView = {
        let thumbView = UIView()
        thumbView.layer.cornerRadius = Layout.thumbViewWidth / 2
//        thumbView.backgroundColor = UIColor.blue
        thumbView.frame = CGRect(x: 0, y: 0, width: Layout.thumbViewWidth, height: Layout.thumbViewWidth)
//        thumbView.layer.shadowOffset = CGSize(width: 0, height: 2)
//        thumbView.layer.shadowOpacity = 0.4
//        thumbView.layer.shadowRadius = 1
//        let shadowPath = UIBezierPath(ovalIn: thumbView.bounds)
//        thumbView.layer.shadowPath = shadowPath.cgPath
        thumbView.isUserInteractionEnabled = false
        return thumbView
    }()

    private lazy var backgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.layer.cornerRadius = Layout.sliderHeight / 2
        return backgroundView
    }()

    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
        return panGesture
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let panGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(tap:)))
        panGesture.numberOfTouchesRequired = 1
        panGesture.numberOfTapsRequired = 1
        return panGesture
    }()

    public var seekingToProgress: ((_ progress: CGFloat, _ finished: Bool, _ rawLength: CGFloat) -> Void)?

    public var panBegan: (() -> Void)?

    func setProgressColor(_ color: UIColor?) {
        backgroundView.backgroundColor = color
        thumbView.backgroundColor = color
    }

    var thumbViewHidden: Bool {
        get {
            thumbView.isHidden
        }
        set {
            thumbView.isHidden = newValue
        }
    }

    var boldBackgroundColor: Bool = false {
        didSet {
            let boldHeight = Layout.sliderHeight + 2
            backgroundView.snp.updateConstraints { (maker) in
                maker.height.equalTo(boldBackgroundColor ? boldHeight :Layout.sliderHeight)
            }
            backgroundView.layer.cornerRadius = boldBackgroundColor ? boldHeight / 2.0 : Layout.sliderHeight / 2.0
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(backgroundView)
        addSubview(thumbView)
        thumbView.isHidden = true
        backgroundView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.height.equalTo(Layout.sliderHeight)
        }
        addGestureRecognizer(panGesture)
        addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateTrackProgress()
    }

    public func setProgress(_ progress: CGFloat) {
        let progress = min(1, max(0, progress))
        self.progress = progress
        self.updateTrackProgress()
    }

    public func setProgress(_ progress: CGFloat, animated: Bool) {
        let progress = min(1, max(0, progress))
        self.progress = progress

        UIView.animate(withDuration: animated ? 0.3 : 0, delay: 0, options: .curveLinear, animations: {
            self.updateTrackProgress()
            self.thumbView.isHidden = false
        }, completion: nil)
    }
}

private extension MinutesSpeakerSlider {
    func updateTrackProgress() {
        // 最小和最大中心位置
        let minCenterX = Layout.thumbViewWidth / 2
        let maxCenterX = backgroundView.bounds.width - Layout.thumbViewWidth / 2
//        thumbView.center.x = maxProgressWidth * CGFloat(progress) + minCenterX
        thumbView.center.x = maxProgressWidth * CGFloat(progress)
        thumbView.center.x = max(minCenterX, min(maxCenterX, thumbView.center.x))
        thumbView.center.y = backgroundView.center.y
    }

    // 小圆点最大滚动距离
    var maxProgressWidth: CGFloat {
//        return backgroundView.frame.width - Layout.thumbViewWidth
        return backgroundView.frame.width
    }

    @objc
    private func handlePan(pan: UIPanGestureRecognizer) {
//        let translate = pan.translation(in: self)
        let location = pan.location(in: self)
        switch pan.state {
        case .began:
            isInteractive = true
            progressBeforeDragging = progress

//            self.thumbView.isHidden = false

//            let progressDelta = translate.x / maxProgressWidth
//            let newProgress = progressBeforeDragging + CGFloat(progressDelta)
//            setProgress(newProgress, animated: false)

            panBegan?()
        case .changed:
            let newProgress = location.x / maxProgressWidth
//            let newProgress = progressBeforeDragging + CGFloat(progressDelta)

//            let width = bounds.width
//            var currentValue = loc.x / width
//            if currentValue < 0 {
//                currentValue = 0
//            }
//            if currentValue > 1 {
//                currentValue = 1
//            }

            setProgress(newProgress, animated: false)
            seekingToProgress?(progress, false, location.x)

        case .cancelled, .ended, .failed:
            isInteractive = false

            seekingToProgress?(progress, true, location.x)
        default:
            break
        }
    }

    @objc
    private func handleTap(tap: UITapGestureRecognizer) {
        let location = tap.location(in: self)

        let progressDelta = location.x / maxProgressWidth
        let newProgress = progressDelta

        setProgress(newProgress, animated: false)

        seekingToProgress?(progress, true, location.x)
    }
}
