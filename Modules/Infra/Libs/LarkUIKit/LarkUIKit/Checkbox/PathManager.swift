//
//  PathManager.swift
//  LarkUIKit
//
//  Created by 刘晚林 on 2017/1/6.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

final class PathManager: NSObject {
    var size: CGFloat = 0.0
    var lineWidth: CGFloat = 0.0
    var innerCycloRadius: CGFloat = 8
    var boxType: CheckboxType = .circle

    func pathForBox() -> UIBezierPath {
        var path: UIBezierPath

        switch self.boxType {
        case .square:
            path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.size, height: self.size), cornerRadius: 3.0)
            path.apply(CGAffineTransform(rotationAngle: CGFloat.pi * 2.5))
            path.apply(CGAffineTransform(translationX: self.size, y: 0))
        case .circle, .concentric:
            let radius = self.size / 2.0
            path = UIBezierPath(
                arcCenter: CGPoint(x: radius, y: radius),
                radius: radius - lineWidth / 2.0,
                startAngle: -CGFloat.pi / 4,
                endAngle: 2 * CGFloat.pi - CGFloat.pi / 4, clockwise: true
            )
        }

        return path
    }

    func pathForCheckMark() -> UIBezierPath {
        let markPath = UIBezierPath()

        func addCheckMark(to path: UIBezierPath) {
            markPath.move(to: CGPoint(x: self.size / 3.1578, y: self.size / 2))
            markPath.addLine(to: CGPoint(x: self.size / 2.0618, y: self.size / 1.578_94))
            markPath.addLine(to: CGPoint(x: self.size / 1.3953, y: self.size / 2.7272))
        }

        switch boxType {
        case .circle:
            addCheckMark(to: markPath)
        case .square:
            addCheckMark(to: markPath)
            if self.boxType == .square {
                markPath.apply(CGAffineTransform(scaleX: 1.5, y: 1.5))
                markPath.apply(CGAffineTransform(translationX: -self.size / 4, y: -self.size / 4))
            }
        case .concentric:
            markPath.addArc(withCenter: CGPoint(x: self.size / 2, y: self.size / 2),
                            radius: innerCycloRadius,
                            startAngle: 0,
                            endAngle: CGFloat(Double.pi * 2),
                            clockwise: true)
        }

        return markPath
    }
}
