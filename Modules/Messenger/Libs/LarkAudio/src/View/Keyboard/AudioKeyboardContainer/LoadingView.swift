//
//  LoadingView.swift
//  AnimationDemo
//
//  Created by 张鸿运 on 2021/3/30.
//

import Foundation
import UIKit

final class LoadingView: UIView {
    public var strokeColor: UIColor = UIColor.ud.primaryOnPrimaryFill {
        didSet {
            loadingLayer.ud.setStrokeColor(strokeColor)
        }
    }
    public var fillColor: UIColor = UIColor.ud.color(0, 0, 255) {
        didSet {
            loadingLayer.fillColor = fillColor.cgColor
        }
    }

    public var radius: CGFloat = 0.0

    private lazy var loadingLayer: CAShapeLayer = {
        let loadingLayer = CAShapeLayer()
        loadingLayer.fillColor = UIColor.ud.color(0, 0, 255).cgColor
        loadingLayer.strokeColor = UIColor.ud.primaryOnPrimaryFill.cgColor
        loadingLayer.lineWidth = 2.5
        loadingLayer.lineCap = CAShapeLayerLineCap.round
        return loadingLayer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(loadingLayer)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        loadingLayer.path = cycleBezierPath().cgPath
        loadingAnimation()
    }

    private func cycleBezierPath() -> UIBezierPath {
        return UIBezierPath(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
                            radius: radius == 0 ? bounds.width / 4 * 3 : radius,
                            startAngle: -CGFloat(Double.pi / 2),
                            endAngle: CGFloat(Double.pi / 2 * 3),
                            clockwise: true)
    }

    private func loadingAnimation() {
        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = 0
        strokeStartAnimation.toValue = 1
        strokeStartAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        strokeStartAnimation.duration = 1.5
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0
        strokeEndAnimation.toValue = 1
        strokeEndAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        strokeEndAnimation.duration = 1.5 / 2.0
                let strokeAniamtionGroup = CAAnimationGroup()
        strokeAniamtionGroup.animations = [strokeStartAnimation, strokeEndAnimation]
        strokeAniamtionGroup.duration = 1.5
        strokeAniamtionGroup.fillMode = CAMediaTimingFillMode.removed
        strokeAniamtionGroup.isRemovedOnCompletion = false
        strokeAniamtionGroup.repeatCount = Float.infinity
        loadingLayer.add(strokeAniamtionGroup, forKey: "strokeAniamtionGroup")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        loadingAnimation()
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
        loadingLayer.removeAllAnimations()
    }
}
