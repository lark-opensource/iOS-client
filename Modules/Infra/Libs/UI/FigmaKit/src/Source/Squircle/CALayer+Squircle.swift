//
//  CALayer+Squircle.swift
//  Social
//
//  Created by Hayden on 2020/5/13.
//  Copyright © 2020 shengsheng. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

private extension CALayer {

    func setSmoothCorner(radius: CGFloat = .greatestFiniteMagnitude,
                         corners: UIRectCorner = [.allCorners],
                         smoothness: CornerSmoothLevel = .max) {
        if canAchieveSmoothCornerBySystemAPI(radius: radius, smoothness: smoothness) {
            cornerRadius = radius
            maskedCorners = translateRectCornerIntoCornerMask(corners)
            if #available(iOS 13.0, *) {
                cornerCurve = smoothness == .none ? .circular : .continuous
            }
        } else {
            setMask(by: { bounds in
                UIBezierPath.squircle(
                    forRect: bounds,
                    cornerRadius: radius,
                    roundedCorners: corners,
                    cornerSmoothness: smoothness
                )
            })
        }
    }

    private func translateRectCornerIntoCornerMask(_ corners: UIRectCorner) -> CACornerMask {
        var maskedCorners: CACornerMask = []
        if corners.contains(.topLeft) {
            maskedCorners.insert(.layerMinXMinYCorner)
        }
        if corners.contains(.topRight) {
            maskedCorners.insert(.layerMaxXMinYCorner)
        }
        if corners.contains(.bottomLeft) {
            maskedCorners.insert(.layerMinXMaxYCorner)
        }
        if corners.contains(.bottomRight) {
            maskedCorners.insert(.layerMaxXMaxYCorner)
        }
        return maskedCorners
    }

    private func canAchieveSmoothCornerBySystemAPI(radius: CGFloat, smoothness: CornerSmoothLevel) -> Bool {
        switch smoothness {
        case .none, .natural:
            if #available(iOS 13, *) {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }

    func setSmoothBorder(width: CGFloat, color: UIColor) {
        guard mask != nil else {
            borderWidth = width
            borderColor = color.cgColor
            return
        }
        if propertyObserver == nil {
            propertyObserver = LayerObserver()
            propertyObserver?.layer = self
        }
        let setterCallback = { [weak self] in
            guard let self = self else { return }
            guard let maskLayer = self.mask as? CAShapeLayer else { return }
            self.removeSmoothBorder()
            let borderLayer = CAShapeLayer()
            borderLayer.name = CALayer.smoothBorderName
            borderLayer.path = maskLayer.path
            borderLayer.lineWidth = width * 2
            borderLayer.strokeColor = color.cgColor
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.frame = self.bounds
            self.addSublayer(borderLayer)
        }
        setterCallback()
        propertyObserver?.onFrameChange["border"] = (1, setterCallback)
    }

    func removeSmoothCorner() {
        guard mask != nil else {
            cornerRadius = 0
            return
        }
        removeMask()
    }

    func removeSmoothBorder() {
        guard mask != nil else {
            borderWidth = 0
            return
        }
        self.sublayers?
            .filter { $0.name == CALayer.smoothBorderName }
            .forEach { $0.removeFromSuperlayer() }
    }

    private static let smoothBorderName = "squircleBorder"

    func setMask(by bezierPath: UIBezierPath) {
        guard !bezierPath.isEmpty else { return }

        let maskLayer = CAShapeLayer()
        maskLayer.path = bezierPath.cgPath
        self.mask = maskLayer
        self.shadowPath = maskLayer.path
    }

    func setMask(by pathMaker: @escaping (CGRect) -> UIBezierPath) {
        if propertyObserver == nil {
            propertyObserver = LayerObserver()
            propertyObserver?.layer = self
        }
        let setterCallback = { [weak self] in
            guard let self = self else { return }
            guard self.bounds != .zero else { return }

            let maskLayer = CAShapeLayer()
            maskLayer.path = pathMaker(self.bounds).cgPath
            self.mask = maskLayer
            self.shadowPath = maskLayer.path
        }
        setterCallback()
        propertyObserver?.onFrameChange["mask"] = (0, setterCallback)
    }

    func removeMask() {
        removeSmoothBorder()
        self.mask?.removeFromSuperlayer()
    }
}

public extension UXExtension where BaseType: CALayer {

    /// Set a bounding mask by customized berize path.
    func setMask(by bezierPath: UIBezierPath) {
        base.setMask(by: bezierPath)
    }

    /// Set a bounding mask by customized berize path.
    func setMask(by pathMaker: @escaping (CGRect) -> UIBezierPath) {
        base.setMask(by: pathMaker)
    }

    /// Remove customized bounding mask.
    func removeMask() {
        base.removeMask()
    }

    /// Set rounded corner mask.
    func setSmoothCorner(radius: CGFloat,
                         corners: UIRectCorner = [.allCorners],
                         smoothness: CornerSmoothLevel = .max) {
        base.setSmoothCorner(radius: radius, corners: corners, smoothness: smoothness)
    }

    /// Remove rounded corner mask.
    func removeSmoothCorner() {
        base.removeSmoothCorner()
    }

    /// Set border according to rounded corner mask.
    func setSmoothBorder(width: CGFloat, color: UIColor) {
        base.setSmoothBorder(width: width, color: color)
    }

    /// Remove rounded corner border.
    func removeSmoothBorder() {
        base.removeSmoothBorder()
    }
}
