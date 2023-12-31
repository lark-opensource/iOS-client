//
//  InstanceDecoration.swift
//  Calendar
//
//  Created by Liang Hongbin on 11/11/22.
//

import UIKit
import Foundation

class Indicator: CAShapeLayer {
    override init() {
        super.init()
        masksToBounds = true
    }

    override init(layer: Any) {
        super.init(layer: layer)
        masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateWith(iWidth: CGFloat, iHeight: CGFloat) {
        let iPath = CGMutablePath()
        let rotateAroundCenter = CGAffineTransform(translationX: iWidth / 2, y: 0).rotated(by: .pi / -4)
            .translatedBy(x: -iWidth / 2 - iHeight / 4, y: 0)
        iPath.addLines(between: [CGPoint(x: iWidth / 2, y: 0), CGPoint(x: iWidth / 2, y: iHeight)], transform: rotateAroundCenter)

        path = iPath
        lineWidth = iHeight
        frame = CGRect(origin: .zero, size: CGSize(width: iWidth, height: iHeight))
    }
}

class DashedBorder: CAShapeLayer {
    override init() {
        super.init()
        fillColor = nil
        lineWidth = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateWith(rect: CGRect, cornerWidth: CGFloat) {
        guard cornerWidth >= 0, 2 * cornerWidth <= rect.width else { return }
        path = CGMutablePath(roundedRect: rect, cornerWidth: cornerWidth, cornerHeight: cornerWidth, transform: nil)
    }
}
