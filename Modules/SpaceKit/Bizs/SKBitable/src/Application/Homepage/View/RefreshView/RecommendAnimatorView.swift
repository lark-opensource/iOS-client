//
//  RecommendAnimatorView.swift
//  SKBitable
//
//  Created by justin on 2023/9/6.
//

import Foundation
import UniverseDesignColor
import ESPullToRefresh

/// Activity indicator view with nice animations
open class RecommendIndicatorView: UIView {

    public static var defaultColor = UIColor.blue
    
    public static let strokeAnimationKey = "strokeAnimation"
    
    public static let defaultSize = CGSize(width: 20.0, height: 20.0)
    
    /// Color of activity indicator view.
    public var color: UIColor = RecommendIndicatorView.defaultColor

    /// Current status of animation, read-only.
    private(set) public var isAnimating: Bool = false
    
    lazy var circleLayer: CAShapeLayer = {
        let layer: CAShapeLayer = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: Self.defaultSize.width / 2, y: Self.defaultSize.height / 2),
        radius: Self.defaultSize.width / 2,
        startAngle: 0,
        endAngle: .pi + .pi / 2,
        clockwise: true)
        layer.fillColor = nil
        layer.strokeColor = Self.defaultColor.cgColor
        layer.lineWidth = 3
        layer.backgroundColor = nil
        layer.path = path.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: Self.defaultSize.width, height: Self.defaultSize.height)
        return layer
    }()

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }

    public init(frame: CGRect = .zero, color: UIColor? = nil) {
        self.color = color ?? RecommendIndicatorView.defaultColor
        super.init(frame: frame)
        
        circleLayer.strokeColor = self.color.cgColor
        circleLayer.frame = self.circleLayerFrame
        layer.addSublayer(circleLayer)
    }
    
    
    var circleLayerFrame: CGRect {
        let viewSize = self.circleSize
        return CGRect(
            x: (layer.bounds.width - viewSize.width) / 2,
            y: (layer.bounds.height - viewSize.height) / 2,
            width: viewSize.width,
            height: viewSize.height
        )
    }
    
    var circleSize: CGSize {
        var animationRect = frame.inset(by: .zero)
        var minEdge = min(animationRect.width, animationRect.height)
        if minEdge <= 0.0 {
            minEdge = Self.defaultSize.width
        }
        animationRect.size = CGSize(width: minEdge, height: minEdge)
        return animationRect.size
    }
    

    public override var bounds: CGRect {
        didSet {
            // setup the animation again for the new bounds
            if oldValue != bounds {
                circleLayer.frame = self.circleLayerFrame
                if isAnimating {
                    setUpAnimation()
                }
            }
        }
    }

    public final func startAnimating() {
        isAnimating = true
        layer.speed = 1
        setUpAnimation()
    }

    public final func stopAnimating() {
        isAnimating = false
        self.circleLayer.removeAnimation(forKey: Self.strokeAnimationKey)
    }

    private final func setUpAnimation() {
        self.circleLayer.removeAnimation(forKey: Self.strokeAnimationKey)
        self.circleLayer.add(self.strokeAnimations(), forKey: Self.strokeAnimationKey)
    }
    
    func strokeAnimations() -> CAAnimationGroup {
        let beginTime: Double = 0.0
        let strokeStartDuration: Double = 0.6
        let strokeEndDuration: Double = 0.35

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)

        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.duration = strokeEndDuration
        strokeEndAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
        strokeEndAnimation.fromValue = 0
        strokeEndAnimation.toValue = 1
        strokeEndAnimation.beginTime = strokeStartDuration

        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.duration = strokeStartDuration
        strokeStartAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
        strokeStartAnimation.fromValue = 0
        strokeStartAnimation.toValue = 1
        strokeStartAnimation.beginTime = beginTime

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [rotationAnimation, strokeEndAnimation, strokeStartAnimation]
        groupAnimation.duration = beginTime + strokeStartDuration + strokeEndDuration
        groupAnimation.repeatCount = .infinity
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = .forwards
        
        return groupAnimation
    }
}


class RecommendAnimatorView: UIView, ESRefreshProtocol, ESRefreshAnimatorProtocol {
    var insets: UIEdgeInsets = .zero
    var view: UIView { self }
    var duration: TimeInterval = 0.3
    var trigger: CGFloat = 56.0
    var executeIncremental: CGFloat = 56.0
    var state: ESRefreshViewState = .pullToRefresh

    private let indicatorView = RecommendIndicatorView(color: UIColor.ud.primaryContentDefault)

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(indicatorView)
        indicatorView.snp.makeConstraints {
            $0.width.height.equalTo(RecommendIndicatorView.defaultSize.width)
            $0.center.equalToSuperview()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshAnimationBegin(view: ESRefreshComponent) {
        isHidden = false
        indicatorView.startAnimating()
    }

    func refreshAnimationEnd(view: ESRefreshComponent) {
        isHidden = true
        indicatorView.stopAnimating()
    }

    func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) {
        isHidden = progress >= (5.0 / self.trigger) ? false : true
    }

    func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        guard self.state != state else { return }
        self.state = state
    }
}
