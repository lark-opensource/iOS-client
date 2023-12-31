//
//  WhiteboardShape+Path.swift
//  ByteView
//
//  Created by 阮明哲 on 2022/3/25.
//

import Foundation
import CoreGraphics
import WbLib

extension Path {
    func makeCGPath(_ id: ShapeID, path: CGMutablePath? = nil) -> CGMutablePath {
        let cgpath = path ?? CGMutablePath()
        let points = points.map { CGPoint(x: $0.x, y: $0.y) }
        let actions = actions
        if points.isEmpty {
            return cgpath
        }
        var index: Int = 0
        for action in actions {
            switch action {
            case .MoveTo:
                guard index < points.count else {
                    logger.info("MoveTo Error id:\(id), path:\(self)")
                    assertionFailure("MoveTo Error")
                    return cgpath
                }
                cgpath.move(to: points[index])
                index += 1
            case .LineTo:
                guard index < points.count else {
                    logger.info("LineTo Error id:\(id), path:\(self)")
                    assertionFailure("LineTo Error")
                    return cgpath
                }
                cgpath.addLine(to: points[index])
                index += 1
            case .QuadTo:
                guard index + 1 < points.count else {
                    logger.info("QuadTo Error id:\(id), path:\(self)")
                    assertionFailure("QuadTo Error")
                    return cgpath
                }
                cgpath.addQuadCurve(to: points[index + 1], control: points[index])
                index += 2
            case .CubicTo:
                guard index + 2 < points.count else {
                    logger.info("CubicTo Error id:\(id), path:\(self)")
                    assertionFailure("CubicTo Error")
                    return cgpath
                }
                cgpath.addCurve(to: points[index + 2], control1: points[index], control2: points[index + 1])
                index += 3
            case .Close:
                cgpath.closeSubpath()
            default:
                continue
            }
        }
        return cgpath
    }
}
