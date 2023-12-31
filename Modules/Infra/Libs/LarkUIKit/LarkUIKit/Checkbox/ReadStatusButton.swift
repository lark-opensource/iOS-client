//
//  ReadStatusButton.swift
//  LarkUIKit
//
//  Created by 刘晚林 on 2017/8/9.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

open class ReadStatusButton: UIButton {
    fileprivate var animationManager: AnimationManager!
    fileprivate var pathManager: PathManager!

    public var animationDuration: CGFloat = 0.5 {
        didSet {
            self.animationManager.animationDuration = animationDuration
        }
    }

    fileprivate(set) var percent: CGFloat = 0

    public var lineWidth: CGFloat = 2 {
        didSet {
            self.pathManager.lineWidth = self.lineWidth
            self.reload()
        }
    }

    public var defaultColor: UIColor = UIColor.ud.N400 {
        didSet {
            self.reload()
        }
    }

    public var trackColor: UIColor = UIColor.ud.colorfulOrange {
        didSet {
            self.reload()
        }
    }

    fileprivate var boxLayer: CAShapeLayer?
    fileprivate var sectorLayer: CAShapeLayer?
    fileprivate var checkMarkLayer: CAShapeLayer?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    public override func layoutSubviews() {
        self.pathManager.size = self.frame.height
        super.layoutSubviews()
    }

    public override func draw(_ rect: CGRect) {
        self.update(percent: percent)
    }

    public func update(percent: CGFloat) {
        if percent.isNaN || percent < 0 {
            return
        }
        self.percent = percent
        self.drawEntireBox()
    }
}

private extension ReadStatusButton {
    func commonInit() {
        self.backgroundColor = UIColor.clear

        self.initPathManager()
        self.initAnimationManager()
    }

    func initPathManager() {
        self.pathManager = PathManager()
        self.pathManager.lineWidth = self.lineWidth
        self.pathManager.boxType = .circle
    }

    func initAnimationManager() {
        self.animationManager = AnimationManager(animationDuration: self.animationDuration)
    }

    func drawEntireBox() {
        self.drawBox()
        self.drawSector()
        self.drawCheckMark()
    }

    func drawLineLayer(path: UIBezierPath, strokeColor: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()

        layer.frame = self.bounds
        layer.path = path.cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = strokeColor.cgColor
        layer.lineWidth = self.lineWidth

        layer.lineCap = .round
        layer.lineJoin = .round

        return layer
    }

    func drawSectorLayer(path: UIBezierPath, strokeColor: UIColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.frame = self.bounds
        layer.path = path.cgPath
        layer.fillColor = strokeColor.cgColor

        return layer
    }

    func drawBox() {
        self.boxLayer?.removeFromSuperlayer()

        let boxColor = percent <= 0 ? defaultColor : trackColor
        self.boxLayer = drawLineLayer(
            path: pathManager.pathForBox(),
            strokeColor: boxColor
        )

        self.layer.addSublayer(self.boxLayer!)
    }

    func drawSector() {
        self.sectorLayer?.removeFromSuperlayer()
        if percent == 1 || percent == 0 { return }
        let sectorColor = trackColor
        self.sectorLayer = drawSectorLayer(
            path: pathManager.pathForSector(percent: percent, fillColor: sectorColor),
            strokeColor: sectorColor
        )

        self.layer.addSublayer(self.sectorLayer!)
    }

    func drawCheckMark() {
        self.checkMarkLayer?.removeFromSuperlayer()
        if percent != 1 { return }
        let strokeColor = trackColor
        self.checkMarkLayer = drawLineLayer(
            path: pathManager.pathForCheckMark(),
            strokeColor: strokeColor
        )

        self.layer.addSublayer(self.checkMarkLayer!)
    }

    func reload() {
        self.checkMarkLayer?.removeFromSuperlayer()
        self.checkMarkLayer = nil

        self.sectorLayer?.removeFromSuperlayer()
        self.sectorLayer = nil

        self.boxLayer?.removeFromSuperlayer()
        self.boxLayer = nil

        self.setNeedsDisplay()
    }
}

extension PathManager {
    func pathForSector(percent: CGFloat, fillColor: UIColor) -> UIBezierPath {
        let radius = self.size / 2.0
        let path = UIBezierPath(
            arcCenter: CGPoint(x: radius, y: radius),
            radius: radius * 0.7 - lineWidth / 2.0,
            startAngle: -CGFloat.pi / 2,
            endAngle: 2 * CGFloat.pi * percent - CGFloat.pi / 2,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: radius, y: radius))
        fillColor.setFill()
        return path
    }
}
