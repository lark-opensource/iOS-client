//
//  SketchShape+Path.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/9.
//

import Foundation
import CoreGraphics

extension OvalDrawable {
    var path: CGPath {
        return CGPath(ellipseIn: frame, transform: nil)
    }
}

extension RectangleDrawable {
    var path: CGPath {
        return CGPath(rect: self.frame, transform: nil)
    }
}

extension ArrowDrawable {
    var path: CGPath {

        let path = CGMutablePath()

        let smallEnd: CGFloat = style.size
        let bigEnd: CGFloat = style.size * 3
        let arrowSize: CGFloat = style.size * 7

        let dx = end.x - start.x
        let dy = end.y - start.y
        let len = sqrt(dx * dx + dy * dy)

        if len < 1E-3 {
            return path
        }

        let udx = dx / len
        let udy = dy / len

        let ndx = -udy
        let ndy = udx

        let pt0 = CGPoint(x: end.x - udx * arrowSize + ndx * arrowSize * 0.5,
                          y: end.y - udy * arrowSize + ndy * arrowSize * 0.5)
        let pt1 = CGPoint(x: end.x - udx * arrowSize - ndx * arrowSize * 0.5,
                          y: end.y - udy * arrowSize - ndy * arrowSize * 0.5)

        let pt2 = CGPoint(x: pt0.x - ndx * (arrowSize - bigEnd) * 0.5,
                          y: pt0.y - ndy * (arrowSize - bigEnd) * 0.5)
        let pt3 = CGPoint(x: pt1.x + ndx * (arrowSize - bigEnd) * 0.5,
                          y: pt1.y + ndy * (arrowSize - bigEnd) * 0.5)

        let pt4 = CGPoint(x: start.x + ndx * smallEnd * 0.5,
                          y: start.y + ndy * smallEnd * 0.5)

        path.move(to: end)
        path.addLine(to: pt0)
        path.addLine(to: pt2)

        if len > arrowSize {
            path.addLine(to: pt4)

            var startAngle: CGFloat = atan(ndy / ndx)
            if startAngle < 0 {
                startAngle += .pi
            }
            if ndy < 0 {
                startAngle += .pi
            }

            path.addRelativeArc(center: start,
                                radius: smallEnd * 0.5,
                                startAngle: startAngle,
                                delta: .pi)
        }
        path.addLine(to: pt3)
        path.addLine(to: pt1)
        path.closeSubpath()
        return path
    }
}

extension PencilPathDrawable {
    var path: CGPath {
        let path = CGMutablePath()
        if points.isEmpty {
            return path
        }
        path.move(to: points[0])
        switch dimension {
        case .linear:
            for pt in points.dropFirst() {
                path.addLine(to: pt)
            }
        case .quadratic:
            for idx in stride(from: 1, to: points.endIndex - 1, by: 2) {
                path.addQuadCurve(to: points[idx + 1], control: points[idx])
            }
        case .cubic:
            for idx in stride(from: 1, to: points.endIndex - 2, by: 3) {
                path.addCurve(to: points[idx + 2],
                              control1: points[idx],
                              control2: points[idx + 1])
            }
        }
        return path
    }
}
