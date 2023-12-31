//
//  UIBezierPath+Squircle.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/9/4.
//

import Foundation
import UIKit

// swiftlint:disable all

public extension UIBezierPath {

    /// Make a squircle berizr path with different corner radii.
    static func squircle(forRect rect: CGRect,
                         cornerRadii: CornerRadii,
                         cornerSmoothness: CornerSmoothLevel) -> UIBezierPath {
        guard rect.size != .zero else { return UIBezierPath() }
        
        return roundedRect(rect, cornerRadii: cornerRadii, keyPoints: cornerSmoothness.keyPoints)
    }

    /// Make a squircle berizr path with unified corner radii.
    static func squircle(forRect rect: CGRect,
                         cornerRadius: CGFloat,
                         roundedCorners: UIRectCorner = [.allCorners],
                         cornerSmoothness: CornerSmoothLevel = .max) -> UIBezierPath {
        guard rect.size != .zero else { return UIBezierPath() }
        
        let maxCornerRadius = min(rect.width, rect.height) / 2 / (1 + cornerSmoothness.value)
        let realCornerRadius = min(max(0, cornerRadius), maxCornerRadius)
        switch cornerSmoothness {
        case .none:
            return pathForNoneSmoothLevel(forRect: rect, cornerRadius: cornerRadius, roundedCorners: roundedCorners)
        case .natural:
            return pathForNaturalSmoothLevel(forRect: rect, cornerRadius: realCornerRadius, roundedCorners: roundedCorners)
        case .max:
            return pathForMaxSmoothLevel(forRect: rect, cornerRadius: realCornerRadius, roundedCorners: roundedCorners)
        }
    }

