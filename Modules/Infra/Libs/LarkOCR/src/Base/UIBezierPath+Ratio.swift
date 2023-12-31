//
//  UIBezierPath+Ratio.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/26.
//

import UIKit
import Foundation

extension UIBezierPath {

    public convenience init(roundedPolygon points: [CGPoint], ratio: CGFloat) {
        self.init()
        for i in 0 ..< points.count {
            var prev = i - 1
            if prev < 0 {
                prev = points.count - 1
            }

            var next = i + 1
            if next >= points.count {
                next = 0
            }

            let p1 = points[prev]
            let p2 = points[i]
            let p3 = points[next]

            let p12 = CGPoint(
                x: (p1.x + p2.x) / 2 * ratio + p2.x * (1 - ratio),
                y: (p1.y + p2.y) / 2 * ratio + p2.y * (1 - ratio)
            )
            let p23 = CGPoint(
                x: (p2.x + p3.x) / 2 * ratio + p2.x * (1 - ratio),
                y: (p2.y + p3.y) / 2 * ratio + p2.y * (1 - ratio)
            )

            if self.isEmpty {
                self.move(to: p1)
            }
            self.addLine(to: p12)
            self.addQuadCurve(to: p23, controlPoint: p2)
        }
    }

    public convenience init(roundedPolygon points: [CGPoint], radius: CGFloat) {
        self.init()
        for i in 0 ..< points.count {
            var prev = i - 1
            if prev < 0 {
                prev = points.count - 1
            }

            var next = i + 1
            if next >= points.count {
                next = 0
            }

            let p1 = points[prev]
            let p2 = points[i]
            let p3 = points[next]

            let p12Distances = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))

            let p12 = CGPoint(
                x: p2.x + (p1.x - p2.x) * 4 / p12Distances,
                y: p2.y + (p1.y - p2.y) * 4 / p12Distances
            )

            let p23Distances = sqrt(pow(p2.x - p3.x, 2) + pow(p2.y - p3.y, 2))

            let p23 = CGPoint(
                x: p2.x + (p3.x - p2.x) * 4 / p23Distances,
                y: p2.y + (p3.y - p2.y) * 4 / p23Distances
            )

            if self.isEmpty {
                let p21Distances = sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
                let p21 = CGPoint(
                    x: p1.x + (p2.x - p1.x) * 4 / p21Distances,
                    y: p1.y + (p2.y - p1.y) * 4 / p21Distances
                )
                self.move(to: p21)
            }
            self.addLine(to: p12)
            self.addQuadCurve(to: p23, controlPoint: p2)
        }
    }

}
