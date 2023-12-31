//
//  Cursor.swift
//  LKRichView
//
//  Created by qihongye on 2021/9/1.
//

import UIKit
import Foundation

/// Basic select locaition defination.
///
/// This data structure is designed for `SelectionRange`.
public struct SelectionLocation {
    public weak var anchorNode: RenderObject?
    public let lineNo: CFIndex
    public let location: CFIndex
    public let length: UInt
    public var point: CGPoint
}

public enum CursorType {
    case start
    case end
}

public protocol Cursor: AnyObject {
    var type: CursorType { get }
    var location: SelectionLocation { get set }
    var rect: CGRect { get set }
    var center: CGPoint { get }
    var renderLayer: CALayer { get }
    var fillColor: UIColor { get set }
    /// 开始/结束光标热区扩大
    var hitTestInsects: UIEdgeInsets { get set }

    func hitTest(_ point: CGPoint, with event: UIEvent?) -> Bool

    func updateRenderLayer()
}

open class SelectionCursor: Cursor {
    public let type: CursorType

    public var location: SelectionLocation

    public var rect: CGRect = .zero {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            updateRenderLayer()
            CATransaction.commit()
        }
    }

    public var center: CGPoint {
        return CGPoint(x: rect.centerX, y: rect.centerY)
    }

    public var fillColor: UIColor = UIColor.blue

    public var pointRadius: CGFloat = 4

    public var lineWidth: CGFloat = 2

    public var hitTestInsects: UIEdgeInsets = .zero

    private var _layer: CAShapeLayer
    public var renderLayer: CALayer {
        return _layer
    }

    public init(type: CursorType) {
        self.type = type
        self.location = SelectionLocation(anchorNode: nil, lineNo: kCFNotFound, location: kCFNotFound, length: 0, point: .zero)
        _layer = CAShapeLayer()
        _layer.contentsScale = UIScreen.main.scale
        _layer.magnificationFilter = CALayerContentsFilter(rawValue: kCISamplerFilterNearest)
        _layer.allowsEdgeAntialiasing = true
    }

    public func hitTest(_ point: CGPoint, with event: UIEvent?) -> Bool {
        return rect.inset(by: hitTestInsects).contains(point) || _layer.frame.contains(point)
    }

    public func updateRenderLayer() {
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
        self._layer.fillColor = fillColor.cgColor
        self._layer.path = path
    }
}