    private static func pathForNoneSmoothLevel(forRect bounds: CGRect,
                                               cornerRadius: CGFloat,
                                               roundedCorners: UIRectCorner) -> UIBezierPath {
        let r = cornerRadius
        let c = r * 0.4477152
        let w = bounds.width
        let h = bounds.height
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: r))
        if roundedCorners.contains(.topLeft) {
            bezierPath.addCurve(to: CGPoint(x: r, y: 0), controlPoint1: CGPoint(x: 0, y: c), controlPoint2: CGPoint(x: c, y: 0))
        } else {
            bezierPath.addLine(to: CGPoint(x: 0, y: 0))
        }
        bezierPath.addLine(to: CGPoint(x: w - r, y: 0))
        if roundedCorners.contains(.topRight) {
            bezierPath.addCurve(to: CGPoint(x: w, y: r), controlPoint1: CGPoint(x: w - c, y: 0), controlPoint2: CGPoint(x: w, y: c))
        } else {
            bezierPath.addLine(to: CGPoint(x: w, y: 0))
        }
        bezierPath.addLine(to: CGPoint(x: w, y: h - r))
        if roundedCorners.contains(.bottomRight) {
            bezierPath.addCurve(to: CGPoint(x: w - r, y: h), controlPoint1: CGPoint(x: w, y: h - c), controlPoint2: CGPoint(x: w - c, y: h))
        } else {
            bezierPath.addLine(to: CGPoint(x: w, y: h))
        }
        bezierPath.addLine(to: CGPoint(x: r, y: h))
        if roundedCorners.contains(.bottomLeft) {
            bezierPath.addCurve(to: CGPoint(x: 0, y: h - r), controlPoint1: CGPoint(x: c, y: h), controlPoint2: CGPoint(x: 0, y: h - c))
        } else {
            bezierPath.addLine(to: CGPoint(x: 0, y: h))
        }
        bezierPath.addLine(to: CGPoint(x: 0, y: r))
        bezierPath.close()
        return bezierPath
    }

    private static func pathForNaturalSmoothLevel(forRect bounds: CGRect,
                                                  cornerRadius: CGFloat,
                                                  roundedCorners: UIRectCorner) -> UIBezierPath {
        let cornerRadii = CGSize(
            width: cornerRadius,
            height: cornerRadius
        )
        return UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: roundedCorners,
            cornerRadii: cornerRadii
        )
    }

    private static func pathForMaxSmoothLevel(forRect bounds: CGRect,
                                              cornerRadius: CGFloat,
                                              roundedCorners: UIRectCorner) -> UIBezierPath {
        let r = cornerRadius
        let a = r * 0.292893218813
        let b = a * 2
        let c = r * 1.057191
        let d = r * 2

        let w = bounds.width
        let h = bounds.height
        let bezierPath = UIBezierPath()

        // start point at top left
        bezierPath.move(to: CGPoint(x: 0, y: d))
        // top left corner
        if roundedCorners.contains(.topLeft) {
            bezierPath.addCurve(to: CGPoint(x: a, y: a), controlPoint1: CGPoint(x: 0, y: c), controlPoint2: CGPoint(x: 0, y: b))
            bezierPath.addCurve(to: CGPoint(x: d, y: 0), controlPoint1: CGPoint(x: b, y: 0), controlPoint2: CGPoint(x: c, y: 0))
        } else {
            bezierPath.addLine(to: CGPoint(x: 0, y: 0))
        }
        // top line
        bezierPath.addLine(to: CGPoint(x: w - d, y: 0))
        // top right corner
        if roundedCorners.contains(.topRight) {
            bezierPath.addCurve(to: CGPoint(x: w - a, y: a), controlPoint1: CGPoint(x: w - c, y: 0), controlPoint2: CGPoint(x: w - b, y: 0))
            bezierPath.addCurve(to: CGPoint(x: w, y: d), controlPoint1: CGPoint(x: w, y: b), controlPoint2: CGPoint(x: w, y: c))
        } else {
            bezierPath.addLine(to: CGPoint(x: w, y: 0))
        }
        // right line
        bezierPath.addLine(to: CGPoint(x: w, y: h - d))
        // bottom right corner
        if roundedCorners.contains(.bottomRight) {
            bezierPath.addCurve(to: CGPoint(x: w - a, y: h - a), controlPoint1: CGPoint(x: w, y: h - c), controlPoint2: CGPoint(x: w, y: h - b))
            bezierPath.addCurve(to: CGPoint(x: w - d, y: h), controlPoint1: CGPoint(x: w - b, y: h), controlPoint2: CGPoint(x: w - c, y: h))
        } else {
            bezierPath.addLine(to: CGPoint(x: w, y: h))
        }
        // bottom line
        bezierPath.addLine(to: CGPoint(x: d, y: h))
        // bottom left corner
        if roundedCorners.contains(.bottomLeft) {
            bezierPath.addCurve(to: CGPoint(x: a, y: h - a), controlPoint1: CGPoint(x: c, y: h), controlPoint2: CGPoint(x: b, y: h))
            bezierPath.addCurve(to: CGPoint(x: 0, y: h - d), controlPoint1: CGPoint(x: 0, y: h - b), controlPoint2: CGPoint(x: 0, y: h - c))
        } else {
            bezierPath.addLine(to: CGPoint(x: 0, y: h))
        }
        // left line
        bezierPath.addLine(to: CGPoint(x: 0, y: d))
        // back to start point
        bezierPath.close()
        return bezierPath
    }

    /// 生成圆角矩形 Path 的通用方法
    private static func roundedRect(_ rect: CGRect, cornerRadii: CornerRadii, keyPoints: SquircleKeyPoints) -> UIBezierPath {

        let P0 = keyPoints.p0
        let P1 = keyPoints.p1
        let C0 = keyPoints.c0
        let C1 = keyPoints.c1
        let C2 = keyPoints.c2

        let r1 = cornerRadii.topLeft
        let r2 = cornerRadii.topRight
        let r3 = cornerRadii.bottomRight
        let r4 = cornerRadii.bottomLeft

        let w = rect.width
        let h = rect.height

        let bezierPath = UIBezierPath()
        // top left corner
        bezierPath.move(to: CGPoint(x: P0.y * r1, y: P0.x * r1))
        bezierPath.addCurve(to: CGPoint(x: P1.y * r1, y: P1.x * r1),
                            controlPoint1: CGPoint(x: C0.y * r1, y: C0.x * r1),
                            controlPoint2:CGPoint(x: C1.y * r1, y: C1.x * r1))
        bezierPath.addCurve(to: CGPoint(x: P1.x * r1, y: P1.y * r1),
                            controlPoint1: CGPoint(x: C2.y * r1, y: C2.x * r1),
                            controlPoint2: CGPoint(x: C2.x * r1, y: C2.y * r1))
        bezierPath.addCurve(to: CGPoint(x: P0.x * r1, y: P0.y * r1),
                            controlPoint1: CGPoint(x: C1.x * r1, y: C1.y * r1),
                            controlPoint2: CGPoint(x: C0.x * r1, y: C0.y * r1))
        // top line
        bezierPath.addLine(to: CGPoint(x: (w - P0.x * r2), y: P0.y * r2))
        // top right corner
        bezierPath.addCurve(to: CGPoint(x: (w - P1.x * r2), y: P1.y * r2),
                            controlPoint1: CGPoint(x: (w - C0.x * r2), y: C0.y * r2),
                            controlPoint2:CGPoint(x: (w - C1.x * r2), y: C1.y * r2))
        bezierPath.addCurve(to: CGPoint(x: (w - P1.y * r2), y: P1.x * r2),
                            controlPoint1: CGPoint(x: (w - C2.x * r2), y: C2.y * r2),
                            controlPoint2: CGPoint(x: (w - C2.y * r2), y: C2.x * r2))
        bezierPath.addCurve(to: CGPoint(x: w, y: P0.x * r2),
                            controlPoint1: CGPoint(x: w, y: C1.x * r2),
                            controlPoint2: CGPoint(x: w, y: C0.x * r2))
        // right line
        bezierPath.addLine(to: CGPoint(x: w, y: (h - P0.x * r3)))
        // bottom right corner
        bezierPath.addCurve(to: CGPoint(x: (w - P1.y * r3), y: (h - P1.x * r3)),
                            controlPoint1: CGPoint(x: w, y: (h - C0.x * r3)),
                            controlPoint2: CGPoint(x: w, y: (h - C1.x * r3)))
        bezierPath.addCurve(to: CGPoint(x: (w - P1.x * r3), y: (h - P1.y * r3)),
                            controlPoint1: CGPoint(x: (w - C2.y * r3), y: (h - C2.x * r3)),
                            controlPoint2: CGPoint(x: (w - C2.x * r3), y: (h - C2.y * r3)))
        bezierPath.addCurve(to: CGPoint(x: (w - P0.x * r3), y: h),
                            controlPoint1: CGPoint(x: (w - C1.x * r3), y: h),
                            controlPoint2: CGPoint(x: (w - C0.x * r3), y: h))
        // bottom line
        bezierPath.addLine(to: CGPoint(x: P0.x * r4, y: h))
        // bottom left corner
        bezierPath.addCurve(to: CGPoint(x: P1.x * r4, y: (h - P1.y * r4)),
                            controlPoint1: CGPoint(x: C0.x * r4, y: h),
                            controlPoint2: CGPoint(x: C1.x * r4, y: h))
        bezierPath.addCurve(to: CGPoint(x: P1.y * r4, y: (h - P1.x * r4)),
                            controlPoint1: CGPoint(x: C2.x * r4, y: (h - C2.y * r4)),
                            controlPoint2: CGPoint(x: C2.y * r4, y: (h - C2.x * r4)))
        bezierPath.addCurve(to: CGPoint(x: P0.y * r4, y: (h - P0.x * r4)),
                            controlPoint1: CGPoint(x: C1.y * r4, y: (h - C1.x * r4)),
                            controlPoint2: CGPoint(x: C0.y * r4, y: (h - C0.x * r4)))
        // left line
        bezierPath.addLine(to: CGPoint(x: 0, y: P0.x * r1))
        bezierPath.close()

        return bezierPath
    }
}

