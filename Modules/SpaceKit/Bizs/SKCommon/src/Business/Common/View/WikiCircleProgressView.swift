//
//  WikiCircleProgressView.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/9.
//  

import UIKit
import UniverseDesignColor

class WikiCircleProgressView: UIView {

    var lineWidth: CGFloat = 1.5

    private(set) var progress: CGFloat = 0
    private var backgroundLayer: CAShapeLayer!
    private var frameLayer: CAShapeLayer?

    var circleColor: UIColor = UDColor.N500

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        let center = bounds.center
        let radius = min(frame.width, frame.height) / 2
        let backgroundPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.lineWidth = lineWidth
        backgroundLayer.strokeColor = UIColor.ud.N100.cgColor
        backgroundLayer.fillColor = nil
        backgroundLayer.path = backgroundPath.cgPath
        layer.addSublayer(backgroundLayer)
        self.backgroundLayer = backgroundLayer
    }

    func update(progress: CGFloat) {
        self.progress = max(0, min(progress, 1))
        updateCircleLayer(progress: progress)
    }

    private func updateCircleLayer(progress: CGFloat) {
        let center = bounds.center
        let radius = min(frame.width, frame.height) / 2
        let startAngle = CGFloat.pi * 1.5 // 圆弧从上方开始
        let endAngle = CGFloat.pi * 2 * progress + startAngle
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        let frameLayer = CAShapeLayer()
        frameLayer.lineWidth = lineWidth
        frameLayer.strokeColor = circleColor.cgColor
        frameLayer.fillColor = nil
        frameLayer.path = circlePath.cgPath
        self.frameLayer?.removeFromSuperlayer()
        layer.addSublayer(frameLayer)
        self.frameLayer = frameLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutBackgroundLayer()
    }

    private func layoutBackgroundLayer() {
        let center = bounds.center
        let radius = min(frame.width, frame.height) / 2
        let backgroundPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        backgroundLayer.path = backgroundPath.cgPath
    }
}
