//
//  Gradientable.swift
//  FigmaKit
//
//  Created by Hayden on 2020/4/22.
//

import Foundation
import UIKit

// disable-lint: magic number

public protocol Gradientable: UIView {
    var type: GradientType { get set }
    var colors: [UIColor] { get set }
    var direction: GradientDirection { get set }
    var locations: [NSNumber]? { get set }
}

public struct GradientPattern {
    public var type: GradientType
    public var colors: [UIColor]
    public var direction: GradientDirection
    public var locations: [NSNumber]?

    public init(direction: GradientDirection, colors: [UIColor], type: GradientType = .linear, locations: [NSNumber]? = nil) {
        self.type = type
        self.colors = colors
        self.direction = direction
        self.locations = locations
    }

    public static var clear: GradientPattern {
        GradientPattern(direction: .leftToRight, colors: [])
    }

    public func toColor(withSize size: CGSize) -> UIColor? {
        UIColor.fromGradientWithType(type,
                                     direction: direction,
                                     frame: CGRect(origin: .zero, size: size),
                                     colors: colors,
                                     locations: locations)
    }
}

public enum GradientType {
    case linear, angular, radial

    func toSystemType() -> CAGradientLayerType {
        switch self {
        case .linear:
            return .axial
        case .angular:
            if #available(iOS 12.0, *) {
                return .conic
            } else {
                return .axial
            }
        case .radial:
            return .radial
        }
    }
}

public enum GradientDirection {

    /// 从上到下渐变
    case topToBottom
    /// 从下到上渐变
    case bottomToTop
    /// 从左到右渐变
    case leftToRight
    /// 从右到左渐变
    case rightToLeft
    /// 从左下到右上对角渐变
    case diagonal45
    /// 从左上到右下对角渐变
    case diagonal135
    /// 以给定的角度渐变，数值范围 `[0, 360]`
    case angleInDegree(CGFloat)
    /// 以给定的弧度渐变，数值范围 `[0, 2*pi]`
    case angleInRedian(CGFloat)

    var angle: CGFloat {
        switch self {
        case .bottomToTop:          return 0
        case .diagonal45:           return 45
        case .leftToRight:          return 90
        case .diagonal135:          return 135
        case .topToBottom:          return 180
        case .rightToLeft:          return 270
        case .angleInDegree(let d): return clippedAngle(d)
        case .angleInRedian(let r): return clippedAngle(rad2Deg(r))
        }
    }

    private func clippedAngle(_ angle: CGFloat) -> CGFloat {
        var clippedAngle = angle
        while clippedAngle < 0 { clippedAngle += 360 }
        while clippedAngle >= 360 { clippedAngle -= 360 }
        return clippedAngle
    }

    private func rad2Deg(_ radian: CGFloat) -> CGFloat {
        return radian * 180 / .pi
    }

    var needsFixAngle: Bool {
        switch self {
        case .diagonal45, .diagonal135:
            return true
        default:
            return false
        }
    }

    var startAndEndPointForLinear: (CGPoint, CGPoint) {
        return getStartAndEndPoint(forAngle: angle)
    }

    var startAndEndPointForAngular: (CGPoint, CGPoint) {
        return (
            CGPoint(x: 0.5, y: 0.5),
            getStartAndEndPoint(forAngle: angle).1
        )
    }

    var startAndEndPointForRadial: (CGPoint, CGPoint) {
        return (
            CGPoint(x: 0.5, y: 0.5),
            CGPoint(x: 1.0, y: 1.0)
        )
    }

    private func getStartAndEndPoint(forAngle angle: CGFloat) -> (CGPoint, CGPoint) {
        let radian = angle / 180 * .pi
        // Set default points for angle of 0°
        var startPointX: CGFloat = 0.5
        var startPointY: CGFloat = 1.0
        switch angle {
        case 0..<45, 315..<360:
            startPointX = 0.5 - CGFloat(tan(radian) * 0.5).roundedTo(2)
            startPointY = 1.0
        case 45..<135:
            startPointX = 0.0
            startPointY = 0.5 + CGFloat(tan(.pi / 2 - radian) * 0.5).roundedTo(2)
        case 135..<225:
            startPointX = 0.5 - CGFloat(tan(.pi - radian) * 0.5).roundedTo(2)
            startPointY = 0.0
        case 225..<315:
            startPointX = 1.0
            startPointY = 0.5 - CGFloat(tan(.pi * 3 / 2 - radian) * 0.5).roundedTo(2)
        default:
            break
        }
        let startPoint = CGPoint(x: startPointX, y: startPointY)
        let endPoint = CGPoint(x: 1 - startPointX, y: 1 - startPointY)
        return (startPoint, endPoint)
    }
}

fileprivate extension CGFloat {

    func roundedTo(_ decimals: Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(decimals))
        return (self * divisor).rounded() / divisor
    }
}

// enable-lint: magic number