private struct SquircleKeyPoints {
    var p0: CGPoint
    var p1: CGPoint
    var c0: CGPoint
    var c1: CGPoint
    var c2: CGPoint

    static var s0 = SquircleKeyPoints(
        p0: CGPoint(x: 1.6, y: 0),
        p1: CGPoint(x: 0.5460095, y: 0.1089935),
        c0: CGPoint(x: 1.0399475, y: 0),
        c1: CGPoint(x: 0.7599212, y: 0),
        c2: CGPoint(x: 0.3578474, y: 0.2048669)
    )

    static var s60 = SquircleKeyPoints(
        p0: CGPoint(x: 1.6, y: 0),
        p1: CGPoint(x: 0.5460095, y: 0.1089935),
        c0: CGPoint(x: 1.0399475, y: 0),
        c1: CGPoint(x: 0.7599212, y: 0),
        c2: CGPoint(x: 0.3578474, y: 0.2048669)
    )

    static var s100 = SquircleKeyPoints(
        p0: CGPoint(x: 2.0, y: 0),
        p1: CGPoint(x: 0.5460095, y: 0.1089935),
        c0: CGPoint(x: 1.0399475, y: 0),
        c1: CGPoint(x: 0.7599212, y: 0),
        c2: CGPoint(x: 0.3578474, y: 0.2048669)
    )
}

private extension CornerSmoothLevel {

    var keyPoints: SquircleKeyPoints {
        switch self {
        case .none:
            // P0 = P1, C0 = P1, C1 = P1
            return SquircleKeyPoints(
                p0: CGPoint(x: 1.0, y: 0),
                p1: CGPoint(x: 1.0, y: 0),
                c0: CGPoint(x: 1.0, y: 0),
                c1: CGPoint(x: 1.0, y: 0),
                c2: CGPoint(x: 0.4477153, y: 0)
            )
        case .natural:
            return SquircleKeyPoints(
                p0: CGPoint(x: 1.6, y: 0),
                p1: CGPoint(x: 0.5460095, y: 0.1089935),
                c0: CGPoint(x: 1.0399475, y: 0),
                c1: CGPoint(x: 0.7599212, y: 0),
                c2: CGPoint(x: 0.3578474, y: 0.2048669)
            )
        case .max:
            // C2 = P1
            return SquircleKeyPoints(
                p0: CGPoint(x: 2.0, y: 0),
                p1: CGPoint(x: 0.2928932, y: 0.2928932),
                c0: CGPoint(x: 1.0571909, y: 0),
                c1: CGPoint(x: 0.5857864, y: 0),
                c2: CGPoint(x: 0.2928932, y: 0.2928932)
            )
        }
    }
}

// swiftlint:enable all
