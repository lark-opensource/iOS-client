//
//  MinutesPullToRefresh.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/1/14.
//

import Foundation
import ESPullToRefresh
import UniverseDesignColor
import SnapKit

public final class MinutesRefreshHeaderAnimator: UIView, ESRefreshProtocol, ESRefreshAnimatorProtocol {
    public var insets: UIEdgeInsets = UIEdgeInsets.zero
    public var view: UIView { return self }
    public var duration: TimeInterval = 0.3
    public var trigger: CGFloat = 56.0
    public var executeIncremental: CGFloat = 56.0
    public var state: ESRefreshViewState = .pullToRefresh

    var showingRefreshAnimation = false

    var circleView: CircleView = {
        let circleView = CircleView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        return circleView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(circleView)
        circleView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
    }

    func startAnimation() {
        layer.speed = 1

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [rotationAnimation]
        groupAnimation.duration = 1.0
        groupAnimation.repeatCount = .infinity
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = .forwards
        circleView.circle.add(groupAnimation, forKey: "animation")
    }

    func stopAnimation() {
        circleView.circle.removeAllAnimations()
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refreshAnimationBegin(view: ESRefreshComponent) {
        startAnimation()
        showingRefreshAnimation = true
    }

    public func refreshAnimationEnd(view: ESRefreshComponent) {
        stopAnimation()
        showingRefreshAnimation = false
    }

    public func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) {
        let p = max(0.0, min(1.0, progress))
        var trans = CATransform3DIdentity
        let angel = CGFloat(.pi * 2 * p)
        trans = CATransform3DMakeRotation(angel, 0, 0, 1)
        circleView.circle.transform = trans
        alpha = p
    }

    public func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        guard self.state != state else {
            return
        }
        self.state = state

        switch state {
        case .pullToRefresh:
            circleView.isHidden = false
        case .releaseToRefresh:
            break
        case .noMoreData:
            break
        default:
            break
        }
    }
}

class CircleView: UIView {

    static private let circleColor = UIColor.ud.primaryContentDefault
    static private let lineWidth: CGFloat = 2.0
    static private let circleSize: CGSize = CGSize(width: 20, height: 20)

    var circle: CircleLayer = {
        let layer: CircleLayer = CircleLayer()
        let path: UIBezierPath = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: circleSize.width / 2, y: circleSize.height / 2),
        radius: circleSize.width / 2,
        startAngle: 0,
        endAngle: .pi / 2,
        clockwise: false)
        layer.fillColor = nil
        layer.strokeColor = circleColor.cgColor
        layer.lineWidth = lineWidth
        layer.lineCap = .round
        layer.backgroundColor = nil
        layer.path = path.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: circleSize.width, height: circleSize.height)
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.addSublayer(circle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CircleLayer: CAShapeLayer {
    override func layoutSublayers() {
        super.layoutSublayers()
        if let theSublayers = sublayers {
            for s in theSublayers {
                var theFrame = s.frame

                theFrame.origin.x = (bounds.width - theFrame.width) / 2.0
                theFrame.origin.y = (bounds.height - theFrame.height) / 2.0
                s.frame = theFrame
            }
        }
    }
}
