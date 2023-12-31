//
//  OcrTextArea.swift
//  LarkImageEditor
//
//  Created by Fan Xia on 2021/3/12.
//

import UIKit
import Foundation
import ServerPB

final class OcrTextArea {
    private var points = [CGPoint]()

    init(polygon: Polygon, originalSize: CGSize, scaledTo targetSize: CGSize) {
        if originalSize.width == 0 || originalSize.height == 0 {
            return
        }
        let xRatio = targetSize.width / originalSize.width
        let yRatio = targetSize.height / originalSize.height
        for point in polygon.points {
            points.append(CGPoint(x: CGFloat(point.x) * xRatio, y: CGFloat(point.y) * yRatio))
        }
    }

    func getBezierPath() -> UIBezierPath {
        let path = UIBezierPath()
        for point in points {
            if point == points.first {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        return path
    }
}
