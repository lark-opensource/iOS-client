//
//  TriangleView.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/12/15.
//

import Foundation
import UniverseDesignColor

final class TriangleView: UIView {
    var triangleColor: UIColor = UDColor.R500 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        triangleColor.set()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.fill()
    }
}
