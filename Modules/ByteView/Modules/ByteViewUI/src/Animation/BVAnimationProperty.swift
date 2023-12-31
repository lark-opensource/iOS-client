//
//  BVAnimationProperty.swift
//  ByteViewUI
//
//  Created by chenyizhuo on 2022/11/22.
//

import UIKit

public enum BVAnimationPropertyType {
    case none

    // -- position & size --

    case frame

    case origin
    case x
    case y

    case size
    case width
    case height

    case center
    case centerX
    case centerY

    // -- background color --

    case color
    case alpha
}

public final class BVAnimationProperty {
    let type: BVAnimationPropertyType
    var fromValue: Any?
    var toValue: Any?

    public init(type: BVAnimationPropertyType, fromValue: Any? = nil, toValue: Any? = nil) {
        self.type = type
        self.fromValue = fromValue
        self.toValue = toValue
    }

    func appliedValue(with percentage: CGFloat, inverse: Bool = false) -> Any? {
        switch type {
        case .frame:
            if let from = fromValue as? CGRect, let to = toValue as? CGRect {
                return inverse ? to.applied(percentage, to: from) : from.applied(percentage, to: to)
            }
        case .origin, .center:
            if let from = fromValue as? CGPoint, let to = toValue as? CGPoint {
                return inverse ? to.applied(percentage, to: from) : from.applied(percentage, to: to)
            }
        case .size:
            if let from = fromValue as? CGSize, let to = toValue as? CGSize {
                return inverse ? to.applied(percentage, to: from) : from.applied(percentage, to: to)
            }
        case .x, .y, .centerX, .centerY, .width, .height, .alpha:
            if let from = toFloat(fromValue), let to = toFloat(toValue) {
                return inverse ? to.applied(percentage, to: from) : from.applied(percentage, to: to)
            }
        case .color:
            if let from = fromValue as? UIColor, let to = toValue as? UIColor {
                return inverse ? to.applied(percentage, to: from) : from.applied(percentage, to: to)
            }
        case .none: break
        }
        return nil
    }

    private func toFloat(_ value: Any?) -> CGFloat? {
        if let value = value as? (any BinaryInteger) {
            return CGFloat(value)
        } else if let value = value as? (any BinaryFloatingPoint) {
            return CGFloat(value)
        } else {
            return nil
        }
    }
}

private protocol ProgressCalculatable {
    func applied(_ percentage: CGFloat, to target: Self) -> Self
}

@inline(__always) private func step(_ from: CGFloat, _ to: CGFloat, _ percentage: CGFloat) -> CGFloat {
    from + (to - from) * percentage
}

extension CGFloat: ProgressCalculatable {
    fileprivate func applied(_ percentage: CGFloat, to target: CGFloat) -> CGFloat {
        step(self, target, percentage)
    }
}

extension CGPoint: ProgressCalculatable {
    fileprivate func applied(_ percentage: CGFloat, to target: CGPoint) -> CGPoint {
        CGPoint(x: step(x, target.x, percentage), y: step(y, target.y, percentage))
    }
}

extension CGSize: ProgressCalculatable {
    fileprivate func applied(_ percentage: CGFloat, to target: CGSize) -> CGSize {
        CGSize(width: step(width, target.width, percentage), height: step(height, target.height, percentage))
    }
}

extension CGRect: ProgressCalculatable {
    fileprivate func applied(_ percentage: CGFloat, to target: CGRect) -> CGRect {
        CGRect(x: step(minX, target.minX, percentage),
               y: step(minY, target.minY, percentage),
               width: step(width, target.width, percentage),
               height: step(height, target.height, percentage))
    }
}

extension UIColor: ProgressCalculatable {
    fileprivate func applied(_ percentage: CGFloat, to target: UIColor) -> Self {
        var (r1, g1, b1, a1) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        var (r2, g2, b2, a2) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        target.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return Self.init(red: step(r1, r2, percentage),
                       green: step(g1, g2, percentage),
                       blue: step(b1, b2, percentage),
                       alpha: step(a1, a2, percentage))
    }
}
