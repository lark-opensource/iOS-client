//
//  UDSpinIndicator.swift
//  UniverseDesignLoading
//
//  Created by Miaoqi Wang on 2020/10/15.
//

import UIKit
import Foundation

class UDSpinInicator: UIView {
    var shapeLayer: CAShapeLayer?

    var size: CGFloat = 0
    var color: UIColor = .clear
    var lineWidth: CGFloat = 1
    var circleDegree: CGFloat = 0.6
    var animationDuration: TimeInterval = 1.2

    init(size: CGFloat,
         color: UIColor,
         lineWidth: CGFloat,
         circleDegree: CGFloat,
         animationDuration: TimeInterval) {
        let frame = CGRect(x: 0, y: 0, width: size, height: size)
        super.init(frame: frame)

        self.size = size
        self.color = color
        self.lineWidth = lineWidth
        self.circleDegree = circleDegree
        self.animationDuration = animationDuration
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(resetSpin),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        getShapeLayer()
    }

    public func update(size: CGFloat? = nil,
                       color: UIColor? = nil,
                       lineWidth: CGFloat? = nil,
                       circleDegree: CGFloat? = nil,
                       animationDuration: TimeInterval? = nil) {
        if let size = size {
            self.size = size
            self.frame = CGRect(x: 0, y: 0, width: size, height: size)
        }
        if let color = color {
            self.color = color
        }
        if let lineWidth = lineWidth {
            self.lineWidth = lineWidth
        }
        if let circleDegree = circleDegree {
            self.circleDegree = circleDegree
        }
        if let animationDuration = animationDuration {
            self.animationDuration = animationDuration
        }
        getShapeLayer()
    }

    func getShapeLayer() {
        self.shapeLayer?.removeFromSuperlayer()

        let path = UIBezierPath(arcCenter: .init(x: size / 2, y: size / 2),
                                radius: (size - lineWidth) / 2, // 内切圆
                                startAngle: 0,
                                endAngle: CGFloat.pi * 2,
                                clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.strokeStart = 0
        shapeLayer.strokeEnd = 1
        shapeLayer.lineWidth = lineWidth
        shapeLayer.path = path.cgPath

        shapeLayer.frame = bounds
        layer.addSublayer(shapeLayer)

        let validDegree = min(max(circleDegree, 0.1), 0.9)
        let startAnimation = CABasicAnimation(keyPath: "strokeStart")
        startAnimation.fromValue = -log2(1 / (1 - validDegree))
        startAnimation.toValue = 1
        let endAnimation = CABasicAnimation(keyPath: "strokeEnd")
        endAnimation.fromValue = 0
        endAnimation.toValue = 1

        let group = CAAnimationGroup()
        group.animations = [startAnimation, endAnimation]
        group.duration = animationDuration
        group.repeatCount = Float.infinity
        shapeLayer.add(group, forKey: nil)

        self.shapeLayer = shapeLayer
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        getShapeLayer()
    }

    override func didMoveToWindow() {
        guard self.window != nil else { return }
        getShapeLayer()
    }

    @objc private func resetSpin() {
        guard self.superview != nil else { return }
        getShapeLayer()
    }
}
