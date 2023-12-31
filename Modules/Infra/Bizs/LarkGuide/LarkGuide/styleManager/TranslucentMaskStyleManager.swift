//
//  TranslucentMaskStyleManager.swift
//  LarkChat
//
//  Created by sniper on 2018/11/20.
//

import Foundation
import UIKit

final class TranslucentMaskStyleManager: MaskStyleManager {

    weak var maskView: MaskView?

    private lazy var maskLayer: CALayer = {
        return self.createSublayer()
    }()

    private var cutoutMaskLayer = CAShapeLayer()
    private var fullMaskLayer = CAShapeLayer()

    private let color: UIColor

    init(color: UIColor) {
        self.color = color
    }

    private func createSublayer() -> CALayer {
        let layer = CALayer()
        //        layer.name = maskView.sublayerName
        return layer
    }

    func showOverlay(_ show: Bool, withDuration duration: TimeInterval, completion: ((Bool) -> Void)?) {

        guard let maskView = maskView else { return }

        maskView.isHidden = false
        maskView.alpha = show ? 0.0 : maskView.alpha
        maskView.backgroundColor = .clear
        maskView.holder.backgroundColor = color

        if !show { self.maskLayer.removeFromSuperlayer() }

        UIView.animate(withDuration: 0.2, animations: {
            maskView.alpha = show ? 1.0 : 0.0
        }, completion: { success in
            if show {
                self.maskLayer.removeFromSuperlayer()
                self.maskLayer.frame = maskView.bounds
                self.maskLayer.backgroundColor = self.color.cgColor
                maskView.holder.layer.addSublayer(self.maskLayer)
                maskView.holder.backgroundColor = UIColor.clear
            } else {
                self.maskLayer.removeFromSuperlayer()
            }
            completion?(success)
        })
    }

    func showCutout(_ show: Bool, withDuration duration: TimeInterval,
                    completion: ((Bool) -> Void)?) {

        if show { updateCutoutPath() }

        CATransaction.begin()

        fullMaskLayer.opacity = show ? 0.0 : 1.0

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = show ? 1.0 : 0.0
        animation.toValue = show ? 0.0 : 1.0
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.isRemovedOnCompletion = true

        CATransaction.setCompletionBlock {
            completion?(true)
        }

        fullMaskLayer.add(animation, forKey: "opacityAnimationFade")

        CATransaction.commit()
    }

    // MARK: Private methods
    private func updateCutoutPath() {
        cutoutMaskLayer.removeFromSuperlayer()
        fullMaskLayer.removeFromSuperlayer()

        guard let cutoutPath = maskView?.cutoutPath else {
            maskLayer.mask = nil
            return
        }

        configureCutoutMask(usingCutoutPath: cutoutPath)
        configureFullMask()

        let tempMaskLayer = CALayer()
        tempMaskLayer.frame = maskLayer.bounds
        tempMaskLayer.addSublayer(self.cutoutMaskLayer)
        tempMaskLayer.addSublayer(self.fullMaskLayer)

        maskLayer.mask = tempMaskLayer
    }

    private func configureCutoutMask(usingCutoutPath cutoutPath: UIBezierPath) {
        cutoutMaskLayer = CAShapeLayer()
        cutoutMaskLayer.name = "cutoutMaskLayer"
        cutoutMaskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        cutoutMaskLayer.frame = maskLayer.frame

        let cutoutMaskLayerPath = UIBezierPath()
        cutoutMaskLayerPath.append(UIBezierPath(rect: maskLayer.bounds))
        cutoutMaskLayerPath.append(cutoutPath)

        cutoutMaskLayer.path = cutoutMaskLayerPath.cgPath
    }

    private func configureFullMask() {
        fullMaskLayer = CAShapeLayer()
        fullMaskLayer.name = "fullMaskLayer"
        fullMaskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fullMaskLayer.frame = maskLayer.frame
        fullMaskLayer.opacity = 1.0

        let fullMaskLayerPath = UIBezierPath()
        fullMaskLayerPath.append(UIBezierPath(rect: maskLayer.bounds))

        fullMaskLayer.path = fullMaskLayerPath.cgPath
    }
}
