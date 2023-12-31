//
//  CircleProgressView.swift
//  ByteView
//
//  Created by huangshun on 2020/1/17.
//

import UIKit

open class CircleProgressView: UIView {

    public var lineWidth: CGFloat = 1.5

    private(set) var progress: CGFloat = 0
    private var backgroundLayer: CAShapeLayer!
    private var frameLayer: CAShapeLayer?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(frame.width, frame.height) / 2
        let backgroundPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true)
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.lineWidth = lineWidth
        backgroundLayer.path = backgroundPath.cgPath
        layer.addSublayer(backgroundLayer)
        backgroundLayer.ud.setStrokeColor(UIColor.ud.N100)
        backgroundLayer.fillColor = nil
        self.backgroundLayer = backgroundLayer
    }

    public func update(progress: CGFloat) {
        self.progress = max(0, min(progress, 1))
        updateCircleLayer(progress: self.progress)
    }

    private func updateCircleLayer(progress: CGFloat) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(frame.width, frame.height) / 2
        let startAngle = CGFloat.pi * 1.5 // 圆弧从上方开始
        let endAngle = CGFloat.pi * 2 * progress + startAngle
        let circlePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true)
        let frameLayer = CAShapeLayer()
        frameLayer.lineWidth = lineWidth
        frameLayer.path = circlePath.cgPath
        self.frameLayer?.removeFromSuperlayer()
        layer.addSublayer(frameLayer)
        frameLayer.ud.setStrokeColor(UIColor.ud.primaryContentDefault)
        frameLayer.fillColor = nil
        self.frameLayer = frameLayer
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutBackgroundLayer()
    }

    private func layoutBackgroundLayer() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(frame.width, frame.height) / 2
        let backgroundPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true)
        backgroundLayer.path = backgroundPath.cgPath
    }
}
