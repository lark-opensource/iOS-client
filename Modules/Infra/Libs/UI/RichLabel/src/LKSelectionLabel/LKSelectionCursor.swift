//
//  SelectionCursor.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/19.
//

import UIKit
import Foundation
open class LKSelectionCursor {
    public enum TypeEnum {
        case start, end
    }

    public var rect: CGRect = .zero {
        didSet {
            CATransaction.begin()
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            updateLayer()
            CATransaction.commit()
        }
    }

    public let type: TypeEnum

    public var lineNo: CFIndex = kCFNotFound

    public var location: CFIndex = kCFNotFound

    public var fillColor: CGColor = UIColor.blue.cgColor

    public var pointRadius: CGFloat = 4

    public var lineWidth: CGFloat = 2

    public var hitTestInsects: UIEdgeInsets = .zero

    private var _layer: CAShapeLayer
    open var layer: CAShapeLayer {
        return _layer
    }

    public init(type: TypeEnum) {
        self.type = type
        _layer = CAShapeLayer()
        _layer.contentsScale = UIScreen.main.scale
        _layer.magnificationFilter = CALayerContentsFilter(rawValue: kCISamplerFilterNearest)
        _layer.allowsEdgeAntialiasing = true
    }

    public func hitTest(_ point: CGPoint) -> Bool {
        return rect.inset(by: hitTestInsects).contains(point) || layer.frame.contains(point)
    }

    open func updateLayer() {
        let path = CGMutablePath()
        let diameter = 2 * pointRadius
        let dHeight = floor(pow(pow(pointRadius, 2) - pow(lineWidth / 2, 2), 0.5))
        _layer.frame = CGRect(x: 0, y: 0, width: diameter, height: rect.height + dHeight + pointRadius)

        switch self.type {
        case .start:
            path.addPath(CGPath(rect: CGRect(
                x: (diameter - lineWidth) / 2,
                y: pointRadius + dHeight,
                width: lineWidth,
                height: rect.height
            ), transform: nil))
            path.addPath(UIBezierPath(
                arcCenter: CGPoint(x: pointRadius, y: pointRadius),
                radius: pointRadius,
                startAngle: 0,
                endAngle: 180,
                clockwise: true
            ).cgPath)
            self._layer.frame.origin.y = rect.maxY - self._layer.frame.height
            self._layer.frame.origin.x = rect.minX - self._layer.frame.width / 2
        case .end:
            path.addPath(CGPath(rect: CGRect(
                x: (diameter - lineWidth) / 2,
                y: 0,
                width: lineWidth,
                height: rect.height
            ), transform: nil))
            path.addPath(UIBezierPath(
                arcCenter: CGPoint(x: 4, y: rect.height + dHeight),
                radius: pointRadius,
                startAngle: 0,
                endAngle: 180,
                clockwise: true
            ).cgPath)
            self._layer.frame.origin.y = rect.minY
            self._layer.frame.origin.x = rect.maxX - self._layer.frame.width / 2
        }
        self._layer.fillColor = fillColor
        self._layer.path = path
    }
}
