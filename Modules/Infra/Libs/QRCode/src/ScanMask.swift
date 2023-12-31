//
//  QRScanView.swift
//  Lark
//
//  Created by zc09v on 2017/4/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

final class ScanMask: UIView {
    let cornerLength: CGFloat = 18
    let edgeLayer = CAShapeLayer()
    let cornerLayer = CAShapeLayer()
    let fillLayer = CAShapeLayer()
    let scanningLayer = CALayer()
    let scanningImgLayer = CALayer()
    let animation = CABasicAnimation()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.addSublayer(edgeLayer)
        self.layer.addSublayer(cornerLayer)
        self.layer.addSublayer(fillLayer)
        self.layer.addSublayer(scanningLayer)
        scanningLayer.addSublayer(scanningImgLayer)
    }

    public func update(frame: CGRect, scanRect: CGRect) {
        let path = UIBezierPath(rect: frame)
        let w = frame.size.width
        let h = frame.size.height
        let fillPath = UIBezierPath(rect: CGRect(x: frame.origin.x - w / 2,
                                                 y: frame.origin.y - h / 2, width: w * 2, height: h * 2))
        fillLayer.path = fillPath.cgPath
        fillLayer.ud.setFillColor(UIColor.ud.staticBlack.withAlphaComponent(0.1))
        self.addScanAnimation(rect: scanRect)
    }

    // UIBezierPath.stroke要放到drawrect中，或者有指定的context
    // UIBezierPath制定的坐标，都是默认是当前view的
    fileprivate func addEdge(rect: CGRect) {
        let edgePath = UIBezierPath(rect: rect)
        edgeLayer.path = edgePath.cgPath
        edgeLayer.ud.setStrokeColor(UIColor.ud.colorfulBlue)
        edgeLayer.ud.setFillColor(UIColor.clear)

        let cornerPath = UIBezierPath()
        let originPoint = CGPoint(x: rect.origin.x, y: rect.origin.y)
        cornerPath.move(to: CGPoint(x: originPoint.x + cornerLength, y: originPoint.y))
        cornerPath.addLine(to: CGPoint(x: originPoint.x, y: originPoint.y))
        cornerPath.addLine(to: CGPoint(x: originPoint.x, y: originPoint.y + cornerLength))

        cornerPath.move(to: CGPoint(x: originPoint.x + cornerLength, y: originPoint.y + rect.size.height))
        cornerPath.addLine(to: CGPoint(x: originPoint.x, y: originPoint.y + rect.size.height))
        cornerPath.addLine(to: CGPoint(x: originPoint.x, y: originPoint.y + rect.size.height - cornerLength))

        cornerPath.move(to: CGPoint(x: originPoint.x + rect.size.width - cornerLength, y: originPoint.y))
        cornerPath.addLine(to: CGPoint(x: originPoint.x + rect.size.width, y: originPoint.y))
        cornerPath.addLine(to: CGPoint(x: originPoint.x + rect.size.width, y: originPoint.y + cornerLength))

        cornerPath.move(to: CGPoint(x: originPoint.x + rect.size.width,
                                    y: originPoint.y + rect.size.height - cornerLength))
        cornerPath.addLine(to: CGPoint(x: originPoint.x + rect.size.width,
                                       y: originPoint.y + rect.size.height))
        cornerPath.addLine(to: CGPoint(x: originPoint.x + rect.size.width - cornerLength,
                                       y: originPoint.y + rect.size.height))

        cornerLayer.path = cornerPath.cgPath
        cornerLayer.lineWidth = 3
        cornerLayer.ud.setStrokeColor(UIColor.ud.colorfulBlue)
        cornerLayer.ud.setFillColor(UIColor.clear)
    }

    fileprivate func addScanAnimation(rect: CGRect) {
        scanningLayer.ud.setBackgroundColor(UIColor.clear)
        scanningLayer.frame = rect

        let image = Resources.scanning
        scanningImgLayer.contents = image.cgImage
        scanningImgLayer.bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        scanningImgLayer.position = CGPoint(x: (rect.size.width-image.size.width)/2, y: -image.size.height)
        scanningImgLayer.anchorPoint = CGPoint(x: 0, y: 0)

        let totalDuration = 3.2
        let fadingDuation = 0.25
        animation.keyPath = "position.y"
        animation.toValue = rect.size.height-image.size.height
        animation.duration = totalDuration

        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0
        fadeIn.toValue = 1
        fadeIn.duration = fadingDuation
        fadeIn.beginTime = 0

        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1
        fadeOut.toValue = 0
        fadeOut.duration = fadingDuation
        fadeOut.beginTime = totalDuration-fadingDuation

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [fadeIn, animation, fadeOut]
        animationGroup.duration = totalDuration
        animationGroup.isRemovedOnCompletion = false
        animationGroup.repeatCount = Float.infinity

        scanningImgLayer.add(animationGroup, forKey: "ScanAnimation")
    }

    func pauseScan() {
        CodeScanTool.execInMainThread {
            self.pauseAnimation(layer: self.scanningImgLayer)
        }
    }

    func resumeScan() {
        CodeScanTool.execInMainThread {
            self.resumeAnimation(layer: self.scanningImgLayer)
        }
    }

    private func pauseAnimation(layer: CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }

    private func resumeAnimation(layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
