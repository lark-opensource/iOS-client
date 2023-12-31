//
//  SquircleView.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/9/1.
//

import Foundation
import UIKit
import QuartzCore

open class SquircleView: UIView {

    open var cornerRadius: CGFloat = 0 {
        didSet {
            updateMaskPath()
            updateBorderPath()
        }
    }

    open var cornerSmoothness: CornerSmoothLevel = .max {
        didSet {
            updateMaskPath()
            updateBorderPath()
        }
    }

    open var roundedCorners: UIRectCorner = [.allCorners] {
        didSet {
            updateMaskPath()
            updateBorderPath()
        }
    }

    open var borderWidth: CGFloat = 0 {
        didSet {
            updateBorderPath()
        }
    }

    open var borderColor: UIColor = .black {
        didSet {
            updateBorderPath()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        layer.mask = shapeLayer
    }

    private let shapeLayer = CAShapeLayer()
    private var borderLayer: CAShapeLayer?
    private var maskPath = UIBezierPath().cgPath

    override open func layoutSubviews() {
        super.layoutSubviews()
        updateMaskPath()
        updateBorderPath()
    }

    private func updateMaskPath() {
        let newPath = UIBezierPath.squircle(
            forRect: bounds,
            cornerRadius: cornerRadius,
            roundedCorners: roundedCorners,
            cornerSmoothness: cornerSmoothness
        ).cgPath
        self.maskPath = newPath
        if let foundAnimation = layer.findAnimation(forKeyPath: "bounds.size") {
            let animation = CABasicAnimation(keyPath: "path")
            animation.duration = foundAnimation.duration
            animation.timingFunction = foundAnimation.timingFunction
            animation.fromValue = shapeLayer.path
            animation.toValue = newPath
            shapeLayer.add(animation, forKey: "path")
            shapeLayer.path = newPath
        } else {
            shapeLayer.path = newPath
        }
    }

    private func updateBorderPath() {
        var borderLayer: CAShapeLayer
        if let currentLayer = self.borderLayer {
            borderLayer = currentLayer
        } else {
            borderLayer = CAShapeLayer()
            layer.addSublayer(borderLayer)
            self.borderLayer = borderLayer
        }
        borderLayer.frame = bounds
        borderLayer.name = "squircleBorderName"
        borderLayer.path = maskPath
        borderLayer.lineWidth = borderWidth * 2
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
    }
}

fileprivate extension CALayer {

    func findAnimation(forKeyPath keyPath: String) -> CABasicAnimation? {
        return animationKeys()?
            .compactMap({ animation(forKey: $0) as? CABasicAnimation })
            .first(where: { $0.keyPath == keyPath })
    }
}
